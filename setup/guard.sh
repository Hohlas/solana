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

TIME() {
TZ=Europe/Moscow date +"%b %e  %H:%M:%S"
}

GET_VOTING_IP(){
	SERV='root@'$(solana gossip | grep $IDENTITY | awk '{print $1}')
	VOTING_IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from root@IP
 	local_validator=$(timeout 3 stdbuf -oL solana-validator --ledger $LEDGER monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}')
	if [[ -z $VOTING_IP ]]; then # if $VOTING_IP empty
		return
  		fi
 	# if [ "$CUR_IP" == "$VOTING_IP" ];  then
  	if [ "$local_validator" == "$IDENTITY" ]; then
  		SERV_TYPE='PRIMARY'
	else 
 		SERV_TYPE='SECONDARY'
    	fi
	}
SEND_INFO(){
	local message="$1"
	curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_INFO -d text="$message" > /dev/null
	echo "$(TIME) $message" >> ~/guard.log
 	echo -e "$(TIME) $message \033[0m"
	}
SEND_ALARM(){
	local message="$1"
	curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_ALARM -d text="$message" > /dev/null
	echo "$(TIME) $message" >> ~/guard.log
 	echo -e "$(TIME) $RED $message \033[0m"
	}


echo " == SOLANA GUARD ==" | tee -a ~/guard.log
#source ~/sol_git/setup/check.sh
GET_VOTING_IP
echo "voting  IP=$VOTING_IP" | tee -a ~/guard.log
echo "current IP=$CUR_IP" | tee -a ~/guard.log
echo -e "IDENTITY = $GREEN$IDENTITY \033[0m" | tee -a ~/guard.log
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
		echo "$(TIME) Health: $HEALTH" >> ~/guard.log  # log every warning_message
		if [[ $health_warning -ge 1 ]]; then # 
			health_warning=-12
			SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: Health: $HEALTH"
		fi
	fi  
	
	# check behind
	if [[ $BEHIND -lt 1 ]]; then # if BEHIND<1 
		behind_warning=0
	else
		let behind_warning=behind_warning+1
		echo "$(TIME) Behind=$BEHIND    " | tee -a ~/guard.log  # log every warning_message
		CLR=$RED
		HEALTH="$BEHIND"
		if [[ $behind_warning -ge 3 ]] && [[ $BEHIND -ge 3 ]]; then # 
			behind_warning=-12 # sent next message after  12*5 seconds
	 		SEND_INFO "$SERV_TYPE ${NODE}.${NAME}: Behind=$BEHIND"
		fi
	fi
	REMOTE_BEHIND=$(cat $HOME/remote_behind)
	if (( $REMOTE_BEHIND >= 1 )); then 
		REMOTE_HEALTH="$RED $REMOTE_BEHIND"; 
	else 
		REMOTE_HEALTH="$GREEN ok"; 
	fi
	echo -ne "$(TZ=Europe/Moscow date +"%H:%M:%S")  $SERV_TYPE ${NODE}.${NAME}, next:$TME_CLR$next_slot_time\033[0mmin,${CLR} $HEALTH\033[0m,$REMOTE_HEALTH\033[0m $primary_mode        \r "

 	# check guard running on remote server
 	current_time=$(date +%s)
	command_output=$(ssh -o ConnectTimeout=5 REMOTE "echo '$BEHIND' > $HOME/remote_behind" 2>&1)
	command_exit_status=$?
	if [ $command_exit_status -ne 0 ] && [ $((current_time - connection_alarm_time)) -ge 120  ]; then
		SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: can't connect to $REMOTE_IP, Error: $command_output"
		connection_alarm_time=$current_time
		fi
 	last_modified=$(date -r "$HOME/remote_behind" +%s)
	time_diff=$((current_time - last_modified)) #; echo "last: $time_diff seconds"
	if [ $time_diff -ge 300 ] && [ $((current_time - connection_alarm_time)) -ge 120  ]; then
		SEND_ALARM "guard inactive on ${NODE}.${NAME}, $REMOTE_IP"
		connection_alarm_time=$current_time
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
        echo "$(TIME) connection failed, attempt $DISCONNECT_COUNTER" | tee -a ~/guard.log
    else
        DISCONNECT_COUNTER=0
    fi
    # connection loss for 15 seconds (5sec * 3)
    if [ $DISCONNECT_COUNTER -ge 3 ]; then
        # bash "$CONNECTION_LOSS_SCRIPT" # no need to vote_off in offline
        systemctl restart solana
        systemctl stop jito-relayer.service
	SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: Connection loss, RESTART SOLANA"
	fi
  }

