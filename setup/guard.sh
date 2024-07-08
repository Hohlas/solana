#!/bin/bash

PORT='2010' # remote server ssh port
KEYS=$HOME/keys
LEDGER=$HOME/solana/ledger
SOLANA_SERVICE="$HOME/solana/solana.service"
EMPTY_KEY=$(grep -oP '(?<=--identity\s).*' "$SOLANA_SERVICE" | tr -d '\\') # get key path from solana.service
VOTING_KEY=$(grep -oP '(?<=--authorized-voter\s).*' "$SOLANA_SERVICE" | tr -d '\\')
IDENTITY=$(solana address) 
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
version=$(solana --version | awk '{print $2}')
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
SITES=("www.google.com" "www.bing.com")
configDir="$HOME/.config/solana"
SOL_BIN="$(cat ${configDir}/install/config.yml | grep 'active_release_dir\:' | awk '{print $2}')/bin"
DISCONNECT_COUNTER=0
GREY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'
#==== tg_bot_token ====
# CHAT_ALARM=-100...684
# CHAT_INFO=-100...888
# BOT_TOKEN=507...lWU
#======================
source $KEYS/tg_bot_token # get CHAT_ALARM, CHAT_INFO, BOT_TOKEN
half1=${BOT_TOKEN%%:*}
half2=${BOT_TOKEN#*:}
BOT_TOKEN=$half1:$half2
if [[ -z $BOT_TOKEN ]]; then # if $BOT_TOKEN is empty
	echo -e "Warning! Can't read telegram bot token from $KEYS/tg_bot_token"
	return
fi

GET_VOTING_IP(){
	SERV='root@'$(solana gossip | grep $IDENTITY | awk '{print $1}')
	VOTING_IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from root@IP
	if [ "$CUR_IP" == "$VOTING_IP" ]; then
		SERV_TYPE='PRIMARY'
    else 
		SERV_TYPE='SECONDARY'
    fi
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
echo -e "IDENTITY = $GREEN$IDENTITY \033[0m";
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
	my_slot=$(solana leader-schedule -v | grep $IDENTITY | awk -v var=$RPC_SLOT '$1>=var' | head -n1 | cut -d ' ' -f3)
	slots_remaining=$((my_slot-RPC_SLOT))
	next_slot_time=$((($slots_remaining * 459) / 60000))
	if [[ $next_slot_time -lt 2 ]]; then # next_slot_time<2 
		TME_CLR=$RED
	else	
		TME_CLR=$GREEN
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
	
	# check behind
	if [[ $BEHIND -lt 1 ]]; then # if BEHIND<1 
		behind_warning=0
	else
		let behind_warning=behind_warning+1
		echo "Behind=$BEHIND $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log  # log every warning_message
		CLR=$RED
		HEALTH="behind $BEHIND"
		if [[ $behind_warning -ge 3 ]] && [[ $BEHIND -ge 3 ]]; then # 
			behind_warning=-12 # sent next message after  12*5 seconds
	 		MSG="$SERV_TYPE ${NODE}.${NAME}: Behind=$BEHIND"
			SEND_INFO
		fi
	fi
	
	echo -ne " $SERV_TYPE ${NODE}.${NAME}, next:$TME_CLR$next_slot_time\033[0mmin, $(TZ=Europe/Moscow date +"%H:%M:%S"),${CLR} $HEALTH         \r \033[0m"

 	# check guard running on remote server
 	command_output=$(scp -P $PORT -i $KEYS/*.ssh $HOME/cur_ip root@$REMOTE_IP:$HOME/remote_ip) # update file on remote server
	command_exit_status=$?
	if [ $command_exit_status -ne 0 ]; then
		MSG="$SERV_TYPE ${NODE}.${NAME}: can't connect to $REMOTE_IP"
		SEND_ALARM
		fi
 	last_modified=$(date -r "$HOME/remote_ip" +%s)
	current_time=$(date +%s)
	time_diff=$((current_time - last_modified)) #; echo "last: $time_diff seconds"
	if [ $time_diff -ge 600 ]; then
		MSG="guard inactive on ${NODE}.${NAME}, $REMOTE_IP"
		SEND_ALARM
		echo $REMOTE_IP > $HOME/remote_ip # update file for stop alarm next 600 seconds
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

PRIMARY_SERVER(){ #######################################################################
	#echo -e "\n = PRIMARY  SERVER ="
	MSG=$(printf "PRIMARY SERVER start \n%s ${NODE}.${NAME} \n%s on $CUR_IP")
	SEND_INFO
	while [[ "$CUR_IP" == "$VOTING_IP" ]]; do
		CHECK_CONNECTION
		CHECK_HEALTH
		GET_VOTING_IP
		sleep 5
	done
	echo -e "$RED VOTING IP change to $VOTING_IP \033[0m  $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S") MSK         \r"
	echo "VOTING IP change to $VOTING_IP $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S") MSK" >> ~/guard.log
	}
	
SECONDARY_SERVER(){ ##################################################################
	MSG=$(printf "SECONDARY  SERVER start \n%s ${NODE}.${NAME} \n%s on $CUR_IP")
	SEND_INFO
	# waiting remote server fail and selfcheck health
	set_primary=0 # 
	until [[ $HEALTH == "ok" && $BEHIND -lt 1 && $set_primary -ge 1 ]]; do
		JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${IDENTITY}"'" )')
		LastVote=$(echo "$JSON" | jq -r '.lastVote')
		Delinquent=$(echo "$JSON" | jq -r '.delinquent')
		if [[ $Delinquent == true ]]; then
			set_primary=2
		fi
		if [[ $become_primary == "once" && next_slot_time -ge 2 ]]; then
			become_primary=''
			set_primary=2
		fi
		if [[ $become_primary == "everytime" && next_slot_time -ge 2 ]]; then
			set_primary=2
		fi	
		CHECK_HEALTH #  self check node health
		BECOME_PRIMARY
  		GET_VOTING_IP
  		if [ "$CUR_IP" == "$VOTING_IP" ]; then
    		return
       	fi
		sleep 5
	done
		# STOP SOLANA on REMOTE server
	MSG=$(printf "${NODE}.${NAME} change voting server ${VOTING_IP} ") # \n%s vote_off remote server
	command_output=$(ssh -o ConnectTimeout=5 REMOTE $SOL_BIN/solana-validator -l $LEDGER set-identity $EMPTY_KEY 2>&1)
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
	timeout 5 scp -P $PORT -i $KEYS/*.ssh $SERV:$LEDGER/tower-1_9-$IDENTITY.bin $LEDGER
	echo "  stop telegraf on REMOTE server"
	ssh -o ConnectTimeout=5 REMOTE systemctl stop telegraf
	echo "  stop jito-relayer on REMOTE server"
	# ssh -o ConnectTimeout=5 REMOTE systemctl stop jito-relayer.service

	# START SOLANA on LOCAL server
	if [ -f $LEDGER/tower-1_9-$IDENTITY.bin ]; then 
		TOWER_STATUS=' with existing tower'
		solana-validator -l $LEDGER set-identity --require-tower $VOTING_KEY;
	else
		TOWER_STATUS=' without tower'
		solana-validator -l $LEDGER set-identity $VOTING_KEY;
	fi
	# update telegraf
	sed -i "/^  hostname = /c\  hostname = \"$NAME\"" /etc/telegraf/telegraf.conf
	systemctl start telegraf
	# systemctl start jito-relayer.service
	echo -e "\033[31m vote ON\033[0m"$TOWER_STATUS
	MSG=$(printf "$MSG \n%s VOTE ON$TOWER_STATUS")
	SEND_ALARM
	# solana-validator --ledger $LEDGER monitor
	# ssh REMOTE $SOL_BIN/solana-validator --ledger $LEDGER monitor
	# ssh REMOTE $SOL_BIN/solana catchup ~/solana/validator_link.json --our-localhost
	}


GET_VOTING_IP
become_primary=$1 # read script argument
if [ "$SERV_TYPE" == "PRIMARY" ]; then # PRIMARY can't determine REMOTE_IP of SECONDARY
	if [[ $become_primary == "p" ]]; then 
		become_primary='everytime'; 
		echo -e "start guard in $RED everytime Primary mode\033[0m"
	fi
	if [ -f $HOME/remote_ip ]; then # SECONDARY should have written its IP to PRIMARY
		REMOTE_IP=$(cat $HOME/remote_ip) # echo "get REMOTE_IP of SECONDARY_SERVER from $HOME/remote_ip: $REMOTE_IP"
	else 
		REMOTE_IP=''	
	fi
	if [[ -z $REMOTE_IP ]]; then # if $REMOTE_IP empty
		echo -e "Warning! Run guard on SECONDARY server to get it's IP"
		return
	fi
else # SECONDARY
	if [[ $become_primary == "p" ]]; then 
		become_primary='once'; 
		echo -e "start guard in $RED switch to Primary mode\033[0m"
	fi
	REMOTE_IP=$VOTING_IP # it's true for SECONDARY
fi

chmod 600 $KEYS/*.ssh
eval "$(ssh-agent -s)"  # Start ssh-agent in the background
ssh-add $KEYS/*.ssh # Add SSH private key to the ssh-agent
# create ssh alias for remote server
echo " 
Host REMOTE
HostName $REMOTE_IP
User root
Port $PORT
IdentityFile $KEYS/*.ssh
" > ~/.ssh/config

# check SSH connection to remote server
remote_identity=$(ssh -o ConnectTimeout=5 REMOTE $SOL_BIN/solana address 2>&1)
command_exit_status=$?
if [ $command_exit_status -ne  0 ]; then
	echo -e "$RED SSH connection not available  \033[0m"
  	return
fi

if [ "$remote_identity" == "$IDENTITY" ]; then
	echo -e "$GREEN SSH connection succesful \033[0m"
else
    	echo -e "$RED Remote server connection Error \033[0m"
	echo "Current Identity = $IDENTITY,"
	echo "Remote Identity  = $remote_identity"
	return
fi

echo $CUR_IP > $HOME/cur_ip
echo $REMOTE_IP > $HOME/remote_ip # update file for stop alarm next 600 seconds

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
