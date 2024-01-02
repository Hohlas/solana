# # #   send tower to remote $SERV   # # #
sudo tee <<EOF >/dev/null ~/tower_out.sh
#!/bin/bash
source $HOME/.bashrc
if [ -f ~/keys/ssh.key ]; then chmod 600 ~/keys/ssh.key
else echo -e '\033[31m - WARNING !!! no file ssh.key in ~/keys - \033[0m'
fi 
solana-validator -l ~/solana/ledger wait-for-restart-window --min-idle-time 5 --skip-new-snapshot-check
scp -P 2010 -i /root/keys/ssh.key /root/solana/ledger/tower-1_9-\$(solana-keygen pubkey ~/solana/validator-keypair.json).bin root@$SERV:/root/solana/ledger
echo 'send tower to '$SERV
EOF
chmod +x ~/tower_out.sh

# # #   get tower from remote $SERV   # # #
sudo tee <<EOF >/dev/null ~/tower_in.sh
#!/bin/bash
source $HOME/.bashrc
if [ -f ~/keys/ssh.key ]; then chmod 600 ~/keys/ssh.key
else echo -e '\033[31m - WARNING !!! no file ssh.key in ~/keys - \033[0m'
fi
solana-validator -l ~/solana/ledger wait-for-restart-window --min-idle-time 5 --skip-new-snapshot-check
scp -P 2010 -i /root/keys/ssh.key $SERV:/root/solana/ledger/tower-1_9-\$(solana-keygen pubkey ~/solana/validator-keypair.json).bin /root/solana/ledger
# ~/vote_on.sh
echo 'get tower from '$SERV
EOF
chmod +x ~/tower_in.sh

# # #   Start Voting   # # #
sudo tee <<EOF >/dev/null ~/vote_on.sh
#!/bin/bash
source $HOME/.bashrc
solana-validator -l ~/solana/ledger set-identity --require-tower ~/solana/validator-keypair.json
ln -sfn ~/solana/validator-keypair.json ~/solana/validator_link.json
systemctl restart telegraf
echo 'Start Voting'
EOF
chmod +x ~/vote_on.sh

# # #   Stop Voting   # # #
sudo tee <<EOF >/dev/null ~/vote_off.sh
#!/bin/bash
source $HOME/.bashrc
if [ ! -f ~/solana/empty-validator.json ]; then 
solana-keygen new -s --no-bip39-passphrase -o ~/solana/empty-validator.json
fi
solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json
ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json
systemctl stop telegraf
echo 'No Voting mode'
EOF
chmod +x ~/vote_off.sh

# # #   check address   # # #
sudo tee <<EOF >/dev/null ~/address.sh
#!/bin/bash
source $HOME/.bashrc
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
EOF
chmod +x ~/address.sh
