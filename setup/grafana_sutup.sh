#!/bin/bash
ulimit -n 1000000
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D8FF8E1F7DF8B07E

echo -e '\n\e[42m install telegraf \e[0m\n'
cd
apt install gnupg -y # gnupg2 gnupg1 -y
cat <<EOF | sudo tee /etc/apt/sources.list.d/influxdata.list
deb https://repos.influxdata.com/ubuntu focal stable
EOF
sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
sudo apt-get update && sudo apt -y install telegraf git jq bc -y
sudo systemctl enable --now telegraf
sudo systemctl is-enabled telegraf

echo -e '\n\e[42m install monitor.sh \e[0m\n'
sudo adduser telegraf sudo
sudo adduser telegraf adm
sudo -- bash -c 'echo "telegraf ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers'
sudo cp /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.orig
sudo rm -rf /etc/telegraf/telegraf.conf
cd ~/ 
git clone https://github.com/stakeconomy/solanamonitoring/  
chmod +x ~/solanamonitoring/monitor.sh
if [ ! -e /etc/default/locale ]; 
then curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/crypto/locale > /etc/default/locale; 
echo "Download locale file to /etc/default"; 
fi # файл locale иногда отсутствует, из-за этого появляется ошибка

echo -e '\n\e[42m dowload telegraf.conf \e[0m\n'
curl https://raw.githubusercontent.com/Hohlas/solana/main/setup/telegraf.conf > /etc/telegraf/telegraf.conf
sudo systemctl daemon-reload 
sudo systemctl enable telegraf 
sudo systemctl restart telegraf 
