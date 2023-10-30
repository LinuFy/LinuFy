#!/bin/sh

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "[-] Please run as root" >&2;
        exit 1;
    else
        echo "[+] Root user detected" >&2;
    fi
}

check_distro() {
    if [ -f /etc/os-release ]; then
        # On Linux systems
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            echo "[+] Ubuntu distribution detected" >&2;
            if [ "$VERSION_ID" = "22.04" ]; then
                echo "[+] Ubuntu $VERSION_ID detected" >&2;
            else
                echo "[-] Only ubuntu 22.04 is supported" >&2;
            fi
        else
            echo "Only Ubuntu is supported" >&2;
            exit 1;
        fi
    else
        echo "Only Ubuntu is  > /dev/null 2>&1;  supported" >&2;
        exit 1;
    fi
}

check_docker() {
    if [ -x "$(command -v docker)" ]; then
        echo "[+] Docker $(docker version -f "{{.Server.Version}}") detected" >&2;
    else
        echo "[-] Docker not detected" >&2;
        echo "[+] Try to install docker" >&2;
        apt-get update > /dev/null 2>&1;
        apt-get install -y ca-certificates curl gnupg > /dev/null 2>&1;
        install -m 0755 -d /etc/apt/keyrings > /dev/null 2>&1;
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg > /dev/null 2>&1;
        chmod a+r /etc/apt/keyrings/docker.gpg > /dev/null 2>&1;
        echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1;
        apt-get update > /dev/null 2>&1;
        apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1;
    fi
}

check_linufy() {
    if [ "$(docker ps -a -q -f name=myapp)" ]; then
        echo "[+] LinuFy application is detected" >&2;
    else
        echo "[-] LinuFy application not detected" >&2;
        curl -LO https://raw.githubusercontent.com/LinuFy/LinuFy/main/docker-compose.yml > /dev/null 2>&1;
        mkdir -p ./linufy_db
        chown 1000:1000 ./linufy_db
        linufy_db_root_password=$(openssl rand -hex 32)
        linufy_db_password=$(openssl rand -hex 32)
        echo "Set let's encrypt email address (ex. postmaster@example.com):"
        read linufy_le_email
        echo "Set LinuFy domain name (ex. server1.example.com):"
        read linufy_domain_name
        sed -i "s/LINUFY_DB_ROOT_PASSWORD/$linufy_db_root_password/" docker-compose.yml
        sed -i "s/LINUFY_DB_PASSWORD/$linufy_db_password/" docker-compose.yml
        sed -i "s/LINUFY_LE_EMAIL/$linufy_le_email/" docker-compose.yml
        sed -i "s/LINUFY_DOMAIN_NAME/$linufy_domain_name/" docker-compose.yml
        docker compose up -d > /dev/null 2>&1;
        echo "[+] LinuFy application is installed" >&2;
    fi
}

check_root
check_distro
check_docker
check_linufy
