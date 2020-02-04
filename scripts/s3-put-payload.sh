# the project root directory, parent directory of this script file
dir="$(cd "$(dirname "$0")/.."; pwd)"

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <object.key>" >&2
  exit 1
fi

if [[ ! -f "$dir/$1.json" ]]; then
  cd "$dir/terraform"
  OUTPUT=$(terraform output)
  REGION=$(echo "$OUTPUT" | grep ^region | tr ' ' '\n' | tail -1)
  BUCKET=$(echo "$OUTPUT" | grep ^bucket | tr ' ' '\n' | tail -1)
  FUNCTION=$(echo "$OUTPUT" | grep ^convert_function | tr ' ' '\n' | tail -1)
  OBJECT=$(aws s3api list-objects-v2 \
    --region $REGION \
    --bucket $BUCKET \
    --query "Contents[?Key == '$1']" \
    --output json)
  if [[ $(echo "$OBJECT" | wc --lines) -lt 2 ]]; then
    echo "abort: object not found. region:$REGION bucket:$BUCKET key:$1"
    exit 1
  fi
  echo "$OBJECT" \
    | jq '.[0]' \
    | sed --expression 's|\\\"||g' \
    | jq --arg region $REGION '. + {Region: $region}' \
    | jq --arg bucket $BUCKET '. + {Bucket: $bucket}' \
    | jq --arg "function" $FUNCTION '. + {Function: $function}' --monochrome-output \
    > "$dir/$1.json"
fi

JSON=$(cat "$dir/$1.json")
REGION=$(echo "$JSON" | jq '.Region' --raw-output)
BUCKET=$(echo "$JSON" | jq '.Bucket' --raw-output)
KEY=$(echo "$JSON" | jq '.Key' --raw-output)
SIZE=$(echo "$JSON" | jq '.Size' --raw-output)
ETAG=$(echo "$JSON" | jq '.ETag' --raw-output)
EVENT_TIME=$(echo "$JSON" | jq '.LastModified' --raw-output)

EVENT=$(cat <<EOF
{
  "Records": [
    {
      "eventVersion": "2.0",
      "eventSource": "aws:s3",
      "awsRegion": "REGION",
      "eventTime": "EVENT_TIME",
      "eventName": "ObjectCreated:Put",
      "userIdentity": {
        "principalId": "EXAMPLE"
      },
      "requestParameters": {
        "sourceIPAddress": "127.0.0.1"
      },
      "responseElements": {
        "x-amz-request-qid": "EXAMPLE123456789",
        "x-amz-id-2": "EXAMPLE123/5678abcdefghijklambdaisawesome/mnopqrstuvwxyzABCDEFGH"
      },
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "testConfigRule",
        "bucket": {
          "name": "BUCKET",
          "ownerIdentity": {
            "principalId": "EXAMPLE"
          },
          "arn": "arn:aws:s3:::BUCKET"
        },
        "object": {
          "key": "KEY",
          "size": "SIZE",
          "eTag": "ETAG",
          "sequencer": "0A1B2C3D4E5F678901"
        }
      }
    }
  ]
}
EOF
)

echo "$EVENT" | sed --expression "s|REGION|$REGION|" \
  --expression "s|BUCKET|$BUCKET|" \
  --expression "s|KEY|$KEY|" \
  --expression "s|SIZE|$SIZE|" \
  --expression "s|ETAG|$ETAG|" \
  --expression "s|EVENT_TIME|$EVENT_TIME|"