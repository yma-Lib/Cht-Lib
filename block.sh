#!/bin/bash

function backup_nginx_config {
    local backup_file="/etc/nginx/sites-available/${domain}.bak_$(date +%F_%T)"
    cp /etc/nginx/sites-available/$domain $backup_file
    echo "Backup of $domain configuration saved as $backup_file"
}

function add_user_agent_block {
    if grep -q "map \$http_user_agent \$deny_access" /etc/nginx/sites-available/$domain; then
        echo "User-agent block already exists for $domain"
    else
        sed -i "/server_name $domain;/i map \$http_user_agent \$deny_access {\n    default 1;\n    \"~*Mozilla/5\\.0 \\(Windows NT 10\\.0; Win64; x64\\) AppleWebKit/537\\.36 \\(KHTML, like Gecko\\) Chrome/96\\.0\\.4664\\.45 Safari/537\\.36\" 0;\n}" /etc/nginx/sites-available/$domain
        echo "User-agent block added for $domain"
    fi
}

function del_user_agent_block {
    if grep -q "map \$http_user_agent \$deny_access" /etc/nginx/sites-available/$domain; then
        sed -i "/map \$http_user_agent \$deny_access {/,/}/d" /etc/nginx/sites-available/$domain
        echo "User-agent block removed for $domain"
    else
        echo "No user-agent block found for $domain"
    fi
}

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <domain> <-add|-del>"
    exit 1
fi

domain=$1
action=$2

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

nginx -t && systemctl restart nginx
