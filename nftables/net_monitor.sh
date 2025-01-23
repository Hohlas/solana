#!/bin/bash

LOG_FILE="$HOME/net_monitor/nftables.log"
BOT_TOKEN="5076252443:AAF1rtoCAReYVY8QyZcdXGmuUOrNVICllWU"
CHAT_INFO="-1001548522888"

TIME() {
    TZ=Europe/Moscow date +"%b %e  %H:%M:%S"
}

LOG() {
    local message="$1"
    echo "$(TIME) $message" | tee -a $LOG_FILE
}

SEND_INFO(){
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_INFO -d text="$message" > /dev/null
    echo "$(TIME) $message" >> $LOG_FILE
    echo -e "$(TIME) $GREEN $message $CLEAR"
}

# Функция для проверки счетчиков nftables
check_counters() {
    local counter_name="$1"
    local threshold="$2"
    local counter_value=$(nft list counter ip dos_protection ${counter_name} 2>/dev/null | grep -oE 'packets [0-9]+' | awk '{print $2}')
    
    if [ -z "$counter_value" ]; then
        return  # Молча выходим, если счетчик не найден
    fi
    
    if [ "$counter_value" -gt "$threshold" ]; then
        echo $message
        # SEND_INFO "Alert: $counter_name exceeded threshold ($counter_value > $threshold)"
    fi
}

# Мониторинг логов nftables
monitor_logs() {
    tail -fn0 /var/log/kern.log | while read line ; do
        if echo "$line" | grep -q "\[NFT\]"; then
            attack_type=$(echo "$line" | grep -oE '\[NFT\] [A-Z-]+' | cut -d' ' -f2)
            ip=$(echo "$line" | grep -oE 'SRC=[0-9.]+' | cut -d= -f2)
            
            message="Detected attack: $attack_type from IP: $ip"
            echo $message
            # SEND_INFO "$message"
        fi
    done
}

trap 'kill $(jobs -p)' EXIT # Trap для корректного завершения
# Основной цикл мониторинга 
while true; do
    # Проверяем счетчики каждую минуту
    check_counters "syn_flood_counter" 1000
    check_counters "icmp_flood_counter" 1000
    check_counters "tcp_flood_counter" 1000
    check_counters "tcp_conn_counter" 1000
    check_counters "udp_flood_counter" 10000
    check_counters "portscan_counter" 100
    
    sleep 60
done &

# Запускаем мониторинг логов
monitor_logs
