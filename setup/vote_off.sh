#!/bin/bash
# # #   Stop Voting   # # # # # # # # # # # # # # # # # # # # #
source $HOME/.bashrc
if [ ! -f ~/solana/empty-validator.json ]; then 
solana-keygen new -s --no-bip39-passphrase -o ~/solana/empty-validator.json
fi

ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json

command_output=$(solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json 2>&1)
command_exit_status=$?
echo $command_output 
if [ $command_exit_status -eq 0 ]; then   echo -e "\033[32m set empty identity successful \033[0m" 
else                                      echo -e "\033[31m can not set empty identity \033[0m"
fi

systemctl stop telegraf
systemctl stop jito-relayer.service
echo -e "\033[31m vote OFF\033[0m"
