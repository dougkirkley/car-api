#!/bin/bash

URL=$(terraform output api_url)
DATA=$(cat ./example.json)

echo "Checking POST Request"
curl -s -XPOST -d "${DATA}" "${URL}"
echo
echo "Checking GET items request"
curl -s "${URL}"
echo
echo "Checking GET item request"
ITEM=$(curl -s "${URL}" | jq -r '.[0].id')
curl -s "${URL}/${ITEM}"
echo
echo "Checking non-existant item"
curl -s "${URL}/notreal"
echo
