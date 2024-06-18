#!/bin/bash
# # #   Start Voting   # # # # # # # # # # # # # # # # # # # # #
source $HOME/.bashrc
PORT='2010'
PUB_KEY=$(solana address -k ~/solana/validator-keypair.json) 
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
GREY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'

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
		exit
	fi
	scp -P $PORT -i /root/keys/*.ssh root@$REMOTE_IP:~/check_ssh ~/
	ssh REMOTE rm ~/check_ssh
	echo -e "\033[32m$(cat ~/check_ssh)\033[0m"
	rm ~/check_ssh

	echo "${NODE}.${NAME} RESTART ${VOTING_IP} \n%s STOP REMOTE SERVER:"
	
	command_output=$(ssh -o ConnectTimeout=5 REMOTE ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json 2>&1)
	command_exit_status=$?
	echo "  try to change validator link on REMOTE server: $command_output" 
	if [ $command_exit_status -eq 0 ]; then
		echo -e "\033[32m  change validator link on REMOTE server successful \033[0m" 
		MSG=$(printf "$MSG \n%s change validator link")
	fi
	
	command_output=$(ssh -o ConnectTimeout=5 REMOTE $SOL/solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json 2>&1)
	command_exit_status=$?
	echo "  try to set empty identity on REMOTE server: $command_output" 
	if [ $command_exit_status -eq 0 ]; then
		echo -e "\033[32m  set empty identity on REMOTE server successful \033[0m" 
		MSG=$(printf "$MSG \n%s set empty identity")
	else
		echo -e "\033[31m  restart solana on REMOTE server in NO_VOTING mode \033[0m"
		ssh -o ConnectTimeout=5 REMOTE systemctl restart solana
		MSG=$(printf "$MSG \n%s restart solana")
	fi
	
	echo "  move tower from REMOTE to LOCAL "
	timeout 5 scp -P $PORT -i /root/keys/*.ssh $SERV:/root/solana/ledger/tower-1_9-$PUB_KEY.bin /root/solana/ledger
	echo "  stop telegraf on REMOTE server"
	ssh -o ConnectTimeout=5 REMOTE systemctl stop telegraf
	echo "  stop jito-relayer on REMOTE server"
	
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
then echo -e "\033[32m set validator-keypair successful \033[0m" 
else echo -e "\033[31m can not set validator-keypair \033[0m"
fi

# ln -sfn ~/solana/validator-keypair.json ~/solana/validator_link.json
# update telegraf
sed -i "/^  hostname = /c\  hostname = \"$NAME\"" /etc/telegraf/telegraf.conf
systemctl start telegraf
#systemctl start jito-relayer.service
echo -e "\033[32m vote ON\033[0m"$TOWER_STATUS
