#!/bin/bash

rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')

if [ $rpcURL = https://api.mainnet-beta.solana.com ]; then
	CUR_NET="MainNet"
    	REPO_URL="https://api.github.com/repos/jito-foundation/jito-solana/releases/latest"
    	TAG=$(curl -sSL "$REPO_URL" | jq -r '.tag_name')
elif [ $rpcURL = https://api.testnet.solana.com ]; then
    	CUR_NET="TestNet"
	REPO_URL="https://api.github.com/repos/anza-xyz/agave/releases"
    	TAG=$(curl -sSL "$REPO_URL" | jq -r '.[0].tag_name')
else
    	echo "NODE variable unknown $CUR_NODE"
fi

echo "$CUR_NET TAG=$TAG"
