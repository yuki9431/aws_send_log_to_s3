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
MODE="zip" # zip or tgz

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
function send_dir_to_s3bucket() {

    target_dir=${1}
    mode=${2}

    if [ ${mode} == "zip" ]; then
        compressed_file=${target_dir##*/}.zip # /tmp/hoge/fuga -> fuga.zip
        ${ZIP} -r ${compressed_file} ${target_dir}

    elif [ ${mode} == "tgz" ]; then
        compressed_file=${target_dir##*/}.tgz  # /tmp/hoge/fuga -> fuga.tgz
        tar -czf ${compressed_file} ${target_dir}

    else
        log "ERROR: \"mode\" is invalid parameter. Use \"zip\" or \"tgz\"."
        return 1

    fi

    ${AWS} s3 cp ${compressed_file} s3://${BUCKET}/${BUCKET_URI} --recursive

    if [ ${?} -eq 0 ]; then
        log "INFO: Success to send ${compressed_file} to S3."

    else
        log "ERROR: Failure to send ${compressed_file} to S3."
        return 1

    fi

    return 0
}

log "Start"

return_code=0
target_date=$(date "+%Y%m%d" -d "1 day ago")
temporary_directory="/tmp/aws_send_log_to_s3_tmp/${target_date}"

mkdir -p ${temporary_directory}

# Copy target log to temporary_directory
for log in "${TARGET_LOGS[@]}"; do

    target_log="${log}-${target_date}"

    # True if the file exists and its size is greater than 0
    if [ -s ${target_log} ]; then
        cp -p ${target_log} ${temporary_directory}

    # True if the file exists, but the file is enpty
    elif [ -f ${target_log} ]
        log "INFO: ${target_log} is enpty. Skip send processing."

    else
        log "ERROR: not fount ${target_log}"
        return_code=1
    fi

done

send_dir_to_s3bucket ${temporary_directory} ${MODE}
rm -rf ${temporary_directory}
log "Finish"

exit ${return_code}
