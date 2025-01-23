#!/bin/bash

LOG_FILE="$HOME/net_monitor/nftables.log"
if [ -f "$HOME/guard.cfg" ]; then
	if [ -r "$HOME/guard.cfg" ]; then
    	source "$HOME/guard.cfg" # get settings
	   	BOT_TOKEN=$(echo "$BOT_TOKEN" | tr -d '\r') # Удаление символа \r, если он есть
  	else
    	echo "Error: $HOME/guard.cfg exists but is not readable" >&2
  	fi
else
  	echo "Error: $HOME/guard.cfg does not exist" >&2
fi

TIME() {
    TZ=Europe/Moscow date +"%b %e  %H:%M:%S"
}
last_message_file="/tmp/net_monitor_last_message"
# Мониторинг логов nftables
monitor_logs() {
    tail -n 100 /var/log/kern.log | while read line ; do
        if echo "$line" | grep -q "\[NFT\]"; then
            attack_type=$(echo "$line" | grep -oE '\[NFT\] [A-Z-]+' | cut -d' ' -f2)
            ip=$(echo "$line" | grep -oP 'SRC=\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
            message="Detected: $attack_type from: $ip"            
            if [ ! -f "$last_message_file" ] || [ "$message" != "$(cat "$last_message_file")" ]; then
                curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_INFO -d text="$message" > /dev/null
                echo "$(TIME) $message" | tee -a $LOG_FILE  # Записываем в лог
                echo "$message" > "$last_message_file"
            fi    
        fi
    done
}

trap 'kill $(jobs -p)' EXIT # Trap для корректного завершения
# Основной цикл мониторинга 
while true; do
    monitor_logs
    sleep 5
done
