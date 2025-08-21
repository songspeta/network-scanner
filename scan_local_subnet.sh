#!/bin/bash

# scan_local_subnet.sh
# Скрипт сканирует локальную подсети через arping
# Принимает только имя интерфейса
# Поддерживает остановку по Ctrl+C

# Обработчик прерывания
trap 'echo -e "\n\n[!] Сканирование остановлено пользователем (Ctrl+C)"; exit 130' INT

# Проверка прав root
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: скрипт должен быть запущен с правами root" >&2
    exit 1
  fi
}

# Проверка существования интерфейса
check_interface() {
  local interface=$1
  if ! ip link show "$interface" >/dev/null 2>&1; then
    echo "Ошибка: интерфейс '$interface' не существует" >&2
    exit 1
  fi
}

# Получение IP и маски интерфейса
get_network_info() {
  local interface=$1
  local ip_output
  ip_output=$(ip -4 addr show "$interface" 2>/dev/null)

  if [[ -z "$ip_output" ]]; then
    echo "Ошибка: интерфейс '$interface' не имеет IPv4-адреса" >&2
    exit 1
  fi

  # Извлекаем IP/маску: например, 192.168.1.10/24
  local ip_mask
  ip_mask=$(echo "$ip_output" | grep -oE 'inet [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+' | awk '{print $2}')

  if [[ -z "$ip_mask" ]]; then
    echo "Ошибка: не удалось получить IP-адрес с маской для интерфейса '$interface'" >&2
    exit 1
  fi

  echo "$ip_mask"
}

# Разбор подсети и маски
parse_subnet() {
  local ip_mask=$1
  local ip=${ip_mask%/*}
  local mask=${ip_mask#*/}

  # Поддержка /24 и /16
  if [[ "$mask" -eq 24 ]]; then
    echo "${ip%.*}"
  elif [[ "$mask" -eq 16 ]]; then
    echo "${ip%.*.*}"
  else
    echo "Ошибка: поддерживается только /24 и /16 маски" >&2
    exit 1
  fi
}

# Сканирование подсети через arping
scan_subnet() {
  local prefix=$1
  local interface=$2

  echo "--- Сканирование локальной подсети: $prefix.0/24 ---"
  for host in {1..254}; do
    local ip="$prefix.$host"
    echo -n "[*] Проверка $ip... "

    # Ограничиваем arping по времени — 2 секунды максимум
    timeout 2 arping -c 2 -w 1 -I "$interface" "$ip" >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
      echo "HOST IS ALIVE (ARP)"
    else
      echo "no response"
    fi
  done
}

# Основная функция
main() {
  # Проверка на Ctrl+C будет обработана через trap
  check_root

  if [[ $# -ne 1 ]]; then
    echo "Использование: $0 <интерфейс>" >&2
    echo "Пример: $0 enp0s3" >&2
    exit 1
  fi

  local interface=$1

  check_interface "$interface"

  local network_info
  network_info=$(get_network_info "$interface")

  local subnet_prefix
  subnet_prefix=$(parse_subnet "$network_info")

  scan_subnet "$subnet_prefix" "$interface"
}

# Запуск
main "$@"
