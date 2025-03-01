sudo apt update -y
sudo apt upgrade -y
sudo apt install -y software-properties-common curl wget gnupg2 ca-certificates lsb-release ubuntu-keyring

curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/php-archive-keyring.gpg --yes
echo "deb [signed-by=/usr/share/keyrings/php-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/php.list
sudo apt update -y

sudo add-apt-repository -y ppa:ondrej/nginx
sudo apt update -y

sudo apt install -y php7.4-fpm php7.4-cli php7.4-curl php7.4-mbstring php7.4-opcache php7.4-xml php7.4-mysql php7.4-soap php7.4-gd php7.4-zip php7.4-intl
sudo apt install -y nginx

sudo tee /etc/nginx/sites-available/cs2guardian.icu > /dev/null << EOL
server {
    listen 80;
    server_name cs2guardian.icu www.cs2guardian.icu;
    root /var/www/cs2guardian.icu;
    index index.php index.html index.htm;
    client_max_body_size 50G;
    client_body_timeout 600s;
    client_header_timeout 600s;
    keepalive_timeout 600s;
    send_timeout 600s;
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param PHP_VALUE "upload_max_filesize=50G \n post_max_size=50G \n max_execution_time=3600 \n max_input_time=3600";
    }
    location ~ /\.ht {
        deny all;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/cs2guardian.icu /etc/nginx/sites-enabled/

sudo mkdir -p /var/www/cs2guardian.icu
sudo chown -R www-data:www-data /var/www/cs2guardian.icu
sudo chmod -R 755 /var/www/cs2guardian.icu

sudo tee /etc/php/7.4/fpm/conf.d/99-custom.ini > /dev/null << EOL
upload_max_filesize = 50G
post_max_size = 50G
memory_limit = 16G
max_execution_time = 3600
max_input_time = 3600
max_input_vars = 5000
max_file_uploads = 100
max_input_nesting_level = 5000
date.timezone = "Europe/Moscow"
output_buffering = Off
session.gc_maxlifetime = 86400
session.cookie_secure = On
session.cookie_httponly = On
realpath_cache_size = 4096k
realpath_cache_ttl = 3600
opcache.enable = 1
opcache.memory_consumption = 512
opcache.interned_strings_buffer = 64
opcache.max_accelerated_files = 100000
opcache.revalidate_freq = 0
opcache.validate_permission = 1
opcache.validate_root = 1
EOL

sudo nginx -t
sudo systemctl restart nginx
sudo systemctl restart php7.4-fpm
