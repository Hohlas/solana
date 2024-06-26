#!/bin/bash
# # #   check address   # # # # # # # # # # # # # # # # # # # # #
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
version=$(solana --version | awk '{print $2}')
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
empty=$(solana address -k ~/solana/empty-validator.json)
link=$(solana address -k ~/solana/validator_link.json)
current_validator=$(timeout 3 stdbuf -oL solana-validator --ledger ~/solana/ledger monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}')
PUB_KEY=$(solana address -k ~/solana/validator-keypair.json) # validator from keyfile 'validator-keypair.json'
vote=$(solana address -k ~/solana/vote.json)
GRAY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
VOTE_IP=$(solana gossip | grep $PUB_KEY | awk '{print $1}')

if [ $rpcURL = https://api.testnet.solana.com ]; then 
echo -e "\033[34m "$NODE'.'$NAME" \033[0m";
echo -e "\033[34m network=api.testnet \033[0m v$version - $client";
elif [ $rpcURL = https://api.mainnet-beta.solana.com ]; then 
echo -e "\033[31m "$NODE'.'$NAME" \033[0m";
echo -e "\033[31m network=api.mainnet-beta \033[0m v$version - $client";
fi	
# echo "v$version - $client, IP:$CUR_IP"

if [[ $current_validator == $empty ]]; then 
echo -e ' tower to '`whoami`'@'$CUR_IP"$GRAY  # run it on another server\033[0m"
VAL_CLR=$GRAY # set gray color
elif [[ $current_validator == $PUB_KEY ]]; then 
echo -e ' tower from '`whoami`'@'$CUR_IP"$GRAY  # run it on another server\033[0m"
VAL_CLR=$GREEN # set green color
else
echo -e "\033[31m current_validator="$current_validator"  unknown status, CUR_IP:$CUR_IP\033[0m";
fi
if   [[ $link == $empty ]];   then LNK_CLR=$GRAY   # set gray color
else [[ $link == $PUB_KEY ]];      LNK_CLR=$GREEN  # set green color
fi
# next slot
current_slot=$(solana slot)
my_slot=$(solana leader-schedule -v | grep $PUB_KEY | awk -v var=$current_slot '$1>=var' | head -n1 | cut -d ' ' -f3)
slots_remaining=$((my_slot-current_slot))
minutes_remaining=$((($slots_remaining * 459) / 60000))
score=$(solana validators --sort=credits -r -n | grep $PUB_KEY | awk '{print $1}'); 
if [[ $minutes_remaining -lt 2 ]]; then # minutes_remaining<2 
		TME_CLR=$RED
	else	
		TME_CLR=$GREEN
	fi
echo -e " next:$TME_CLR$minutes_remaining\033[0mmin,  score=$score"

echo '--'
echo ' vote account:      '$vote
echo -e " epmty_keypair:     "$GRAY$empty"\033[0m"   # gray color
echo -e " validator_link:    ${LNK_CLR}"$link"\033[0m"
echo -e " validator-keypair: "$GREEN$PUB_KEY"\033[0m" # green color
echo -e " current validator: ${VAL_CLR}"$current_validator"\033[0m"
echo '--'

if [ "$CUR_IP" == "$VOTE_IP" ]; then STATUS=$GREEN" on current server \033[0m";
else                              STATUS=$GRAY" on "$VOTE_IP" \033[0m"; 
fi

DELINQUEENT=$(solana validators --url $rpcURL --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" ) | .delinquent ')
if   [[ $DELINQUEENT == true ]];  then echo -e "\033[31m DELINK\033[0m"$STATUS;
elif [[ $DELINQUEENT == false ]]; then echo -e "\033[32m VOTING\033[0m"$STATUS; 
else     echo -e "\033[31m unknown voting status $DELINQUEENT\033[0m";
fi
