#!/bin/bash
echo -e '\n\e[42m Install Solana Node \e[0m\n'
# create dirs
mkdir -p ~/solana
mkdir -p /mnt/disk1/snapshots
mkdir -p /mnt/disk1/accounts
mkdir -p /mnt/disk2/ledger
mkdir -p /mnt/disk3/accounts_index
mkdir -p /mnt/disk3/accounts_hash_cache


if [ ! -e /swapfile2 ]; then
echo -e '\n\e[42m make SWAP \e[0m\n'
sudo fallocate -l 300G /swapfile2
sudo chmod 600 /swapfile2
sudo mkswap /swapfile2
sudo swapon /swapfile2 
echo "
# add SWAP
/swapfile2 none swap sw 0 0
" | sudo tee -a /etc/fstab
else
echo -e '\n\e[42m SWAP already exist \e[0m\n'
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

echo -e '\n\e[42m Install Solana \e[0m\n'
apt install curl nano rsync cron logrotate chrony -y
if [[ $NODE == "main" ]]; then
sh -c "$(curl -sSfL https://release.jito.wtf/v$TAG-jito/install)"
~/sol_git/Jito/jito_relayer_setup.sh
else 
sh -c "$(curl -sSfL https://release.solana.com/v$TAG/install)"  
fi 
export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
solana --version

echo -e '\n\e[42m edit bashrc file \e[0m\n'
if ! grep -q "$HOME/.local/share/solana/install/active_release/bin" ~/.bashrc; then
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    echo 'export PATH='$PATH >> ~/.bashrc
fi

# create alias #
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
echo 'alias node_set=~/sol_git/setup/node_set.sh' >> $HOME/.bashrc
echo 'alias node_reset=~/sol_git/setup/node_reset.sh' >> $HOME/.bashrc
echo 'alias snap=~/sol_git/setup/snap.sh' >> $HOME/.bashrc
echo 'alias git_clone=~/sol_git/setup/git_clone.sh' >> $HOME/.bashrc
echo "alias ssh_agent='source ~/sol_git/setup/ssh_agent.sh'" >> $HOME/.bashrc
echo 'alias guard=~/sol_git/setup/guard.sh' >> $HOME/.bashrc
echo "alias shred_keys='find /root/keys -type f -exec shred -u {} \;'" >> $HOME/.bashrc	
echo ' # --- # ' >> $HOME/.bashrc

source $HOME/.bashrc
source ~/sol_git/setup/node_set.sh

sysctl -p /etc/sysctl.d/21-solana-validator.conf
systemctl daemon-reload
systemctl restart logrotate
systemctl restart chronyd.service
source ~/sol_git/setup/grafana_setup.sh 
echo -e '\n\e[42m Solana setup complete \e[0m\n'
