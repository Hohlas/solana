#!/bin/bash
# # #   Start Voting   # # # # # # # # # # # # # # # # # # # # #
source $HOME/.bashrc
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
PUB_KEY=$(solana-keygen pubkey ~/solana/validator-keypair.json)

Delinquent=false
until [[ $Delinquent == true ]]; do
JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" )')
LastVote=$(echo "$JSON" | jq -r '.lastVote')
Delinquent=$(echo "$JSON" | jq -r '.delinquent')
echo -ne "Looking for "$PUB_KEY". LastVote="$LastVote" \r"
sleep 3
done

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
