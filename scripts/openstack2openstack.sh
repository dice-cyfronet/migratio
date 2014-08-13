#!/bin/bash

set -x

export __dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -eq 0 ] || [ $# -eq 1 ]
then
    echo "Usage: $0 <image-uuid> <config-file>"
    exit 1
fi

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

command -v glance > /dev/null 2>&1 || { echo "Need to have 'glance'" >&2; exit 1; }
command -v rsync > /dev/null 2>&1 || { echo "Need to have 'rsync'" >&2; exit 1; }
command -v ssh > /dev/null 2>&1 || { echo "Need to have 'ssh'" >&2; exit 1; }

ssh ${EXTERNAL_USER}@${EXTERNAL_HOST} command -v glance > /dev/null 2>&1 || { echo "Need to have 'glance' on external host" >&2; exit 1; }

image_uuid=$1
image_list=$(glance image-list)

check_local=$(echo "${image_list}" | grep ${image_uuid} | wc -l)

if [ ${check_local} -eq 1 ]
then
    remote_checksums=$(ssh ${EXTERNAL_USER}@${EXTERNAL_HOST} \
        "source ~/.creds;
        glance image-list | head -n -1 | tail -n +4 | awk '{print \$2}' | while read remote_image_uuid
        do
            glance image-show \${remote_image_uuid} | grep checksum | awk '{print \$4}'
        done")

    checksum=$(glance image-show ${image_uuid} | grep checksum | awk '{print $4}')
    check_remote=$(echo "${remote_checksums}" | grep ${checksum} | wc -l)

    if [ ${check_remote} -eq 0 ]
    then
        image_name=$(echo "${image_list}" | grep ${image_uuid} | awk -F'|' '{print $3}' | sed -e 's/^ *//' -e 's/ *$//')
        disk_format=$(echo "${image_list}" | grep ${image_uuid} | awk -F'|' '{print $4}' | sed -e 's/^ *//' -e 's/ *$//')
        container_format=$(echo "${image_list}" | grep ${image_uuid} | awk -F'|' '{print $5}' | sed -e 's/^ *//' -e 's/ *$//')
        hash_sum=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)

        rsync ${IMAGES_DIR}/${image_uuid} \
            ${EXTERNAL_USER}@${EXTERNAL_HOST}:/tmp/${image_uuid}-${hash_sum}
        echo "Transfered"

        ssh ${EXTERNAL_USER}@${EXTERNAL_HOST} \
            "source ~/.creds;
            glance image-create \
            --name \"${image_name}-${hash_sum}\" \
            --disk-format ${disk_format} \
            --container-format ${container_format} \
            --property source_uuid=${image_uuid} \
            --property source_cs=${SOURCE_CS} < /tmp/${image_uuid}-${hash_sum}; \
            rm -f /tmp/${image_uuid}-${hash_sum}"
        echo "Registered"
        exit 0
    else
        echo "Requested image was uploaded!"
        exit 1
    fi
else
    echo "Requested image not exist!"
    exit 1
fi
