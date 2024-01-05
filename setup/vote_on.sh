#!/bin/bash
# # #   Start Voting   # # # # # # # # # # # # # # # # # # # # #
source $HOME/.bashrc
solana-validator -l ~/solana/ledger set-identity --require-tower ~/solana/validator-keypair.json
ln -sfn ~/solana/validator-keypair.json ~/solana/validator_link.json
systemctl restart telegraf
echo -e "\033[31m vote ON\033[0m"
