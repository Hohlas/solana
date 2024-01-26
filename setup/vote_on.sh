#!/bin/bash
# # #   Start Voting   # # # # # # # # # # # # # # # # # # # # #
source $HOME/.bashrc
if [ -f ~/solana/ledger/tower-1_9-$(solana-keygen pubkey ~/solana/validator-keypair.json).bin ]; 
then 
echo -e "\033[32m tower exist\033[0m";
solana-validator -l ~/solana/ledger set-identity --require-tower ~/solana/validator-keypair.json; 
else
echo -e "\033[31m without tower\033[0m";
solana-validator -l ~/solana/ledger set-identity ~/solana/validator-keypair.json;
fi
ln -sfn ~/solana/validator-keypair.json ~/solana/validator_link.json
# update telegraf
sed -i "/^  hostname = /c\  hostname = \"$NAME\"" /etc/telegraf/telegraf.conf
systemctl start telegraf
echo -e "\033[31m vote ON\033[0m"
