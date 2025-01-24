#!/bin/bash
# сбор статистики
LOG_FILE="$HOME/net_monitor/nftables.log"
RATE_FILE="$HOME/net_monitor/rates.log"
INTERVAL=60

TIME() {
   TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S"
}

monitor_rates() {
   while true; do
       echo "$(TIME) --- Rate Analysis ---" >> "$RATE_FILE"
       
       hour_min=$(date +'%H:%M')
       for type in "SYN" "ICMP" "TCP" "UDP"; do
           count=$(tail -c 100M /var/log/kern.log | grep -a "$(date +'%b %-d') $hour_min" | grep "\[NFT\] ${type}-RATE:" | wc -l)
           rate=$(echo "scale=2; $count / $INTERVAL" | bc)
           echo "${type}-RATE: $rate packets/sec" >> "$RATE_FILE"
       done
       
       sleep $INTERVAL
   done
}

monitor_rates &
wait
