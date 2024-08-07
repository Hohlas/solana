#!/bin/bash
#===========================================
CHECK_VER=v1.3.5
LEDGER=$HOME/solana/ledger
SOLANA_SERVICE="$HOME/solana/solana.service"
#===========================================
EMPTY_KEY=$(grep -oP '(?<=--identity\s).*' "$SOLANA_SERVICE" | tr -d '\\') # get key path from solana.service
VOTING_KEY=$(grep -oP '(?<=--authorized-voter\s).*' "$SOLANA_SERVICE" | tr -d '\\')
IDENTITY=$(solana address) 
VOTE_ACCOUNT=$(grep -oP '(?<=--vote-account\s).*' "$SOLANA_SERVICE" | tr -d '\\')
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
version=$(solana --version | awk '{print $2}')
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
VOTE_IP=$(solana gossip | grep $VOTING_KEY | awk '{print $1}')
current_validator=$(timeout 3 stdbuf -oL solana-validator --ledger "$LEDGER" monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}')
GRAY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'


if [ $rpcURL = https://api.testnet.solana.com ]; then 
	NODE="test";
elif [ $rpcURL = https://api.mainnet-beta.solana.com ]; then 
	NODE="main"; fi
echo " $NODE.$NAME $version-$client"



if [[ $current_validator == $EMPTY_KEY ]]; then VAL_CLR=$GRAY # set gray color
elif [[ $current_validator == $VOTING_KEY ]]; then VAL_CLR=$GREEN # set green color
else
echo -e "\033[31m current_validator="$current_validator"  unknown status, CUR_IP:$CUR_IP\033[0m";
fi

# next slot
current_slot=$(solana slot)
my_slot=$(solana leader-schedule -v | grep $VOTING_KEY | awk -v var=$current_slot '$1>=var' | head -n1 | cut -d ' ' -f3)
slots_remaining=$((my_slot-current_slot))
minutes_remaining=$((($slots_remaining * 459) / 60000))
score=$(solana validators --sort=credits -r -n | grep $VOTING_KEY | awk '{print $1}'); 
if [[ $minutes_remaining -lt 2 ]]; then TME_CLR=$RED
else TME_CLR=$GREEN; fi
echo -e " next:$TME_CLR$minutes_remaining\033[0mmin,  score=$score"

echo '--'
echo ' vote account:      '$VOTE_ACCOUNT
echo -e " epmty_keypair:     "$GRAY$EMPTY_KEY"\033[0m"   # gray color
echo -e " validator-keypair: "$GREEN$VOTING_KEY"\033[0m" # green color
echo -e " current validator: ${VAL_CLR}"$current_validator"\033[0m"
echo '--'

if [ "$CUR_IP" == "$VOTE_IP" ]; then STATUS=$GREEN" on current server \033[0m";
else                              STATUS=$GRAY" on "$VOTE_IP" \033[0m"; 
fi

DELINQUEENT=$(solana validators --url $rpcURL --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${VOTING_KEY}"'" ) | .delinquent ')
if   [[ $DELINQUEENT == true ]];  then echo -e "\033[31m DELINK\033[0m"$STATUS;
elif [[ $DELINQUEENT == false ]]; then echo -e "\033[32m VOTING\033[0m"$STATUS; 
else     echo -e "\033[31m unknown voting status $DELINQUEENT\033[0m";
fi
