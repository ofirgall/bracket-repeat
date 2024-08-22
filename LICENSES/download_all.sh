#!/usr/bin/env bash

licenses=$(curl https://api.github.com/licenses)

echo "$licenses" | jq -c '.[]' |
while read -r row
do
  name=$(echo "$row" | jq '.spdx_id' --raw-output)
  url=$(echo "$row" | jq '.url' --raw-output)
  body=$(curl $url | jq '.body' --raw-output)
  echo "$body" > $name
done

