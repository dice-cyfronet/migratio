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

: ${AWS_ACCESS_KEY:?"Need to set AWS_ACCESS_KEY non-empty"}
: ${AWS_SECRET_KEY:?"Need to set AWS_SECRET_KEY non-empty"}
: ${EC2_URL:?"Need to set EC2_URL non-empty"}
: ${AWS_REGION:?"Need to set AWS_REGION non-empty"}
: ${SOURCE_CS:?"Need to set SOURCE_CS non-empty"}

command -v glance > /dev/null 2>&1 || { echo "Need to have 'glance'" >&2; exit 1; }

command -v sudo > /dev/null 2>&1 || { echo "Need to have 'sudo'" >&2; exit 1; }
command -v qemu-img > /dev/null 2>&1 || { echo "Need to have 'qemu-img'" >&2; exit 1; }

command -v ec2-import-instance > /dev/null 2>&1 || { echo "Need to have 'ec2-import-instance'" >&2; exit 1; }
command -v ec2-describe-conversion-tasks > /dev/null 2>&1 || { echo "Need to have 'ec2-describe-conversion-tasks'" >&2; exit 1; }
command -v ec2-create-image > /dev/null 2>&1 || { echo "Need to have 'ec2-create-image'" >&2; exit 1; }
command -v ec2-describe-images > /dev/null 2>&1 || { echo "Need to have 'ec2-describe-image'" >&2; exit 1; }
command -v ec2-create-tags > /dev/null 2>&1 || { echo "Need to have 'ec2-create-tags'" >&2; exit 1; }

image_uuid=$1
image_list=$(glance image-list)

check_local=$(echo "${image_list}" | grep ${image_uuid} | wc -l)

if [ ${check_local} -eq 1 ]
then
    image_name=$(echo "${image_list}" | grep ${image_uuid} | awk -F'|' '{print $3}' | sed -e 's/^ *//' -e 's/ *$//')
    hash_sum=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)

    if [ ! -f /tmp/${image_uuid}.raw ]
    then
        sudo qemu-img convert -f qcow2 -O raw /var/lib/glance/images/${image_uuid} /tmp/${image_uuid}.raw
    fi

    check_remote=$(ec2-describe-images | grep IMAGE | grep ${image_uuid} | wc -l)
    if [ ${check_remote} -eq 0 ]
    then
        ec2-import-instance /tmp/${image_uuid}.raw -f RAW -b imported-images -p Linux --region ${AWS_REGION} -t m3.medium -a x86_64 -d ${image_uuid}-${hash_sum} -o ${AWS_ACCESS_KEY} -w ${AWS_SECRET_KEY}
        echo "Transfered"

        sleep 30

        __output=$(ec2-describe-conversion-tasks | grep ${image_uuid}-${hash_sum})

        if [ ! -z "${__output}" ]
        then
            instance=$(echo ${__output} | cut -f 12 -d " ")

            until echo ${__output} | grep -E complete
            do
                sleep 30
                __output=$(ec2-describe-conversion-tasks | grep ${instance})
            done

            sleep 30

            ec2-create-image -n ${image_uuid}-${hash_sum} -d "${image_name}-${image_uuid}-${hash_sum}" ${instance}
            __ami_id=$(ec2-describe-images | grep ${image_uuid}-${hash_sum} | awk '{print $2}')
            ec2-create-tags ${__ami_id} --tag source_cs=${SOURCE_CS} --tag source_uuid=${image_uuid} --tag Name=${image_name}-${image_uuid}-${hash_sum}
            echo "Registered"

            rm -f /tmp/${image_uuid}.raw
            exit 0
        else
            echo "Image was not uploaded!"
            exit 1
        fi
    fi
else
    echo "Requested image not exist!"
    exit 1
fi
