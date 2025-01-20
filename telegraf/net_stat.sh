#!/bin/bash

# Директория для хранения логов
LOG_DIR="/var/log/solana-monitoring"
mkdir -p "$LOG_DIR"

# Файлы для логирования
STATS_FILE="$LOG_DIR/stats.log"
ANALYSIS_FILE="$LOG_DIR/analysis.log"

# Функция для записи статистики
collect_statistics() {
    echo "=== Solana Validator Statistics === $(date) ===" >> "$STATS_FILE"
    
    # TCP соединения по состояниям
    echo -e "\n=== TCP Connection States ===" >> "$STATS_FILE"
    netstat -ant | awk '{print $6}' | sort | uniq -c >> "$STATS_FILE"
    
    # Активные соединения по портам
    echo -e "\n=== Active Connections by Port ===" >> "$STATS_FILE"
    netstat -tnp | grep ESTABLISHED | awk '{print $4}' | cut -d: -f2 | sort | uniq -c >> "$STATS_FILE"
    
    # UDP трафик на портах Solana
    echo -e "\n=== UDP Traffic on Solana Ports ===" >> "$STATS_FILE"
    timeout 30 tcpdump -i any 'udp portrange 8000-8020' -n 2>/dev/null | wc -l >> "$STATS_FILE"
    
    # Топ IP-адресов по количеству соединений
    echo -e "\n=== Top IPs by Connection Count ===" >> "$STATS_FILE"
    netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -n 10 >> "$STATS_FILE"
    
    # Статистика использования CPU и памяти процессом solana-validator
    echo -e "\n=== Solana Validator Resource Usage ===" >> "$STATS_FILE"
    ps aux | grep solana-validator | grep -v grep >> "$STATS_FILE"
    
    # Информация о нагрузке на сеть
    echo -e "\n=== Network Interface Statistics ===" >> "$STATS_FILE"
    ip -s link >> "$STATS_FILE"
    
    # Статистика iptables
    echo -e "\n=== IPTables Statistics ===" >> "$STATS_FILE"
    iptables -nvL >> "$STATS_FILE"
}

# Функция для анализа логов и выявления аномалий
analyze_logs() {
    local log_file="$1"

    if [[ ! -f "$log_file" ]]; then
        echo "Log file does not exist: $log_file" >> "$ANALYSIS_FILE"
        return
    fi

    echo "=== Connection Analysis === $(date) ===" >> "$ANALYSIS_FILE"
    
    # Анализ количества TIME_WAIT соединений
    time_wait_count=$(grep "TIME_WAIT" "$log_file" | wc -l)
    
    if [ "$time_wait_count" -gt 100 ]; then
        echo "WARNING: High number of TIME_WAIT connections: $time_wait_count" >> "$ANALYSIS_FILE"
    fi
    
    # Анализ подключений по портам
    echo -e "\n=== Port Analysis ===" >> "$ANALYSIS_FILE"
    grep "Active Connections by Port" -A 20 "$log_file" >> "$ANALYSIS_FILE"
    
    # Анализ топ IP-адресов
    echo -e "\n=== Suspicious IP Analysis ===" >> "$ANALYSIS_FILE"

    grep "Top IPs by Connection Count" -A 10 "$log_file" | \
        awk '$1 > 50 {print "WARNING: Suspicious number of connections from IP: " $2 " (Count: " $1 ")"}' \
        >> "$ANALYSIS_FILE"
}

# Функция очистки старых логов (хранить логи за последние 7 дней)
cleanup_old_logs() {
    find "$LOG_DIR" -type f \( -name "stats.log" -o -name "analysis.log" \) -mtime +7 -delete
}

# Основной процесс
collect_statistics
analyze_logs "$STATS_FILE"
cleanup_old_logs
