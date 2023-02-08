#!/bin/bash

filename="./BlackBox"
part_size=6291456 # 6 MB
# part_size=6291456*7/6 # 6 MB
black_image="Black-Image"
bucket_name="blackbox-test-00811"

# get size of a give file name
function get_file_size() {
  filename=$1

  filesize=$(stat -c "%s" "$filename")
  echo $filesize
}

# create the bucket if it does not already exist
function create_bucket() {
  bucket_exists=$(ibmcloud cos buckets | grep -o $bucket_name)

  if [ -z "$bucket_exists" ]; then
    ibmcloud cos bucket-create --bucket $bucket_name
  fi
}

# start a multipart upload session for the upload and then store the ID of the
# session in multipart.json
function create_multipart_upload() {
  ibmcloud cos multipart-upload-create --bucket $bucket_name --key $black_image --output json > multipart.json
}

# abort the multipart session if needed
function abort_multipart_upload() {
  upload_id=$1

  ibmcloud cos multipart-upload-abort --bucket $bucket_name --key $black_image --upload-id $upload_id
}

function create_part_file() {
  part_num=$1
  # output file
  parts_json="parts.json"
  # get the Etag for the part from the singlepart.json
  ETag=$(jq -r -r '.ETag' singlepart.json | sed 's/^"\(.*\)"$/\1/')
  # temp file
  temp_file="temp.json"

  # add the part number and Etag to the file name parts.json
  jq --arg part $part_num --arg Etag "$ETag" '.Parts |= . + [{"PartNumber": $part, "ETag": $Etag}]' "$parts_json" > "$temp_file"
  mv "$temp_file" "$parts_json"
 
}

# upload a single specific part
function upload_a_part() {
  seek_part=$1
  read_size=$2
  part_num=$3
  upload_id=$4

  # this python file take part size and part number and the part binary will store in out.txt
  python main.py $seek_part $read_size $part_num $filename
  ibmcloud cos part-upload --bucket $bucket_name --key $black_image --upload-id $upload_id --part-number $part_num --body out.txt
}

# complete the multipart upload with the response of json format
function complete_multipart_upload() {
  upload_id=$1

  ibmcloud cos multipart-upload-complete --bucket $bucket_name --key $black_image --upload-id $upload_id --multipart-upload file://$(pwd)/parts.json
}

# number of parts and the remaing parts
function part_count_data() {
  part_size=$1

  file_size=$(get_file_size "$filename")
  part_count=$((file_size/part_size))
  echo $((part_count+1)) $((file_size%part_size))
  # return parts count that can be created using given part size
  # the size of the remaining part
}

function main() {

  echo "Creating a bucket..."
  create_bucket # create a bucket for multipart uplaod
  echo "Bucket created."

  echo "Creating a multipart upload session..."
  create_multipart_upload # create a multipart upload session
  echo "Multipart upload session was created."

  upload_id=$(jq -r '.UploadId' multipart.json) # get the multipart session ID

  read part_count part_remaining < <(part_count_data "$part_size") # calculate the parts that should be upload

  # echo $part_count $part_remaining

  echo "Uploading parts..."
  for ((part_num=1; part_num<part_count; part_num++)); do
    upload_a_part $part_size $part_size $part_num $upload_id
    # create_part_file $part_num
  done

  # upload remaining part after the given part size parts are completed
  if [ $part_remaining -ne 0 ]; then
    echo "Remaining part is uploading..."
    upload_a_part $part_size $part_remaining $part_count $upload_id
    # create_part_file $part_count
    echo "Remaining part was uploaded."
  fi
  echo "All parts were uploaded."

  # complete_multipart_upload $upload_id # complete the multipart upload
}

arg=$1
if [ "$arg" == "main" ]; then
  main
else
  upload_id=$(jq -r '.UploadId' multipart.json) # get the multipart session ID
  abort_multipart_upload $upload_id # abort the multipart upload
fi


