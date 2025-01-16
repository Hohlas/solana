
## Server setup
```bash
sudo apt update && sudo apt upgrade -y && sudo apt install sysstat git ncdu ufw iptables tmux htop atop curl nano fail2ban smartmontools mc bc man rsync cron chrony logrotate rsyslog encfs jq zip unzip -y
```
[Create Partitions & SWAP](https://github.com/Hohlas/ubuntu/blob/main/set/disk.md)

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
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor # check 
```
```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor # set perfomance mode 
```
```bash
ulimit -n 1000000  # set ulimit
ulimit -n # check ulimit 
```
```bash
echo "
net.ipv4.tcp_fin_timeout = 30
net.core.netdev_max_backlog = 50000
net.core.optmem_max = 20480

net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 87380 134217728
" > /etc/sysctl.d/22-solana-turbo.conf
sysctl -p /etc/sysctl.d/22-solana-turbo.conf
```
```bash
# read current
sysctl net.ipv4.tcp_rmem 
sysctl net.ipv4.tcp_fin_timeout
sysctl net.core.netdev_max_backlog
```
</details>

<details>
<summary>SSH settings</summary>
  
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
systemctl enable fail2ban
systemctl restart fail2ban
fail2ban-client status

# config EncFS
# mkdir -p ~/.crpt ~/keys
# encfs ~/.crpt ~/keys # 
```

</details>

## Install Solana Node
```   copy validator.json, vote.json to ~/keys   ```
```bash
# MAIN #
export TAG=v2.0.15-jito
export NODE=main
export NAME=$(echo $(hostname) | tr '[:lower:]' '[:upper:]') #
```
```bash
# TEST #
export TAG=v2.0.5
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

[Jito](https://github.com/Hohlas/solana/tree/main/Jito)

[Grafana](https://github.com/Hohlas/solana/blob/main/telegraf/readme.md)


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
<summary>Project X</summary>

[projectx.run](https://projectx.run) | [validators list](https://projectx.run/validators)

```bash
# switch on ProjectX relayer
solana-validator -l $HOME/solana/ledger set-relayer-config --relayer-url http://127.0.0.1:11226 
```
```bash
# switch on Jito public relayer
solana-validator -l ~/solana/ledger set-relayer-config --relayer-url http://frankfurt.mainnet.relayer.jito.wtf:8100 
```

```bash
# neccesary software install
sudo apt update && sudo apt upgrade -y
sudo apt install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler -y
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"            # For sh/bash/zsh/ash/dash/pdksh
# source $HOME/.cargo/env
```
```bash
# Clone relayer repo and build binary
cd $HOME
git clone https://github.com/projectxsol/lite-relayer.git
cd lite-relayer
git fetch
git submodule update --init --recursive
cargo build --release --bin transaction-relayer
```
[block-engines](https://docs.projectx.run/how-to-connect/block-engines)

```bash
X_BLOCK_ENGINE=http://de.projectx.run:11227
X_BLOCK_ENGINE=http://de.block-engine.com:11227
echo $X_BLOCK_ENGINE
```
```bash
# create relayer.service
tee $HOME/relayer.service > /dev/null <<EOF
[Unit]
Description=X Transaction Relayer
Requires=network-online.target
After=network-online.target
[Service]
User=$USER
Type=simple
ExecStart=$HOME/lite-relayer/target/release/transaction-relayer \
--keypair-path $HOME/solana/relayer-keypair.json \
--signing-key-pem-path $HOME/solana/private.pem \
--verifying-key-pem-path $HOME/solana/public.pem \
--webserver-bind-addr 127.0.0.1:5050 \
--grpc-bind-ip 127.0.0.1 \
--x-block-engine-url $X_BLOCK_ENGINE
RestartSec=10
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
sudo mv $HOME/relayer.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable relayer.service
sudo systemctl restart relayer
sudo ufw allow 11228,11229/udp
journalctl -u relayer -f
```

</details>

<details>
<summary>UFW</summary>

```bash
ufw status
```
```bash
ufw reset 
ufw allow 2010 # SSH
ufw allow 8000/tcp  # RPC
ufw allow 8899/tcp  # JSON RPC over HTTP
ufw allow 8900/tcp  # JSON RPC over Websockets
ufw allow 8001/tcp  # Gossip
ufw allow 8000:8020/udp
# relayer
ufw allow 10000:10007/udp
ufw allow 11226/tcp
ufw allow 11227:11229/udp
ufw enable
```

```bash
ufw status
iptables -nvL  # проверить состояние конфигурации
nft list ruleset
tail -f ~/solana/solana.log | grep "timed out" # check logs for connection loss
```
```bash
iptables -S # разрешать входящие, исходящие и транзитные одной командой
iptables -P INPUT ACCEPT   # Разрешим все входящие,
iptables -P FORWARD ACCEPT # перенаправляющие и
iptables -P OUTPUT ACCEPT  # исходящие соединения
iptables -F            # очистить 
iptables -t nat -F     # правила 
iptables -t mangle -F  # во всех таблицах
iptables -X # Удаляем все цепочки, которые не используются
```

</details>

---

[HOHLA.MAIN](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&refresh=1m&var-pubkey=AptafqHRpGk3KCQrGtuPGuPvWMuPc4N15X7NN7VUsfbd&var-server=HOHLA&var-inter=1m&var-netif=All&from=now-6h&to=now) | 
[hohla.test](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&var-server=hohla&var-inter=30s&var-cpu=All&var-netif=All&var-pubkey=8HzsgkGhEFP2MKuuPDy5f8qvqR6hmwPqeq7UMY3X2Z6T&refresh=5s&from=now-12h&to=now)

[HOHLA SFDP](https://solana.org/sfdp-validators/AptafqHRpGk3KCQrGtuPGuPvWMuPc4N15X7NN7VUsfbd) | 
[HOHLA stakewiz](https://stakewiz.com/validator/3FLezD8GJgnawEHhZcsjdPxZVar9FzqEdViusQ5ZdSwe)
