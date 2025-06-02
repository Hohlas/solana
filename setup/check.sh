#!/bin/bash

CHECK_VER=v1.3.9
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
#===========================================
SOLANA_SERVICE="$HOME/solana/solana.service"
LEDGER=$(grep -oP '(?<=--ledger\s).*' "$SOLANA_SERVICE" | tr -d '\\\r\n' | xargs)
EMPTY_KEY=$(grep -oP '(?<=--identity\s).*' "$SOLANA_SERVICE" | tr -d '\\\r\n' | xargs)
VOTING_KEY=$(grep -oP '(?<=--authorized-voter\s).*' "$SOLANA_SERVICE" | tr -d '\\\r\n' | xargs)
VOTE_ACC_KEY=$(grep -oP '(?<=--vote-account\s).*' "$SOLANA_SERVICE" | tr -d '\\\r\n' | xargs)
if [ $rpcURL = https://api.testnet.solana.com ]; then 
	NODE="test";
elif [ $rpcURL = https://api.mainnet-beta.solana.com ]; then 
	NODE="main"; 
fi
#===========================================
version=$(solana-validator --version 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error! Can't run 'solana-validator'"
	return
else
	version=$(echo "$version" | awk -F '[ ()]' '{print $1, $2, $NF}' | sed 's/client://')
fi	
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
current_validator=$(timeout 3 stdbuf -oL solana-validator --ledger $LEDGER monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}')
#===========================================
EMPTY_ADDR=$(solana address -k $EMPTY_KEY)
VOTING_ADDR=$(solana address -k $VOTING_KEY)
VOTE_ACC_ADDR=$(solana address -k $VOTE_ACC_KEY)
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
VOTE_IP=$(solana gossip | grep $VOTING_ADDR | awk '{print $1}')
GRAY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CLEAR=$'\033[0m'
#===========================================
if [[ $current_validator == $EMPTY_ADDR ]]; then VAL_CLR=$GRAY # set gray color
elif [[ $current_validator == $VOTING_ADDR ]]; then VAL_CLR=$GREEN # set green color
else
echo -e "\033[31m current_validator="$current_validator"  unknown status, CUR_IP:$CUR_IP\033[0m";
fi

# next slot
current_slot=$(solana slot)
my_slot=$(solana leader-schedule -v | grep $VOTING_ADDR | awk -v var=$current_slot '$1>=var' | head -n1 | cut -d ' ' -f3)
slots_remaining=$((my_slot-current_slot))
minutes_remaining=$((($slots_remaining * 459) / 60000))
TVC=$(solana validators --sort=credits -r -n | grep $VOTING_ADDR | awk '{print $1}'); 
if [[ $minutes_remaining -lt 2 ]]; then TME_CLR=$RED
else TME_CLR=$GREEN; fi
echo " == SOLANA CHECK $CHECK_VER"
echo -e " $BLUE$NODE.$NAME $YELLOW$version $client $CLEAR"
echo -e " next:$TME_CLR$minutes_remaining\033[0mmin,  TVC=$BLUE$TVC $CLEAR"
echo " voting  IP=$VOTE_IP"
echo " current IP=$CUR_IP"
echo '--'
echo -e " vote account:      $VOTE_ACC_ADDR"
echo -e " epmty_keypair:     $GRAY$EMPTY_ADDR \033[0m"   
echo -e " validator-keypair: $GREEN$VOTING_ADDR \033[0m"
echo -e " current validator: $VAL_CLR$current_validator \033[0m"
echo '--'

if [ "$CUR_IP" == "$VOTE_IP" ]; then STATUS=" on current server \033[0m";
else                              STATUS=$GRAY" on "$VOTE_IP" \033[0m"; 
fi

DELINQUEENT=$(solana validators --url $rpcURL --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${VOTING_ADDR}"'" ) | .delinquent ')
if   [[ $DELINQUEENT == true ]];  then echo -e "\033[31m DELINK\033[0m"$STATUS;
elif [[ $DELINQUEENT == false ]]; then echo -e "\033[32m VOTING\033[0m"$STATUS; 
else     echo -e "\033[31m unknown voting status $DELINQUEENT\033[0m";
fi
