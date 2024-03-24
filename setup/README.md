
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
