#!/bin/bash

# Определяем активный сетевой интерфейс
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)

# Первоначальные значения для сети
PREV_RX=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
PREV_TX=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

while true; do
    # Загрузка CPU (общая)
    CPU=$(top -bn1 | grep "%Cpu(s)" | awk '{print 100 - $8"%"}')
    
    # Свободная память в ГБ
    MEM=$(free -g | awk '/Mem:/ {print $7"GB"}')
    
    # Сетевая статистика
    CUR_RX=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    CUR_TX=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
    
    # Рассчет скорости за 1 секунду
    RX_SPEED=$(echo "scale=0; (($CUR_RX - $PREV_RX) * 8) / (1024 * 1024)" | bc)
    TX_SPEED=$(echo "scale=0; (($CUR_TX - $PREV_TX) * 8) / (1024 * 1024)" | bc)
    
    # Обновляем предыдущие значения
    PREV_RX=$CUR_RX
    PREV_TX=$CUR_TX
    
    # Вывод в одну строку с возвратом каретки
    printf "\rCPU: %-7s | Mem: %-8s | Net: ▼%d ▲%d Mb/s" \
    "$CPU" "$MEM" "$RX_SPEED" "$TX_SPEED"
    
    # Задержка между обновлениями
    sleep 1
done
