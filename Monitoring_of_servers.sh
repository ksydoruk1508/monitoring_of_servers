#!/usr/bin/env bash
# =====================================================================
#  N3R Node Hub — Monitoring (Prometheus/Grafana/Node Exporter)
#  Ubuntu/Debian (apt). Требуется sudo для установок.
#  Version: 0.2.0
# =====================================================================
set -Eeuo pipefail

# -----------------------------
# Branding / Logo (identical)
# -----------------------------
display_logo() {
  cat <<'EOF'
   __  __                       _             _       
  / /  \ \      /\             | |           | |      
 | | ___| |    /  \   _ __   __| | __ _ _ __ | |_ ___ 
 | |/ __| |   / /\ \ | '_ \ / _` |/ _` | '_ \| __/ _ \
 | | (__| |  / ____ \| | | | (_| | (_| | | | | ||  __/
 | |\___| | /_/    \_\_| |_|\__,_|\__,_|_| |_|\__\___|
  \_\  /_/                                            
                                                      
  Github:   https://github.com/ksydoruk1508
  Teletype: https://teletype.in/@c6zr7        

  Donate: 0x0004230c13c3890F34Bb9C9683b91f539E809000
EOF
}

# -----------------------------
# Colors & helpers (identical)
# -----------------------------
clrGreen=$'\033[0;32m'
clrCyan=$'\033[0;36m'
clrBlue=$'\033[0;34m'
clrRed=$'\033[0;31m'
clrYellow=$'\033[1;33m'
clrMag=$'\033[1;35m'
clrReset=$'\033[0m'
clrBold=$'\033[1m'
clrDim=$'\033[2m'

ok()    { echo -e "${clrGreen}[OK]${clrReset} ${*:-}"; }
info()  { echo -e "${clrCyan}[INFO]${clrReset} ${*:-}"; }
warn()  { echo -e "${clrYellow}[WARN]${clrReset} ${*:-}"; }
err()   { echo -e "${clrRed}[ERROR]${clrReset} ${*:-}"; }
hr()    { echo -e "${clrDim}────────────────────────────────────────────────────────${clrReset}"; }

trap 'err "Ошибка на строке $LINENO. См. вывод выше."' ERR

# -----------------------------
# Config
# -----------------------------
SCRIPT_NAME="N3R-Monitoring"
SCRIPT_VERSION="0.2.0"
LANG_CHOICE="ru"
CONFIG_FILE="/etc/prometheus/prometheus.yml"

# -----------------------------
# i18n (extendable)
# -----------------------------
choose_language() {
  clear; display_logo
  echo -e "\n${clrBold}${clrMag}Select language / Выберите язык${clrReset}"
  echo -e "${clrDim}1) Русский${clrReset}"
  echo -e "${clrDim}2) English${clrReset}"
  read -rp "> " ans
  case "${ans:-}" in
    2) LANG_CHOICE="en" ;;
    *) LANG_CHOICE="ru" ;;
  esac
}

tr() {
  local k="${1-}"; [[ -z "$k" ]] && return 0
  case "$LANG_CHOICE" in
    en)
      case "$k" in
        menu_title) echo "Monitoring — Prometheus/Grafana/Node Exporter" ;;
        m1_prom) echo "Install Prometheus (main server)" ;;
        m2_graf) echo "Install Grafana (main server)" ;;
        m3_nodeexp) echo "Install Node Exporter (any server)" ;;
        m4_rm_nodeexp) echo "Remove Node Exporter" ;;
        m5_add) echo "Add server to monitoring (main server)" ;;
        m6_del) echo "Remove server from monitoring (main server)" ;;
        m7_view) echo "View monitoring list (main server)" ;;
        m8_edit) echo "Edit monitoring list manually (main server)" ;;
        m0_exit) echo "Exit" ;;
        press_enter) echo "Press Enter to return..." ;;
        need_root_warn) echo "Some steps require sudo/root. You'll be prompted if needed." ;;
        installing_prom) echo "Installing Prometheus..." ;;
        prom_done) echo "Prometheus installed and started" ;;
        installing_graf) echo "Installing Grafana..." ;;
        graf_done) echo "Grafana installed and started" ;;
        installing_nodeexp) echo "Installing Node Exporter..." ;;
        nodeexp_done) echo "Node Exporter installed, started, and open on port 9100" ;;
        removing_nodeexp) echo "Removing Node Exporter..." ;;
        nodeexp_removed) echo "Node Exporter removed" ;;
        ufw_warn_enable) echo "UFW may be enabled; ensure SSH (22) is allowed to avoid lockout." ;;
        ufw_open_port) echo "Opening firewall port" ;;
        config_missing) echo "Prometheus config not found" ;;
        add_ip_prompt) echo "Enter IP address to add" ;;
        del_ip_prompt) echo "Enter IP address to remove" ;;
        prom_restart) echo "Restarting Prometheus..." ;;
        prom_restarted) echo "Prometheus restarted" ;;
        list_current) echo "Current monitored targets:" ;;
        list_empty) echo "Target list is empty" ;;
        edit_open) echo "Opening Prometheus config in editor..." ;;
        edit_warn) echo "Be careful editing YAML. Press Enter to continue or Ctrl+C to cancel." ;;
        invalid_choice) echo "Invalid choice, try again." ;;
        *) echo "Invalid choice" ;;
      esac
      ;;
    *)
      case "$k" in
        menu_title) echo "Мониторинг — Prometheus/Grafana/Node Exporter" ;;
        m1_prom) echo "Установка Prometheus (главный сервер)" ;;
        m2_graf) echo "Установка Grafana (главный сервер)" ;;
        m3_nodeexp) echo "Установка Node Exporter (любой сервер)" ;;
        m4_rm_nodeexp) echo "Удаление Node Exporter" ;;
        m5_add) echo "Добавить сервер в мониторинг (главный сервер)" ;;
        m6_del) echo "Удалить сервер из мониторинга (главный сервер)" ;;
        m7_view) echo "Просмотр списка мониторинга (главный сервер)" ;;
        m8_edit) echo "Редактирование списка вручную (главный сервер)" ;;
        m0_exit) echo "Выход" ;;
        press_enter) echo "Нажмите Enter для возврата..." ;;
        need_root_warn) echo "Некоторые шаги требуют sudo/root. Вас попросят ввести пароль при необходимости." ;;
        installing_prom) echo "Устанавливаю Prometheus..." ;;
        prom_done) echo "Prometheus установлен и запущен" ;;
        installing_graf) echo "Устанавливаю Grafana..." ;;
        graf_done) echo "Grafana установлена и запущена" ;;
        installing_nodeexp) echo "Устанавливаю Node Exporter..." ;;
        nodeexp_done) echo "Node Exporter установлен, запущен и доступен на порту 9100" ;;
        removing_nodeexp) echo "Удаляю Node Exporter..." ;;
        nodeexp_removed) echo "Node Exporter удалён" ;;
        ufw_warn_enable) echo "Будет включён UFW; убедитесь, что SSH (22) разрешён, иначе потеряете доступ." ;;
        ufw_open_port) echo "Открываю порт в файрволе" ;;
        config_missing) echo "Файл конфигурации Prometheus не найден" ;;
        add_ip_prompt) echo "Введите IP-адрес для добавления" ;;
        del_ip_prompt) echo "Введите IP-адрес для удаления" ;;
        prom_restart) echo "Перезапускаю Prometheus..." ;;
        prom_restarted) echo "Prometheus перезапущен" ;;
        list_current) echo "Текущие цели мониторинга:" ;;
        list_empty) echo "Список целей пуст" ;;
        edit_open) echo "Открываю конфигурацию Prometheus в редакторе..." ;;
        edit_warn) echo "Осторожно с YAML. Enter — продолжить, Ctrl+C — отмена." ;;
        invalid_choice) echo "Неверный выбор, попробуйте снова." ;;
        *) echo "Invalid choice" ;;
      esac
      ;;
  esac
}

