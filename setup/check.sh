#!/bin/bash
# # #   check address   # # # # # # # # # # # # # # # # # # # # #
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
version=$(solana --version | awk '{print $2}')
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
empty=$(solana address -k ~/solana/empty-validator.json)
link=$(solana address -k ~/solana/validator_link.json)
validator=$(stdbuf -oL solana-validator --ledger ~/solana/ledger monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}') # voting validator
PUB_KEY=$(solana address -k ~/solana/validator-keypair.json) # validator from keyfile 'validator-keypair.json'
vote=$(solana address -k ~/solana/vote.json)
echo '--'
echo 'epmty_validator:   '$empty
echo 'validator_link:    '$link
echo 'current validator: '$validator' - set-identity'
echo 'validator-keypair: '$PUB_KEY' - from file'
echo 'vote account:      '$vote
echo '--'

if [ $rpcURL = https://api.testnet.solana.com ]; then 
echo -e "\033[34m "$NODE'.'$NAME" \033[0m";
echo -e "\033[34m network=api.testnet \033[0m";
elif [ $rpcURL = https://api.mainnet-beta.solana.com ]; then 
echo -e "\033[31m "$NODE'.'$NAME" \033[0m";
echo -e "\033[31m network=api.mainnet-beta \033[0m";
fi	
echo "v$version - $client"

if [[ $link == $empty ]]; then 
echo ' tower to '`whoami`'@'$(wget -q -4 -O- http://icanhazip.com)'  # run it on Primary server'	
echo -e "\033[32m validator=empty\033[0m"; 
fi
if [[ $link == $validator ]]; then 
echo ' tower from '`whoami`'@'$(wget -q -4 -O- http://icanhazip.com)'  # run it on Primary server'
echo  -e "\033[31m validator=true\033[0m"; 
fi


DELINQUEENT=$(solana validators --url $rpcURL --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" ) | .delinquent ')
if [[ -z $DELINQUEENT ]]; then
echo "unknown voting status"
elif [[ $DELINQUEENT == true ]]; then 
echo -e "\033[32m vote OFF\033[0m";
else
echo -e "\033[31m vote ON\033[0m"; 
fi
