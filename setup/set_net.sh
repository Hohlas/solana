source $HOME/.bashrc
SET_NODE=$1
SET_NAME=$2
echo 'node='$SET_NODE ' name='$SET_NAME
curl https://raw.githubusercontent.com/Hohlas/solana/main/$SET_NODE/${SET_NAME,,} >> $HOME/.bashrc
if [[ $SET_NODE == "main" ]]; then 
solana config set --url https://api.mainnet-beta.solana.com --keypair ~/solana/validator-keypair.json
$GIT/Jito/solana.service > ~/solana/solana.service
~/vote_off.sh
echo -e "\033[31m set MAIN $SET_NAME\033[0m"
elif [[ $SET_NODE == "test" ]]; then
solana config set --url https://api.testnet.solana.com --keypair ~/solana/validator-keypair.json
$GIT/test/solana.service > ~/solana/solana.service
~/vote_on.sh
echo -e "\033[34m set test $SET_NAME\033[0m"
else
echo -e "\033[31m Warning, unknown node type: $SET_NODE \033[0m"
fi
systemctl daemon-reload
~/check.sh
