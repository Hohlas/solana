
## Server setup
```bash
sudo apt update && sudo apt upgrade -y && sudo apt install sysstat git ncdu ufw iptables tmux htop atop curl nano fail2ban smartmontools mc bc man rsync cron logrotate rsyslog encfs jq zip unzip -y
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

---

## LINKS
### grafana
[HOHLA.MAIN](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&refresh=1m&var-pubkey=AptafqHRpGk3KCQrGtuPGuPvWMuPc4N15X7NN7VUsfbd&var-server=HOHLA&var-inter=1m&var-netif=All&from=now-6h&to=now) | 
[hohla.test](https://metrics.stakeconomy.com/d/f2b2HcaGz/solana-community-validator-dashboard?orgId=1&var-server=hohla&var-inter=30s&var-cpu=All&var-netif=All&var-pubkey=8HzsgkGhEFP2MKuuPDy5f8qvqR6hmwPqeq7UMY3X2Z6T&refresh=5s&from=now-12h&to=now)
### solana foundation
[HOHLA](https://solana.org/sfdp-validators/AptafqHRpGk3KCQrGtuPGuPvWMuPc4N15X7NN7VUsfbd)
### stakewiz
[HOHLA](https://stakewiz.com/validator/3FLezD8GJgnawEHhZcsjdPxZVar9FzqEdViusQ5ZdSwe)
