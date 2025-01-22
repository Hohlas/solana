## сбор сетевой статистики 

```bash
mkdir -p $HOME/net_monitor; cd $HOME/net_monitor
curl curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/net_stat.sh > $HOME/net_monitor/net_stat.sh;
chmod +x $HOME/net_monitor/net_stat.sh
./net_stat.sh
```

```bash
mkdir -p $HOME/net_monitor
curl curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/net_stat.sh > $HOME/net_monitor/net_monitor.sh;
curl curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables.conf > /etc/nftables.conf
systemctl enable nftables
systemctl start nftables
chmod +x $HOME/net_monitor/net_monitor.sh

```
```bash
#
```
```bash
ufw disable
systemctl disable ufw
systemctl stop ufw
```
