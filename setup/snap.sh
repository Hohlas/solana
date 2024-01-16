#!/bin/bash
DIR=$1
SERV=$2
if [[ $DIR == "to" ]]; then   # LOCAL -> REMOTE
rsync -a -e "ssh -p 2010 -i ~/keys/test.ssh" --progress \
~/solana/snapshots $SERV:~/solana/
else                          # REMOTE -> LOCAL
rsync -a -e "ssh -p 2010 -i ~/keys/test.ssh" --progress \
$SERV:~/solana/snapshots ~/solana/
fi

# rsync -a -e "ssh -p 2010 -i ~/keys/test.ssh" --progress ~/solana/ledger/*snapshot* $SERV:~/solana/ledger/
