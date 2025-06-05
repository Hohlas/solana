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
echo 'export validator_key='$(solana address -k ~/solana/validator-keypair.json) >> $HOME/.bashrc
echo 'export vote_account='$(solana address -k ~/solana/vote.json) >> $HOME/.bashrc

if [ ! -f ~/solana/empty-validator.json ]; then 
    echo "create empty-validator.json"
    solana-keygen new -s --no-bip39-passphrase -o ~/solana/empty-validator.json
fi

# update services and network url
if [[ $NODE == "main" ]]; then
    solana config set --url https://api.mainnet-beta.solana.com --keypair ~/solana/validator-keypair.json
    cp ~/sol_git/Jito/solana.service ~/solana/solana.service
    read -p " modify for 3 disks? (y/n)" MODIFY;
    export NAME=$(echo "$NAME" | tr '[:lower:]' '[:upper:]') # имя большими буквами
    if [[ "$MODIFY" == "y" ]]; then 
        echo -e "\033[31m modify solana.service for 3 disks \033[0m"
        awk '
        /^--ledger \/mnt\/ramdisk\/ledger/ {
          print "--ledger /root/solana/ledger \\"
          print "--accounts /mnt/disk1/accounts \\"
          print "--accounts /mnt/disk2/accounts \\"
          print "--accounts-index-path /mnt/ramdisk/accounts_index \\"
          next
        }
        {print}
        ' ~/solana/solana.service > ~/solana/solana.service.tmp && mv ~/solana/solana.service.tmp ~/solana/solana.service   
    fi
elif [[ $NODE == "test" ]]; then
    solana config set --url https://api.testnet.solana.com --keypair ~/solana/validator-keypair.json
    cp ~/sol_git/test/solana.service ~/solana/solana.service
    export NAME=$(echo "$NAME" | tr '[:upper:]' '[:lower:]') # имя малыми буквами
else
    echo -e "\033[31m Warning, unknown node type: $NODE \033[0m"
    exit
fi
echo 'export NAME='$NAME >> $HOME/.bashrc
# Chande telegraf NAME
source ~/.bashrc
tmp="\"$NAME\""
sed -i "/^  hostname = /c\  hostname = $tmp" /etc/telegraf/telegraf.conf

#guardcfg_name=$(echo "$NAME" | tr '[:upper:]' '[:lower:]') # имя малыми буквами
#curl -H "Authorization: token $PAT" https://raw.githubusercontent.com/Hohlas/private/main/solana/guard/$guardcfg_name.cfg > $HOME/guard.cfg
#echo -e "\n\e[42m download guard.cfg   \e[0m\n"

systemctl daemon-reload
~/sol_git/setup/check.sh
