sudo tee <<EOF >/dev/null ~/get_ip.sh
#!/bin/bash
# # #  get IP to \$SERV   # # # # # # # # # # # # # # # #
source \$HOME/.bashrc
if   [[ \$NODE == "main" ]]; then addr='test'; # get IP for test 
elif [[ \$NODE == "test" ]]; then addr='main'; # get IP for main 
else 
addr='none'
echo -e '\033[31m WARNING, wrong type NODE = \033[0m'\$NODE
fi
if [[ \$addr != "none" ]]; then
tmp=\$(curl https://raw.githubusercontent.com/Hohlas/solana/main/\$addr/\${NAME,,})
SERV=root@\$(echo "\$tmp" | grep -o 'IP=[^ ]*' | cut -d '=' -f2)
echo " --"
echo 'set IP from '\$addr'.'\${NAME,,} ": \$SERV"
fi
EOF
chmod +x ~/get_ip.sh

sudo tee <<EOF >/dev/null ~/tower_out.sh
#!/bin/bash
# # #   send tower to remote $SERV   # # # # # # # # # # # #
source \$HOME/.bashrc
if [ -f ~/keys/*.ssh ]; then chmod 600 ~/keys/*.ssh
else echo -e '\033[31m - WARNING !!! no any *.ssh files in ~/keys - \033[0m'
fi 
solana-validator -l ~/solana/ledger wait-for-restart-window --min-idle-time 5 --skip-new-snapshot-check
scp -P 2010 -i /root/keys/*.ssh /root/solana/ledger/tower-1_9-\$(solana-keygen pubkey ~/solana/validator-keypair.json).bin \$SERV:/root/solana/ledger
echo 'send tower to '\$SERV
EOF
chmod +x ~/tower_out.sh


sudo tee <<EOF >/dev/null ~/tower_in.sh
#!/bin/bash
# # #   get tower from remote $SERV   # # # # # # # # # # # #
source \$HOME/.bashrc
if [ -f ~/keys/*.ssh ]; then chmod 600 ~/keys/*.ssh
else echo -e '\033[31m - WARNING !!! no any *.ssh files in ~/keys - \033[0m'
fi
solana-validator -l ~/solana/ledger wait-for-restart-window --min-idle-time 5 --skip-new-snapshot-check
scp -P 2010 -i /root/keys/*.ssh \$SERV:/root/solana/ledger/tower-1_9-\$(solana-keygen pubkey ~/solana/validator-keypair.json).bin /root/solana/ledger
# ~/vote_on.sh
echo 'get tower from '\$SERV
EOF
chmod +x ~/tower_in.sh


sudo tee <<EOF >/dev/null ~/vote_on.sh
#!/bin/bash
# # #   Start Voting   # # # # # # # # # # # # # # # # # # # # #
source \$HOME/.bashrc
solana-validator -l ~/solana/ledger set-identity --require-tower ~/solana/validator-keypair.json
ln -sfn ~/solana/validator-keypair.json ~/solana/validator_link.json
systemctl restart telegraf
echo 'Start Voting'
EOF
chmod +x ~/vote_on.sh


sudo tee <<EOF >/dev/null ~/vote_off.sh
#!/bin/bash
# # #   Stop Voting   # # # # # # # # # # # # # # # # # # # # #
source \$HOME/.bashrc
if [ ! -f ~/solana/empty-validator.json ]; then 
solana-keygen new -s --no-bip39-passphrase -o ~/solana/empty-validator.json
fi
solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json
ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json
systemctl stop telegraf
echo 'No Voting mode'
EOF
chmod +x ~/vote_off.sh


sudo tee <<EOF >/dev/null ~/address.sh
#!/bin/bash
# # #   check address   # # # # # # # # # # # # # # # # # # # # #
source \$HOME/.bashrc
empty=\$(solana address -k ~/solana/empty-validator.json)
link=\$(solana address -k ~/solana/validator_link.json)
validator=\$(solana address -k ~/solana/validator-keypair.json)
vote=\$(solana address -k ~/solana/vote.json)
echo '--'
echo 'epmty_validator: '\$empty
echo 'validator_link: '\$link
echo 'validator: '\$validator
echo 'vote: '\$vote
echo '--'
if [[ \$link == \$empty ]]; then echo 'link=empty: voting OFF'; fi
if [[ \$link == \$validator ]]; then echo 'link=validator: voting ON'; fi

networkrpcURL=\$(cat \$HOME/.config/solana/cli/config.yml | grep json_rpc_url | grep -o '".*"' | tr -d '"')
if [ "\$networkrpcURL" == "" ]; then networkrpcURL=\$(cat /root/.config/solana/cli/config.yml | grep json_rpc_url | awk '{ print \$2 }')
fi
if [ \$networkrpcURL = https://api.testnet.solana.com ]; then net="api.testnet";
elif [ \$networkrpcURL = https://api.mainnet-beta.solana.com ]; then net="api.mainnet-beta";
fi	
echo 'NODE='$NODE 'network='\$net
EOF
chmod +x ~/address.sh

