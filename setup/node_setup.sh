#!/bin/bash
echo -e '\n\e[42m Install Solana Node \e[0m\n'
apt install sysstat python3-venv git ncdu nftables tmux htop atop curl nano smartmontools bc man rsync cron chrony logrotate rsyslog jq zip unzip -y

# create dirs
mkdir -p ~/solana  # ln -sf /mnt/disk2/ledger ~/solana
mkdir -p /mnt/snapshots
mkdir -p /mnt/ramdisk

if [ ! -d "$HOME/keys" ]; then
	echo "# keys to RAM" | sudo tee -a /etc/fstab 
	echo "tmpfs /mnt/keys tmpfs nodev,nosuid,noexec,nodiratime,size=1M 0 0" | sudo tee -a /etc/fstab
    mkdir -p /mnt/keys
	mount -a
    ln -sf /mnt/keys "$HOME/keys" 
    echo "create RAMDISK for keys"
else
    echo "RAMDISK for keys exist"
fi

echo -e '\n\e[42m set CPU  perfomance mode \e[0m\n'
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor # set perfomance mode 
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor # check perfomance
grep 'cpu MHz' /proc/cpuinfo # MHz

echo -e '\n\e[42m change swappiness \e[0m\n'
sysctl vm.swappiness=1  # change current SWAPPINESS
echo "vm.swappiness=1" | sudo tee -a /etc/sysctl.conf # change after reboot SWAPPINESS
sysctl -f # обновить параметры из файла настроек

