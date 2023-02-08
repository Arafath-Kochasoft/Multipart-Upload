#!/bin/bash

# output file
parts_json="parts.json"
ETag=$(jq -r -r '.ETag' singlepart.json | sed 's/^"\(.*\)"$/\1/')
# temp file
temp_file="temp.json"

# Loop to add objects to the parts list
for i in {1..2}; do
  jq --arg part $i --arg Etag "$ETag" '.Parts |= . + [{"PartNumber": $part, "ETag": $Etag}]' "$parts_json" > "$temp_file"
  mv "$temp_file" "$parts_json"
done
# echo $ETag