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
███    ███  ██████  ███    ██ ██ ████████  ██████  ██████  ██ ███    ██  ██████  
████  ████ ██    ██ ████   ██ ██    ██    ██    ██ ██   ██ ██ ████   ██ ██       
██ ████ ██ ██    ██ ██ ██  ██ ██    ██    ██    ██ ██████  ██ ██ ██  ██ ██   ███ 
██  ██  ██ ██    ██ ██  ██ ██ ██    ██    ██    ██ ██   ██ ██ ██  ██ ██ ██    ██ 
██      ██  ██████  ██   ████ ██    ██     ██████  ██   ██ ██ ██   ████  ██████  
                                                                                 
                                                                                 
 ██████  ███████                                                                 
██    ██ ██                                                                      
██    ██ █████                                                                   
██    ██ ██                                                                      
 ██████  ██                                                                      
                                                                                 
                                                                                 
███████ ███████ ██████  ██    ██ ███████ ██████  ███████                         
██      ██      ██   ██ ██    ██ ██      ██   ██ ██                              
███████ █████   ██████  ██    ██ █████   ██████  ███████                         
     ██ ██      ██   ██  ██  ██  ██      ██   ██      ██                         
███████ ███████ ██   ██   ████   ███████ ██   ██ ███████   

________________________________________________________________________________________________________________________________________


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
    # Определяем архитектуру системы
    ARCH=$(uname -m)
    NODE_EXPORTER_VERSION="1.8.2"
    case $ARCH in
        x86_64)
            NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
            ;;
        aarch64)
            NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-arm64.tar.gz"
            ;;
        armv7l | arm)
            NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-armv7.tar.gz"
            ;;
        *)
            echo -e "${RED}Архитектура $ARCH не поддерживается этим скриптом${NC}"
            exit 1
            ;;
    esac

    # Загружаем и распаковываем Node Exporter
    wget $NODE_EXPORTER_URL
    tar -xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-*.tar.gz
    sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-*/node_exporter /usr/local/bin/

    # Удаляем временные файлы
    rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-*
    rm node_exporter-${NODE_EXPORTER_VERSION}.linux-*.tar.gz

    echo -e "${BLUE}Создаем системный сервис для Node Exporter...${NC}"
    sudo useradd --no-create-home --shell /bin/false node_exporter || true
    sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
    sudo chmod +x /usr/local/bin/node_exporter

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

function remove_node_exporter {
    echo -e "${BLUE}Удаляем Node Exporter...${NC}"
    sudo程式ctl stop node_exporter
    sudo systemctl disable node_exporter
    sudo rm /usr/local/bin/node_exporter
    sudo rm /etc/systemd/system/node_exporter.service
    sudo userdel node_exporter
    sudo systemctl daemon-reload
    echo -e "${GREEN}Node Exporter успешно удален!${NC}"
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

    sudo sed -i "/job_name: 'node_exporter'/,/targets: \[/ s/\(targets: \[[^]]*\)\]/\1, '$new_ip:9100']/" "$CONFIG_FILE"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка при добавлении нового сервера. Пожалуйста, проверьте файл конфигурации.${NC}"
        return
    fi

    echo -e "${GREEN}Сервер $new_ip успешно добавлен в список наблюдения!${NC}"

    echo -e "${BLUE}Перезапускаем Prometheus...${NC}"
    sudo systemctl restart prometheus
    echo -e "${GREEN}Prometheus успешно перезапущен!${NC}"
}

# Новая функция для удаления сервера из списка наблюдения
function remove_server_from_monitoring {
    CONFIG_FILE="/etc/prometheus/prometheus.yml"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Файл конфигурации Prometheus не найден: $CONFIG_FILE${NC}"
        return
    fi

    echo -e "${BLUE}Удаляем сервер из списка наблюдения...${NC}"
    echo -e "${YELLOW}Список текущих серверов в мониторинге:${NC}"
    # Печатаем строку с targets (и следующую за ней) для наглядности
    grep 'targets:' -A 1 "$CONFIG_FILE"

    echo -e "${YELLOW}Введите IP-адрес сервера, который нужно удалить:${NC}"
    read remove_ip

    if [ -z "$remove_ip" ]; then
        echo -e "${RED}IP-адрес не был введен. Возврат в главное меню.${NC}"
        return
    fi

    # Удаляем из списка. Небольшой трюк: удаляем шаблон '$remove_ip:9100' c дополнительной запятой, если она есть
    sudo sed -i "/job_name: 'node_exporter'/,/targets: \[/ s/'$remove_ip:9100',\?//g" "$CONFIG_FILE"

    echo -e "${BLUE}Перезапускаем Prometheus...${NC}"
    sudo systemctl restart prometheus
    echo -e "${GREEN}Сервер $remove_ip успешно удален из списка наблюдения!${NC}"
}

