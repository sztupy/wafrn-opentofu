#!/usr/bin/env bash

set -e

BACKUP_DIR=$1
BACKUP_SIZE=`du -sb "$BACKUP_DIR" | cut -f 1`
# each backup is 3 files, so this should keep 2 backups up even if everything else is deleted
FILES_TO_KEEP=6

function get_biggest_file() {
  BIGGEST_FILE=`s3cmd -c $CONFIG_FILE ls -r s3://$BUCKET_NAME | sort | head -n -$FILES_TO_KEEP |sort -k 3 | tail -n 1 | awk '{print $4}'`
}

function get_bucket_size() {
  BUCKET_SIZE=`s3cmd -c $CONFIG_FILE du s3://$BUCKET_NAME | awk '{print $1}'`
}

function run_backup() {
  get_bucket_size

  while [ $(( $BUCKET_SIZE + $BACKUP_SIZE)) -gt $MAX_SIZE_BYTES ]; do
    get_biggest_file
    if [ -z "$BIGGEST_FILE" ]; then
      echo "WARNING! No more files to delete"
      break
    fi
    echo "Deleting file $BIGGEST_FILE to make space"
    s3cmd -c $CONFIG_FILE rm "$BIGGEST_FILE"
    get_bucket_size
    echo "Bucket size is $BUCKET_SIZE"
  done

  s3cmd -c $CONFIG_FILE sync $BACKUP_DIR s3://$BUCKET_NAME
}

%{if has_onsite_backup}
echo "Starting on-site backup"
MAX_SIZE_BYTES=${onsite_max_size}000000000000
CONFIG_FILE="$HOME/onsite.s3cfg"
BUCKET_NAME=${onsite_bucket_name}
run_backup
echo "Finishing on-site backup"
%{endif}

%{if has_offsite_backup}
echo "Starting off-site backup"
MAX_SIZE_BYTES=${offsite_max_size}000000000000
CONFIG_FILE="$HOME/offsite.s3cfg"
BUCKET_NAME=${offsite_bucket_name}
run_backup
echo "Finishing on-site backup"
%{endif}

# # Uncomment lines below to add additional backup locations
# echo "Starting backup"
#
# # Maximum size you want your bucket to be. This is 1 GB below
# MAX_SIZE_BYTES=1000000000000
#
# # Use s3cmd --configure to generate this file
# CONFIG_FILE="$HOME/additional.s3cfg"
#
# # The name of the bucket to backup to
# BUCKET_NAME=bucket_name
#
# run_backup
#
# echo "Finishing backup"
