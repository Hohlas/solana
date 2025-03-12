#!/bin/bash

# Настройки
orig_settings="0.45 4 0 24"
hard_settings="0.5 4 0 24"
soft_settings="0.55 2 0 24"
set_file="$HOME/solana/mostly_confirmed_threshold"
set_patch=$hard_settings

TIME() {
	TZ=Europe/Moscow date +"%b %e  %H:%M:%S"
	}

# Бесконечный цикл
while true; do
    # Получить информацию об эпохе
    output=$(solana epoch-info)
    epoch_percent=$(echo "$output" | grep "Epoch Completed Percent:" | awk '{print $4}' | tr -d '%')

    # Проверка на случай пустого значения
    if [[ -z "$epoch_percent" ]]; then
        echo "Ошибка: Невозможно получить процент завершения эпохи."
        sleep 30
        continue
    fi

    # Проверка попадания в заданные диапазоны
    if (( $(echo "$epoch_percent > 99.7" | bc -l) )); then
        rm -f $set_file
        echo -e "$TIME epoch=$epoch_percent% > 99.7: Path OFF"
    elif (( $(echo "$epoch_percent > 25.5" | bc -l) )); then
        echo $set_patch > $set_file
        echo -e "$TIME epoch=$epoch_percent% > 25.5: [$(cat $set_file)]"
    elif (( $(echo "$epoch_percent > 24.5" | bc -l) )); then
        rm -f $set_file
        echo -e "$TIME epoch=$epoch_percent% > 24.5: Path OFF"
    elif (( $(echo "$epoch_percent > 0.5" | bc -l) )); then
        echo $set_patch > $set_file
        echo -e "$TIME epoch=$epoch_percent% > 0.5: [$(cat $set_file)]"
    else
        echo $set_patch > $set_file
        echo -e "$TIME epoch=$epoch_percent% [$(cat $set_file)]"
    fi

    # Пауза перед следующей проверкой
    sleep 30
done
