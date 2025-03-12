#!/bin/bash

# Настройки
orig_settings="0.45 4 0 24"
hard_settings="0.5 4 0 24"
soft_settings="0.55 2 0 24"
set_file="$HOME/solana/mostly_confirmed_threshold"
set_patch=$hard_settings  # Инициализация патча

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
        #rm -f $set_file;                 echo "$(TIME) epoch=$epoch_percent% > 99.7: Path OFF"
        echo $soft_settings > $set_file; echo "$(TIME) epoch=$epoch_percent% > 99.7: [$(cat $set_file)]" 
    elif (( $(echo "$epoch_percent > 25.5" | bc -l) )); then
        echo $set_patch > $set_file;     echo "$(TIME) epoch=$epoch_percent% > 25.5: [$(cat $set_file)]"
    elif (( $(echo "$epoch_percent > 24.5" | bc -l) )); then
        #rm -f $set_file;                 echo "$(TIME) epoch=$epoch_percent% > 24.5: Path OFF"
        echo $soft_settings > $set_file; echo "$(TIME) epoch=$epoch_percent% > 24.5: [$(cat $set_file)]"
    elif (( $(echo "$epoch_percent > 0.5" | bc -l) )); then
        echo $set_patch > $set_file;     echo "$(TIME) epoch=$epoch_percent% > 0.5: [$(cat $set_file)]"
    else
        echo $set_patch > $set_file;     echo "$(TIME) epoch=$epoch_percent% [$(cat $set_file)]"
    fi

    sleep 60
done
