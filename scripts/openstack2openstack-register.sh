#!/bin/bash

export __dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -eq 0 ] || [ $# -eq 1 ]
then
    echo "Usage: $0 <image-uuid> <config-file>"
    exit 1
fi

mkdir -p ${__dir}/logs
. ~/.creds
. $2

: ${OS_TENANT_NAME:?"Need to set OS_TENANT_NAME non-empty"}
: ${OS_USERNAME:?"Need to set OS_USERNAME non-empty"}
: ${OS_PASSWORD:?"Need to set OS_PASSWORD non-empty"}
: ${OS_AUTH_URL:?"Need to set OS_AUTH_URL non-empty"}

: ${IMAGES_DIR:?"Need to set IMAGES_DIR non-empty"}

: ${EXTERNAL_USER:?"Need to set EXTERNAL_USER non-empty"}
: ${EXTERNAL_HOST:?"Need to set EXTERNAL_HOST non-empty"}
: ${SOURCE_CS:?"Need to set SOURCE_CS non-empty"}

command -v glance > /dev/null 2>&1 || { echo "No 'glance' installed" >&2; exit 1; }
command -v rsync > /dev/null 2>&1 || { echo "No 'rsync' installed" >&2; exit 1; }
command -v ssh > /dev/null 2>&1 || { echo "No 'ssh' installed" >&2; exit 1; }

ssh ${EXTERNAL_USER}@${EXTERNAL_HOST} command -v glance > /dev/null 2>&1 || { echo "No 'glance' on external host" >&2; exit 1; }

image_uuid=$1

image_list=$(glance image-list) &>> ${__dir}/logs/o2o-r.log
echo "$(date) [Result for image_list]: ${image_list}" &>> ${__dir}/logs/o2o-r.log

check_local=$(echo "${image_list}" | grep ${image_uuid} | wc -l) &>> ${__dir}/logs/o2o-r.log
echo "$(date) [Result for check_local]: ${check_local}" &>> ${__dir}/logs/o2o-r.log

if [ ${check_local} -eq 1 ]
then
    remote_checksums=$(ssh ${EXTERNAL_USER}@${EXTERNAL_HOST} \
        "source ~/.creds;
        glance image-list | head -n -1 | tail -n +4 | awk '{print \$2}' | while read remote_image_uuid
        do
            glance image-show \${remote_image_uuid} | grep checksum | awk '{print \$4}'
        done") &>> ${__dir}/logs/o2o-r.log

    checksum=$(glance image-show ${image_uuid} | grep checksum | awk '{print $4}') &>> ${__dir}/logs/o2o-r.log
    echo "$(date) [Result for checksum]: ${checksum}" &>> ${__dir}/logs/o2o-r.log

    check_remote=$(echo "${remote_checksums}" | grep ${checksum} | wc -l) &>> ${__dir}/logs/o2o-r.log
    echo "$(date) [Result for check_remote]: ${check_remote}" &>> ${__dir}/logs/o2o-r.log

    if [ ${check_remote} -eq 0 ]
    then
        image_name=$(echo "${image_list}" | grep ${image_uuid} | awk -F'|' '{print $3}' | sed -e 's/^ *//' -e 's/ *$//') &>> ${__dir}/logs/o2o-r.log
        echo "$(date) [Result for image_name]: ${image_name}" &>> ${__dir}/logs/o2o-r.log

        disk_format=$(echo "${image_list}" | grep ${image_uuid} | awk -F'|' '{print $4}' | sed -e 's/^ *//' -e 's/ *$//') &>> ${__dir}/logs/o2o-r.log
        echo "$(date) [Result for disk_format]: ${image_name}" &>> ${__dir}/logs/o2o-r.log

        container_format=$(echo "${image_list}" | grep ${image_uuid} | awk -F'|' '{print $5}' | sed -e 's/^ *//' -e 's/ *$//') &>> ${__dir}/logs/o2o-r.log
        echo "$(date) [Result for container_format]: ${container_format}" &>> ${__dir}/logs/o2o-r.log

        ssh ${EXTERNAL_USER}@${EXTERNAL_HOST} \
            "source ~/.creds;
            glance image-create \
            --name \"${image_name}\" \
            --disk-format ${disk_format} \
            --container-format ${container_format} \
            --property source_uuid=${image_uuid} \
            --property source_cs=${SOURCE_CS} < /tmp/${image_uuid}; \
            rm -f /tmp/${image_uuid}" &>> ${__dir}/logs/o2o-r.log

        echo "Registered"
        exit 0
    else
        echo "Requested image was uploaded."
        exit 1
    fi
else
    echo "Requested image not exist."
    exit 1
fi
