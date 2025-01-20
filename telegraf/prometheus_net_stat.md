## сбор статистики работы сети

```bash
 # Установка Prometheus
apt-get update
apt-get install -y prometheus

# Установка Node Exporter
apt-get install -y prometheus-node-exporter

# Установка Grafana
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
apt-get install -y grafana

# Установка Netdata https://my-netdata.io/kickstart.sh
curl curl https://raw.githubusercontent.com/Hohlas/solana/main/telegraf/kickstart.sh > ~/kickstart.sh; chmod +x ~/kickstart.sh
source ~/kickstart.sh
```

```bash
 curl curl https://raw.githubusercontent.com/Hohlas/solana/main/telegraf/net_stat.sh > ~/net_stat.sh;
chmod +x ~/net_stat.sh
(crontab -l 2>/dev/null; echo "*/2 * * * * $HOME/net_stat.sh") | crontab -
```

```bash
 # Посмотреть уникальные события в анализе
grep "WARNING" combined_analysis.log | sort | uniq -c

# Проанализировать топ IP-адресов
grep -A 10 "Top IPs by Connection Count" combined_stats.log

# Посмотреть статистику по состояниям соединений
grep -A 10 "TCP Connection States" combined_stats.log
```

```bash
 # Настройка ротации логов
cat << EOF > /etc/logrotate.d/solana-monitoring
$LOG_DIR/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF
```
