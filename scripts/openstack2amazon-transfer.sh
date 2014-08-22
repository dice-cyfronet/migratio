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
command -v ec2-import-instance > /dev/null 2>&1 || { echo "Need to have 'ec2-import-instance'" >&2; exit 1; }

image_uuid=$1

if [ -f /tmp/${image_uuid}.raw ]
then
    check_remote=$(ec2-describe-images | grep IMAGE | grep ${image_uuid} | wc -l)
    if [ ${check_remote} -eq 0 ]
    then
        ec2-import-instance /tmp/${image_uuid}.raw -f RAW -b imported-images -p Linux --region ${AWS_REGION} -t m3.medium -a x86_64 -d ${image_uuid} -o ${AWS_ACCESS_KEY} -w ${AWS_SECRET_KEY}
        sleep 30
        echo "Image transfered"
        exit 0
    else
        echo "Requested image was uploaded!"
        exit 1
    fi
else
    echo "Image not converted!"
    exit 1
fi
