#!/bin/bash

url="https://pastebin.com/raw/8LbpK8d9"
phrase="123"

while true; do
    content=$(curl -s $url)
    if [[ "$content" == *"$phrase"* ]]; then
        echo "Фраза найдена!"
        break
    else
        echo "Фраза не найдена, повторяем проверку..."
        sleep 5  # ждем 5 секунд перед следующей проверкой
    fi
done
