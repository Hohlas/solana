#!/bin/bash
# # #   set MAIN/TEST settings
curl https://raw.githubusercontent.com/Hohlas/solana/main/$NODE/${NAME,,} >> $HOME/.bashrc
if [[ $NODE == "main" ]]; then 
solana config set --url https://api.mainnet-beta.solana.com --keypair ~/solana/validator-keypair.json
$GIT/Jito/solana.service > ~/solana/solana.service
~/vote_off.sh
echo -e "\033[31m set MAIN $NAME\033[0m"
elif [[ $NODE == "test" ]]; then
solana config set --url https://api.testnet.solana.com --keypair ~/solana/validator-keypair.json
$GIT/test/solana.service > ~/solana/solana.service
~/vote_on.sh
echo -e "\033[34m set test $NAME\033[0m"
else
echo -e "\033[31m Warning, unknown node type: $NODE \033[0m"
fi
systemctl daemon-reload
~/check.sh
