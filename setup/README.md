
## Server setup
```bash
sudo apt update && sudo apt upgrade -y && sudo apt install sysstat git ncdu nftables tmux htop atop curl nano smartmontools bc man rsync cron chrony logrotate rsyslog encfs jq parted xfsprogs fdisk zip unzip -y
```
[Create Partitions & SWAP](https://github.com/Hohlas/ubuntu/blob/main/set/disk.md)

<details>
<summary>SSH settings</summary>
  
```bash
export NEWHOSTNAME="hohla"
# passwd root
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
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/crypto/authorized_keys >> ~/.ssh/authorized_keys # add ssh pubkey 'testnet'
chmod 600 ~/.ssh/authorized_keys
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
mv /etc/ssh/ssh_config /etc/ssh/ssh_config.bak
if [ -d /etc/ssh/sshd_config.d ]; then rm -f /etc/ssh/sshd_config.d/*; fi
if [ -d /etc/ssh/ssh_config.d ]; then rm -f /etc/ssh/ssh_config.d/*; fi
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/crypto/sshd_config > /etc/ssh/sshd_config
sudo ufw allow 2010  # добавить порт в правила файрвола
systemctl daemon-reload
systemctl restart ssh.socket # обновляет порт и адрес, указанные в sshd_config
systemctl restart ssh  # перезапустить службу sshприменяет остальные настройки
nano ~/.ssh/authorized_keys
```

```bash
# config file2ban
echo "backend = systemd" >> /etc/fail2ban/jail.d/defaults-debian.conf
echo "authpriv.*      /var/log/auth.log" >> /etc/rsyslog.conf
systemctl enable fail2ban
systemctl restart fail2ban
fail2ban-client status

# config EncFS
# mkdir -p ~/.crpt ~/keys
# encfs ~/.crpt ~/keys # 
```

</details>


<details>
<summary>System check</summary>

```bash
curl -sL yabs.sh | bash  # full test
curl -sL yabs.sh | bash -s -- -fg    # speed test
smartctl -a /dev/nvme0n1 
```
[iostat](https://github.com/Hohlas/ubuntu/tree/main/test#readme)
</details>

<details>
<summary>Perfomance</summary>

```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor # set perfomance mode 
```
```bash
ulimit -n 1000000  # set ulimit
ulimit -n # check ulimit 
```
```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor # check perfomance mode 
grep 'cpu MHz' /proc/cpuinfo # cpu MHz
dmidecode -t memory | grep -i speed # DIMM MT/s
```
--- 
```bash
# set additional settings
echo "
net.ipv4.tcp_fin_timeout = 15
net.core.netdev_max_backlog = 50000
net.core.optmem_max = 20480
net.core.somaxconn = 65535

net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 87380 134217728
net.ipv4.tcp_mem = 4096 87380 134217728
" > /etc/sysctl.d/22-solana-turbo.conf
sysctl -p /etc/sysctl.d/22-solana-turbo.conf
```
```bash
# read additional settings
sysctl net.ipv4.tcp_fin_timeout
sysctl net.core.netdev_max_backlog
sysctl net.core.optmem_max
sysctl net.core.somaxconn
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem
sysctl net.ipv4.tcp_mem
```
```bash
# read standart
sysctl net.core.rmem_default
sysctl net.core.rmem_max
sysctl net.core.wmem_default
sysctl net.core.wmem_max
sysctl vm.max_map_count
sysctl fs.nr_open
```
</details>



## Install Solana Node
```   copy validator.json, vote.json to ~/keys   ```
```bash
# MAIN #
export TAG=v2.2.15-jito
export NODE=main
export NAME=$(echo $(hostname) | tr '[:lower:]' '[:upper:]') #
```
```bash
# TEST #
export TAG=v2.2.15
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
node_set | node_reset | finder
get_tag | node_install | node_update
check | logs | next | monitor | catch
guard | vote_on | vote_off | ssh_agent
mount_keys | umount_keys | shred_keys
```
[Export guard.cfg](https://github.com/Hohlas/private/tree/main/solana/patch#export-guardcfg)

[Jito](https://github.com/Hohlas/solana/tree/main/Jito)

[Grafana](https://github.com/Hohlas/solana/blob/main/telegraf/readme.md)

[export guard.cfg](https://github.com/Hohlas/private/blob/main/solana/patch/README.md#export-guaardcfg)

<details>
<summary>setup snapshot finder</summary>

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

</details>

<details>
<summary>Jito relayer</summary>

[Monitoring](https://grafana.metrics.jito.wtf:3000/) | [Running Relayer](https://jito-foundation.gitbook.io/mev/jito-relayer/running-a-relayer#running-the-relayer) | [releases](https://github.com/jito-foundation/jito-relayer/releases) | [Block Engines](https://jito-foundation.gitbook.io/mev/solana-mev/third-party-block-engines) | 

```bash
# switch to local relayer
solana-validator -l $HOME/solana/ledger set-relayer-config --relayer-url http://127.0.0.1:11226 
```
```bash
# switch to public relayer
solana-validator -l ~/solana/ledger set-relayer-config --relayer-url http://frankfurt.mainnet.relayer.jito.wtf:8100 
```
```bash
# switch block-engine
solana-validator -l $HOME/solana/ledger set-block-engine-config --block-engine-url https://frankfurt.mainnet.block-engine.jito.wtf
```
```bash
# copy relayer service
cp ~/sol_git/Jito/jito-relayer.service ~/solana/relayer.service
ln -sf ~/solana/relayer.service /etc/systemd/system
systemctl daemon-reload
# systemctl restart relayer
# systemctl status relayer
# journalctl -u relayer -f
```
```bash
# download relayer bin
JTAG=$(curl -s https://api.github.com/repos/jito-foundation/jito-relayer/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
echo "latest jito-relayer TAG = $JTAG"
mkdir -p $HOME/jito-relayer
wget -P $HOME/jito-relayer https://github.com/jito-foundation/jito-relayer/releases/download/$JTAG/jito-transaction-relayer-x86_64-unknown-linux-gnu
chmod +x $HOME/jito-relayer/jito-transaction-relayer-x86_64-unknown-linux-gnu
$HOME/jito-relayer/jito-transaction-relayer-x86_64-unknown-linux-gnu -V
```
```bash
# set Amsterdam
sed -i "/^--relayer-url /c --relayer-url http://amsterdam.mainnet.relayer.jito.wtf:8100 \\\\" ~/solana/solana.service
sed -i "/^--block-engine-url /c --block-engine-url https://amsterdam.mainnet.block-engine.jito.wtf \\\\" ~/solana/solana.service
sed -i "/^--shred-receiver-address /c --shred-receiver-address 74.118.140.240:1002" ~/solana/solana.service
sed -i "/^Environment=BLOCK_ENGINE_URL/c Environment=BLOCK_ENGINE_URL=https://amsterdam.mainnet.block-engine.jito.wtf" ~/solana/relayer.service
systemctl daemon-reload
```
```bash
# set Frankfurt
sed -i "/^--relayer-url /c --relayer-url http://frankfurt.mainnet.relayer.jito.wtf:8100 \\\\" ~/solana/solana.service
sed -i "/^--block-engine-url /c --block-engine-url https://frankfurt.mainnet.block-engine.jito.wtf \\\\" ~/solana/solana.service
sed -i "/^--shred-receiver-address /c --shred-receiver-address 64.130.50.14:1002" ~/solana/solana.service
sed -i "/^Environment=BLOCK_ENGINE_URL/c Environment=BLOCK_ENGINE_URL=https://frankfurt.mainnet.block-engine.jito.wtf" ~/solana/relayer.service
systemctl daemon-reload
```
```bash
ping frankfurt.mainnet.relayer.jito.wtf
```
```bash
ping amsterdam.mainnet.relayer.jito.wtf
```

</details>

<details>
<summary>nftables</summary>

[nftables](https://github.com/Hohlas/solana/blob/main/nftables/README.md) 
```bash
apt update && apt install nftables -y
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables.conf > /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables
```
```bash
# удаление старого фаервола iptables
ufw disable
systemctl disable ufw
systemctl stop ufw
iptables -F # очищает все правила фильтрации в iptables
iptables -X # удаляет все пользовательские цепочки из iptables
iptables -S # разрешать входящие, исходящие и транзитные одной командой
iptables -L -n -v  # Показать текущие правила
```

</details>

---

[HOHLA.MAIN](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&refresh=1m&var-pubkey=AptafqHRpGk3KCQrGtuPGuPvWMuPc4N15X7NN7VUsfbd&var-server=HOHLA&var-inter=1m&var-netif=All&from=now-6h&to=now) | 
[hohla.test](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&var-server=hohla&var-inter=30s&var-cpu=All&var-netif=All&var-pubkey=8HzsgkGhEFP2MKuuPDy5f8qvqR6hmwPqeq7UMY3X2Z6T&refresh=5s&from=now-12h&to=now)

[HOHLA SFDP](https://solana.org/sfdp-validators/AptafqHRpGk3KCQrGtuPGuPvWMuPc4N15X7NN7VUsfbd) | 
[HOHLA stakewiz](https://stakewiz.com/validator/3FLezD8GJgnawEHhZcsjdPxZVar9FzqEdViusQ5ZdSwe)
