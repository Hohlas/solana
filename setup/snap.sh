#!/bin/bash
DIR=$1
SERV=$2
key=$(ls ~/keys/*.ssh) # any *.ssh file in ~/keys
if [[ $DIR == "to" ]]; then   # LOCAL -> REMOTE
rsync -a -e "ssh -p 2010 -i $key" --progress ~/solana/snapshots $SERV:~/solana/
# rsync -a -e "ssh -p 2010 -i $key" --progress ~/solana/ledger/*snapshot-* $SERV:~/solana/ledger/
else                          # REMOTE -> LOCAL
rsync -a -e "ssh -p 2010 -i $key" --progress $SERV:~/solana/snapshots ~/solana/
# rsync -a -e "ssh -p 2010 -i $key" --progress $SERV:~/solana/ledger/*snapshot-* ~/solana/ledger/
fi
