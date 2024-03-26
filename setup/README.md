
## Server setup
```bash
sudo apt update && sudo apt upgrade -y && sudo apt install git ncdu ufw tmux htop curl nano fail2ban smartmontools mc man rsync cron logrotate rsyslog encfs jq -y
```
```bash
export NEWHOSTNAME="hohla"
```
```bash
sudo hostname $NEWHOSTNAME # сменить до перезагрузки
sudo hostnamectl set-hostname $NEWHOSTNAME
```

```bash
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
mkdir -p ~/.crpt ~/keys
encfs ~/.crpt ~/keys # 
```

## Install Solana Node
{+ copy validator.json, vote.json to ~/keys +}
```bash
# MAIN #
export TAG=v1.17.28-jito
export NODE=main
export NAME=$(echo $(hostname) | tr '[:lower:]' '[:upper:]') #
```
```bash
# TEST #
export TAG=v1.18.8
export NODE=test  # test or main
export NAME=$(echo $(hostname) | tr '[:upper:]' '[:lower:]')
```

```bash
curl https://raw.githubusercontent.com/Hohlas/solana/main/setup/solana_setup.sh > ~/node_setup.sh
chmod +x ~/node_setup.sh; ~/node_setup.sh
source $HOME/.bashrc
```
```bash
systemctl restart solana  # sudo systemctl restart solana
systemctl status solana
```
terminal commands
```bash
node_set | node_reset
check 
logs
next 
monitor | catch
guard | vote_on | vote_off
mount_keys | umount_keys | shred_keys
```
install/update commands
```bash
get_tag
solana-install init $TAG
node_install
```
