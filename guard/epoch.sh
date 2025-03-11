#!/bin/bash

# Настройки
hard_settings="0.5 4 0 24"  # 0.45 4 0 24
soft_settings="0.55 2 0 24"

# Бесконечный цикл
while true; do
    # Запись hard_settings в файл по умолчанию
    echo $hard_settings > mostly_confirmed_threshold

    # Получить информацию об эпохе
    output=$(solana epoch-info)
    epoch_percent=$(echo "$output" | grep "Epoch Completed Percent:" | awk '{print $4}' | tr -d '%')

    # Проверка на случай пустого значения
    if [[ -z "$epoch_percent" ]]; then
        echo "Ошибка: Невозможно получить процент завершения эпохи."
        sleep 10
        continue
    fi

    # Вывести результат с текущим временем
    

    # Проверка попадания в заданные диапазоны
    if (( $(echo "$epoch_percent > 99.7" | bc -l) )); then
        echo -e "$(TZ=Europe/Moscow date +"%H:%M:%S") epoch=$epoch_percent% > 99.7: soft_settings"
        echo $soft_settings > mostly_confirmed_threshold
    elif (( $(echo "$epoch_percent > 25.5" | bc -l) )); then
        echo -e "$(TZ=Europe/Moscow date +"%H:%M:%S") epoch=$epoch_percent% > 25.5: hard_settings"
        echo $hard_settings > mostly_confirmed_threshold
    elif (( $(echo "$epoch_percent > 24.5" | bc -l) )); then
        echo -e "$(TZ=Europe/Moscow date +"%H:%M:%S") epoch=$epoch_percent% > 24.5: soft_settings"
        echo $soft_settings > mostly_confirmed_threshold
    elif (( $(echo "$epoch_percent > 0.5" | bc -l) )); then
        echo -e "$(TZ=Europe/Moscow date +"%H:%M:%S") epoch=$epoch_percent% > 0.5: hard_settings"
        echo $hard_settings > mostly_confirmed_threshold
    else
        echo "$(TZ=Europe/Moscow date +"%H:%M:%S")  epoch percent=$epoch_percent%      "    
    fi

    # Пауза перед следующей проверкой
    sleep 10
done
