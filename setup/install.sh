#!/bin/bash

if [ "$1" == "main" ]; then
  echo -e '\n\e[42m Install Jito-Solana \e[0m\n'
  sh -c "$(curl -sSfL https://release.jito.wtf/$TAG/install)"
  ~/sol_git/Jito/jito_relayer_setup.sh
elif [ "$1" == "test" ]; then
  echo -e '\n\e[42m Install Solana Testnet \e[0m\n'
  sh -c "$(curl -sSfL https://release.solana.com/$TAG/install)" 
else
    echo "Usage: $0 [test|main]"
    exit 1
fi
solana --version

if ! grep -q "$HOME/.local/share/solana/install/active_release/bin" ~/.bashrc; then
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    echo 'export PATH='$PATH >> ~/.bashrc
fi
