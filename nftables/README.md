## nftables firewall

<details>
<summary>Описание функций</summary>

Фильтрация трафика фаерволом для портов соланы  
Защита от DDOS: Добавляет IP в блэклист на 120сек за подозрительную активность  
Фиксирует подозрительную активность в /var/log/kern.log  
Определяет аттаки:  
  ICMP flood  
  TCP flood  
  UDP flood  
  Port scan  

```bash
 
```
</details>

```bash
# удаление старого фаервола iptables
ufw disable
systemctl disable ufw
systemctl stop ufw
iptables -F
iptables -S # 
iptables -X
```
```bash
iptables -L -n -v  # Показать текущие правила
```



### установка и запуск фаервола на nftables
```bash
apt update
apt install nftables
mkdir -p $HOME/net_monitor
# фаервол, ddos фильтр
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables.conf > /etc/nftables.conf
# скрипт оповещения в телегу и терминал
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/net_monitor.sh > $HOME/net_monitor/net_monitor.sh;
systemctl enable nftables
chmod +x $HOME/net_monitor/net_monitor.sh
```
```bash
systemctl restart nftables
```
```bash
~/net_monitor/net_monitor.sh # запускать в отдельном окне
```
```bash
nft -f nftables.conf # Примените изменения
systemctl disable nftables
systemctl stop nftables
nft flush ruleset # Очистка всех правил
```



<details>
<summary>Проверка</summary>
Мониторинг логов на тестируемом сервере

```bash
# счетчик пакетов
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables_counter.conf > /etc/nftables_counter.conf
# скрипт для формирования статистики rates.csv
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/packets_counter.sh > $HOME/net_monitor/packets_counter.sh
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
apt install nmap hping3
```  
```bash
hping3 -S -p 8899 --flood $TEST_IP # SYN-flood
```
```bash
nmap -p- -T4 $TEST_IP # Port scan
```
```bash
hping3 --udp -p 8000 --flood $TEST_IP # UDP flood
```
```bash
hping3 -1 --flood $TEST_IP # ICMP flood
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
```bash

```
Значения используются для выставления ограничений в nftables.conf  
tcp_in -> TCP flood  
udp_in -> UDP flood

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


