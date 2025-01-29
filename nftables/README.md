## nftables firewall

<details>
<summary>Описание функций</summary>

Фаервол портов соланы  (ssh, 8000-8001, 8900, 11226, ...)
DDOS защита: Добавляет IP в блэклист на 120сек на основе фильтров, логирует /var/log/kern.log 

<ins>Фильтры:</ins>  
- ICMP - частота echo-запросов (ping): 30 пакетов/сек, всплески 30 пакетов  
- TCP - кол-во TCP соединений от одного IP: 100/сек, всплески 100 пакетов  
- UDP - кол-во UDP-пакетов от одного IP: 100К/сек, всплески 20К пакетов  
- Port scan - Защита от сканирования портов чаще чем 200 в минуту  

</details>

```bash
# удаление старого фаервола iptables
ufw disable
systemctl disable ufw
systemctl stop ufw
iptables -F # очищает все правила фильтрации в iptables
iptables -X # удаляет все пользовательские цепочки из iptables
iptables -S # разрешать входящие, исходящие и транзитные одной командой
```
```bash
iptables -L -n -v  # Показать текущие правила
```


### установка и запуск фаервола на nftables
```bash
apt update && apt install nftables -y
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables.conf > /etc/nftables.conf
systemctl enable nftables
```
```bash
systemctl restart nftables
```
```bash
systemctl disable nftables
systemctl stop nftables
nft flush ruleset # Очистка всех правил
nft -f nftables.conf # Применение изменений без перезапуска сервиса
```
```bash
grep "NFT" /var/log/kern.log # срабатывания фильтров
nft list ruleset # просмотр всех правил
nft list table filter # просмотр таблицы filter
nft list chain filter input # просмотр цепочки input таблицы filter.
nft list chain filter ddos_protection # # просмотр цепочки ddos_protection таблицы filter.
```
<details>
<summary>Сервис отправки уведомлений </summary>

```bash
# сервис оповещения в телегу и терминал (реализован в guard)
mkdir -p $HOME/net_monitor
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/net_monitor.sh > $HOME/net_monitor/net_monitor.sh
chmod +x $HOME/net_monitor/net_monitor.sh
echo "[Unit]
Description=NFTables Monitor Service
After=network.target nftables.service

[Service]
Type=simple
ExecStart=$HOME/net_monitor/net_monitor.sh
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/net-monitor.service
systemctl daemon-reload
systemctl enable net-monitor
systemctl restart net-monitor
```
</details>


<details>
<summary>Проверка</summary>
Мониторинг логов на тестируемом сервере

```bash
mkdir -p $HOME/net_monitor
# счетчик пакетов
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables_counter.conf > /etc/nftables_counter.conf
# mv /etc/nftables_counter.conf /etc/nftables.conf # заменить сервис фильтра мониторингом
# скрипт для формирования статистики rates.csv
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/packets_counter.sh > ~/net_monitor/packets_counter.sh
chmod +x ~/net_monitor/packets_counter.sh
~/net_monitor/packets_counter.sh
```
```bash
# раскомментировать include "/etc/nftables_counter.conf"
nano /etc/nftables.conf 
```



```bash
tail -f /var/log/kern.log | grep NFT # логи фильтра
tail -f ~/net_monitor/nftables.log  # логи скрипта net_monitor.sh
```

Имитация атаки с удаленного сервера 

```bash
TEST_IP="195.3.223.66" # IP тестируемого сервера
TIMER="120s"
apt install nmap hping3
```  
```bash
timeout $TIMER hping3 -S -p 8900 --flood $TEST_IP # SYN-flood
```
```bash
timeout $TIMER nmap -p- -T4 $TEST_IP # Port scan
```
```bash
timeout $TIMER hping3 --udp -p 8000 --flood $TEST_IP # UDP flood
nping --udp -p 8000-8020 --rate 1000 $TEST_IP
```
```bash
timeout $TIMER hping3 -1 --flood $TEST_IP # ICMP flood
```
```bash
# TCP atack  
for i in {1..30}; do 
    nc -zv $TEST_IP 8899 & 
    sleep 0.1
done 
```

</details>

<details>
<summary>определение пороговых значений для настройки nftables фильтров </summary>
 
<ins>nftables.conf</ins> - Использует счетчики для отслеживания трафика по типам (TCP/UDP).  
<ins>packets_counter.sh</ins> - Каждую минуту считывает показания счетчиков nftables.  
Вычисляет скорость трафика в pps (packets per second) и записывает статистику в rates.csv.  
Сбрасывает счетчики раз в минуту после каждого измерения. 

```bash
mkdir -p $HOME/net_monitor; cd $HOME/net_monitor
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/packets_counter.sh > $HOME/net_monitor/packets_counter.sh
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables_counter.conf > /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables
chmod +x $HOME/net_monitor/packets_counter.sh
$HOME/net_monitor/packets_counter.sh
```
```bash
nft list counters # Показания счётчиков
watch -n 1 'nft list counters'  # Обновление каждую секунду
```
### оценка 'tcp-syn' запросов - количество подключений с одного IP
```bash
# Запишите 'tcp-syn' трафик в файл за несколько минут
tcpdump -i any -ttt 'tcp[tcpflags] & tcp-syn != 0' -n -w syn_packets.pcap
```
```bash
# показать статистику количеств подключений в минуту от каждого IP
tcpdump -r syn_packets.pcap -n -tt | awk '{print int($1/60)" "$5}' | cut -d. -f1-4 | sort | uniq -c | sort -k2,2 -k1,1nr
```
### оценка 'ICMP' запросов - (ping)
```bash
# Запуск записи лога подключений на 60 секунд
timeout --kill-after=1s 60s tcpdump -i any icmp -n -w icmp_packets.pcap
```
```bash
# После записи проанализируем количество для каждого IP
tcpdump -r icmp_packets.pcap -n | awk '{print $5}' | cut -d. -f1-4 | sort | uniq -c | sort -nr
```
до 30 запросов/минуту

### оценка 'UDP' запросов
```bash
# Запуск записи лога подключений на 60 секунд
timeout 60s tcpdump -i any udp dst port 8000 -n -w udp_packets.pcap
```
```bash
# После записи проанализируем количество udp запросов для каждого IP
tcpdump -r udp_packets.pcap -n | awk '{print $5}' | cut -d. -f1-4 | sort | uniq -c | sort -nr > udp_packets.log
```
до 50К пакетов/сек

![image](https://github.com/user-attachments/assets/14288973-c121-432d-95e4-5e370927bb80)


```bash
# вывести максимальные значения из rates.csv
awk -F';' '
NR == 1 { for(i=1;i<=NF;i++) header[i]=$i }
NR > 1 {
   for (i=2; i<=NF; i++) 
       if ($i+0 > max[i]) max[i] = $i
} 
END {
   for (i=2; i<=NF; i++)
       print header[i] " max:" max[i]
}' "$HOME/net_monitor/rates.csv"

```

</details>

<details>
<summary>сбор сетевой статистики старый метод</summary>

```bash
mkdir -p $HOME/net_monitor; cd $HOME/net_monitor
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/net_stat.sh > $HOME/net_monitor/net_stat.sh;
chmod +x $HOME/net_monitor/net_stat.sh
./net_stat.sh 
```
</details>


