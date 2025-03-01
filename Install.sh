#!/bin/bash

# Обновление системы и установка зависимостей
echo "Обновление системы и установка зависимостей..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget gnupg2 ca-certificates lsb-release ubuntu-keyring

# Добавление репозиториев для PHP и Nginx
echo "Добавление репозиториев для PHP и Nginx..."
sudo add-apt-repository -y ppa:ondrej/php
sudo add-apt-repository -y ppa:ondrej/nginx
sudo apt update -y

# Установка Nginx и PHP (7.4)
echo "Установка Nginx и PHP 7.4..."
sudo apt install -y nginx
sudo apt install -y php7.4-fpm php7.4-cli php7.4-curl php7.4-sqlite3 php7.4-common php7.4-opcache php7.4-mbstring php7.4-xml php7.4-mysql

# Конфигурация PHP
echo "Настройка PHP..."
sudo tee /etc/php/7.4/fpm/conf.d/custom.ini > /dev/null << EOL
upload_max_filesize = 1000M
post_max_size = 1000M
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
max_file_uploads = 20
display_errors = Off
log_errors = On
error_log = /var/log/php_errors.log
date.timezone = "Europe/Moscow"
session.gc_maxlifetime = 1440
session.cookie_secure = On
session.cookie_httponly = On
EOL

# Перезапуск PHP FPM
echo "Перезапуск PHP FPM..."
sudo systemctl restart php7.4-fpm

# Настройка Nginx для вашего сайта
echo "Настройка Nginx для вашего сайта..."
sudo tee /etc/nginx/sites-available/cs2guardian.icu > /dev/null << EOL
server {
    listen 80;
    server_name cs2guardian.icu www.cs2guardian.icu;

    # Корневая директория сайта
    root /var/www/html;  # Или ваш путь /var/www/cs2guardian.icu
    index index.php index.html index.htm;

    # Ограничения на загрузку и таймауты
    client_max_body_size 1000M;
    client_body_timeout 300s;
    client_header_timeout 300s;
    keepalive_timeout 300s;
    send_timeout 300s;

    # Основной обработчик PHP файлов
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # Обработка PHP
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param PHP_VALUE "upload_max_filesize=1000M \n post_max_size=1000M \n max_execution_time=300 \n max_input_time=300";
    }

    # Защита от доступа к скрытым файлам
    location ~ /\.ht {
        deny all;
    }
}
EOL

# Создание симлинка и активация конфигурации
echo "Создание симлинка и активация конфигурации..."
sudo ln -s /etc/nginx/sites-available/cs2guardian.icu /etc/nginx/sites-enabled/

# Проверка синтаксиса конфигурации Nginx
echo "Проверка синтаксиса конфигурации Nginx..."
sudo nginx -t

# Перезапуск Nginx для применения изменений
echo "Перезапуск Nginx..."
sudo systemctl restart nginx

echo "Установка и настройка завершены!"
