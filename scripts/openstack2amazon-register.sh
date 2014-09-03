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

: ${AWS_ACCESS_KEY:?"Need to set AWS_ACCESS_KEY non-empty"}
: ${AWS_SECRET_KEY:?"Need to set AWS_SECRET_KEY non-empty"}
: ${EC2_URL:?"Need to set EC2_URL non-empty"}
: ${AWS_REGION:?"Need to set AWS_REGION non-empty"}
: ${SOURCE_CS:?"Need to set SOURCE_CS non-empty"}

command -v glance > /dev/null 2>&1 || { echo "No 'glance'" >&2; exit 1; }

command -v ec2-describe-images > /dev/null 2>&1 || { echo "No 'ec2-describe-images' installed" >&2; exit 1; }
command -v ec2-describe-conversion-tasks > /dev/null 2>&1 || { echo "No 'ec2-describe-conversion-tasks' installed" >&2; exit 1; }

command -v ec2-import-instance > /dev/null 2>&1 || { echo "No 'ec2-import-instance' installed" >&2; exit 1; }
command -v ec2-create-image > /dev/null 2>&1 || { echo "No 'ec2-create-image' installed" >&2; exit 1; }
command -v ec2-create-tags > /dev/null 2>&1 || { echo "No 'ec2-create-tags' installed" >&2; exit 1; }

image_uuid=$1

image_list=$(glance image-list) &>> ${__dir}/logs/o2a-c.log
echo "$(date) [Result for glance image-list]: ${image_list}" &>> ${__dir}/logs/o2a-c.log

image_name=$(echo "${image_list}" | grep ${image_uuid} | awk -F'|' '{print $3}' | sed -e 's/^ *//' -e 's/ *$//') &>> ${__dir}/logs/o2a-c.log
echo "$(date) [Result for image_name]: ${image_name}" &>> ${__dir}/logs/o2a-c.log

if [ -f /tmp/${image_uuid}.raw ]
then
    check_remote=$(ec2-describe-images | grep IMAGE | grep ${image_uuid} | wc -l) &>> ${__dir}/logs/o2a-r.log
    echo "$(date) [Result for check_remote]: ${check_remote}" &>> ${__dir}/logs/o2a-r.log

    if [ ${check_remote} -eq 0 ]
    then
        __output=$(ec2-describe-conversion-tasks | grep ${image_uuid} | sort -k6 | tail -n 1) &>> ${__dir}/logs/o2a-r.log
        echo "$(date) [Result for ec2-describe-conversion-tasks]: ${__output}" &>> ${__dir}/logs/o2a-r.log

        if [ ! -z "${__output}" ]
        then
            instance=$(echo ${__output} | cut -f 10 -d " ") &>> ${__dir}/logs/o2a-r.log
            task_import=$(echo ${__output} | cut -f 4 -d " ") &>> ${__dir}/logs/o2a-r.log
            __output=$(ec2-create-image -n ${image_uuid} -d "${image_name}-${image_uuid}" ${instance}) &>> ${__dir}/logs/o2a-r.log
            echo "$(date) [Result for ec2-create-image]: ${__output}" &>> ${__dir}/logs/o2a-r.log

            sleep 30

            __ami_id=$(ec2-describe-images | grep ${image_uuid} | awk '{print $2}') &>> ${__dir}/logs/o2a-r.log
            echo "$(date) [Result for ec2-describe-images]: ${__ami_id}" &>> ${__dir}/logs/o2a-r.log

            until [ -n "${__ami_id}" ]
            do
                sleep 30
                __ami_id=$(ec2-describe-images | grep ${image_uuid} | awk '{print $2}') &>> ${__dir}/logs/o2a-r.log
                echo "$(date) [Result for ec2-describe-images]: ${__ami_id}" &>> ${__dir}/logs/o2a-r.log
            done

            __output=$(ec2-create-tags ${__ami_id} --tag source_cs=${SOURCE_CS} --tag source_uuid=${image_uuid} --tag Name="${image_name}-${image_uuid}") &>> ${__dir}/logs/o2a-r.log
            echo "$(date) [Result for ec2-create-tags]: ${__output}" &>> ${__dir}/logs/o2a-r.log

            __output=$(rm -f /tmp/${image_uuid}.raw*) &>> ${__dir}/logs/o2a-r.log
            echo "$(date) [Result for rm]: ${__output}" &>> ${__dir}/logs/o2a-r.log

            __output=$(ec2-delete-disk-image -t ${task_import} -o ${AWS_ACCESS_KEY} -w ${AWS_SECRET_KEY})
            echo "$(date) [Result for ec2-delete-disk-image]: ${__output}" &>> ${__dir}/logs/o2a-r.log

            __output=$(ec2-terminate-instances ${instance}) &>> ${__dir}/logs/o2a-r.log
            echo "$(date) [Result for ec2-terminate-instances]: ${__output}" &>> ${__dir}/logs/o2a-r.log

            echo "Registered image"
            exit 0
        else
            echo "Image was not uploaded."
            exit 1
        fi
    else
        echo "Requested image was uploaded."
        exit 1
    fi
else
    echo "Image not converted."
    exit 1
fi
