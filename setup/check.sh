#!/bin/bash
# # #   check address   # # # # # # # # # # # # # # # # # # # # #
source $HOME/.bashrc
empty=$(solana address -k ~/solana/empty-validator.json)
link=$(solana address -k ~/solana/validator_link.json)
validator=$(solana address -k ~/solana/validator-keypair.json)
vote=$(solana address -k ~/solana/vote.json)
echo '--'
echo 'epmty_validator: '$empty
echo 'validator_link: '$link
echo 'validator: '$validator
echo 'vote: '$vote
echo '--'
networkrpcURL=$(cat $HOME/.config/solana/cli/config.yml | grep json_rpc_url | grep -o '".*"' | tr -d '"')
if [ $networkrpcURL = https://api.testnet.solana.com ]; then NET="api.testnet";
elif [ $networkrpcURL = https://api.mainnet-beta.solana.com ]; then NET="api.mainnet-beta";
fi	
echo ' '$NODE'.'$NAME ' network='$NET
echo ' ~/tower.sh '`whoami`'@'$(wget -q -4 -O- http://icanhazip.com)'  # run it on Primary server'
if [[ $link == $empty ]]; then echo -e "\033[32m vote OFF\033[0m"; fi
if [[ $link == $validator ]]; then echo  -e "\033[31m vote ON\033[0m"; fi