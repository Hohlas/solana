#!/bin/bash

if [ -z "$1" ]; then
	CUR_NODE=$NODE
else
	CUR_NODE=$1
fi

if [ "$CUR_NODE" == "main" ]; then
    REPO_URL="https://api.github.com/repos/jito-foundation/jito-solana/releases/latest"
    TAG=$(curl -sSL "$REPO_URL" | jq -r '.tag_name')
elif [ "$CUR_NODE" == "test" ]; then
    REPO_URL="https://api.github.com/repos/anza-xyz/agave/releases"
    TAG=$(curl -sSL "$REPO_URL" | jq -r '.[0].tag_name')
else
    echo "NODE variable unknown $CUR_NODE"
fi

echo " TAG=$TAG"
