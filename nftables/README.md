## DDOS protection 

```bash
# удаление фаервола
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
nft -f nftables.conf # Примените изменения
systemctl disable nftables
systemctl stop nftables
nft flush ruleset # Очистка всех правил
```



<details>
<summary>Проверка</summary>
Мониторинг логов на тестируемом сервере

```bash
tail -f /var/log/kern.log | grep NFT 
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
nmap -p- -T4 195.3.223.66 # Port scan
```
```bash
hping3 --udp -p 8000 --flood 195.3.223.66 # UDP flood
```
```bash
hping3 -1 --flood 195.3.223.66 # ICMP flood
```
```bash
# TCP atack  
for i in {1..30}; do 
    nc -zv 195.3.223.66 8899 & 
    sleep 0.1
done 
```
</details>

<details>
<summary>сбор сетевой статистики</summary>

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