PRIMARY_SERVER(){ #######################################################################
	#echo -e "\n = PRIMARY  SERVER ="
	SEND_INFO "PRIMARY ${NODE}.${NAME}\n%s$CUR_IP start"
	while [[ "$CUR_IP" == "$VOTING_IP" ]]; do
		CHECK_CONNECTION
		CHECK_HEALTH
		GET_VOTING_IP
		sleep 5
	done
	echo -e "$(TIME) change VOTING: $VOTING_IP  " | tee -a ~/guard.log
	}
	
SECONDARY_SERVER(){ ##################################################################
	SEND_INFO "SECONDARY ${NODE}.${NAME}\n%s$CUR_IP start"
	# waiting remote server fail and selfcheck health
	set_primary=0 # 
	REASON=''
	until [[ $HEALTH == "ok" && $BEHIND -lt 1 && $set_primary -ge 1 ]]; do
		JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${IDENTITY}"'" )')
		LastVote=$(echo "$JSON" | jq -r '.lastVote')
		Delinquent=$(echo "$JSON" | jq -r '.delinquent')
		if [[ $Delinquent == true ]]; then
			set_primary=2; 	REASON="Delinquent";
		fi
		if [[ $behind_threshold -ge 1 ]] && [[ $REMOTE_BEHIND -ge $behind_threshold ]]; then
			set_primary=2; 	REASON="REMOTE_BEHIND>$behind_threshold";
		fi
		if [[ $primary_mode == "permanent_primary" && next_slot_time -ge 2 ]]; then
			set_primary=2; 	REASON="set Permanent Primary mode"; 
		fi	
		CHECK_HEALTH #  self check node health
  		GET_VOTING_IP
  		if [ "$SERV_TYPE" == "$PRIMARY" ]; then 
    			return; 
       		fi
		sleep 5
	done
		# STOP SOLANA on REMOTE server
	MSG=$(printf "${NODE}.${NAME} switch server to ${VOTING_IP} \n%s $REASON") # \n%s vote_off remote server
	command_output=$(ssh -o ConnectTimeout=5 REMOTE $SOL_BIN/solana-validator -l $LEDGER set-identity $EMPTY_KEY 2>&1)
	command_exit_status=$?
	if [ $command_exit_status -eq 0 ]; then
		echo -e "\033[32m  set empty identity on REMOTE server successful \033[0m" 
		MSG=$(printf "$MSG \n%s set empty identity")
	else
		SEND_ALARM "Can't set identity on remote server, Error: $command_output"
		command_output=$(ssh -o ConnectTimeout=5 REMOTE systemctl restart solana 2>&1)
  		command_exit_status=$?
    		if [ $command_exit_status -eq 0 ]; then
			echo -e "$(TIME) restart solana on REMOTE server in NO_VOTING mode" | tee -a ~/guard.log
      		else
			SEND_ALARM "Can't restart solana on REMOTE server, Error: $command_output"
			if ping -c 3 -W 3 "$REMOTE_IP" > /dev/null 2>&1; then
				return
			fi
			SEND_ALARM "Can't ping REMOTE server"
		fi
		MSG=$(printf "$MSG \n%s restart solana")
	fi
	# remove old tower before
	rm $LEDGER/tower-2_9-$IDENTITY.bin 
	if [ $command_exit_status -eq 0 ]; then echo "$(TIME) remove old tower OK" | tee -a ~/guard.log
	else echo "$(TIME) remove old tower Error: $command_exit_status" | tee -a ~/guard.log
	fi
	# copy tower from remote server
	timeout 5 scp -P $PORT -i $KEYS/*.ssh $SERV:$LEDGER/tower-1_9-$IDENTITY.bin $LEDGER
	command_exit_status=$?
	if [ $command_exit_status -eq 0 ]; then echo "$(TIME) copy tower from $SERV OK" | tee -a ~/guard.log
	elif [ $command_exit_status -eq 124 ]; then echo "$(TIME) copy tower from $SERV timeout exceed" | tee -a ~/guard.log
	else echo "$(TIME) copy tower from $SERV Error: $command_exit_status" | tee -a ~/guard.log
	fi
	# stop telegraf service on remote server
	ssh -o ConnectTimeout=5 REMOTE systemctl stop telegraf
	command_exit_status=$?
	if [ $command_exit_status -eq 0 ]; then echo "$(TIME) stop telegraf on remote server OK" | tee -a ~/guard.log
	elif [ $command_exit_status -eq 124 ]; then echo "$(TIME) stop telegraf on remote server timeout exceed" | tee -a ~/guard.log
 	else echo "$(TIME) stop telegraf on remote server Error: $command_exit_status" | tee -a ~/guard.log
	fi
 	# echo "  stop jito-relayer on REMOTE server"
	# ssh -o ConnectTimeout=5 REMOTE systemctl stop jito-relayer.service

	# START SOLANA on LOCAL server
	if [ -f $LEDGER/tower-1_9-$IDENTITY.bin ]; then 
		TOWER_STATUS=' with tower'; 	solana-validator -l $LEDGER set-identity --require-tower $VOTING_KEY;
	else
		TOWER_STATUS=' without tower'; 	solana-validator -l $LEDGER set-identity $VOTING_KEY;
	fi
	command_exit_status=$?
	if [ $command_exit_status -eq 0 ]; then echo "$(TIME) set identity$TOWER_STATUS OK" | tee -a ~/guard.log
	else echo "$(TIME) set identity Error: $command_exit_status" | tee -a ~/guard.log
	fi
	# update telegraf
	# sed -i "/^  hostname = /c\  hostname = \"$NAME\"" /etc/telegraf/telegraf.conf
	systemctl start telegraf
	# systemctl start jito-relayer.service
	# MSG=$(printf "$MSG \n%s VOTE ON$TOWER_STATUS")
	SEND_ALARM "$(printf "$MSG \n%s VOTE ON$TOWER_STATUS")"
	# solana-validator --ledger $LEDGER monitor
	# ssh REMOTE $SOL_BIN/solana-validator --ledger $LEDGER monitor
	# ssh REMOTE $SOL_BIN/solana catchup ~/solana/validator_link.json --our-localhost
	}


GET_VOTING_IP
argument=$1 # read script argument
primary_mode=''
if [[ $argument =~ ^[0-9]+$ ]] && [ "$argument" -gt 0 ]; then
    	behind_threshold=$argument # 
	echo -e "$RED behind threshold = $behind_threshold  \033[0m"
else
    	behind_threshold="0"
	primary_mode=$argument 
fi
if [[ $primary_mode == "p" ]]; then 
	primary_mode='permanent_primary'; 
	echo -e "start guard in $RED Permanent Primary mode\033[0m"
fi	
if [ "$SERV_TYPE" == "PRIMARY" ]; then # PRIMARY can't determine REMOTE_IP of SECONDARY
	if [ -f $HOME/remote_ip ]; then # SECONDARY should have written its IP to PRIMARY
		REMOTE_IP=$(cat $HOME/remote_ip) # echo "get REMOTE_IP of SECONDARY_SERVER from $HOME/remote_ip: $REMOTE_IP"
	else 
		REMOTE_IP=''	
	fi
	if [[ -z $REMOTE_IP ]]; then # if $REMOTE_IP empty
		echo -e "Warning! Run guard on SECONDARY server first to get it's IP"
		return
	fi
else # SECONDARY
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
	echo -e "$RED SSH connection not available, Error: $remote_identity  \033[0m"
  	return
fi

if [ "$remote_identity" == "$IDENTITY" ]; then
	echo -e "$GREEN SSH connection succesful \033[0m" | tee -a ~/guard.log
else
    	echo -e "$RED Remote server connection Error \033[0m"
	echo "Current Identity = $IDENTITY,"
	echo "Remote Identity  = $remote_identity"
	return
fi

echo '0' > $HOME/remote_behind # update local file for stop alarm next 600 seconds
command_output=$(ssh -o ConnectTimeout=5 REMOTE "echo '$CUR_IP' > $HOME/remote_ip" 2>&1) # send 'current IP' to remote server
command_exit_status=$?
if [ $command_exit_status -ne 0 ]; then
    SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: can't connect to $REMOTE_IP, Error: $command_output"
fi

while true  ###  main cycle   #################################################
do
	GET_VOTING_IP
	if [ "$SERV_TYPE" == "$PRIMARY" ]; then
		PRIMARY_SERVER
	else
		SECONDARY_SERVER
	fi	
	sleep 10
done
