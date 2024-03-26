#!/bin/bash

if [[ "$1" == *"jito"* ]]; then
  echo -e '\n\e[42m Install Jito-Solana \e[0m\n'
  sh -c "$(curl -sSfL https://release.jito.wtf/$TAG/install)"
  chmod +x ~/sol_git/Jito/jito_relayer_setup.sh
  ~/sol_git/Jito/jito_relayer_setup.sh
else
  echo -e '\n\e[42m Install Solana Testnet \e[0m\n'
  sh -c "$(curl -sSfL https://release.solana.com/$TAG/install)" 
fi
solana --version

if ! grep -q "$HOME/.local/share/solana/install/active_release/bin" ~/.bashrc; then
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    echo 'export PATH='$PATH >> ~/.bashrc
fi
