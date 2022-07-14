#!/bin/bash

# Note:
# It may be undefined in some environments, so it is explicitly stated.
# Linux basic commands are not specified.
# If the path is different, it must be rewritten.
AWS="aws"
ZIP="zip"

# Note: Change parameter before use ./aws_send_log_to_s3.sh
LOGFILE="/var/log/aws_send_log_to_s3.log"
BUCKET="BUCKET"
BUCKET_URI="BUCKET_URI"
TARGET_LOGS=("/var/log/messages", "/var/log/http/access.log")
MODE="zip" # zip or tar.gz

return_code=0

# Redirect stdout, stderr
# Note: stdout are not displayed. stderr are output to logfile.
exec 1> /dev/null
exec 2>> ${LOGFILE}

# Use when an error occurs 
function log() {
    local fname=${BASH_SOURCE[1]##*/} # = aws_send_log_to_s3.sh

    # Format example: 2012/03/04 05:06:07 (aws_send_log_to_s3.sh:89:main) ERROR: hoge
    echo -e "$(date '+%Y/%m/%d %H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $@" | tee -a ${LOGFILE}
}

# Compress and send to S3
function send_file_to_s3bucket() {

    target_file=${1}
    mode=${2}

    if [ ${mode} == "zip" ]; then
        compressed_file=${target_file}.zip
        ${ZIP} ${compressed_file} ${target_file}

    elif [ ${mode} == "tar.gz" ]; then
        compressed_file=${target_file}.tgz
        tar -czf ${compressed_file} ${target_file}

    else
        log "ERROR: \"mode\" is invalid parameter. Use \"zip\" or \"tar.gz\"."
        return 1

    fi

    ${AWS} s3 cp ${compressed_file} s3://${BUCKET}/${BUCKET_URI}

    return ${?}
}

log "Startup"

for log in "${TARGET_LOGS[@]}"; do

    target_date=$(date "+%Y%m%d" -d "1 day ago")
    target_log="${log}-${target_date}"

    # True if the file exists and its size is greater than 0
    if [ -s ${target_log} ]; then
        send_file_to_s3bucket ${target_log} ${MODE}

        if [ ${?} -eq 0 ]; then
            log "INFO: Success to send ${target_log} to S3."

        else
            log "ERROR: Failure to send ${target_log} to S3."
            return_code=1
        fi

    # True if the file exists, but the file is enpty
    elif [ -f ${target_log} ]
        log "INFO: ${target_log} is enpty. Skip send processing."
    else
        log "ERROR: not fount ${target_log}"
        return_code=1
    fi

done

log "Finish"
exit ${return_code}