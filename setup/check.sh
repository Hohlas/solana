#!/bin/bash
# # #   check address   # # # # # # # # # # # # # # # # # # # # #
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
version=$(solana --version | awk '{print $2}')
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
empty=$(solana address -k ~/solana/empty-validator.json)
link=$(solana address -k ~/solana/validator_link.json)
validator=$(timeout 3 stdbuf -oL solana-validator --ledger ~/solana/ledger monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}')
PUB_KEY=$(solana address -k ~/solana/validator-keypair.json) # validator from keyfile 'validator-keypair.json'
vote=$(solana address -k ~/solana/vote.json)

if [ $rpcURL = https://api.testnet.solana.com ]; then 
echo -e "\033[34m "$NODE'.'$NAME" \033[0m";
echo -e "\033[34m network=api.testnet \033[0m";
elif [ $rpcURL = https://api.mainnet-beta.solana.com ]; then 
echo -e "\033[31m "$NODE'.'$NAME" \033[0m";
echo -e "\033[31m network=api.mainnet-beta \033[0m";
fi	
echo "v$version - $client"

if [[ $validator == $empty ]]; then 
echo ' tower to '`whoami`'@'$(wget -q -4 -O- http://icanhazip.com)'  # run it on another server'
VAL_CLR="\033[90m" # set gray color
elif [[ $validator == $PUB_KEY ]]; then 
echo ' tower from '`whoami`'@'$(wget -q -4 -O- http://icanhazip.com)'  # run it on another server'
VAL_CLR="\033[32m" # set green color
else
echo -e "\033[31m validator="$validator", unknown status \033[0m";
fi
if   [[ $link == $empty ]];   then LNK_CLR="\033[90m" # set gray color
else [[ $link == $PUB_KEY ]];      LNK_CLR="\033[32m" # set green color
fi

echo '--'
echo ' vote account:      '$vote
echo -e " epmty_keypair:     \033[90m"$empty"\033[0m"   # gray color
echo -e " validator-keypair: \033[32m"$PUB_KEY"\033[0m" # green color
echo -e " validator_link:    ${LNK_CLR}"$link"\033[0m"
echo -e " current validator: ${VAL_CLR}"$validator"\033[0m"
echo '--'
DELINQUEENT=$(solana validators --url $rpcURL --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" ) | .delinquent ')
if   [[ $DELINQUEENT == true ]];  then echo -e "\033[31m DELINK\033[0m";
elif [[ $DELINQUEENT == false ]]; then echo -e "\033[32m VOTING\033[0m"; 
else     echo -e "\033[31m unknown voting status $DELINQUEENT\033[0m";
fi
