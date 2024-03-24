
## Server setup
```
sudo apt update && sudo apt upgrade -y && sudo apt install git ncdu ufw tmux htop curl nano fail2ban smartmontools mc man rsync cron logrotate rsyslog encfs jq -y
```
```
export NEWHOSTNAME="hohla"
```
```
sudo hostname $NEWHOSTNAME # сменить до перезагрузки
sudo hostnamectl set-hostname $NEWHOSTNAME
```

```
# config SSH
mkdir -p ~/.ssh
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/crypto/sshd_config > /etc/ssh/sshd_config
sudo ufw allow 2010  # добавить порт в правила файрвола
sudo systemctl restart ssh  # перезапустить службу ssh
chmod 600 ~/.ssh/authorized_keys

# config file2ban
echo "backend = systemd" >> /etc/fail2ban/jail.d/defaults-debian.conf
echo "authpriv.*      /var/log/auth.log" >> /etc/rsyslog.conf
systemctl restart fail2ban
fail2ban-client status

# config EncFS
encfs ~/.crpt ~/keys # 
```

## Install Solana Node
```
# MAIN #
export TAG=1.17.27
export NODE=main
export NAME=$(echo $(hostname) | tr '[:lower:]' '[:upper:]') #
```
```

curl https://raw.githubusercontent.com/Hohlas/solana/main/setup/solana_setup.sh > ~/solana_setup.sh
chmod +x ~/solana_setup.sh
~/solana_setup.sh
source $HOME/.bashrc
```
```
systemctl restart solana  # sudo systemctl restart solana
systemctl status solana
```
```
node_set # set TEST/MAIN settings
check #
next # next slot time
monitor # node monitor
catch # catchup
```
