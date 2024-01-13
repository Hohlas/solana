mkdir -p ~/solana/snapshots
SERV=$1 #
rsync -a -e "ssh -p 2010 -i ~/keys/test.ssh" --progress --include '*snapshot*' --exclude '*' $SERV:~/solana/ledger/ ~/solana/snapshots
