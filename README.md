# Network Scanner

Bash скрипт для сканирования локальной сети с использованием `arping` и `ping`.

## 📋 Описание

Скрипт позволяет сканировать сеть на предмет активных хостов, используя два метода:
- `arping` — для обнаружения устройств на канальном уровне
- `ping` — для проверки доступности хостов через ICMP

## ⚙️ Требования

- Linux/Unix система
- Установленные утилиты: `arping`, `ping`
- Права root (sudo)

## 🚀 Установка

```bash
git clone https://github.com/songspeta/network-scanner.git
cd network-scanner
chmod +x check_ip.sh

 📖 Использование
Сканирование всей сети (PREFIX.0.0/16)

sudo ./check_ip.sh 192.168 eth0

Сканирование одной подсети (PREFIX.SUBNET.0/24)

sudo ./check_ip.sh 192.168 eth0 10

Сканирование одного IP адреса

sudo ./check_ip.sh 192.168 eth0 10 50

## 📊 Пример вывода

[*] IP : 192.168.2.1 - HOST IS ALIVE (ARP)
[*] IP : 192.168.2.2 - HOST IS ALIVE (PING)
[*] IP : 192.168.2.3 - no response

## 🛡️ Безопасность
Скрипт проверяет права root перед запуском и валидирует все входные параметры.

## 📄 Лицензия
MIT
