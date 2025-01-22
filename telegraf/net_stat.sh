#!/bin/bash

# Директория для хранения логов
LOG_DIR="$HOME/net_stat"
mkdir -p "$LOG_DIR"

# Файлы для логирования
STATS_FILE="$LOG_DIR/stats.log"
ANALYSIS_FILE="$LOG_DIR/analysis.log"

# Функция для записи статистики с выводом в терминал
log_save() {
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $1" | tee -a "$STATS_FILE"
}

# Обработка SIGINT для корректного завершения работы
trap "echo 'Скрипт остановлен'; exit" SIGINT

handle_error() {
    echo "Ошибка при выполнении команды: $1" | tee -a "$STATS_FILE"
}

# Сбор общей статистики
collect_statistics() {
    log_save " === Solana Validator Statistics ==="
    
    # TCP соединения по состояниям
    log_save " === TCP Connection States ==="
    if ! netstat -ant | awk '{print $6}' | sort | uniq -c | tee -a "$STATS_FILE"; then
        handle_error "netstat -ant"
    fi
    
    # Активные соединения по портам
    log_save " === Active Connections by Port ==="
    if ! netstat -tnp | grep ESTABLISHED | awk '{print $4}' | cut -d: -f2 | sort | uniq -c | tee -a "$STATS_FILE"; then
        handle_error "netstat -tnp"
    fi
    
    # UDP трафик на портах Solana
    log_save " === UDP Traffic on Ports 8002-8020 ==="
    if ! timeout 10 tcpdump -i any 'udp portrange 8002-8020' -n 2>/dev/null | wc -l | tee -a "$STATS_FILE"; then
        handle_error "tcpdump"
    fi
    
    # Топ IP-адресов по количеству соединений
    log_save " === Top IPs by Connection Count ==="
    if ! netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -n 10 | tee -a "$STATS_FILE"; then
        handle_error "netstat -ntu"
    fi
    
    # Информация о нагрузке на сеть
    log_save " === Network Interface Statistics ==="
    if ! ip -s link | tee -a "$STATS_FILE"; then
        handle_error "ip link"
    fi
}

# Расширенный анализ соединений
enhance_connection_analysis() {
    log_save " === Enhanced Connection Analysis ==="
    
    # Анализ соединений по состояниям для каждого порта
    log_save "Connection states per port:"
    if ! netstat -ant | awk '{print $4" "$6}' | sort | uniq -c | tee -a "$STATS_FILE"; then
        handle_error "netstat for connection states"
    fi
    
    # Средняя скорость установки новых соединений
    log_save " New connection rate:"
    if ! ss -tn state syn-recv | wc -l | tee -a "$STATS_FILE"; then
        handle_error "ss syn-recv"
    fi
    
    # Анализ длительности соединений
    log_save " Connection duration analysis:"
    if ! ss -tn state established -o | tee -a "$STATS_FILE"; then
        handle_error "ss established connections"
    fi
}

# Мониторинг портов Solana
monitor_solana_specific() {
    log_save " === Solana-specific Metrics ==="
    
    local solana_ports=(8000 8001 8899 8900)
    
    for port in "${solana_ports[@]}"; do
        log_save "Port $port connections:"
        if ! netstat -ant | grep ":$port" | wc -l | tee -a "$STATS_FILE"; then
            handle_error "netstat for port $port"
        fi
    done
    
    # Анализ UDP трафика с разбивкой по портам
    log_save " Detailed UDP traffic analysis:"
    for port in "${solana_ports[@]}"; do
        log_save "UDP traffic on port $port:"
        if ! timeout 10 tcpdump -i any "udp port $port" -n 2>/dev/null | wc -l | tee -a "$STATS_FILE"; then
            handle_error "tcpdump for UDP port $port"
        fi
    done
}

# мониторинг ICMP-трафика
monitor_icmp_traffic() {
    log_save " === ICMP Traffic Analysis ==="
    
    # Общее количество ICMP пакетов
    log_save "Total ICMP packets (10 second sample):"
    if ! timeout 10 tcpdump -i any 'icmp' -n 2>/dev/null | wc -l | tee -a "$STATS_FILE"; then
        handle_error "tcpdump ICMP count"
    fi
    
    # Краткая статистика по типам (важно для настройки защиты)
    log_save " ICMP types summary:"
    if ! timeout 10 tcpdump -i any 'icmp' -nn 2>/dev/null | \
        awk '/ICMP/ {print $3}' | sort | uniq -c | tee -a "$STATS_FILE"; then
        handle_error "tcpdump ICMP types"
    fi
}


