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

: ${AWS_ACCESS_KEY:?"Need to set AWS_ACCESS_KEY non-empty"}
: ${AWS_SECRET_KEY:?"Need to set AWS_SECRET_KEY non-empty"}
: ${EC2_URL:?"Need to set EC2_URL non-empty"}
: ${AWS_REGION:?"Need to set AWS_REGION non-empty"}
: ${SOURCE_CS:?"Need to set SOURCE_CS non-empty"}

command -v ec2-describe-images > /dev/null 2>&1 || { echo "Need to have 'ec2-describe-images'" >&2; exit 1; }
command -v ec2-describe-conversion-tasks > /dev/null 2>&1 || { echo "Need to have 'ec2-describe-conversion-tasks'" >&2; exit 1; }

command -v ec2-import-instance > /dev/null 2>&1 || { echo "Need to have 'ec2-import-instance'" >&2; exit 1; }
command -v ec2-create-image > /dev/null 2>&1 || { echo "Need to have 'ec2-create-image'" >&2; exit 1; }
command -v ec2-create-tags > /dev/null 2>&1 || { echo "Need to have 'ec2-create-tags'" >&2; exit 1; }

image_uuid=$1

if [ -f /tmp/${image_uuid}.raw ]
then
    check_remote=$(ec2-describe-images | grep IMAGE | grep ${image_uuid} | wc -l)
    if [ ${check_remote} -eq 1 ]
    then
        __output=$(ec2-describe-conversion-tasks | grep ${image_uuid})

        if [ ! -z "${__output}" ]
        then
            ec2-create-image -n ${image_uuid} -d "${image_name}-${image_uuid}" ${instance}

            sleep 30

            __ami_id=$(ec2-describe-images | grep ${image_uuid} | awk '{print $2}')
            until [ -n "${__ami_id}" ]
            do
                sleep 30
                __ami_id=$(ec2-describe-images | grep ${image_uuid}} | awk '{print $2}')
            done

            ec2-create-tags ${__ami_id} --tag source_cs=${SOURCE_CS} --tag source_uuid=${image_uuid} --tag Name="${image_name}-${image_uuid}"

            rm -f /tmp/${image_uuid}.raw

            echo "Registered image"
            exit 0
        else
            echo "Image was not uploaded!"
            exit 1
        fi
    else
        echo "Requested image was not uploaded!"
        exit 1
    fi
else
    echo "Image not converted!"
    exit 1
fi
