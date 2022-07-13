#!/bin/bash

LOGFILE="/var/log/aws_send_log_to_s3.log"
AWS="aws"
BUCKET="TEST"
BUCKET_URI="staging"
TARGET_LOGS=("/var/log/messages", "/var/log/http/access.log")

# Use when an error occurs 
function log() {
    local fname=${BASH_SOURCE[1]##*/} # = aws_send_log_to_s3.sh

    # Example output: 2012/03/04 05:06:07 (aws_send_log_to_s3.sh:89:main) EXAMPLE ERROR
    echo -e "$(date '+%Y/%m/%d %H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $@" | tee -a ${LOGFILE}
}

# Import Config
cd $(dirname "$0")
. oci_update_lb_ssl.conf

# Redirect stdout, stderr
exec 1> /dev/null
exec 2>> ${LOGFILE}

# Search target logs
for log in "${TARGET_LOGS[@]}"; do

    target_date=$(date "+%Y%m%d" -d "1 day ago")
    target_log="${log}-${target_date}"

    if [ -e ${target_log} ]; then
        log "not fount ${target_log}"
    fi

done

# Compress target logs

# Upload target log to S3
aws s3 cp ./folder s3://${BUCKET}/${BUCKET_URI} --recursive
