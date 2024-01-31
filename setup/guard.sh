#!/bin/bash

PUB_KEY=$(solana-keygen pubkey ~/solana/validator-keypair.json)
SOL=/root/.local/share/solana/install/active_release/bin
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)

SERV=$1
if [ -z "$SERV" ]
then
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
echo "SSH connection error!"
exit 1
fi

# waitin remote server fail
DELINQUEENT=false
until [[ $DELINQUEENT == true ]]
do
echo -ne "waiting "$PUB_KEY" stop voting...\r"
sleep 5
DELINQUEENT=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" ) | .delinquent ')
done

# STOP SOLANA on REMOTE server
ssh REMOTE $SOL/solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json
ssh REMOTE ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json
ssh REMOTE systemctl stop telegraf
scp -P 2010 -i /root/keys/$NAME.ssh $SERV:/root/solana/ledger/tower-1_9-$PUB_KEY.bin /root/solana/ledger

# START SOLANA on LOCAL server
if [ -f ~/solana/ledger/tower-1_9-$PUB_KEY.bin ]; 
then 
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


#ssh REMOTE $SOL/solana catchup ~/solana/validator_link.json --our-localhost
