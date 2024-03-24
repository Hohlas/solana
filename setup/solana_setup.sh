#!/bin/bash
echo -e '\n\e[42m Run solana settings \e[0m\n'
# create dirs
mkdir -p ~/solana
mkdir -p /mnt/disk1/snapshots
mkdir -p /mnt/disk1/accounts
mkdir -p /mnt/disk2/ledger
mkdir -p /mnt/disk3/accounts_index
mkdir -p /mnt/disk3/accounts_hash_cache

# git clone
if [ -d ~/sol_git ]; then 
cd ~/sol_git; 
git fetch origin; # get last updates from git
git reset --hard origin/main # сбросить локальную ветку до последнего коммита из git
else 
cd; git clone https://github.com/Hohlas/solana.git ~/sol_git
fi
chmod +x ~/sol_git/setup/*.sh

# download settings and scripts
cp ~/sol_git/setup/21-solana-validator.conf /etc/sysctl.d/21-solana-validator.conf
cp ~/sol_git/setup/90-solana-nofiles.conf /etc/security/limits.d/90-solana-nofiles.conf
cp ~/sol_git/setup/solana.logrotate /etc/logrotate.d/solana.logrotate
cp ~/sol_git/setup/trim.sh /etc/cron.hourly/trim; chmod +x /etc/cron.hourly/trim
cp ~/sol_git/setup/chrony.conf /etc/chrony.conf 
cp ~/sol_git/Jito/jito-relayer.service ~/solana/jito-relayer.service
# create links
ln -sf ~/solana/solana.service /etc/systemd/system  # solana.service
ln -sf ~/solana/jito-relayer.service /etc/systemd/system # jito-relayer.service
ln -s /mnt/disk2/ledger ~/solana/ledger

# install solana
apt install curl nano rsync cron logrotate chrony -y
if [[ $NODE == "main" ]]; then
sh -c "$(curl -sSfL https://release.jito.wtf/v$TAG-jito/install)"
else 
sh -c "$(curl -sSfL https://release.solana.com/v$TAG/install)"  
fi 




# add PATH
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

sysctl -p /etc/sysctl.d/21-solana-validator.conf
systemctl daemon-reload
systemctl restart logrotate
systemctl restart chronyd.service
~/sol_git/setup/grafana_setup.sh 
echo -e '\n\e[42m Solana setup complete \e[0m\n'
