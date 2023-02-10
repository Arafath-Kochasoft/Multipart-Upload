# !/bin/bash
: << 'EOF'
# output file
parts_json="parts.json"
ETag=$(jq -r -r '.ETag' singlepart.json | sed 's/^"\(.*\)"$/\1/')
# temp file
temp_file="temp.json"

# Loop to add objects to the parts list
for i in {1..2}; do
  jq --arg part $i --arg Etag "$ETag" '.Parts |= . + [{"PartNumber": $part|tonumber, "ETag": $Etag}]' "$parts_json" > "$temp_file"
  mv "$temp_file" "$parts_json"
done
echo $ETag
EOF

# value=$(jq -c '.' parts.json)
# echo $value

# file_path='./progress-multipart.json'

# if jq '.Uploads' $file_path > /dev/null 2>&1; then
#     echo "The key 'Uploads' exists."
# else
#     echo "The key 'Uploads' does not exist."
# fi
# file_path="./progress-multipart.json"

# if jq '.Uploads' $file_path 2>/dev/null | grep 'null' >/dev/null; then
#     echo "The key 'Uploads' does not exist."
# else
#     echo "The key 'Uploads' exists."
# fi

dividend=10.5
divisor=3.2

result=$(echo "$dividend / $divisor" | bc -l)

echo "Result: $result"