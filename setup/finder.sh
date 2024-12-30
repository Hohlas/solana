#!/bin/bash
read -p " Do You need to restart node after snapshot downloading? (y/n)" RESTART; 

LEDGER=$HOME/solana/ledger
SOLANA_SERVICE="$HOME/solana/solana.service"
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
echo -e " Node=\033[32m $NODE \033[0m"
cd ~/solana-snapshot-finder && python3 -m venv venv && source ./venv/bin/activate
systemctl daemon-reload

SNAPSHOT_PATH=$(grep -oP '(?<=--snapshots\s).*' "$SOLANA_SERVICE" | tr -d '\\')
if [[ -z "$SNAPSHOT_PATH" ]]; then
    SNAPSHOT_PATH=$LEDGER
fi    
echo -e "snapshot path =\033[32m $SNAPSHOT_PATH \033[0m "

if [[ $rpcURL = https://api.mainnet-beta.solana.com ]]; then
    echo -e " download snapshot for\033[32m MainNet \033[0m"
    python3 snapshot-finder.py --snapshot_path $SNAPSHOT_PATH --num_of_retries 10 --measurement_time 10 --min_download_speed 40 --max_snapshot_age 500 --max_latency 500 --with_private_rpc --sort_order latency -r https://api.mainnet-beta.solana.com
elif [[ $rpcURL = https://api.testnet.solana.com ]]; then
    echo -e " download snapshot for\033[32m TestNet \033[0m"
    python3 snapshot-finder.py --snapshot_path $SNAPSHOT_PATH --num_of_retries 10 --measurement_time 10 --min_download_speed 50 --max_snapshot_age 500 --with_private_rpc --sort_order latency -r https://api.testnet.solana.com
else
    echo -e "\033[31m Warning, unknown node type: $NODE \033[0m"
    return
fi
if [[ "$RESTART" == "y" ]]; then 
    systemctl restart solana && tail -f ~/solana/solana.log
fi    
        # add snapshots