# Мониторинг скорости передачи данных на сетевых интерфейсах. 
monitor_network_bandwidth() {
    log_save " === Network Bandwidth Statistics ==="
    
    # Получаем список активных сетевых интерфейсов
    local interfaces=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}')
    
    for interface in $interfaces; do
        log_save " Interface: $interface"
        # Используем sar для измерения скорости передачи данных
        if ! sar -n DEV 1 5 | grep "$interface" | tail -n 1 | tee -a "$STATS_FILE"; then
            handle_error "sar bandwidth measurement for $interface"
        fi
    done
}

# Анализ установленных соединений с учетом времени их существования
analyze_connection_duration() {
    log_save " === Connection Duration Analysis ==="
    
    # Анализируем длительность установленных соединений
    log_save "Established connections with duration:"
    if ! ss -tn state established -o | \
        awk '{ if(NR>1) print $1,$4,$5,$6 }' | tee -a "$STATS_FILE"; then
        handle_error "connection duration analysis"
    fi
}

# Отслеживание соотношения новых и установленных соединений
monitor_connection_states() {
    log_save " === Connection State Ratios ==="
    
    # Подсчитываем количество соединений в разных состояниях
    local established=$(ss -tn state established | wc -l)
    local syn_recv=$(ss -tn state syn-recv | wc -l)
    local fin_wait=$(ss -tn state fin-wait-1 | wc -l)
    
    # Записываем результаты
    log_save "Established: $established"
    log_save "SYN_RECV: $syn_recv"
    log_save "FIN_WAIT: $fin_wait"
    
    # Рассчитываем соотношение новых соединений к установленным
    if [ "$established" -ne 0 ]; then
        local ratio=$(echo "scale=2; $syn_recv / $established" | bc)
        log_save "New/Established ratio: $ratio"
    fi
}

# Мониторинг загрузки системных ресурсов, связанных с сетевой активностью
monitor_system_resources() {
    log_save " === System Resource Usage ==="
    
    # Загрузка CPU сетевыми процессами
    log_save "Network-related CPU usage:"
    if ! top -b -n 1 | grep -E "solana|validator|tcpdump" | tee -a "$STATS_FILE"; then
        handle_error "CPU usage monitoring"
    fi
    
    # Использование сетевых буферов
    log_save " Network buffer usage:"
    if ! sysctl net.ipv4.tcp_mem net.ipv4.tcp_wmem net.ipv4.tcp_rmem | tee -a "$STATS_FILE"; then
        handle_error "network buffer monitoring"
    fi
}

# Анализ распределения подключений по портам Solana
analyze_solana_port_distribution() {
    log_save " === Solana Port Distribution Analysis ==="
    
    # Определяем порты Solana
    local ports=(8000 8001 8899 8900)
    
    for port in "${ports[@]}"; do
        # Подсчитываем общее количество соединений
        local total=$(netstat -ant | grep ":$port" | wc -l)
        # Подсчитываем установленные соединения
        local established=$(netstat -ant | grep ":$port" | grep ESTABLISHED | wc -l)
        
        log_save "Port $port:"
        log_save "  Total connections: $total"
        log_save "  Established: $established"
        
        # Анализируем источники подключений
        log_save "  Connection sources:"
        if ! netstat -ant | grep ":$port" | awk '{print $5}' | cut -d: -f1 | \
            sort | uniq -c | sort -nr | head -5 | tee -a "$STATS_FILE"; then
            handle_error "port $port source analysis"
        fi
    done
}





# Основной процесс в цикле
while true; do
    collect_statistics
    enhance_connection_analysis
    monitor_solana_specific
    monitor_icmp_traffic  
    monitor_network_bandwidth
    analyze_connection_duration
    monitor_connection_states
    monitor_system_resources
    analyze_solana_port_distribution
    sleep 5  # Задержка между циклами
done
