#!/bin/bash
# # #   set MAIN/TEST settings
# update from git
if [ -d ~/sol_git ]; then 
cd ~/sol_git; 
git fetch origin; # get last updates from git
git reset --hard origin/main # сбросить локальную ветку до последнего коммита из git
else git clone https://github.com/Hohlas/solana.git ~/sol_git
fi
chmod +x ~/sol_git/setup/*.sh
source $HOME/.bashrc

# update .bashrc, key links, grafana name
cat ~/sol_git/$NODE/${NAME,,} >> $HOME/.bashrc
ln -sf ~/keys/*${NODE}_vote.json ~/solana/vote.json
ln -sf ~/keys/*${NODE}_validator.json ~/solana/validator-keypair.json
tmp="\"$NAME\""
sed -i "/^  hostname = /c\  hostname = $tmp" /etc/telegraf/telegraf.conf
~/sol_git/setup/vote_off.sh

# update services and network url
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
~/sol_git/setup/check.sh
