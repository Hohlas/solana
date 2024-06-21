
## Server setup
```bash
sudo apt update && sudo apt upgrade -y && sudo apt install git ncdu ufw tmux htop curl nano fail2ban smartmontools mc man rsync cron logrotate rsyslog encfs jq -y
```
[Server setup - notion](https://hohla.notion.site/SERVER-SETUP-5107bc05d2cb422f94f2ed5d0471b5b4?pvs=4)
### create and mount partitions   
```bash
lsblk # check MOUNTPOINTS
fdisk /dev/nvme1n1 #
  # d # delete 
  # n # create new. 'ENTER' by default. 
  # w # write changes
mkfs.ext4 /dev/nvme1n1p1 # format partition 'p1'
```
```bash
mkdir -p /mnt/disk1
mkdir -p /mnt/disk2
mkdir -p /mnt/disk3
mount /dev/nvme1n1p1 /mnt/disk1
echo '/dev/nvme1n1p1 /mnt/disk1 ext4 defaults 0 1' | sudo tee -a /etc/fstab
mount /dev/nvme2n1p1 /mnt/disk2
echo '/dev/nvme2n1p1 /mnt/disk2 ext4 defaults 0 1' | sudo tee -a /etc/fstab
mount /dev/nvme3n1p1 /mnt/disk3
echo '/dev/nvme3n1p1 /mnt/disk3 ext4 defaults 0 1' | sudo tee -a /etc/fstab
mount -a
```

### SSH settings
```bash
export NEWHOSTNAME="hohla"
```
```bash
sudo hostname $NEWHOSTNAME # сменить до перезагрузки
sudo hostnamectl set-hostname $NEWHOSTNAME
sudo nano /etc/hosts
```

```bash
# config SSH
mkdir -p ~/.ssh
rm ~/.ssh/*
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/crypto/authorized_keys > ~/.ssh/authorized_keys # add ssh pubkey 'testnet'
chmod 600 ~/.ssh/authorized_keys
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
mv /etc/ssh/ssh_config /etc/ssh/ssh_config.bak
if [ -d /etc/ssh/sshd_config.d ]; then rm -f /etc/ssh/sshd_config.d/*; fi
if [ -d /etc/ssh/ssh_config.d ]; then rm -f /etc/ssh/ssh_config.d/*; fi
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/crypto/sshd_config > /etc/ssh/sshd_config
sudo ufw allow 2010  # добавить порт в правила файрвола
sudo systemctl restart ssh  # перезапустить службу ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
nano ~/.ssh/authorized_keys
```

```bash
# config file2ban
echo "backend = systemd" >> /etc/fail2ban/jail.d/defaults-debian.conf
echo "authpriv.*      /var/log/auth.log" >> /etc/rsyslog.conf
systemctl restart fail2ban
fail2ban-client status

# config EncFS
mkdir -p ~/.crpt ~/keys
encfs ~/.crpt ~/keys # 
```

## Install Solana Node
```   copy validator.json, vote.json to ~/keys   ```
```bash
# MAIN #
export TAG=v1.18.15-jito
export NODE=main
export NAME=$(echo $(hostname) | tr '[:lower:]' '[:upper:]') #
```
```bash
# TEST #
export TAG=v1.18.17
export NODE=test  # test or main
export NAME=$(echo $(hostname) | tr '[:upper:]' '[:lower:]')
```

```bash
curl https://raw.githubusercontent.com/Hohlas/solana/main/setup/node_setup.sh > ~/node_setup.sh
chmod +x ~/node_setup.sh; ~/node_setup.sh
source $HOME/.bashrc
```
```bash
systemctl restart solana  # sudo systemctl restart solana
systemctl status solana
```
```bash
ulimit -n 1000000  # set ulimit
ulimit -n # check ulimit
```
### alias
```bash
git_clone
node_set | node_reset
get_tag | node_install | node_update
check | logs | next | monitor | catch
guard | vote_on | vote_off | ssh_agent
mount_keys | umount_keys | shred_keys
```
## Jito-Relayer Setup
```bash
curl https://raw.githubusercontent.com/Hohlas/solana/main/Jito/jito_relayer_setup.sh > ~/jito_relayer_setup.sh
chmod +x ~/jito_relayer_setup.sh
~/jito_relayer_setup.sh
```
## Grafana Setup
```bash
source ~/sol_git/setup/grafana_setup.sh
```
### update config file
```bash
git_clone
cp ~/sol_git/setup/telegraf.conf /etc/telegraf/telegraf.conf
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
sed -i "/^solanaPrice=/c\solanaPrice=555" /root/solanamonitoring/monitor.sh
systemctl restart telegraf
```
## Snapshot Finder
### setup snapshot finder
```bash
cd 
ulimit -n 1000000
rm -rf ~/solana-snapshot-finder
sudo apt update
sudo apt install python3-venv git -y
git clone https://github.com/c29r3/solana-snapshot-finder.git
# git clone https://github.com/Hohlas/solana-snapshot-finder.git
cd ~/solana-snapshot-finder
python3 -m venv venv
source ./venv/bin/activate
pip3 install -r requirements.txt
```
### init snapshot finder
```bash
source ~/.bashrc; 
cd ~/solana-snapshot-finder \
&& python3 -m venv venv \
&& source ./venv/bin/activate
```
### MainNet snapshot finder
```bash
systemctl stop solana
rm -rf ~/solana/ledger/*
#rm -rf /mnt/disk1/snapshots/* 
rm -rf /mnt/disk1/accounts/*
rm -rf /mnt/disk2/ledger/*
rm -rf /mnt/disk3/accounts_index/*
rm -rf /mnt/disk3/accounts_hash_cache/*
```
```bash
python3 snapshot-finder.py --snapshot_path /mnt/disk1/snapshots --num_of_retries 10 --measurement_time 10 --min_download_speed 40 --max_snapshot_age 500 --max_latency 500 --with_private_rpc --sort_order latency -r https://api.mainnet-beta.solana.com && \
systemctl restart solana && tail -f ~/solana/solana.log
```
### TestNet snapshot finder
```bash
python3 snapshot-finder.py --snapshot_path $HOME/solana/ledger --num_of_retries 10 --measurement_time 10 --min_download_speed 50 --max_snapshot_age 500 --with_private_rpc --sort_order latency -r https://api.testnet.solana.com && \
systemctl daemon-reload && systemctl restart solana
tail -f ~/solana/solana.log
```
## LINKS
### grafana
[BUKA](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&var-inter=30s&var-cpu=All&var-netif=All&from=now-6h&to=now&var-pubkey=5NiHw5LZn1FiL848XzbEBxuygbNvMJ7CsPvXNC8VmCLN&var-server=BUKA&refresh=1m) | [HOHLA](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&refresh=1m&var-pubkey=AptafqHRpGk3KCQrGtuPGuPvWMuPc4N15X7NN7VUsfbd&var-server=HOHLA&var-inter=1m&var-netif=All&from=now-6h&to=now) | [VALERA](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&var-inter=30s&var-cpu=All&var-netif=eth0&from=now-12h&to=now&var-pubkey=A4fxKaaNPBCaMwqKyhHxoWKJ5ybgvmmwTQmNmGtt2aoC&var-server=VALERA&refresh=1m&var-version=)
| [buka](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&var-server=buka&var-inter=30s&var-cpu=All&var-netif=All&var-pubkey=mFJG277eG7EFS7Zu2UU5BkFZQW7PpAVfjMaFsTqXAUq&refresh=5s&from=now-12h&to=now) | [hohla](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&var-server=hohla&var-inter=30s&var-cpu=All&var-netif=All&var-pubkey=8HzsgkGhEFP2MKuuPDy5f8qvqR6hmwPqeq7UMY3X2Z6T&refresh=5s&from=now-12h&to=now) |  [valera](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&refresh=5s&var-server=valera&var-inter=30s&var-cpu=All&var-netif=All&var-pubkey=CpFKK4LrfnCZ32gQPPW8hVMqFsMSe46k7cUjs8h77iQQ&from=now-12h&to=now)
### solana foundation
[BUKA](https://solana.org/sfdp-validators/5NiHw5LZn1FiL848XzbEBxuygbNvMJ7CsPvXNC8VmCLN) |  [HOHLA](https://solana.org/sfdp-validators/AptafqHRpGk3KCQrGtuPGuPvWMuPc4N15X7NN7VUsfbd) |  [VALERA](https://solana.org/sfdp-validators/A4fxKaaNPBCaMwqKyhHxoWKJ5ybgvmmwTQmNmGtt2aoC)
### stakewiz
[BUKA](https://stakewiz.com/validator/FGj3nQTn2Lwe9KkaKnFGm4HcxLSh8B8TjpvP4CinP4iX) | [HOHLA](https://stakewiz.com/validator/3FLezD8GJgnawEHhZcsjdPxZVar9FzqEdViusQ5ZdSwe) | [VALERA](https://stakewiz.com/validator/9esjPxaUdD7yg4yDrBkP3jLipcAGVjpLDXsddF89avzW)
