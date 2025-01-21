#!/bin/bash

# Директория для хранения логов
LOG_DIR="/var/log/solana-monitoring"
mkdir -p "$LOG_DIR"

# Файлы для логирования
STATS_FILE="$LOG_DIR/stats.log"
ANALYSIS_FILE="$LOG_DIR/analysis.log"

# Функция для записи статистики с выводом в терминал
log_save() {
    echo "$(date): $1" | tee -a "$STATS_FILE"
}

# Обработка SIGINT для корректного завершения работы
trap "echo 'Скрипт остановлен'; exit" SIGINT

handle_error() {
    echo "Ошибка при выполнении команды: $1" | tee -a "$STATS_FILE"
}

# Сбор общей статистики
collect_statistics() {
    log_save "=== Solana Validator Statistics ==="
    
    # TCP соединения по состояниям
    log_save "\n=== TCP Connection States ==="
    if ! netstat -ant | awk '{print $6}' | sort | uniq -c | tee -a "$STATS_FILE"; then
        handle_error "netstat -ant"
    fi
    
    # Активные соединения по портам
    log_save "\n=== Active Connections by Port ==="
    if ! netstat -tnp | grep ESTABLISHED | awk '{print $4}' | cut -d: -f2 | sort | uniq -c | tee -a "$STATS_FILE"; then
        handle_error "netstat -tnp"
    fi
    
    # UDP трафик на портах Solana
    log_save "\n=== UDP Traffic on Solana Ports ==="
    if ! timeout 30 tcpdump -i any 'udp portrange 8000-8020' -n 2>/dev/null | wc -l | tee -a "$STATS_FILE"; then
        handle_error "tcpdump"
    fi
    
    # Топ IP-адресов по количеству соединений
    log_save "\n=== Top IPs by Connection Count ==="
    if ! netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -n 10 | tee -a "$STATS_FILE"; then
        handle_error "netstat -ntu"
    fi
    
    # Информация о нагрузке на сеть
    log_save "\n=== Network Interface Statistics ==="
    if ! ip -s link | tee -a "$STATS_FILE"; then
        handle_error "ip link"
    fi
}

# Расширенный анализ соединений
enhance_connection_analysis() {
    log_save "\n=== Enhanced Connection Analysis ==="
    
    # Анализ соединений по состояниям для каждого порта
    log_save "Connection states per port:"
    if ! netstat -ant | awk '{print $4" "$6}' | sort | uniq -c | tee -a "$STATS_FILE"; then
        handle_error "netstat for connection states"
    fi
    
    # Средняя скорость установки новых соединений
    log_save "\nNew connection rate:"
    if ! ss -tn state syn-recv | wc -l | tee -a "$STATS_FILE"; then
        handle_error "ss syn-recv"
    fi
    
    # Анализ длительности соединений
    log_save "\nConnection duration analysis:"
    if ! ss -tn state established -o | tee -a "$STATS_FILE"; then
        handle_error "ss established connections"
    fi
}

# Мониторинг портов Solana
monitor_solana_specific() {
    log_save "\n=== Solana-specific Metrics ==="
    
    local solana_ports=(8000 8001 8899 8900)
    
    for port in "${solana_ports[@]}"; do
        log_save "Port $port connections:"
        if ! netstat -ant | grep ":$port" | wc -l | tee -a "$STATS_FILE"; then
            handle_error "netstat for port $port"
        fi
    done
    
    # Анализ UDP трафика с разбивкой по портам
    log_save "\nDetailed UDP traffic analysis:"
    for port in "${solana_ports[@]}"; do
        log_save "UDP traffic on port $port:"
        if ! timeout 10 tcpdump -i any "udp port $port" -n 2>/dev/null | wc -l | tee -a "$STATS_FILE"; then
            handle_error "tcpdump for UDP port $port"
        fi
    done
}

# мониторинг ICMP-трафика
monitor_icmp_traffic() {
    log_save "\n=== ICMP Traffic Analysis ==="
    
    # Подсчитываем общее количество ICMP пакетов за короткий период
    log_save "Total ICMP packets (10 second sample):"
    if ! timeout 10 tcpdump -i any 'icmp' -n 2>/dev/null | wc -l | tee -a "$STATS_FILE"; then
        handle_error "tcpdump ICMP count"
    fi
    
    # Анализируем типы ICMP сообщений
    log_save "\nICMP message types distribution:"
    if ! timeout 10 tcpdump -i any 'icmp' -nn -v 2>/dev/null | \
        awk '/ICMP/ {print $3}' | sort | uniq -c | \
        while read count type; do
            # Добавляем описания для основных типов ICMP
            case "$type" in
                "echo")
                    echo "$count $type (ping request)"
                    ;;
                "echo-reply")
                    echo "$count $type (ping response)"
                    ;;
                "unreachable")
                    echo "$count $type (destination unreachable)"
                    ;;
                *)
                    echo "$count $type"
                    ;;
            esac
        done | tee -a "$STATS_FILE"; then
        handle_error "tcpdump ICMP types analysis"
    fi
    
    # Анализ источников ICMP-трафика
    log_save "\nTop sources of ICMP traffic:"
    if ! timeout 10 tcpdump -i any 'icmp' -nn 2>/dev/null | \
        awk '{print $3}' | sort | uniq -c | sort -nr | head -5 | \
        while read count ip; do
            echo "$count packets from $ip"
        done | tee -a "$STATS_FILE"; then
        handle_error "tcpdump ICMP sources analysis"
    fi
    
    # Проверка на аномальное количество ICMP-пакетов
    local icmp_count=$(timeout 5 tcpdump -i any 'icmp' -n 2>/dev/null | wc -l)
    local threshold=100  # Пороговое значение для 5-секундного периода
    
    if [ "$icmp_count" -gt "$threshold" ]; then
        log_save "WARNING: Повышенный ICMP-трафик: $icmp_count пакетов за 5 секунд"
        
        # Детальный анализ при превышении порога
        log_save "Detailed analysis of high ICMP traffic:"
        if ! timeout 5 tcpdump -i any 'icmp' -nn -v 2>/dev/null | \
            awk '/ICMP/ {print $3" from "$5}' | sort | uniq -c | \
            sort -nr | head -10 | tee -a "$STATS_FILE"; then
            handle_error "tcpdump ICMP detailed analysis"
        fi
    fi
}

# Основной процесс в цикле
while true; do
    collect_statistics
    enhance_connection_analysis
    monitor_solana_specific
    monitor_icmp_traffic  # мониторинг ICMP
    sleep 5  # Задержка между циклами
done
