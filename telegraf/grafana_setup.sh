#!/bin/bash
# ulimit -n 2048000

echo -e '\n\e[42m install GPG keys \e[0m\n'
# Загрузка и добавление ключа
gpg --keyserver keyserver.ubuntu.com --recv-keys D8FF8E1F7DF8B07E
gpg --export --armor D8FF8E1F7DF8B07E | sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/D8FF8E1F7DF8B07E.gpg --import
# права пользователю _apt:
sudo chown _apt /etc/apt/trusted.gpg.d/D8FF8E1F7DF8B07E.gpg

# Загрузка и добавление ключа
curl -sL https://repos.influxdata.com/influxdb.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdb.gpg >/dev/null
# права пользователю _apt:
sudo chown _apt /etc/apt/trusted.gpg.d/influxdb.gpg


echo -e '\n\e[42m install telegraf \e[0m\n'
cd
apt install gnupg -y # gnupg2 gnupg1 -y
cat <<EOF | sudo tee /etc/apt/sources.list.d/influxdata.list
deb https://repos.influxdata.com/ubuntu focal stable
EOF

sudo apt-get update && sudo apt -y install telegraf git jq bc -y
# systemctl enable telegraf

echo -e '\n\e[42m install monitor.sh \e[0m\n'
if id "telegraf" &>/dev/null; then
    echo 'user "telegraf" already exists'
else
sudo adduser telegraf sudo
sudo adduser telegraf adm
fi
sudo -- bash -c 'echo "telegraf ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers'
sudo cp /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.orig
if [ -d ~/solanamonitoring ]; then 
echo 'telegraf already installed'
else
cd ~/ 
git clone https://github.com/stakeconomy/solanamonitoring/  
chmod +x ~/solanamonitoring/monitor.sh
fi
if [ ! -e /etc/default/locale ]; 
then curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/crypto/locale > /etc/default/locale; 
echo "Download locale file to /etc/default"; 
fi # файл locale иногда отсутствует, из-за этого появляется ошибка


curl https://raw.githubusercontent.com/Hohlas/solana/main/telegraf/telegraf.conf > /etc/telegraf/telegraf.conf
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegraf/monitor.sh > $HOME/solanamonitoring/monitor.sh

tmp="\"$NAME\""
sed -i "/^  hostname = /c\  hostname = $tmp" /etc/telegraf/telegraf.conf
# sed -i "/^solanaPrice=/c\solanaPrice=555" /root/solanamonitoring/monitor.sh

