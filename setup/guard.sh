#!/bin/bash

PORT='2010'
PUB_KEY=$(solana address -k ~/solana/validator-keypair.json) 
SOL=$HOME/.local/share/solana/install/active_release/bin
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
version=$(solana --version | awk '{print $2}')
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
SITES=("www.google.com" "www.bing.com")
#SITES=("www.googererle.com" "www.bindfgdgg.com") # uncomment to check CHECK_CONNECTION()
CONNECTION_LOSS_SCRIPT="$HOME/sol_git/setup/vote_off.sh"
DISCONNECT_COUNTER=0
SERV_TYPE='Secondary'
GREY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'
#===
BOT_TOKEN="5076252443:AAF1rtoCAReYVY8QyZcdXGmuUOrNVICllWU"
CHAT_ALARM=-1001611695684
CHAT_INFO=-1001548522888


GET_VOTING_IP(){
	SERV='root@'$(solana gossip | grep $PUB_KEY | awk '{print $1}')
	VOTING_IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from root@IP
	}

SEND_INFO(){
	curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_INFO -d text="$MSG" > /dev/null
	echo "$MSG $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log
 	echo -e "$MSG \033[0m"
	}
SEND_ALARM(){
	curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_ALARM -d text="$MSG" > /dev/null
	echo "$MSG $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log
 	echo -e "$RED $MSG \033[0m"
	}


