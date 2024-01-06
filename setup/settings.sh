#!/bin/bash
echo -e '\n\e[42m Run solana settings \e[0m\n'
# create dirs
mkdir -p ~/solana/ledger
mkdir -p /mnt/disk3/accounts
mkdir -p /mnt/ramdisk/accounts_hash_cache

# create no voting empty validator
if [ ! -f ~/solana/empty-validator.json ]; then 
solana-keygen new -s --no-bip39-passphrase -o ~/solana/empty-validator.json
fi

# create links
ln -sf ~/solana/solana.service /etc/systemd/system
ln -sf ~/keys/*${NODE}_vote.json ~/solana/vote.json
ln -sf ~/keys/*${NODE}_validator.json ~/solana/validator-keypair.json
ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json # NO voting mode

# create alias #
echo ' # SOLANA  ALIAS # ' >> $HOME/.bashrc
echo "alias mount_keys='encfs ~/.crpt ~/keys'" >> $HOME/.bashrc
echo "alias umount_keys='fusermount -u ~/keys'" >> $HOME/.bashrc
echo "alias check='source ~/sol_git/setup/check.sh'" >> $HOME/.bashrc
echo 'alias tower=~/sol_git/setup/tower.sh' >> $HOME/.bashrc
echo 'alias vote_on=~/sol_git/setup/vote_on.sh' >> $HOME/.bashrc
echo 'alias vote_off=~/sol_git/setup/vote_off.sh' >> $HOME/.bashrc
echo "alias logs='tail -f ~/solana/solana.log'" >> $HOME/.bashrc
echo "alias catch='solana catchup ~/solana/validator_link.json --our-localhost --follow --log'" >> $HOME/.bashrc
echo "alias monitor='solana-validator --ledger ~/solana/ledger monitor'" >> $HOME/.bashrc
echo 'alias next=~/next.sh' >> $HOME/.bashrc
echo "alias node_set='source ~/sol_git/setup/node_set.sh'" >> $HOME/.bashrc
echo ' # --- # ' >> $HOME/.bashrc

# add PATH
if ! echo $PATH | grep -q "$HOME/.local/share/solana/install/active_release/bin"; then
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH='$PATH >> ~/.bashrc
fi
source $HOME/.bashrc
# download settings and scripts
echo -e '\n\e[42m system config \e[0m\n'
~/sol_git/setup/21-solana-validator.conf > /etc/sysctl.d/21-solana-validator.conf
~/sol_git/setup/90-solana-nofiles.conf > /etc/security/limits.d/90-solana-nofiles.conf
~/sol_git/setup/solana.logrotate > /etc/logrotate.d/solana.logrotate
sysctl -p /etc/sysctl.d/21-solana-validator.conf
systemctl restart logrotate
systemctl daemon-reload
cd ~/sol_git/setup
chmod +x ./grafana_setup.sh ./check.sh ./tower.sh ./vote_on.sh ./vote_off.sh ./next.sh ./node_set.sh
./grafana_setup.sh 
echo -e '\n\e[42m Solana setup complete \e[0m\n'