# -----------------------------
# Helpers
# -----------------------------
need_sudo() {
  if [[ $(id -u) -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
    err "sudo не найден. Запустите под root или установите sudo."
    exit 1
  fi
}
run_root() { if [[ $(id -u) -ne 0 ]]; then sudo bash -lc "$*"; else bash -lc "$*"; fi; }

ensure_pkg() {
  run_root "DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get install -y $*"
}

detect_arch() {
  case "$(uname -m)" in
    x86_64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    armv7l|armv7) echo "armv7" ;;
    *) echo "unsupported" ;;
  esac
}

# -----------------------------
# Core install/update
# -----------------------------
install_prometheus() {
  clear; display_logo; hr
  info "$(tr installing_prom)"
  local ARCH VER TGZ URL DIR
  ARCH="$(detect_arch)"; [[ "$ARCH" == "unsupported" ]] && { err "Unsupported arch: $(uname -m)"; return 1; }
  VER="2.55.0-rc.0"
  TGZ="prometheus-${VER}.linux-${ARCH}.tar.gz"
  URL="https://github.com/prometheus/prometheus/releases/download/v${VER}/${TGZ}"

  id -u prometheus >/dev/null 2>&1 || run_root "useradd --no-create-home --shell /bin/false prometheus"
  run_root "mkdir -p /etc/prometheus /var/lib/prometheus"

  run_root "cd /tmp && wget -q --tries=3 --timeout=20 '${URL}' && tar -xzf '${TGZ}'"
  DIR="/tmp/${TGZ%.tar.gz}"

  run_root "install -m 0755 '${DIR}/prometheus' /usr/local/bin/prometheus"
  run_root "install -m 0755 '${DIR}/promtool'   /usr/local/bin/promtool"
  run_root "cp -r '${DIR}/consoles' '${DIR}/console_libraries' /etc/prometheus/ || true"

  if ! sudo test -f "$CONFIG_FILE"; then
    run_root "tee '$CONFIG_FILE' >/dev/null" <<'YAML'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
YAML
  fi

  run_root "chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus"
  run_root "chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool"

  run_root "tee /etc/systemd/system/prometheus.service >/dev/null" <<'EOL'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.listen-address=:9090
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOL

  run_root "systemctl daemon-reload && systemctl enable --now prometheus"
  info "$(tr ufw_open_port): 9090/tcp"
  if command -v ufw >/dev/null 2>&1; then
    run_root "ufw allow 9090/tcp comment 'Prometheus'"
  else
    ensure_pkg ufw
    warn "$(tr ufw_warn_enable)"
    run_root "ufw allow OpenSSH && ufw allow 9090/tcp comment 'Prometheus'"
    run_root "ufw status | grep -q 'Status: active' || ufw --force enable"
  fi
  ok "$(tr prom_done)"
}