echo -e '\n\e[42m GIT clone \e[0m\n'
if [ -d ~/sol_git ]; then 
cd ~/sol_git; 
git fetch origin; # get last updates from git
git reset --hard origin/main # сбросить локальную ветку до последнего коммита из git
else 
cd; git clone https://github.com/Hohlas/solana.git ~/sol_git
fi
chmod +x ~/sol_git/setup/*.sh
curl https://raw.githubusercontent.com/Hohlas/ubuntu/main/test/stat.sh > ~/stat.sh; chmod +x ~/stat.sh

echo -e '\n\e[42m System tune \e[0m\n'
cp ~/sol_git/setup/cpu_performance.service /etc/systemd/system/cpu_performance.service
cp ~/sol_git/setup/21-solana-validator.conf /etc/sysctl.d/21-solana-validator.conf
cp ~/sol_git/setup/90-solana-nofiles.conf /etc/security/limits.d/90-solana-nofiles.conf
cp ~/sol_git/setup/solana.logrotate /etc/logrotate.d/solana.logrotate
cp ~/sol_git/setup/trim.sh /etc/cron.hourly/trim; chmod +x /etc/cron.hourly/trim
cp ~/sol_git/setup/chrony.conf /etc/chrony.conf 
sysctl -p /etc/sysctl.d/21-solana-validator.conf
echo "DefaultLimitNOFILE=1000000" | sudo tee -a /etc/systemd/system.conf
ulimit -n 1000000

echo -e '\n\e[42m download Jito relayer gnu \e[0m\n'
JTAG=$(curl -s https://api.github.com/repos/jito-foundation/jito-relayer/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
echo "latest jito-relayer TAG = $JTAG"
mkdir -p $HOME/jito-relayer
wget -P $HOME/jito-relayer https://github.com/jito-foundation/jito-relayer/releases/download/$JTAG/jito-transaction-relayer-x86_64-unknown-linux-gnu
chmod +x $HOME/jito-relayer/jito-transaction-relayer-x86_64-unknown-linux-gnu
$HOME/jito-relayer/jito-transaction-relayer-x86_64-unknown-linux-gnu -V
echo -e '\n\e[42m copy Jito relayer service \e[0m\n'
cp ~/sol_git/Jito/jito-relayer.service ~/solana/relayer.service
ln -sf ~/solana/relayer.service /etc/systemd/system # relayer.service

# create alias #
echo -e '\n\e[42m edit bashrc file \e[0m\n'
echo ' # SOLANA  ALIAS # ' >> $HOME/.bashrc
echo "alias mount_keys='encfs ~/.crpt ~/keys'" >> $HOME/.bashrc
echo "alias umount_keys='fusermount -u ~/keys'" >> $HOME/.bashrc
echo "alias check='source ~/sol_git/setup/check.sh'" >> $HOME/.bashrc
echo "alias tower='source ~/sol_git/setup/tower.sh'" >> $HOME/.bashrc
echo "alias vote_on='source ~/sol_git/setup/vote_on.sh'" >> $HOME/.bashrc
echo 'alias vote_off=~/sol_git/setup/vote_off.sh' >> $HOME/.bashrc
echo "alias logs='tail -f ~/solana/solana.log'" >> $HOME/.bashrc
echo "alias catch='solana catchup \$current_validator --our-localhost --follow --log'" >> $HOME/.bashrc
echo "alias monitor='solana-validator --ledger ~/solana/ledger monitor'" >> $HOME/.bashrc
echo 'alias next=~/sol_git/setup/next.sh' >> $HOME/.bashrc
echo "alias node_set='source ~/sol_git/setup/node_set.sh'" >> $HOME/.bashrc
echo 'alias node_reset=~/sol_git/setup/node_reset.sh' >> $HOME/.bashrc
echo 'alias snap=~/sol_git/setup/snap.sh' >> $HOME/.bashrc
echo 'alias git_clone=~/sol_git/setup/git_clone.sh' >> $HOME/.bashrc
echo "alias ssh_agent='source ~/sol_git/setup/ssh_agent.sh'" >> $HOME/.bashrc
echo "alias guard='source ~/sol_git/guard/guard.sh'" >> $HOME/.bashrc
echo "alias behind='source ~/sol_git/guard/behind.sh'" >> $HOME/.bashrc
echo "alias shred_keys='find /root/keys -type f -exec shred -u {} \;'" >> $HOME/.bashrc	
echo "alias get_tag='source ~/sol_git/setup/get_tag.sh'" >> $HOME/.bashrc
echo "alias node_install='source ~/sol_git/setup/install.sh'" >> $HOME/.bashrc
echo "alias node_update='source ~/sol_git/setup/update.sh'" >> $HOME/.bashrc
echo "alias finder='source ~/sol_git/setup/finder.sh'" >> $HOME/.bashrc
echo "alias yabs='curl -sL yabs.sh | bash'" >> $HOME/.bashrc
echo "alias stat='source ~/stat.sh'" >> $HOME/.bashrc
echo "alias patch='~/sol_git/setup/patch.sh'" >> $HOME/.bashrc
echo "alias mon='~/sol_git/setup/mon.sh'" >> $HOME/.bashrc
echo ' # --- # ' >> $HOME/.bashrc

echo -e '\n\e[42m install Solana \e[0m\n'
source $HOME/.bashrc
source ~/sol_git/setup/install.sh # install solana
source ~/sol_git/telegraf/grafana_setup.sh # install telegraf 
# source ~/sol_git/setup/get_tag.sh
source ~/sol_git/setup/node_set.sh
ln -sfn ~/solana/solana.service /etc/systemd/system  # solana.service

# nftables
echo -e '\n\e[42m install nftables \e[0m\n'
curl https://raw.githubusercontent.com/Hohlas/solana/main/nftables/nftables.conf > /etc/nftables.conf
systemctl enable nftables
systemctl restart nftables

systemctl daemon-reload
systemctl enable cpu_performance.service
systemctl start cpu_performance.service
systemctl restart logrotate
systemctl restart chronyd.service
chronyc makestep # time correction

# snapshot-finder
echo -e '\n\e[42m install snapshot-finder \e[0m\n'
cd
rm -rf ~/solana-snapshot-finder
git clone https://github.com/c29r3/solana-snapshot-finder.git
cd ~/solana-snapshot-finder
python3 -m venv venv
source ./venv/bin/activate
pip3 install -r requirements.txt
cd; su
echo -e '\n\e[42m Solana setup complete \e[0m\n'
