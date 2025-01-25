#!/bin/bash
RATE_FILE="$HOME/net_monitor/rates.csv"
INTERVAL=60

TIME() {
    TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S"
}

if [ ! -f "$RATE_FILE" ]; then
    # Create header with UDP ports
    header="Time;p2010;p8000;p8001;p8899;tcp_in;tcp_out;udp_in;udp_out"
    for port in $(seq 8000 8020); do
        header="${header};udp${port}"
    done
    echo "$header" > "$RATE_FILE"
fi

monitor_rates() {
    while true; do
        time=$(TIME)
        declare -A rates
        
        # Original counters
        for counter in port_2010 port_8000 port_8001 port_8899 tcp_in tcp_out udp_in udp_out; do
            data=$(nft list counter ip packets_counter ${counter}_counter | grep -oP 'packets \K[0-9]+ bytes [0-9]+')
            if [ -n "$data" ]; then
                packets=$(echo $data | cut -d' ' -f1)
                rate_pps=$((packets / INTERVAL))
                case $counter in
                    "port_2010") rates["p2010"]=$rate_pps ;;
                    "port_8000") rates["p8000"]=$rate_pps ;;
                    "port_8001") rates["p8001"]=$rate_pps ;;
                    "port_8899") rates["p8899"]=$rate_pps ;;
                    *) rates[$counter]=$rate_pps ;;
                esac
            else
                case $counter in
                    "port_2010") rates["p2010"]=0 ;;
                    "port_8000") rates["p8000"]=0 ;;
                    "port_8001") rates["p8001"]=0 ;;
                    "port_8899") rates["p8899"]=0 ;;
                    *) rates[$counter]=0 ;;
                esac
            fi
        done

        # UDP port counters
        for port in $(seq 8000 8020); do
            data=$(nft list counter ip packets_counter port_udp_${port}_counter | grep -oP 'packets \K[0-9]+ bytes [0-9]+')
            if [ -n "$data" ]; then
                packets=$(echo $data | cut -d' ' -f1)
                rates["udp${port}"]=$((packets / INTERVAL))
            else
                rates["udp${port}"]=0
            fi
        done
        
        # Build CSV line
        line="$time;${rates[p2010]};${rates[p8000]};${rates[p8001]};${rates[p8899]};${rates[tcp_in]};${rates[tcp_out]};${rates[udp_in]};${rates[udp_out]}"
        for port in $(seq 8000 8020); do
            line="${line};${rates[udp${port}]}"
        done
        
        echo "$line" >> "$RATE_FILE"
        
        # Reset all counters
        for counter in port_2010 port_8000 port_8001 port_8899 tcp_in tcp_out udp_in udp_out; do
            nft reset counter ip packets_counter ${counter}_counter
        done
        for port in $(seq 8000 8020); do
            nft reset counter ip packets_counter port_udp_${port}_counter
        done
        
        sleep $INTERVAL
    done
}

monitor_rates &
wait
