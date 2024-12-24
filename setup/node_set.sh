#!/bin/bash
echo -e '\n\e[42m Node Set \e[0m\n'
~/sol_git/setup/git_clone.sh
# update .bashrc, key links, grafana name
ln -sf ~/keys/${NAME,,}_${NODE,,}_vote.json ~/solana/vote.json
ln -sf ~/keys/${NAME,,}_${NODE,,}_validator.json ~/solana/validator-keypair.json
ln -sf ~/keys/${NAME,,}_private.pem ~/solana/private.pem
ln -sf ~/keys/${NAME,,}_public.pem ~/solana/public.pem
ln -sf ~/keys/${NAME,,}_relayer-keypair.json ~/solana/relayer-keypair.json
echo '# --- #' >> $HOME/.bashrc
echo 'export TAG='$TAG >> $HOME/.bashrc
echo 'export NODE='$NODE >> $HOME/.bashrc
echo 'export NAME='$NAME >> $HOME/.bashrc
echo 'export validator_key='$(solana address -k ~/solana/validator-keypair.json) >> $HOME/.bashrc
echo 'export vote_account='$(solana address -k ~/solana/vote.json) >> $HOME/.bashrc
source $HOME/.bashrc
if [ ! -f ~/solana/empty-validator.json ]; then 
    echo "create empty-validator.json"
    solana-keygen new -s --no-bip39-passphrase -o ~/solana/empty-validator.json
fi

# update services and network url
if [[ $NODE == "main" ]]; then
    solana config set --url https://api.mainnet-beta.solana.com --keypair ~/solana/validator-keypair.json
    cp ~/sol_git/Jito/solana.service ~/solana/solana.service

    read -p "write snapshots? (y/n)" SNAPS; 
    if [[ "$SNAPS" == "y" ]]; then 
        sed -i "/^--full-snapshot-interval-slots /c --full-snapshot-interval-slots 25000 \\" ~/solana/solana.service
        sed -i "/^--incremental-snapshot-interval-slots /c --incremental-snapshot-interval-slots 2500 \\" ~/solana/solana.service
    fi
    
    sed -i "/^--allowed-validators /c\--allowed-validators $validator_key" ~/solana/jito-relayer.service
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