install_grafana() {
  clear; display_logo; hr
  info "$(tr installing_graf)"
  ensure_pkg adduser libfontconfig1
  run_root "cd /tmp && wget -q https://dl.grafana.com/oss/release/grafana_7.2.0_amd64.deb && dpkg -i grafana_7.2.0_amd64.deb || apt-get -f install -y"
  run_root "systemctl enable --now grafana-server"
  ok "$(tr graf_done)"
}

install_node_exporter() {
  clear; display_logo; hr
  info "$(tr installing_nodeexp)"
  local ARCH VER TGZ DIR URL
  ARCH="$(detect_arch)"
  VER="1.8.2"
  case "$ARCH" in
    amd64) TGZ="node_exporter-${VER}.linux-amd64.tar.gz" ;;
    arm64) TGZ="node_exporter-${VER}.linux-arm64.tar.gz" ;;
    armv7) TGZ="node_exporter-${VER}.linux-armv7.tar.gz" ;;
    *) err "Архитектура $(uname -m) не поддерживается"; return 1 ;;
  esac
  URL="https://github.com/prometheus/node_exporter/releases/download/v${VER}/${TGZ}"

  id -u node_exporter >/dev/null 2>&1 || run_root "useradd --no-create-home --shell /bin/false node_exporter"
  run_root "cd /tmp && wget -q --tries=3 --timeout=20 '${URL}' && tar -xzf '${TGZ}'"
  DIR="/tmp/${TGZ%.tar.gz}"
  run_root "install -m 0755 '${DIR}/node_exporter' /usr/local/bin/node_exporter && chown node_exporter:node_exporter /usr/local/bin/node_exporter"

  run_root "tee /etc/systemd/system/node_exporter.service >/dev/null" <<'EOL'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOL

  run_root "systemctl daemon-reload && systemctl enable --now node_exporter"

  info "$(tr ufw_open_port): 9100/tcp"
  if command -v ufw >/dev/null 2>&1; then
    run_root "ufw allow 9100/tcp comment 'Node Exporter'"
  else
    ensure_pkg ufw
    warn "$(tr ufw_warn_enable)"
    run_root "ufw allow OpenSSH && ufw allow 9100/tcp comment 'Node Exporter'"
    run_root "ufw status | grep -q 'Status: active' || ufw --force enable"
  fi
  ok "$(tr nodeexp_done)"
}

