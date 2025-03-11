#!/bin/bash

# Настройки
hard_settings="0.5 4 0 24"  # 0.45 4 0 24
soft_settings="0.55 2 0 24"
set_file="$HOME/solana/mostly_confirmed_threshold"

# Бесконечный цикл
while true; do
    # Получить информацию об эпохе
    output=$(solana epoch-info)
    epoch_percent=$(echo "$output" | grep "Epoch Completed Percent:" | awk '{print $4}' | tr -d '%')

    # Проверка на случай пустого значения
    if [[ -z "$epoch_percent" ]]; then
        echo "Ошибка: Невозможно получить процент завершения эпохи."
        sleep 10
        continue
    fi

    # Проверка попадания в заданные диапазоны
    if (( $(echo "$epoch_percent > 99.7" | bc -l) )); then
        echo -e "$(TZ=Europe/Moscow date +"%H:%M:%S") epoch=$epoch_percent% > 99.7: soft $(cat $set_file)"
        echo $soft_settings > $set_file
    elif (( $(echo "$epoch_percent > 25.5" | bc -l) )); then
        echo -e "$(TZ=Europe/Moscow date +"%H:%M:%S") epoch=$epoch_percent% > 25.5: hard $(cat $set_file)"
        echo $hard_settings > $set_file
    elif (( $(echo "$epoch_percent > 24.5" | bc -l) )); then
        echo -e "$(TZ=Europe/Moscow date +"%H:%M:%S") epoch=$epoch_percent% > 24.5: soft $(cat $set_file)"
        echo $soft_settings > $set_file
    elif (( $(echo "$epoch_percent > 0.5" | bc -l) )); then
        echo -e "$(TZ=Europe/Moscow date +"%H:%M:%S") epoch=$epoch_percent% > 0.5: hard $(cat $set_file)"
        echo $hard_settings > $set_file
    else
        echo -e "$(TZ=Europe/Moscow date +"%H:%M:%S") epoch=$epoch_percent%, settings=$(cat $set_file)"
    fi

    # Пауза перед следующей проверкой
    sleep 10
done
