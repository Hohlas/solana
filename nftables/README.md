### сбор сетевой статистики 
```bash
mkdir -p $HOME/net_monitor; cd $HOME/net_monitor
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/net_stat.sh > $HOME/net_monitor/net_stat.sh;
chmod +x $HOME/net_monitor/net_stat.sh
./net_stat.sh
```

### установка и запуск фаервола 
```bash
apt update
apt install nftables
mkdir -p $HOME/net_monitor
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/net_monitor.sh > $HOME/net_monitor/net_monitor.sh;
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables.conf > /etc/nftables.conf
systemctl enable nftables
systemctl start nftables
chmod +x $HOME/net_monitor/net_monitor.sh

```
```bash
nft -f nftables.conf # Примените изменения
```
```bash
ufw disable
systemctl disable ufw
systemctl stop ufw
iptables -F
iptables -X 
```