# Функция для просмотра списка наблюдения
function view_monitoring_list {
    CONFIG_FILE="/etc/prometheus/prometheus.yml"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Файл конфигурации Prometheus не найден: $CONFIG_FILE${NC}"
        return
    fi

    echo -e "${BLUE}Текущий список серверов в мониторинге:${NC}"
    # Извлекаем и форматируем список targets
    grep 'targets:' -A 1 "$CONFIG_FILE" | grep -o "'[^']*'" | sed "s/'//g" | while read -r line; do
        echo -e "${CYAN}- $line${NC}"
    done
    
    if [ -z "$(grep 'targets:' -A 1 "$CONFIG_FILE" | grep -o "'[^']*'")" ]; then
        echo -e "${YELLOW}Список серверов пуст${NC}"
    fi
}

# Функция для ручного редактирования списка наблюдения
function edit_monitoring_list {
    CONFIG_FILE="/etc/prometheus/prometheus.yml"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Файл конфигурации Prometheus не найден: $CONFIG_FILE${NC}"
        return
    fi

    echo -e "${BLUE}Открываем файл конфигурации Prometheus для редактирования...${NC}"
    echo -e "${YELLOW}Внимание: Будьте осторожны при редактировании. Следуйте формату YAML.${NC}"
    echo -e "${YELLOW}Нажмите Enter, чтобы продолжить, или Ctrl+C для отмены${NC}"
    read

    # Открываем файл в nano (или другом редакторе, если предпочтительно)
    sudo nano "$CONFIG_FILE"

    # Проверяем синтаксис файла после редактирования
    if command -v promtool &> /dev/null; then
        promtool check config "$CONFIG_FILE"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Обнаружена ошибка в синтаксисе конфигурации. Пожалуйста, проверьте файл.${NC}"
            return
        fi
    fi

    echo -e "${BLUE}Перезапускаем Prometheus...${NC}"
    sudo systemctl restart prometheus
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Конфигурация успешно обновлена и Prometheus перезапущен!${NC}"
    else
        echo -e "${RED}Ошибка при перезапуске Prometheus. Пожалуйста, проверьте конфигурацию.${NC}"
    fi
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка Prometheus (главный сервер)${NC}"
        echo -e "${CYAN}2. Установка Grafana (главный сервер)${NC}"
        echo -e "${CYAN}3. Установка Node Exporter (главный сервер и сервер для мониторинга)${NC}"
        echo -e "${CYAN}4. Удаление Node Exporter${NC}"
        echo -e "${CYAN}5. Добавить сервер в список наблюдения (главный сервер)${NC}"
        echo -e "${CYAN}6. Удалить сервер из списка наблюдения (главный сервер)${NC}"
        echo -e "${CYAN}7. Просмотр списка наблюдения (главный сервер)${NC}"
        echo -e "${CYAN}8. Редактирование списка наблюдения вручную (главный сервер)${NC}"
        echo -e "${CYAN}9. Перейти к другим проектам${NC}"
        echo -e "${CYAN}10. Выход${NC}"

        echo -e "${YELLOW}Введите номер действия:${NC} "
        read choice
        case $choice in
            1) install_prometheus ;;
            2) install_grafana ;;
            3) install_node_exporter ;;
            4) remove_node_exporter ;;
            5) add_server_to_monitoring ;;
            6) remove_server_from_monitoring ;;
            7) view_monitoring_list ;;
            8) edit_monitoring_list ;;
            9)
                wget -q -O Ultimative_Node_Installer.sh https://raw.githubusercontent.com/ksydoruk1508/Ultimative_Node_Installer/main/Ultimative_Node_Installer.sh 
                sudo chmod +x Ultimative_Node_Installer.sh 
                ./Ultimative_Node_Installer.sh
            ;;
            10) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu
