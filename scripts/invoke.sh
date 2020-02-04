#!/bin/bash

# the project root directory, parent directory of this script file
dir="$(cd "$(dirname "$0")/.."; pwd)"

PAYLOAD=$(bash "$dir/scripts/s3-put-payload.sh" uploads/squirrel.jpg)

source "$dir/settings.sh"

aws lambda invoke \
    --region $AWS_REGION \
    --function-name $FUNCTION \
    --payload "$PAYLOAD" \
    "$dir/invoke-output.json"

URL=$(jq '.body' --raw-output invoke-output.json)

curl $URL --output "$dir/squirrel-gray.jpg"