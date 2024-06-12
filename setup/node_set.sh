#!/bin/bash
echo -e '\n\e[42m Node Set \e[0m\n'
# update from git
#if [ -d ~/sol_git ]; then 
#cd ~/sol_git; 
#git fetch origin; # get last updates from git
#git reset --hard origin/main # сбросить локальную ветку до последнего коммита из git
#else 
#cd; git clone https://github.com/Hohlas/solana.git ~/sol_git
#fi
chmod +x ~/sol_git/setup/*.sh
chmod +x ~/sol_git/main/*
chmod +x ~/sol_git/test/*
source ~/sol_git/${NODE}/${NAME,,}

# update .bashrc, key links, grafana name
ln -sf ~/keys/validator.json ~/solana/validator-keypair.json
ln -sf ~/keys/${NAME,,}_private.pem ~/solana/private.pem
ln -sf ~/keys/${NAME,,}_public.pem ~/solana/public.pem
ln -sf ~/keys/${NAME,,}_relayer-keypair.json ~/solana/relayer-keypair.json
echo '# --- #' >> $HOME/.bashrc
echo 'export TAG='$TAG >> $HOME/.bashrc
echo 'export NODE='$NODE >> $HOME/.bashrc
echo 'export NAME='$NAME >> $HOME/.bashrc
echo 'export validator_key='$validator_key >> $HOME/.bashrc
echo 'export vote_account='$vote_account >> $HOME/.bashrc
~/sol_git/setup/vote_off.sh

echo -n "Enter Identity key: "
read -s private_key
export private_key=$private_key

# update services and network url
if [[ $NODE == "main" ]]; then
solana config set --url https://api.mainnet-beta.solana.com --keypair ~/solana/validator-keypair.json
cp ~/sol_git/Jito/solana.service ~/solana/solana.service
sed -i "/^--allowed-validators /c\--allowed-validators $validator_key" ~/solana/jito-relayer.service
echo -e "\033[31m set MAIN $NAME\033[0m"
elif [[ $NODE == "test" ]]; then
solana config set --url https://api.testnet.solana.com --keypair ~/solana/validator-keypair.json
cp ~/sol_git/test/solana.service ~/solana/solana.service
echo -e "\033[34m set test $NAME\033[0m"
else
echo -e "\033[31m Warning, unknown node type: $NODE \033[0m"
fi
sed -i '/^--vote-account /c\--vote-account '"${vote_account}"' \\' /root/solana/solana.service # set vote addr
systemctl daemon-reload
source ~/sol_git/setup/check.sh
