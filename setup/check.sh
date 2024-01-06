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

if [[ $NODE == "main" ]]; then 
echo -e "\033[31m "$NODE'.'$NAME" \033[0m"; 
elif [[ $NODE == "test" ]]; then
echo -e "\033[34m "$NODE'.'$NAME" \033[0m"; 
else
echo -e "\033[31m Warning, unknown node type: $NODE \033[0m"
fi

rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
if [ $rpcURL = https://api.testnet.solana.com ]; then 
echo -e "\033[34m network=api.testnet \033[0m";
elif [ $rpcURL = https://api.mainnet-beta.solana.com ]; then 
echo -e "\033[31m network=api.mainnet-beta \033[0m";
fi	

version=$(solana --version | awk '{print $2}')
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
echo "v$version - $client"

echo ' ~/tower.sh '`whoami`'@'$(wget -q -4 -O- http://icanhazip.com)'  # run it on Primary server'
if [[ $link == $empty ]]; then echo -e "\033[32m vote OFF\033[0m"; fi
if [[ $link == $validator ]]; then echo  -e "\033[31m vote ON\033[0m"; fi
