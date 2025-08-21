#!/bin/bash

# Функция для проверки привилегий root
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Скрипт должен быть запущен с правами root"
    exit 1
  fi
}

# Функция для проверки корректности IP-адреса
validate_ip() {
  local ip=$1
  if [[ $ip =~ ^[0-9]{1,3}$ ]] && [[ $ip -ge 0 ]] && [[ $ip -le 255 ]]; then
    return 0
  else
    return 1
  fi
}

# Функция для сканирования одного IP через arping
scan_ip() {
  local prefix=$1
  local subnet=$2
  local host=$3
  local interface=$4
  local ip="${prefix}.${subnet}.${host}"

  echo -n "[*] IP : ${ip} - "

  # Сначала пробуем arping
  if arping -c 3 -i "$interface" "${ip}" 2>/dev/null | grep -q "bytes from"; then
    echo "HOST IS ALIVE (ARP)"
  else
    # Если не работает, попробуем ping
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
      echo "HOST IS ALIVE (PING)"
    else
      echo "no response"
    fi
  fi

  sleep 0.1
}
# Функция для сканирования всех хостов в подсети
scan_subnet() {
  local prefix=$1
  local subnet=$2
  local interface=$3

  echo "--- Сканирование подсети: ${prefix}.${subnet}.0/24 ---"

  for HOST in {1..255}; do
    scan_ip "$prefix" "$subnet" "$HOST" "$interface"
  done

  sleep 0.5
}

# Функция для сканирования всей сети
scan_network() {
  local prefix=$1
  local interface=$2

  echo "--- Сканирование всей сети: ${prefix}.0.0/16 ---"

  for SUBNET in {1..255}; do
    echo "--- Подсеть: ${prefix}.${SUBNET}.0/24 ---"
    scan_subnet "$prefix" "$SUBNET" "$interface"
  done
}

# Обработка Ctrl+C
trap 'echo "ARPing scan stopped (Ctrl-C)"; exit 1' 2

# Основная логика
main() {
  check_root

  PREFIX="$1"
  INTERFACE="$2"
  SUBNET="$3"
  HOST="$4"

  # Проверка обязательных аргументов
  if [[ -z "$PREFIX" ]] || [[ "$PREFIX" = "NOT_SET" ]]; then
    echo "\$PREFIX must be passed as first positional argument"
    exit 1
  fi

  if [[ -z "$INTERFACE" ]]; then
    echo "\$INTERFACE must be passed as second positional argument"
    exit 1
  fi

  # Проверка формата PREFIX: должен быть в формате xx.xx
  if ! [[ "$PREFIX" =~ ^[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "PREFIX должен быть в формате xx.xx (например, 10.0)"
    exit 1
  fi

  IFS='.' read -ra PREFIX_PARTS <<<"$PREFIX"
  for part in "${PREFIX_PARTS[@]}"; do
    if ! validate_ip "$part"; then
      echo "Некорректный формат PREFIX"
      exit 1
    fi
  done

  # Валидация SUBNET и HOST
  if [[ -n "$SUBNET" ]]; then
    if ! validate_ip "$SUBNET"; then
      echo "SUBNET должен быть числом от 0 до 255"
      exit 1
    fi
  fi

  if [[ -n "$HOST" ]]; then
    if ! validate_ip "$HOST"; then
      echo "HOST должен быть числом от 0 до 255"
      exit 1
    fi
  fi

  # Режим работы
  if [[ -n "$HOST" ]] && [[ -n "$SUBNET" ]]; then
    scan_ip "$PREFIX" "$SUBNET" "$HOST" "$INTERFACE"
  elif [[ -n "$SUBNET" ]]; then
    scan_subnet "$PREFIX" "$SUBNET" "$INTERFACE"
  else
    scan_network "$PREFIX" "$INTERFACE"
  fi
}

main "$@"
