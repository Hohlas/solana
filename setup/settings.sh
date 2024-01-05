
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
echo 'alias check=~/check.sh' >> $HOME/.bashrc
echo 'alias tower=~/tower.sh' >> $HOME/.bashrc
echo 'alias vote_on=~/vote_on.sh' >> $HOME/.bashrc
echo 'alias vote_off=~/vote_off.sh' >> $HOME/.bashrc
echo "alias catch='solana catchup ~/solana/validator_link.json --our-localhost --follow --log'" >> $HOME/.bashrc
echo "alias sol_monitor='solana-validator --ledger ~/solana/ledger monitor'" >> $HOME/.bashrc
echo ' # --- # ' >> $HOME/.bashrc
source $HOME/.bashrc

# add PATH
if ! echo $PATH | grep -q "$HOME/.local/share/solana/install/active_release/bin"; then
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH='$PATH >> ~/.bashrc
fi
