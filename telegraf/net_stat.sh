#!/bin/bash

# Директория для хранения логов
LOG_DIR="/var/log/solana-monitoring"
mkdir -p $LOG_DIR

# Текущая дата для имени файла
DATE=$(date +"%Y%m%d_%H%M%S")

# Функция для записи статистики
collect_statistics() {
    echo "=== Solana Validator Statistics === $(date) ===" > "$LOG_DIR/stats_$DATE.log"
    
    # TCP соединения по состояниям
    echo -e "\n=== TCP Connection States ===" >> "$LOG_DIR/stats_$DATE.log"
    netstat -ant | awk '{print $6}' | sort | uniq -c >> "$LOG_DIR/stats_$DATE.log"
    
    # Активные соединения по портам
    echo -e "\n=== Active Connections by Port ===" >> "$LOG_DIR/stats_$DATE.log"
    netstat -tnp | grep ESTABLISHED | awk '{print $4}' | cut -d: -f2 | sort | uniq -c >> "$LOG_DIR/stats_$DATE.log"
    
    # UDP трафик на портах Solana
    echo -e "\n=== UDP Traffic on Solana Ports ===" >> "$LOG_DIR/stats_$DATE.log"
    timeout 30 tcpdump -i any 'udp portrange 8000-8020' -n 2>/dev/null | wc -l >> "$LOG_DIR/stats_$DATE.log"
    
    # Топ IP-адресов по количеству соединений
    echo -e "\n=== Top IPs by Connection Count ===" >> "$LOG_DIR/stats_$DATE.log"
    netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -n 10 >> "$LOG_DIR/stats_$DATE.log"
    
    # Статистика использования CPU и памяти процессом solana-validator
    echo -e "\n=== Solana Validator Resource Usage ===" >> "$LOG_DIR/stats_$DATE.log"
    ps aux | grep solana-validator | grep -v grep >> "$LOG_DIR/stats_$DATE.log"
    
    # Информация о нагрузке на сеть
    echo -e "\n=== Network Interface Statistics ===" >> "$LOG_DIR/stats_$DATE.log"
    ip -s link >> "$LOG_DIR/stats_$DATE.log"
    
    # Статистика iptables
    echo -e "\n=== IPTables Statistics ===" >> "$LOG_DIR/stats_$DATE.log"
    iptables -nvL >> "$LOG_DIR/stats_$DATE.log"
}

# Функция для анализа логов и выявления аномалий
analyze_logs() {
    local log_file="$1"
    echo "=== Connection Analysis === $(date) ===" > "$LOG_DIR/analysis_$DATE.log"
    
    # Анализ количества TIME_WAIT соединений
    time_wait_count=$(grep "TIME_WAIT" "$log_file" | awk '{print $1}' | awk '{s+=$1} END {print s}')
    if [ -z "$time_wait_count" ]; then
        time_wait_count=0
    fi
    if [ "$time_wait_count" -gt 100 ]; then
        echo "WARNING: High number of TIME_WAIT connections: $time_wait_count" >> "$LOG_DIR/analysis_$DATE.log"
    fi
    
    # Анализ подключений по портам
    echo -e "\n=== Port Analysis ===" >> "$LOG_DIR/analysis_$DATE.log"
    grep "Active Connections by Port" -A 20 "$log_file" >> "$LOG_DIR/analysis_$DATE.log"
    
    # Анализ топ IP-адресов
    echo -e "\n=== Suspicious IP Analysis ===" >> "$LOG_DIR/analysis_$DATE.log"
    grep "Top IPs by Connection Count" -A 10 "$log_file" | \
    awk '$1 > 50 {print "WARNING: Suspicious number of connections from IP: " $2 " (Count: " $1 ")"}' \
    >> "$LOG_DIR/analysis_$DATE.log"
}

# Функция очистки старых логов (хранить логи за последние 7 дней)
cleanup_old_logs() {
    find "$LOG_DIR" -type f -name "stats_*" -mtime +7 -delete
    find "$LOG_DIR" -type f -name "analysis_*" -mtime +7 -delete
}

# Основной процесс
collect_statistics
analyze_logs "$LOG_DIR/stats_$DATE.log"
cleanup_old_logs
