## DDOS protection 

```bash
# удаление старого фаервола
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



### установка и запуск фаервола 
```bash
apt update
apt install nftables
mkdir -p $HOME/net_monitor
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/net_monitor.sh > $HOME/net_monitor/net_monitor.sh;
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables.conf > /etc/nftables.conf
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
tail -f /var/log/kern.log | grep NFT # логи фильтра
tail -f ~/net_monitor/nftables.log  # логи скрипта
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
<summary>сбор сетевой статистики</summary>

Собирает статистику соединения в файл ~/net_monitor/rates.log 
```bash
mkdir -p $HOME/net_monitor; cd $HOME/net_monitor
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/pocket_counter.sh > $HOME/net_monitor/net_stat.sh
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables_counter.sh > /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables
chmod +x $HOME/net_monitor/net_stat.sh
./net_stat.sh


```
Находим максимальные значения трафика
```bash
awk '/tcp_in:/ { if ($2 > max_tcp) max_tcp = $2 } 
     /udp_in:/ { if ($2 > max_udp) max_udp = $2 } 
     END { print "Максимальное значение tcp_in:", max_tcp; print "Максимальное значение udp_in:", max_udp }' ~/net_monitor/rates.log

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


<details>
<summary>empty</summary>

```bash
 
```
</details>

