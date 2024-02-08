#!/bin/bash

PUB_KEY=$(solana-keygen pubkey ~/solana/validator-keypair.json)
SOL=/root/.local/share/solana/install/active_release/bin
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
SITES=("www.google.com" "www.bing.com")
SITES=("www.googererle.com" "www.bindfgdgg.com") # uncomment to check CHECK_CONNECTION()
CONNECTION_LOSS_SCRIPT="$HOME/sol_git/setup/vote_off.sh"
DISCONNECT_COUNTER=0


echo ' SOLANA GUARD'
CHECK_CONNECTION() { # every 5 seconds
    connection=false
    sleep 5
    for site in "${SITES[@]}"; do
        ping -c1 $site &> /dev/null # ping every site once
        if [ $? -eq 0 ]; then
            connection=true # good connection
            echo -ne "\033[32m check server connection $(TZ=Europe/Moscow date +"%H:%M:%S") MSK \r \033[0m"
            break
        fi
    done

    # connection losses counter
    if [ "$connection" = false ]; then
        let DISCONNECT_COUNTER=DISCONNECT_COUNTER+1
        echo "connection failed, attempt "$DISCONNECT_COUNTER
    else
        DISCONNECT_COUNTER=0
    fi

    # connection loss for 20 seconds (5sec * 4)
    if [ $DISCONNECT_COUNTER -ge 4 ]; then
        echo "CONNECTION LOSS"
        bash "$CONNECTION_LOSS_SCRIPT"
        systemctl restart solana && echo -e "\033[32m  restart solana \033[0m"
    fi
}


SERV=$1
if [ -z "$SERV" ]; then
  SERV='root@'$(solana gossip | grep $PUB_KEY | awk '{print $1}')
fi
IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from root@IP
echo 'PUB_KEY: '$PUB_KEY
echo 'voting IP='$IP
echo 'current IP='$CUR_IP
if [ "$CUR_IP" == "$IP" ]; then
  echo -e "\n\n  solana voting on current PRIMARY  SERVER "
  # CHECK_CONNECTION_LOOP 
  until [ $DISCONNECT_COUNTER -ge 4 ]; do
    CHECK_CONNECTION
  done
  exit
fi

echo -e "\n\n  SECONDARY  SERVER"
# you won’t need to enter your passphrase every time.
chmod 600 ~/keys/$NAME.ssh
eval "$(ssh-agent -s)"  # Start ssh-agent in the background
ssh-add ~/keys/$NAME.ssh # Add SSH private key to the ssh-agent

# create ssh alias for remote server
echo " 
Host REMOTE
HostName $IP
User root
Port 2010
IdentityFile /root/keys/$NAME.ssh
" > ~/.ssh/config

# check SSH connection
ssh REMOTE 'echo "SSH connection succesful" > ~/check_ssh'
scp -P 2010 -i /root/keys/$NAME.ssh $SERV:~/check_ssh ~/
ssh REMOTE rm ~/check_ssh
echo -e "\033[32m$(cat ~/check_ssh)\033[0m"
rm ~/check_ssh

echo "  Start monitoring $(TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S") MSK"

# waiting remote server fail
Delinquent=false
until [[ $Delinquent == true ]]; do
  JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" )')
  LastVote=$(echo "$JSON" | jq -r '.lastVote')
  Delinquent=$(echo "$JSON" | jq -r '.delinquent')
  echo -ne "Looking for $PUB_KEY. LastVote=$LastVote $(TZ=Europe/Moscow date +"%H:%M:%S") MSK \r"
  sleep 5
done

echo -e "\033[31m  REMOTE server fail at $(TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S") MSK \033[0m"

# STOP SOLANA on REMOTE server
echo "  change validator link on REMOTE server "  
ssh REMOTE ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json
command_output=$(ssh REMOTE $SOL/solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json 2>&1)
command_exit_status=$?
echo "  try to set empty identity on REMOTE server: $command_output" 
if [ $command_exit_status -eq 0 ]; then
   echo -e "\033[32m  set empty identity on REMOTE server successful \033[0m" 
else
  echo -e "\033[31m  restart solana on REMOTE server in NO_VOTING mode \033[0m"
  ssh REMOTE systemctl restart solana
fi
echo "  move tower from REMOTE to LOCAL "
scp -P 2010 -i /root/keys/$NAME.ssh $SERV:/root/solana/ledger/tower-1_9-$PUB_KEY.bin /root/solana/ledger
echo "  stop telegraf on REMOTE server"
ssh REMOTE systemctl stop telegraf

# START SOLANA on LOCAL server
if [ -f ~/solana/ledger/tower-1_9-$PUB_KEY.bin ]; then 
  TOWER_STATUS=' with existing tower'
  solana-validator -l ~/solana/ledger set-identity --require-tower ~/solana/validator-keypair.json; 
else
  TOWER_STATUS=' without tower'
  solana-validator -l ~/solana/ledger set-identity ~/solana/validator-keypair.json;
fi
ln -sfn ~/solana/validator-keypair.json ~/solana/validator_link.json
# update telegraf
sed -i "/^  hostname = /c\  hostname = \"$NAME\"" /etc/telegraf/telegraf.conf
systemctl start telegraf
echo -e "\033[31m vote ON\033[0m"$TOWER_STATUS

solana-validator --ledger ~/solana/ledger monitor
# ssh REMOTE $SOL/solana-validator --ledger ~/solana/ledger monitor

#ssh REMOTE $SOL/solana catchup ~/solana/validator_link.json --our-localhost