echo ' == SOLANA GUARD =='
#source ~/sol_git/setup/check.sh
GET_VOTING_IP
echo 'voting  IP='$VOTING_IP
echo 'current IP='$CUR_IP
if [ $rpcURL = https://api.testnet.solana.com ]; then 
echo -e "\033[34m "$NODE'.'$NAME" \033[0m";
echo -e "\033[34m network=api.testnet \033[0m v$version - $client";
elif [ $rpcURL = https://api.mainnet-beta.solana.com ]; then 
echo -e "\033[31m "$NODE'.'$NAME" \033[0m";
echo -e "\033[31m network=api.mainnet-beta \033[0m v$version - $client";
fi	

health_warning=0
behind_warning=0
CHECK_HEALTH() { # self check health every 5 seconds  ###########################################
 	# check behind slots
 	RPC_SLOT=$(solana slot -u $rpcURL)
	LOCAL_SLOT=$(solana slot -u localhost)
	BEHIND=$((RPC_SLOT - LOCAL_SLOT))
	my_slot=$(solana leader-schedule -v | grep $PUB_KEY | awk -v var=$RPC_SLOT '$1>=var' | head -n1 | cut -d ' ' -f3)
	slots_remaining=$((my_slot-RPC_SLOT))
	next_slot_time=$((($slots_remaining * 459) / 60000))
	if [[ $BEHIND -lt 1 ]]; then # if BEHIND<1 
		behind_warning=0
	else
		let behind_warning=behind_warning+1
		echo "Behind=$BEHIND $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log  # log every warning_message
		if [[ $behind_warning -ge 3 ]] && [[ $BEHIND -ge 3 ]]; then # 
			behind_warning=-12 # sent next message after  12*5 seconds
	 		MSG="$SERV_TYPE ${NODE}.${NAME}: Behind=$BEHIND"
			SEND_INFO
		fi
	fi
 
 	# check health
 	HEALTH=$(curl -s http://localhost:8899/health)
	if [[ -z $HEALTH ]]; then # if $HEALTH is empty (must be 'ok')
		HEALTH="Warning!"
	fi
	if [[ $HEALTH == "ok" ]]; then
		health_warning=0
		CLR=$GREEN
	else
		CLR=$RED
		let health_warning=health_warning+1
		echo "Health: $HEALTH $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log  # log every warning_message
		if [[ $health_warning -ge 1 ]]; then # 
			health_warning=-12
			MSG="$SERV_TYPE ${NODE}.${NAME}: Health: $HEALTH"
			SEND_ALARM
		fi
	fi  
	}


CHECK_CONNECTION() { # self check connection every 5 seconds ####################################
    connection=false
    for site in "${SITES[@]}"; do
        ping -c1 $site &> /dev/null # ping every site once
        if [ $? -eq 0 ]; then
            connection=true # good connection
            break
        fi
    done
    # connection losses counter
    if [ "$connection" = false ]; then
        let DISCONNECT_COUNTER=DISCONNECT_COUNTER+1
        echo "connection failed, attempt $DISCONNECT_COUNTER $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log
        echo "connection failed, attempt "$DISCONNECT_COUNTER
    else
        DISCONNECT_COUNTER=0
    fi
    # connection loss for 15 seconds (5sec * 3)
    if [ $DISCONNECT_COUNTER -ge 3 ]; then
        echo "CONNECTION LOSS"
        # bash "$CONNECTION_LOSS_SCRIPT" # no need to vote_off in offline
        echo "RESTART SOLANA $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log
        systemctl restart solana && echo -e "\033[31m restart solana \033[0m"
        systemctl stop jito-relayer.service && echo -e "\033[31m stop jito-relayer \033[0m"
		MSG="$SERV_TYPE ${NODE}.${NAME}: Restart solana"
		SEND_ALARM
		# exit
	fi
  }

RETURN_PRIMARY_TO_MASTER_SERVER(){
	if [[ -f ~/keys/master ]]; then # server has master flag file (priority server) 
		if [[ $BEHIND -lt 1 && next_slot_time -ge 2 ]]; then # BEHIND==0 && 
			Become_primary=5 # set flag to become primary server
			MSG=$(printf "become primary server \n%s ${NODE}.${NAME} \n%s on $CUR_IP")
			SEND_INFO
		fi
	fi	
}

PRIMARY_SERVER(){ #######################################################################
	#echo -e "\n = PRIMARY  SERVER ="
	MSG=$(printf "PRIMARY SERVER start \n%s ${NODE}.${NAME} \n%s on $CUR_IP")
	SEND_INFO
	SERV_TYPE='Primary'
	IP_change=0
	# CHECK_CONNECTION_LOOP 
	until [ $IP_change -ge 3 ]; do
		CHECK_CONNECTION
		CHECK_HEALTH
		GET_VOTING_IP
		if [ "$CUR_IP" != "$VOTING_IP" ]; then
			let IP_change+=1
		else
			IP_change=0
		fi	
		
		echo -ne " PRIMARY ${NODE}.${NAME}, next_slot $GREEN$next_slot_time\033[0mmin, $(TZ=Europe/Moscow date +"%H:%M:%S") MSK,${CLR} Health $HEALTH   \r \033[0m"
		sleep 5
	done
	echo -e "$RED VOTING IP change to $VOTING_IP \033[0m  $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S") MSK         \r"
	echo "VOTING IP change to $VOTING_IP $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S") MSK" >> ~/guard.log
	}
	
SECONDARY_SERVER(){ ##################################################################
	MSG=$(printf "SECONDARY  SERVER start \n%s ${NODE}.${NAME} \n%s on $CUR_IP")
	SEND_INFO
	SERV_TYPE='Secondary'
	# waiting remote server fail and selfcheck health
	Become_primary=0 # чтоб не срабатывало с первого раза
	until [[ $HEALTH == "ok" && $Become_primary -ge 3 ]]; do
		JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" )')
		LastVote=$(echo "$JSON" | jq -r '.lastVote')
		Delinquent=$(echo "$JSON" | jq -r '.delinquent')
		if [[ $Delinquent == true ]]; then
			let Become_primary=Become_primary+1
		else 
			Become_primary=0
		fi
		CHECK_HEALTH #  self check node health
		RETURN_PRIMARY_TO_MASTER_SERVER
		echo -ne " SECONDARY ${NODE}.${NAME}, next_slot $GREEN$next_slot_time\033[0mmin, $(TZ=Europe/Moscow date +"%H:%M:%S") MSK,${CLR}  Health $HEALTH     \r \033[0m"
		sleep 5
	done
	echo -e "\033[31m  REMOTE server fail at $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S") MSK          \033[0m"

	# STOP SOLANA on REMOTE server
	MSG=$(printf "${NODE}.${NAME} RESTART ${VOTING_IP} \n%s STOP REMOTE SERVER:")
	command_output=$(ssh -o ConnectTimeout=5 REMOTE ln -sf ~/solana/empty-validator.json ~/solana/validator_link.json 2>&1)
	command_exit_status=$?
	if [ $command_exit_status -eq 0 ]; then
		echo -e " change validator link on REMOTE server $GREEN successful \033[0m" 
		MSG=$(printf "$MSG \n%s change validator link")
  	else
   		echo -e "$RED can't change validator link on REMOTE server \033[0m"
     		echo $command_output
		return
	fi

	command_output=$(ssh -o ConnectTimeout=5 REMOTE $SOL/solana-validator -l ~/solana/ledger set-identity ~/solana/empty-validator.json 2>&1)
	command_exit_status=$?
	if [ $command_exit_status -eq 0 ]; then
		echo -e "\033[32m  set empty identity on REMOTE server successful \033[0m" 
		MSG=$(printf "$MSG \n%s set empty identity")
	else
  		echo $command_output
		command_output=$(ssh -o ConnectTimeout=5 REMOTE systemctl restart solana)
  		command_exit_status=$?
    		if [ $command_exit_status -eq 0 ]; then
			echo -e "$RED  restart solana on REMOTE server in NO_VOTING mode \033[0m"
      		else
			echo -e "$RED  can't restart solana on REMOTE server \033[0m"
   			echo $command_output
   			return
		fi
		MSG=$(printf "$MSG \n%s restart solana")
	fi
	echo "  move tower from REMOTE to LOCAL "
	timeout 5 scp -P $PORT -i /root/keys/*.ssh $SERV:/root/solana/ledger/tower-1_9-$PUB_KEY.bin /root/solana/ledger
	echo "  stop telegraf on REMOTE server"
	ssh -o ConnectTimeout=5 REMOTE systemctl stop telegraf
	echo "  stop jito-relayer on REMOTE server"
	# ssh -o ConnectTimeout=5 REMOTE systemctl stop jito-relayer.service

	# START SOLANA on LOCAL server
	if [ -f ~/solana/ledger/tower-1_9-$PUB_KEY.bin ]; then 
		TOWER_STATUS=' with existing tower'
		solana-validator -l ~/solana/ledger set-identity --require-tower ~/solana/validator-keypair.json;
	else
		TOWER_STATUS=' without tower'
		solana-validator -l ~/solana/ledger set-identity ~/solana/validator-keypair.json;
	fi
	# ln -sfn ~/solana/validator-keypair.json ~/solana/validator_link.json
	# update telegraf
	sed -i "/^  hostname = /c\  hostname = \"$NAME\"" /etc/telegraf/telegraf.conf
	systemctl start telegraf
	# systemctl start jito-relayer.service
	echo -e "\033[31m vote ON\033[0m"$TOWER_STATUS
	MSG=$(printf "$MSG \n%s VOTE ON$TOWER_STATUS")
	SEND_ALARM
	# solana-validator --ledger ~/solana/ledger monitor
	# ssh REMOTE $SOL/solana-validator --ledger ~/solana/ledger monitor
	#ssh REMOTE $SOL/solana catchup ~/solana/validator_link.json --our-localhost
	}


### script start - check ssh connection ###########################################
chmod 600 ~/keys/*.ssh
eval "$(ssh-agent -s)"  # Start ssh-agent in the background
ssh-add ~/keys/*.ssh # Add SSH private key to the ssh-agent

GET_VOTING_IP
if [ "$CUR_IP" == "$VOTING_IP" ]; then # PRIMARY can't determine REMOTE_IP of SECONDARY
	if [ -f ~/keys/remote_ip ]; then # SECONDARY should have written its IP to PRIMARY
		REMOTE_IP=$(cat ~/keys/remote_ip)
		echo "get REMOTE_IP of SECONDARY_SERVER from ~/keys/remote_ip: $REMOTE_IP"
	else 
		REMOTE_IP=''	
	fi
	if [[ -z $REMOTE_IP ]]; then # if $REMOTE_IP empty
		echo -e "Warning! Run guard on SECONDARY server to get it's IP"
		exit
	fi
else # 
	REMOTE_IP=$VOTING_IP # it's true for SECONDARY
	echo $CUR_IP > ~/cur_ip
	scp -P $PORT -i /root/keys/*.ssh ~/cur_ip root@$REMOTE_IP:~/keys/remote_ip
	# ssh REMOTE 'echo $CUR_IP > ~/keys/remote_ip'
	scp -P $PORT -i /root/keys/*.ssh root@$REMOTE_IP:~/keys/remote_ip ~/remote_ip_check 
	echo "send CUR_IP $(cat ~/remote_ip_check) to PRIMARY_SERVER $REMOTE_IP"
fi
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


while true  ###  main circle   #################################################
do
	GET_VOTING_IP
	if [ "$CUR_IP" == "$VOTING_IP" ]; then
		PRIMARY_SERVER
	else
		SECONDARY_SERVER
	fi	
	sleep 10
done
