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
echo "alias check='source ~/check.sh'" >> $HOME/.bashrc
echo 'alias tower=~/tower.sh' >> $HOME/.bashrc
echo 'alias vote_on=~/vote_on.sh' >> $HOME/.bashrc
echo 'alias vote_off=~/vote_off.sh' >> $HOME/.bashrc
echo "alias catch='solana catchup ~/solana/validator_link.json --our-localhost --follow --log'" >> $HOME/.bashrc
echo "alias monitor='solana-validator --ledger ~/solana/ledger monitor'" >> $HOME/.bashrc
echo 'alias next=~/next.sh' >> $HOME/.bashrc
echo "alias node_set='source ~/node_set.sh'" >> $HOME/.bashrc
echo ' # --- # ' >> $HOME/.bashrc

# add PATH
if ! echo $PATH | grep -q "$HOME/.local/share/solana/install/active_release/bin"; then
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH='$PATH >> ~/.bashrc
fi
export GIT='curl https://raw.githubusercontent.com/Hohlas/solana/main'
echo 'export GIT="'$GIT'"' >> $HOME/.bashrc
source $HOME/.bashrc
# download settings and scripts
echo -e '\n\e[42m Download scripts \e[0m\n'
$GIT/setup/21-solana-validator.conf > /etc/sysctl.d/21-solana-validator.conf
$GIT/setup/90-solana-nofiles.conf > /etc/security/limits.d/90-solana-nofiles.conf
$GIT/setup/solana.logrotate > /etc/logrotate.d/solana.logrotate
$GIT/setup/grafana_sutup.sh > ~/grafana_setup.sh
$GIT/setup/check.sh > ~/check.sh
$GIT/setup/tower.sh > ~/tower.sh
$GIT/setup/vote_on.sh > ~/vote_on.sh
$GIT/setup/vote_off.sh > ~/vote_off.sh
$GIT/setup/next.sh > ~/next.sh
$GIT/setup/node_set.sh > ~/node_set.sh
chmod +x ~/grafana_sutup.sh ~/grafana_update.sh ~/check.sh ~/tower.sh ~/vote_on.sh ~/vote_off.sh ~/next.sh ~/node_set.sh
sudo sysctl -p /etc/sysctl.d/21-solana-validator.conf
sudo systemctl daemon-reload
sudo systemctl restart logrotate
~/grafana_sutup.sh 
echo -e '\n\e[42m Solana setup complete \e[0m\n'
# # #
