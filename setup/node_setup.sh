#!/bin/bash
echo -e '\n\e[42m Install Solana Node \e[0m\n'
# create dirs
# mkdir -p ~/solana/ledger  # ln -sf /mnt/disk2/ledger ~/solana
mkdir -p /mnt/disk1
mkdir -p /mnt/disk2
mkdir -p /mnt/disk3
mkdir -p /mnt/ramdisk

if [ ! -d "$HOME/keys" ]; then
	echo "# keys to RAM" | sudo tee -a /etc/fstab 
	echo "tmpfs /mnt/keys tmpfs nodev,nosuid,noexec,nodiratime,size=1M 0 0" | sudo tee -a /etc/fstab
    mkdir -p /mnt/keys
    #echo "# RAMDISK" | sudo tee -a /etc/fstab 
    #echo "tmpfs /mnt/ramdisk tmpfs nodev,nosuid,noexec,nodiratime 0 0" | sudo tee -a /etc/fstab
    #mkdir -p /mnt/ramdisk
	mount -a
    ln -sf /mnt/keys "$HOME/keys" 
    echo "create RAMDISK for keys"
else
    echo "RAMDISK for keys exist"
fi

echo -e '\n\e[42m set CPU  perfomance mode \e[0m\n'
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor # set perfomance mode 

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

echo -e '\n\e[42m Set relayer \e[0m\n'
mkdir -p $HOME/lite-relayer/target/release
cp ~/sol_git/Jito/projectx_relayer.service ~/solana/relayer.service
ln -sf ~/solana/relayer.service /etc/systemd/system # projectx-relayer.service
unzip -oj $HOME/sol_git/Jito/projectx_relayer.zip -d $HOME/lite-relayer/target/release # withour compiling

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
echo "alias finder='source ~/sol_git/setup/finder.sh'" >> $HOME/.bashrc
echo "alias yabs='curl -sL yabs.sh | bash'" >> $HOME/.bashrc
echo "alias stat='source ~/stat.sh'" >> $HOME/.bashrc
echo ' # --- # ' >> $HOME/.bashrc

source $HOME/.bashrc
source ~/sol_git/setup/install.sh
source ~/sol_git/setup/get_tag.sh
source ~/sol_git/setup/node_set.sh
ln -sf ~/solana/solana.service /etc/systemd/system  # solana.service


systemctl daemon-reload
systemctl enable cpu_performance.service
systemctl start cpu_performance.service
systemctl restart logrotate
systemctl restart chronyd.service
source ~/sol_git/setup/grafana_setup.sh 
echo -e '\n\e[42m Solana setup complete \e[0m\n'
