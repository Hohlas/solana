#!/bin/bash
# # #   set MAIN/TEST settings
cd ~/sol_git; git pull;
source $HOME/.bashrc
cat ~/sol_git/$NODE/${NAME,,} >> $HOME/.bashrc
ln -sf ~/keys/*${NODE}_vote.json ~/solana/vote.json
ln -sf ~/keys/*${NODE}_validator.json ~/solana/validator-keypair.json
sed -i "/^  hostname = /c\  hostname = $NAME" /etc/telegraf/telegraf.conf
if [[ $NODE == "main" ]]; then 
solana config set --url https://api.mainnet-beta.solana.com --keypair ~/solana/validator-keypair.json
cp ~/sol_git/Jito/solana.service ~/solana/solana.service
echo -e "\033[31m set MAIN $NAME\033[0m"
elif [[ $NODE == "test" ]]; then
solana config set --url https://api.testnet.solana.com --keypair ~/solana/validator-keypair.json
cp ~/sol_git/test/solana.service ~/solana/solana.service
echo -e "\033[34m set test $NAME\033[0m"
else
echo -e "\033[31m Warning, unknown node type: $NODE \033[0m"
fi
systemctl daemon-reload
~/sol_git/setup/vote_off.sh
~/sol_git/setup/check.sh
