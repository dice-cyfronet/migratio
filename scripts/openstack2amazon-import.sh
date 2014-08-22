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

command -v ec2-describe-images > /dev/null 2>&1 || { echo "No 'ec2-describe-images' installed" >&2; exit 1; }
command -v ec2-describe-conversion-tasks > /dev/null 2>&1 || { echo "No 'ec2-describe-conversion-tasks' installed" >&2; exit 1; }

image_uuid=$1

if [ -f /tmp/${image_uuid}.raw ]
then
    check_remote=$(ec2-describe-images | grep IMAGE | grep ${image_uuid} | wc -l) &>> ${__dir}/logs/o2a-i.log
    echo ${check_remote} &>> ${__dir}/logs/o2a-i.log

    if [ ${check_remote} -eq 0 ]
    then
        __output=$(ec2-describe-conversion-tasks | grep ${image_uuid}) &>> ${__dir}/logs/o2a-i.log
        echo ${__output} &>> ${__dir}/logs/o2a-i.log

        if [ ! -z "${__output}" ]
        then
            instance=$(echo ${__output} | cut -f 12 -d " ") &>> ${__dir}/logs/o2a-i.log
            echo ${instance} &>> ${__dir}/logs/o2a-i.log

            until echo ${__output} | grep -E complete
            do
                sleep 30
                __output=$(ec2-describe-conversion-tasks | grep ${instance}) &>> ${__dir}/logs/o2a-i.log
                echo ${__output} &>> ${__dir}/logs/o2a-i.log
            done

            sleep 30
            echo "Image imported"
            exit 0
        else
            echo "Image was not uploaded!"
            exit 1
        fi
    else
        echo "Requested image was uploaded!"
        exit 1
    fi
else
    echo "Image was not converted!"
    exit 1
fi
