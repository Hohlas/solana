#!/bin/bash

# Настройки
orig="0.45 4 0 24" # настройки Шиноби
hard="0.5 4 0 24" # чуть более консервативные настройки
soft="0.6 2 0 24" # очень консервативные настройки
set_file="$HOME/solana/mostly_confirmed_threshold"


TIME() {
    TZ=Europe/Moscow date +"%b %d %H:%M:%S"
}

while true; do
    output=$(solana epoch-info 2>/dev/null)
    epoch_percent=$(echo "$output" | grep "Epoch Completed Percent:" | awk '{print $4}' | tr -d '%')

    if [[ -z "$epoch_percent" ]]; then
        echo "$(TIME) Ошибка: Невозможно получить процент завершения эпохи."
        sleep 30
        continue
    fi

    # Проверка попадания в заданные диапазоны
    if (( $(echo "$epoch_percent > 99.7" | bc -l) )); then
        echo $soft > $set_file; echo "$(TIME) epoch=$epoch_percent% > 99.7: soft[$(cat $set_file)]" 
    elif (( $(echo "$epoch_percent > 25.3" | bc -l) )); then
        echo $hard > $set_file; echo "$(TIME) epoch=$epoch_percent% > 25.5: hard[$(cat $set_file)]"
    elif (( $(echo "$epoch_percent > 24.8" | bc -l) )); then
        echo $soft > $set_file; echo "$(TIME) epoch=$epoch_percent% > 24.5: soft[$(cat $set_file)]"
    elif (( $(echo "$epoch_percent > 0.3" | bc -l) )); then
        echo $hard > $set_file; echo "$(TIME) epoch=$epoch_percent% >  0.5: hard[$(cat $set_file)]"
    elif (( $(echo "$epoch_percent > 0" | bc -l) )); then
        echo $soft > $set_file; echo "$(TIME) epoch=$epoch_percent% > 0: soft[$(cat $set_file)]"    
    else
        echo $hard > $set_file; echo "$(TIME) epoch=$epoch_percent% hard[$(cat $set_file)]"
    fi

    sleep 60
done
