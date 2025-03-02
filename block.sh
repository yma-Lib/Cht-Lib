#!/bin/bash

function backup_nginx_config {
    # Путь к файлу конфигурации Nginx (используем default)
    local nginx_config="/etc/nginx/sites-available/default"
    local backup_file="${nginx_config}.bak_$(date +%F_%T)"
    cp $nginx_config $backup_file
    echo "Backup of default configuration saved as $backup_file"
}

function add_user_agent_block {
    # Добавляем блокировку по юзер-агенту в default конфиг
    if grep -q "map \$http_user_agent \$deny_access" /etc/nginx/sites-available/default; then
        echo "User-agent block already exists in default configuration"
    else
        sed -i "/server_name $domain;/i map \$http_user_agent \$deny_access {\n    default 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/96\\.0\\.4664\\.45 Safari/537\\.36\" 0;\n}" /etc/nginx/sites-available/default
        echo "User-agent block added to default configuration"
    fi
}

function del_user_agent_block {
    # Удаляем блокировку по юзер-агенту из default конфига
    if grep -q "map \$http_user_agent \$deny_access" /etc/nginx/sites-available/default; then
        sed -i "/map \$http_user_agent \$deny_access {/,/}/d" /etc/nginx/sites-available/default
        echo "User-agent block removed from default configuration"
    else
        echo "No user-agent block found in default configuration"
    fi
}

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <domain> <-add|-del>"
    exit 1
fi

domain=$1
action=$2

# Сохраняем резервную копию файла default перед изменениями
backup_nginx_config

case "$action" in
    -add)
        add_user_agent_block
        ;;
    -del)
        del_user_agent_block
        ;;
    *)
        echo "Invalid option: $action. Use -add or -del."
        exit 1
        ;;
esac

# Перезапуск Nginx после изменений
nginx -t && systemctl restart nginx
