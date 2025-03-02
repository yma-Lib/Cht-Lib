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
        sed -i "/server_name $domain;/i map \$http_user_agent \$deny_access {\n    default 0;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/96\\.0\\.4664\\.45 Safari/537\\.36\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64; rv:94\\.0\\) Gecko/20100101 Firefox/94\\.0\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64; rv:95\\.0\\) Gecko/20100101 Firefox/95\\.0\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/95\\.0\\.4638\\.69 Safari/537\\.36\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/96\\.0\\.4664\\.93 Safari/537\\.36\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; rv:91\\.0\\) Gecko/20100101 Firefox/91\\.0\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/96\\.0\\.4664\\.55 Safari/537\\.36 Edg/96\\.0\\.1054\\.34\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/95\\.0\\.4638\\.69 Safari/537\\.36 Edg/95\\.0\\.1020\\.53\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 6\\.1; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/96\\.0\\.4664\\.45 Safari/537\\.36\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/95\\.0\\.4638\\.69 Safari/537\\.36 OPR/81\\.0\\.4196\\.60\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/96\\.0\\.4664\\.45 Safari/537\\.36 Edg/96\\.0\\.1054\\.29\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; rv:91\\.0\\) Gecko/20100101 Firefox/91\\.0\" 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/105\\.0\\.0\\.0 Safari/537\\.36\" 1;\n    \"~*Java/1\\.8\\.0_431\" 1;\n}" /etc/nginx/sites-available/default
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
