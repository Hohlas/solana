#!/bin/bash
# # #   set MAIN/TEST settings
cd ~/sol_git; git pull;
source $HOME/.bashrc
cat ~/sol_git/$NODE/${NAME,,} >> $HOME/.bashrc
if [[ $NODE == "main" ]]; then 
solana config set --url https://api.mainnet-beta.solana.com --keypair ~/solana/validator-keypair.json
cp ~/sol_git/Jito/solana.service ~/solana/solana.service
~/sol_git/setup/vote_off.sh
echo -e "\033[31m set MAIN $NAME\033[0m"
elif [[ $NODE == "test" ]]; then
solana config set --url https://api.testnet.solana.com --keypair ~/solana/validator-keypair.json
cp ~/sol_git/test/solana.service ~/solana/solana.service
~/sol_git/setup/vote_on.sh
echo -e "\033[34m set test $NAME\033[0m"
else
echo -e "\033[31m Warning, unknown node type: $NODE \033[0m"
fi
systemctl daemon-reload
~/sol_git/setup/check.sh