remove_node_exporter() {
  clear; display_logo; hr
  info "$(tr removing_nodeexp)"
  run_root "systemctl stop node_exporter || true"
  run_root "systemctl disable node_exporter || true"
  run_root "rm -f /usr/local/bin/node_exporter /etc/systemd/system/node_exporter.service"
  id -u node_exporter >/dev/null 2>&1 && run_root "userdel node_exporter" || true
  run_root "systemctl daemon-reload"
  ok "$(tr nodeexp_removed)"
}

# -----------------------------
# Prometheus target list ops
# -----------------------------
prom_cfg_backup() { run_root "cp -a '$CONFIG_FILE' '${CONFIG_FILE}.$(date +%F-%H%M%S).bak'"; }

ensure_node_exporter_job() {
  if ! sudo test -f "$CONFIG_FILE"; then err "$(tr config_missing): $CONFIG_FILE"; return 1; fi
  if ! grep -q "job_name: 'node_exporter'" "$CONFIG_FILE" 2>/dev/null; then
    prom_cfg_backup
    run_root "tee -a '$CONFIG_FILE' >/dev/null" <<'YAML'

# auto-added by N3R-Monitoring
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
YAML
  fi
}

add_server_to_monitoring() {
  clear; display_logo; hr
  if ! sudo test -f "$CONFIG_FILE"; then err "$(tr config_missing): $CONFIG_FILE"; return; fi
  ensure_node_exporter_job || return
  echo -e "${clrYellow}$(tr add_ip_prompt):${clrReset}"
  read -r new_ip
  [[ -z "${new_ip// }" ]] && { warn "IP пуст"; return; }
  if grep -q "'${new_ip}:9100'" "$CONFIG_FILE"; then
    warn "Уже есть в списке"; return
  fi
  prom_cfg_backup
  run_root "sed -i \"/job_name: 'node_exporter'/,/targets: \\[/ { /targets: \\[/ s/]/, '${new_ip}:9100']/ }\" '$CONFIG_FILE'"
  info "$(tr prom_restart)"
  if command -v promtool >/dev/null 2>&1; then
    promtool check config "$CONFIG_FILE" || { err "Ошибка синтаксиса YAML"; return; }
  fi
  run_root "systemctl restart prometheus"
  ok "$(tr prom_restarted)"
}

remove_server_from_monitoring() {
  clear; display_logo; hr
  if ! sudo test -f "$CONFIG_FILE"; then err "$(tr config_missing): $CONFIG_FILE"; return; fi
  echo -e "${clrYellow}$(tr del_ip_prompt):${clrReset}"
  read -r remove_ip
  [[ -z "${remove_ip// }" ]] && { warn "IP пуст"; return; }
  if ! grep -q "'${remove_ip}:9100'" "$CONFIG_FILE"; then
    warn "Такого адреса нет"; return
  fi
  prom_cfg_backup
  run_root "sed -i -E \"/job_name: 'node_exporter'/,/targets: \\[/ { s/, *'${remove_ip}:9100'//g; s/'${remove_ip}:9100', *//g; s/\\[ *, */[/g; s/, *\\]/]/g }\" '$CONFIG_FILE'"
  info "$(tr prom_restart)"
  if command -v promtool >/dev/null 2>&1; then
    promtool check config "$CONFIG_FILE" || { err "Ошибка синтаксиса YAML"; return; }
  fi
  run_root "systemctl restart prometheus"
  ok "$(tr prom_restarted)"
}

