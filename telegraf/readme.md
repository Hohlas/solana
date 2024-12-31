```bash
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegraf/grafana_setup.sh > ~/grafana_setup.sh; chmod +x ~/grafana_setup.sh
source ~/grafana_setup.sh
rm ~/grafana_setup.sh
```
[JStaking telegraf](https://github.com/mfactory-lab/sv-manager/blob/main/docs/advanced.md#how-to-install-monitoring-manually)
```bash
# install telegraf and point it to solana.thevalidators.io
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegraf/grafana_JStaking_setup.sh > ~/grafana_setup.sh; chmod +x ~/grafana_setup.sh
source ~/grafana_setup.sh
rm ~/grafana_setup.sh
# original script #  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mfactory-lab/sv-manager/latest/install/install_monitoring.sh)"
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
### agava 2.1.5 version patch
```bash
sed -i 's/credits\/slots/'\''credits\/max credits'\''/g' "$HOME/solanamonitoring/monitor.sh"
systemctl restart telegraf
```
