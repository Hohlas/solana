#!/bin/bash
# # #   Start Voting   # # # # # # # # # # # # # # # # # # # # #
source $HOME/.bashrc
PORT='2010'
PUB_KEY=$(solana address -k ~/solana/validator-keypair.json) 
SOL=$HOME/.local/share/solana/install/active_release/bin
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
GREY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'
SERV='root@'$(solana gossip | grep $PUB_KEY | awk '{print $1}')
VOTING_IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from root@IP

FORCE=$1
if [ -z "$FORCE" ]; then # no 'force' flag, so waiting for 'delink' status
  Delinquent=false
  until [[ $Delinquent == true ]]; do
    JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" )')
    LastVote=$(echo "$JSON" | jq -r '.lastVote')
    Delinquent=$(echo "$JSON" | jq -r '.delinquent')
    echo -ne "Looking for "$PUB_KEY". LastVote="$LastVote" \r"
    sleep 3
  done
else
	if [ "$CUR_IP" == "$VOTING_IP" ]; then # 
		echo -e "$RED  node voiting on current server  \033[0m"
		return
	fi	
	chmod 600 ~/keys/*.ssh
	eval "$(ssh-agent -s)"  # Start ssh-agent in the background
	ssh-add ~/keys/*.ssh # Add SSH private key to the ssh-agent

	SERV='root@'$(solana gossip | grep $PUB_KEY | awk '{print $1}')
	REMOTE_IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from root@IP
	# create ssh alias for remote server
	echo " 
	Host REMOTE
	HostName $REMOTE_IP
	User root
	Port $PORT
	IdentityFile /root/keys/*.ssh
	" > ~/.ssh/config

	# check SSH connection with primary node server
	command_output=$(ssh REMOTE 'echo "SSH connection succesful" > ~/check_ssh')
	command_exit_status=$?
	if [ $command_exit_status -ne  0 ]; then
		echo -e "$RED SSH connection not available  \033[0m"
		return
	fi
	scp -P $PORT -i /root/keys/*.ssh root@$REMOTE_IP:~/check_ssh ~/
	ssh REMOTE rm ~/check_ssh
	echo -e "$GREEN$(cat ~/check_ssh)\033[0m"
	rm ~/check_ssh
	
	command_output=$(ssh -o ConnectTimeout=5 REMOTE ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json 2>&1)
	command_exit_status=$?
	echo "  change validator link on REMOTE server: $command_output" 
	if [ $command_exit_status -eq 0 ]; then
		echo -e " change validator link on REMOTE server $GREEN successful \033[0m" 
		MSG=$(printf "$MSG \n%s change validator link")
  	else
   		echo -e "$RED can't change validator link on REMOTE server \033[0m"
		return
	fi
	
	command_output=$(ssh -o ConnectTimeout=5 REMOTE $SOL/solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json 2>&1)
	command_exit_status=$?
	echo "  set empty identity on REMOTE server: $command_output" 
	if [ $command_exit_status -eq 0 ]; then
		echo -e " set empty identity on REMOTE server $GREEN successful \033[0m" 
	else
		echo -e "$RED  can't restart solana on REMOTE server in NO_VOTING mode \033[0m"
		return
	fi
 
	echo "  move tower from REMOTE to LOCAL "
	timeout 5 scp -P $PORT -i /root/keys/*.ssh $SERV:/root/solana/ledger/tower-1_9-$PUB_KEY.bin /root/solana/ledger
	echo "  stop telegraf on REMOTE server"
	ssh -o ConnectTimeout=5 REMOTE systemctl stop telegraf
	# echo "  stop jito-relayer on REMOTE server"
	
fi

if [ -f ~/solana/ledger/tower-1_9-$PUB_KEY.bin ]; then  
	TOWER_STATUS=' with existing tower'; TOWER_FLAG="--require-tower"
else  
	TOWER_STATUS=' without tower';       TOWER_FLAG=""
fi
command_output=$(solana-validator -l ~/solana/ledger set-identity $TOWER_FLAG ~/solana/validator-keypair.json 2>&1)
command_exit_status=$?
echo $command_output 
if [ $command_exit_status -eq 0 ]; 
then echo -e "$GREEN set validator-keypair successful \033[0m" 
else echo -e "$RED can't set validator-keypair \033[0m"
fi

# ln -sfn ~/solana/validator-keypair.json ~/solana/validator_link.json
# update telegraf
sed -i "/^  hostname = /c\  hostname = \"$NAME\"" /etc/telegraf/telegraf.conf
systemctl start telegraf
#systemctl start jito-relayer.service
echo -e "\033[32m vote ON\033[0m"$TOWER_STATUS