view_monitoring_list() {
  clear; display_logo; hr
  if ! sudo test -f "$CONFIG_FILE"; then err "$(tr config_missing): $CONFIG_FILE"; return; fi
  echo -e "${clrBlue}$(tr list_current)${clrReset}"
  awk "/job_name: 'node_exporter'/{f=1} f&&/targets:/ {print; exit}" "$CONFIG_FILE" \
    | grep -o "'[^']*'" | sed "s/'//g" | while read -r t; do
        echo -e "${clrCyan}- $t${clrReset}"
      done || true
  if ! grep -q "job_name: 'node_exporter'" "$CONFIG_FILE" || \
     ! awk "/job_name: 'node_exporter'/{f=1} f&&/targets:/" "$CONFIG_FILE" | grep -q "'"; then
    echo -e "${clrYellow}$(tr list_empty)${clrReset}"
  fi
}

edit_monitoring_list() {
  clear; display_logo; hr
  if ! sudo test -f "$CONFIG_FILE"; then err "$(tr config_missing): $CONFIG_FILE"; return; fi
  prom_cfg_backup
  info "$(tr edit_open)"
  echo -e "${clrYellow}$(tr edit_warn)${clrReset}"
  read -r
  run_root "nano '$CONFIG_FILE'"
  if command -v promtool >/dev/null 2>&1; then
    promtool check config "$CONFIG_FILE" || { err "Ошибка синтаксиса YAML"; return; }
  fi
  info "$(tr prom_restart)"
  run_root "systemctl restart prometheus" && ok "$(tr prom_restarted)" || err "Не удалось перезапустить"
}

# -----------------------------
# External runner (style parity)
# -----------------------------
confirm_and_run() {
  local title="$1"; shift
  local cmd="$*"
  clear; display_logo; hr
  echo -e "${clrBold}${clrMag}${title}${clrReset}\n"; hr
  echo -e "${clrDim}${cmd}${clrReset}\n"
  read -rp "$(tr press_enter)" _
  bash -lc "$cmd"
  ok "${title}: done"
}

# -----------------------------
# Main menu (identical UX)
# -----------------------------
main_menu() {
  need_sudo
  choose_language
  info "$(tr need_root_warn)" || true
  while true; do
    clear; display_logo; hr
    echo -e "${clrBold}${clrMag}$(tr menu_title)${clrReset} ${clrDim}(v${SCRIPT_VERSION})${clrReset}\n"
    echo -e "${clrGreen}1)${clrReset} $(tr m1_prom)"
    echo -e "${clrGreen}2)${clrReset} $(tr m2_graf)"
    echo -e "${clrGreen}3)${clrReset} $(tr m3_nodeexp)"
    echo -e "${clrGreen}4)${clrReset} $(tr m4_rm_nodeexp)"
    echo -e "${clrGreen}5)${clrReset} $(tr m5_add)"
    echo -e "${clrGreen}6)${clrReset} $(tr m6_del)"
    echo -e "${clrGreen}7)${clrReset} $(tr m7_view)"
    echo -e "${clrGreen}8)${clrReset} $(tr m8_edit)"
    echo -e "${clrGreen}0)${clrReset} $(tr m0_exit)"
    hr
    read -rp "> " choice;
    case "${choice:-}" in
      1) install_prometheus ;;
      2) install_grafana ;;
      3) install_node_exporter ;;
      4) remove_node_exporter ;;
      5) add_server_to_monitoring ;;
      6) remove_server_from_monitoring ;;
      7) view_monitoring_list ;;
      8) edit_monitoring_list ;;
      0) exit 0 ;;
      *) echo -e "${clrRed}$(tr invalid_choice)${clrReset}" ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

main_menu
