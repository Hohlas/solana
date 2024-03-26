#!/bin/bash

if [ "$1" == "test" ]; then
    REPO_URL="https://api.github.com/repos/jito-foundation/jito-solana/releases/latest"
    TAG=$(curl -sSL "$REPO_URL" | jq -r '.tag_name')
elif [ "$1" == "main" ]; then
    REPO_URL="https://api.github.com/repos/solana-labs/solana/releases"
    TAG=$(curl -sSL "$REPO_URL" | jq -r '.[] | select(.name | startswith("Testnet")) | .tag_name' | head -n 1)
else
    echo "Usage: $0 [test|main]"
    exit 1
fi

echo "$TAG"
