#!/bin/bash
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')

cd ~/solana-snapshot-finder && python3 -m venv venv && source ./venv/bin/activate
systemctl daemon-reload

if [[ $rpcURL = https://api.mainnet-beta.solana.com ]]; then
python3 snapshot-finder.py --snapshot_path /mnt/disk2/ledger --num_of_retries 10 --measurement_time 10 --min_download_speed 40 --max_snapshot_age 500 --max_latency 500 --with_private_rpc --sort_order latency -r https://api.mainnet-beta.solana.com && \
systemctl restart solana && tail -f ~/solana/solana.log
elif [[ $rpcURL = https://api.testnet.solana.com ]]; then
python3 snapshot-finder.py --snapshot_path $HOME/solana/ledger --num_of_retries 10 --measurement_time 10 --min_download_speed 50 --max_snapshot_age 500 --with_private_rpc --sort_order latency -r https://api.testnet.solana.com && \
systemctl daemon-reload && systemctl restart solana
tail -f ~/solana/solana.log
echo -e "\033[31m Warning, unknown node type: $NODE \033[0m"
fi
