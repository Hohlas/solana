## сбор сетевой статистики 

```bash
 curl curl https://raw.githubusercontent.com/Hohlas/solana/main/telegraf/net_stat.sh > ~/net_stat.sh;
chmod +x ~/net_stat.sh
(crontab -l 2>/dev/null; echo "*/2 * * * * $HOME/net_stat.sh") | crontab -
```
```bash
LOG_DIR="/var/log/solana-monitoring"

grep "WARNING" $LOG_DIR/analysis.log | sort | uniq -c # Посмотреть уникальные события в анализе
grep -A 10 "Top IPs by Connection Count" $LOG_DIR/stats.log # Проанализировать топ IP-адресов
grep -A 10 "TCP Connection States" $LOG_DIR/stats.log # Посмотреть статистику по состояниям соединений
```
---
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



