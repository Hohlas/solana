#!/bin/bash
PATCH_VER=v1.1.3
#===================++++++++++========================
# Настройки
#orig="0.45 4 0 24" # настройки Шиноби
#hard="0.5 4 0 24" # чуть более консервативные настройки
hard="0.45 4 0 24" # стандартные настройки
soft="0.6 2 0 24" # очень консервативные настройки
set_file="$HOME/solana/mostly_confirmed_threshold"
GRAY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CLEAR=$'\033[0m'

TIME() {
    TZ=UTC date +"%b %d %H:%M:%S" # TZ=Europe/Moscow
}
echo -e " SOLANA PATCH SWITCHER $BLUE$PATCH_VER $CLEAR   " | tee -a $LOG_FILE
echo " hard=[$hard]   soft=[$soft]"

while true; do
    output=$(solana epoch-info 2>/dev/null)
    epoch_percent=$(echo "$output" | grep "Epoch Completed Percent:" | awk '{print $4}' | tr -d '%')

    if [[ -z "$epoch_percent" ]]; then
        echo "$(TIME) Ошибка: Невозможно получить процент завершения эпохи."
        sleep 30
        continue
    fi

    # Проверка попадания в заданные диапазоны
    # <0%
    if (( $(echo "$epoch_percent > 99.7" | bc -l) )); then
        echo $soft > $set_file; echo "$(TIME) epoch=$epoch_percent% > 99: soft[$(cat $set_file)]" 
    # 25%
    elif (( $(echo "$epoch_percent > 25.3" | bc -l) )); then
        echo $hard > $set_file; echo "$(TIME) epoch=$epoch_percent% : hard[$(cat $set_file)]"
    elif (( $(echo "$epoch_percent > 24.8" | bc -l) )); then
        echo $soft > $set_file; echo "$(TIME) epoch=$epoch_percent% = 25: soft[$(cat $set_file)]"
    # 65%
    elif (( $(echo "$epoch_percent > 65.3" | bc -l) )); then
        echo $hard > $set_file; echo "$(TIME) epoch=$epoch_percent% : hard[$(cat $set_file)]"
    elif (( $(echo "$epoch_percent > 64.8" | bc -l) )); then
        echo $soft > $set_file; echo "$(TIME) epoch=$epoch_percent% = 65: soft[$(cat $set_file)]"
    # >0%    
    elif (( $(echo "$epoch_percent > 0.3" | bc -l) )); then
        echo $hard > $set_file; echo "$(TIME) epoch=$epoch_percent% : hard[$(cat $set_file)]"
    elif (( $(echo "$epoch_percent > 0" | bc -l) )); then
        echo $soft > $set_file; echo "$(TIME) epoch=$epoch_percent% = 0: soft[$(cat $set_file)]"    
    
    else
        echo $hard > $set_file; echo "$(TIME) epoch=$epoch_percent% hard[$(cat $set_file)]"
    fi

    sleep 60
done
