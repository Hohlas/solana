#!/bin/bash
# # #   Stop Voting   # # # # # # # # # # # # # # # # # # # # #
source $HOME/.bashrc
if [ ! -f ~/solana/empty-validator.json ]; then 
solana-keygen new -s --no-bip39-passphrase -o ~/solana/empty-validator.json
fi
solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json
ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json
systemctl stop telegraf
echo -e "\033[32m vote OFF\033[0m"
