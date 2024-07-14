#!/bin/bash
echo -e '\n\e[42m Install Solana Node \e[0m\n'
# create dirs
mkdir -p ~/solana
mkdir -p /mnt/disk1/accounts
mkdir -p /mnt/disk2/ledger

if [ ! -d "$HOME/keys" ]; then
    mkdir -p /mnt/keys
    ln -sf /mnt/keys "$HOME/keys"
    chmod 600 /mnt/keys 
	echo "# KEYS to RAMDISK 
	tmpfs /mnt/keys tmpfs nodev,nosuid,noexec,nodiratime,size=1M 0 0" | sudo tee -a /etc/fstab
	mount /mnt/keys
	echo "create and mount ~/keys in RAMDISK"
else
    echo "~/keys exist"
fi

SWAP_SIZE=300 # required SWAP size
MIN_DIFFERENCE=1
CURRENT_SWAP_SIZE=$(free -g | awk '/^Swap:/ {print $2}')
ADDITIONAL_SWAP=$((SWAP_SIZE - CURRENT_SWAP_SIZE))
if [ "$ADDITIONAL_SWAP" -gt "$MIN_DIFFERENCE" ]; then
    echo -e " current SWAP size\033[32m ${CURRENT_SWAP_SIZE}G \033[0m"
	echo -e " create additional SWAP\033[32m ${ADDITIONAL_SWAP}G \033[0m"
    command_output=$(fallocate -l ${ADDITIONAL_SWAP}G /swapfile2) 
	command_exit_status=$?
	if [ $command_exit_status -ne 0 ]; then
		echo -e "\033[31m can't create swapfile2 \033[0m"
	else
		chmod 600 /swapfile2
		mkswap /swapfile2
		swapon /swapfile2
		echo "/swapfile2 none swap sw 0 0" | sudo tee -a /etc/fstab
	fi
else
    echo -e " current SWAP size\033[32m $CURRENT_SWAP_SIZE\033[0m enough "
fi

echo -e '\n\e[42m change swappiness \e[0m\n'
sudo sysctl vm.swappiness=10  # change current SWAPPINESS
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf # change after reboot SWAPPINESS
sudo sysctl -f # обновить параметры из файла настроек

echo -e '\n\e[42m GIT clone \e[0m\n'
if [ -d ~/sol_git ]; then 
cd ~/sol_git; 
git fetch origin; # get last updates from git
git reset --hard origin/main # сбросить локальную ветку до последнего коммита из git
else 
cd; git clone https://github.com/Hohlas/solana.git ~/sol_git
fi
chmod +x ~/sol_git/setup/*.sh

echo -e '\n\e[42m copy files \e[0m\n'
cp ~/sol_git/setup/21-solana-validator.conf /etc/sysctl.d/21-solana-validator.conf
cp ~/sol_git/setup/90-solana-nofiles.conf /etc/security/limits.d/90-solana-nofiles.conf
cp ~/sol_git/setup/solana.logrotate /etc/logrotate.d/solana.logrotate
cp ~/sol_git/setup/trim.sh /etc/cron.hourly/trim; chmod +x /etc/cron.hourly/trim
cp ~/sol_git/setup/chrony.conf /etc/chrony.conf 
cp ~/sol_git/Jito/jito-relayer.service ~/solana/jito-relayer.service
# create links
ln -sf ~/solana/solana.service /etc/systemd/system  # solana.service
ln -sf ~/solana/jito-relayer.service /etc/systemd/system # jito-relayer.service
ln -sf /mnt/disk2/ledger ~/solana

source ~/sol_git/setup/get_tag.sh $NODE
source ~/sol_git/setup/install.sh $TAG

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
echo "alias guard='source ~/sol_git/setup/guard.sh'" >> $HOME/.bashrc
echo "alias shred_keys='find /root/keys -type f -exec shred -u {} \;'" >> $HOME/.bashrc	
echo "alias get_tag='source ~/sol_git/setup/get_tag.sh'" >> $HOME/.bashrc
echo "alias node_install='source ~/sol_git/setup/install.sh'" >> $HOME/.bashrc
echo "alias node_update='source ~/sol_git/setup/update.sh'" >> $HOME/.bashrc
echo ' # --- # ' >> $HOME/.bashrc

source $HOME/.bashrc
source ~/sol_git/setup/node_set.sh

sysctl -p /etc/sysctl.d/21-solana-validator.conf
systemctl daemon-reload
systemctl restart logrotate
systemctl restart chronyd.service
source ~/sol_git/setup/grafana_setup.sh 
echo -e '\n\e[42m Solana setup complete \e[0m\n'
