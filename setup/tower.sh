#!/bin/bash
# # #   send / get   tower   # # # # # # # # # # # #
source $HOME/.bashrc
if [ -z "$1" ]; then
    echo "warning! Input IP, like: ./tower.sh user@XXX.XX.XX.XX"
    exit 1
fi
DIR=$1  # transfer direction ('to' / 'from')
SERV=$2 # transfer server addr (root@xxx.xx.xx.xx)

# ssh connection
if [ -f ~/keys/*.ssh ]; then chmod 600 ~/keys/*.ssh
else echo -e '\033[31m - WARNING !!! no any *.ssh files in ~/keys - \033[0m'
fi 

# wait for window
solana-validator -l ~/solana/ledger wait-for-restart-window --min-idle-time 10 --skip-new-snapshot-check

# read current keys status
empty=$(solana address -k ~/solana/empty-validator.json)
link=$(solana address -k ~/solana/validator_link.json)
validator=$(solana address -k ~/solana/validator-keypair.json)

# get tower from Secondary server
if [[ $DIR == 'from' ]]; then 
echo -e "\033[31m get tower from\033[0m" $SERV; 
read -p "are you ready? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
scp -P 2010 -i /root/keys/*.ssh $SERV:/root/solana/ledger/tower-1_9-$validator.bin /root/solana/ledger
fi

# send tower to Secondary server
if [[ $DIR == 'to' ]]; then 
echo -e "\033[32m send tower to\033[0m" $SERV; 
read -p "are you ready? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
scp -P 2010 -i /root/keys/*.ssh /root/solana/ledger/tower-1_9-$validator.bin $SERV:/root/solana/ledger
fi
