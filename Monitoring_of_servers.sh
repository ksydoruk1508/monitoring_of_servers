#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

echo -e "${GREEN}"
cat << "EOF"
███████  ██████  ██████      ██   ██ ███████ ███████ ██████      ██ ████████     ████████ ██████   █████  ██████  ██ ███    ██  ██████  
██      ██    ██ ██   ██     ██  ██  ██      ██      ██   ██     ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ████   ██ ██       
█████   ██    ██ ██████      █████   █████   █████   ██████      ██    ██           ██    ██████  ███████ ██   ██ ██ ██ ██  ██ ██   ███ 
██      ██    ██ ██   ██     ██  ██  ██      ██      ██          ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ██  ██ ██ ██    ██ 
██       ██████  ██   ██     ██   ██ ███████ ███████ ██          ██    ██           ██    ██   ██ ██   ██ ██████  ██ ██   ████  ██████  
                                                                                                                                         
                                                                                                                                         
 ██  ██████  ██       █████  ███    ██ ██████   █████  ███    ██ ████████ ███████                                                         
██  ██        ██     ██   ██ ████   ██ ██   ██ ██   ██ ████   ██    ██    ██                                                              
██  ██        ██     ███████ ██ ██  ██ ██   ██ ███████ ██ ██  ██    ██    █████                                                           
██  ██        ██     ██   ██ ██  ██ ██ ██   ██ ██   ██ ██  ██ ██    ██    ██                                                              
 ██  ██████  ██      ██   ██ ██   ████ ██████  ██   ██ ██   ████    ██    ███████

Donate: 0x0004230c13c3890F34Bb9C9683b91f539E809000
EOF
echo -e "${NC}"

function install_prometheus {
    echo -e "${BLUE}Устанавливаем Prometheus...${NC}"
    wget https://github.com/prometheus/prometheus/releases/download/v2.55.0-rc.0/prometheus-2.55.0-rc.0.linux-amd64.tar.gz
    tar xvf prometheus-2.55.0-rc.0.linux-amd64.tar.gz
    sudo mv prometheus-2.55.0-rc.0.linux-amd64 /etc/prometheus
    sudo mv /etc/prometheus/prometheus /usr/local/bin/
    sudo mv /etc/prometheus/promtool /usr/local/bin/

    echo -e "${BLUE}Настраиваем системный сервис Prometheus...${NC}"
    sudo useradd --no-create-home --shell /bin/false prometheus
    sudo chown prometheus:prometheus /usr/local/bin/prometheus
    sudo chown -R prometheus:prometheus /etc/prometheus
    sudo mkdir -p /var/lib/prometheus
    sudo chown -R prometheus:prometheus /var/lib/prometheus

    sudo tee /etc/systemd/system/prometheus.service > /dev/null << EOL
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/

[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl start prometheus
    sudo systemctl enable prometheus
    echo -e "${GREEN}Prometheus успешно установлен и запущен!${NC}"
}

function install_grafana {
    echo -e "${BLUE}Устанавливаем Grafana...${NC}"
    sudo apt --fix-broken install && sudo apt install libfontconfig1 -y
    wget https://dl.grafana.com/oss/release/grafana_7.2.0_amd64.deb
    sudo dpkg -i grafana_7.2.0_amd64.deb
    sudo systemctl start grafana-server
    sudo systemctl enable grafana-server
    echo -e "${GREEN}Grafana успешно установлена и запущена!${NC}"
}

function install_node_exporter {
    echo -e "${BLUE}Устанавливаем Node Exporter...${NC}"
    wget https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz
    tar -xvf node_exporter-1.0.1.linux-amd64.tar.gz
    if ! sudo cp node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin/; then
        echo -e "${RED}Не удалось скопировать файл node_exporter. Похоже, что он уже используется. Попробуйте остановить службу и повторить.${NC}"
        sudo systemctl stop node_exporter
        sudo cp node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin/
    fi

    echo -e "${BLUE}Создаем системный сервис для Node Exporter...${NC}"
    if ! id "node_exporter" &>/dev/null; then
        sudo useradd --no-create-home --shell /bin/false node_exporter
    else
        echo -e "${YELLOW}Пользователь node_exporter уже существует, пропускаем создание.${NC}"
    fi
    sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

    sudo tee /etc/systemd/system/node_exporter.service > /dev/null << EOL
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=default.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl start node_exporter
    sudo systemctl enable node_exporter
    echo -e "${GREEN}Node Exporter успешно установлен и запущен!${NC}"
}

function add_server_to_monitoring {
    echo -e "${BLUE}Добавляем новый сервер в список наблюдения...${NC}"
    CONFIG_FILE="/etc/prometheus/prometheus.yml"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Файл конфигурации Prometheus не найден: $CONFIG_FILE${NC}"
        return
    fi

    echo -e "${YELLOW}Список текущих серверов в мониторинге:${NC}"
    grep 'targets:' -A 1 "$CONFIG_FILE"

    echo -e "${YELLOW}Введите IP-адрес нового сервера для добавления:${NC}"
    read new_ip

    sudo sed -i "/job_name: 'node_exporter'/,/targets: \[/ s/\(targets: \[.*\)\]/\1, '$new_ip:9100']/" "$CONFIG_FILE"
    echo -e "${GREEN}Сервер $new_ip успешно добавлен в список наблюдения!${NC}"

    echo -e "${BLUE}Перезапускаем Prometheus...${NC}"
    sudo systemctl restart prometheus
    echo -e "${GREEN}Prometheus успешно перезапущен!${NC}"
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка Prometheus (главный сервер)${NC}"
        echo -e "${CYAN}2. Установка Grafana (главный сервер)${NC}"
        echo -e "${CYAN}3. Установка Node Exporter (главный сервер и сервер для мониторинга)${NC}"
        echo -e "${CYAN}4. Добавить сервер в список наблюдения (главный сервер)${NC}"
        echo -e "${CYAN}5. Выход${NC}"

        echo -e "${YELLOW}Введите номер:${NC} "
        read choice
        case $choice in
            1) install_prometheus ;;
            2) install_grafana ;;
            3) install_node_exporter ;;
            4) add_server_to_monitoring ;;
            5) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu
