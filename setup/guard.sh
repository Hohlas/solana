#!/bin/bash

PUB_KEY=$(solana-keygen pubkey ~/solana/validator-keypair.json)
SOL=/root/.local/share/solana/install/active_release/bin
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)

echo -e "\n\n  Start monitoring $(TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S") MSK"
SERV=$1
if [ -z "$SERV" ]; then
  SERV='root@'$(solana gossip | grep $PUB_KEY | awk '{print $1}')
fi
IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from root@IP
echo 'PUB_KEY: '$PUB_KEY
echo 'remote IP='$IP
echo 'current IP='$CUR_IP
if [ "$CUR_IP" == "$IP" ]; then
  echo 'WARNING! solana voting on current server'	
  exit
fi


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
ssh REMOTE $SOL/solana --version 
if [ $? -ne 0 ]; then
  echo -e "\033[31m SSH connection error! \033[0m"
  exit 1
else 
  echo -e "\033[32m SSH connection succesful \033[0m"
fi

ssh REMOTE echo "start monitoring $(TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S") MSK"

# waiting remote server fail
Delinquent=false
until [[ $Delinquent == true ]]; do
  JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" )')
  LastVote=$(echo "$JSON" | jq -r '.lastVote')
  Delinquent=$(echo "$JSON" | jq -r '.delinquent')
  echo -ne "Looking for $PUB_KEY. LastVote=$LastVote $(date +"%H:%M:%S") MSK \r"
  sleep 5
done

echo -e "\033[31m  REMOTE server fail $(TZ=Europe/Moscow date +"%Y-%m-%d %H:%M:%S") MSK \033[0m"

# STOP SOLANA on REMOTE server
echo "  set empty identity on REMOTE server "  
ssh REMOTE $SOL/solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json
echo "  change validator link on REMOTE server "  
ssh REMOTE ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json
echo "  stop telegraf"
ssh REMOTE systemctl stop telegraf
echo -e "\033[31m  restart solana on REMOTE server in NO_VOTING mode \033[0m"
ssh REMOTE systemctl restart solana
echo "  copy tower from REMOTE to LOCAL "
scp -P 2010 -i /root/keys/$NAME.ssh $SERV:/root/solana/ledger/tower-1_9-$PUB_KEY.bin /root/solana/ledger

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
