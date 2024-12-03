```bash
source ~/sol_git/telegraf/grafana_setup.sh
```
### update config file
```bash
git_clone
cp ~/sol_git/telegraf/telegraf.conf /etc/telegraf/telegraf.conf
source ~/.bashrc
tmp="\"$NAME\""
sed -i "/^  hostname = /c\  hostname = $tmp" /etc/telegraf/telegraf.conf
systemctl restart telegraf
journalctl -u telegraf -f
```
```bash
nano /etc/telegraf/telegraf.conf  # add config
```
### price service
```bash
sed -i "/^solanaPrice=/c\solanaPrice=$(curl -s 'https://api.margus.one/solana/price/'| jq -r .price)" /root/solanamonitoring/monitor.sh
systemctl restart telegraf
```
