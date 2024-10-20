#!/bin/bash
GUARD_VER=v1.3.8
#===========================================
PORT='2010' # remote server ssh port
KEYS=$HOME/keys
LEDGER=$HOME/solana/ledger
SOLANA_SERVICE="$HOME/solana/solana.service"
#===========================================
EMPTY_KEY=$(grep -oP '(?<=--identity\s).*' "$SOLANA_SERVICE" | tr -d '\\') # get key path from solana.service
VOTING_KEY=$(grep -oP '(?<=--authorized-voter\s).*' "$SOLANA_SERVICE" | tr -d '\\')
IDENTITY=$(solana address) 
VOTING_ADDR=$(solana address -k $VOTING_KEY)
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
version=$(solana --version | awk '{print $2}')
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
SITES=("www.google.com" "www.bing.com")
configDir="$HOME/.config/solana"
SOL_BIN="$(cat ${configDir}/install/config.yml | grep 'active_release_dir\:' | awk '{print $2}')/bin"
DISCONNECT_COUNTER=0
BEHIND_OK_VAL=3 # behind, that seemed ordinary
GREY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'
#==== tg_bot_token ====
# CHAT_ALARM=-100...684
# CHAT_INFO=-100...888
# BOT_TOKEN=507...lWU
#======================
if [ -f "$KEYS/tg_bot_token" ]; then
	if [ -r "$KEYS/tg_bot_token" ]; then
    	source "$KEYS/tg_bot_token" # get CHAT_ALARM, CHAT_INFO, BOT_TOKEN
  	else
    	echo "Error: $KEYS/tg_bot_token exists but is not readable" >&2
  	fi
else
  	echo "Error: $KEYS/tg_bot_token does not exist" >&2
fi

half1=${BOT_TOKEN%%:*}
half2=${BOT_TOKEN#*:}
if [[ -z "$half1" || -z "$half2" ]]; then
  	echo -e "Warning! Can't read telegram bot token from $KEYS/tg_bot_token"
fi
BOT_TOKEN="$half1:$half2"

TIME() {
TZ=Europe/Moscow date +"%b %e  %H:%M:%S"
}

GET_VOTING_IP(){
	local gossip_output
    	local server_address
	declare -A ip_count # ассоциативный массив для хранения количества появлений каждого IP-адреса
	declare -a different_ips # Массив для хранения всех уникальных IP-адресов
 	
  	for i in {1..20}; do # Выполняем 25 запросов
  		voting_ip=$(solana gossip | grep "$IDENTITY" | awk '{print $1}')
    	# Увеличиваем счётчик для данного IP
  		if [[ -n "$voting_ip" ]]; then # Если voting_ip не пустой
    		((ip_count["$voting_ip"]++))
  		fi
  		sleep 0.4 # Maximum number of requests per 10 seconds per IP for a single RPC: 40
	done
	# Находим IP с максимальным количеством появлений
	most_frequent_ip=""
	max_count=0
	
	for ip in "${!ip_count[@]}"; do
  		if (( ip_count["$ip"] > max_count )); then
    		max_count=${ip_count["$ip"]}
    		most_frequent_ip=$ip
  		fi
  		different_ips+=("$ip") # Добавляем уникальный IP в массив
	done
	# Проверяем, есть ли отличающийся IP-адрес
	if [[ ${#different_ips[@]} -gt 1 ]]; then
  		for ip in "${different_ips[@]}"; do
    		if [[ "$ip" != "$most_frequent_ip" ]]; then
      			echo "Different voting IPs: $ip" | tee -a ~/guard.log
    		fi
  		done
	fi
  
	server_address="$most_frequent_ip"
	if [ -z "$server_address" ]; then
        echo "$(TIME) Error: Failed to find server address for identity $IDENTITY" | tee -a ~/guard.log
        return 1
    fi
     
	SERV="$USER@$server_address"
	VOTING_IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from $USER@IP
 	local_validator=$(timeout 3 stdbuf -oL solana-validator --ledger "$LEDGER" monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}')
	if [ $? -ne 0 ]; then
        echo "$(TIME) Error define local_validator" >> ~/guard.log
        return 1
    fi
  
	if [[ -z "$VOTING_IP" ]]; then
        echo "$(TIME) Warning! VOTING_IP is empty" | tee -a ~/guard.log
        return 1
    fi
 	if [ "$CUR_IP" = "$VOTING_IP" ]; then
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
command_exit_status=0; command_output='' # set global variable
SSH(){
	local ssh_command="$1"
  	command_output=$(ssh -o ConnectTimeout=5 REMOTE $ssh_command 2>> ~/guard.log)
  	command_exit_status=$?
  	if [ $command_exit_status -ne 0 ]; then
    	echo "$(TIME) SSH Error: command_output=$command_output" >> ~/guard.log
    	echo "$(TIME) SSH Error: command_exit_status=$command_exit_status" | tee -a ~/guard.log
    	if ping -c 3 -W 3 "$REMOTE_IP" > /dev/null 2>&1; then
			echo "$(TIME) remote server $REMOTE_IP ping OK" | tee -a ~/guard.log
		else
			echo "$(TIME) Error: remote server $REMOTE_IP did not ping" | tee -a ~/guard.log
			if ping -c 3 -W 3 "www.google.com" > /dev/null 2>&1; then
				echo "$(TIME) Google ping OK" | tee -a ~/guard.log
			else
				echo "$(TIME) Error: Google did not ping too" | tee -a ~/guard.log
			fi
		fi
		if [ $((current_time - ssh_alarm_time)) -ge 120 ]; then
      		SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: can't connect to $REMOTE_IP"
      		ssh_alarm_time=$current_time
    	fi
  	fi
	}

echo -e " == SOLANA GUARD $GREEN$GUARD_VER \033[0m" | tee -a ~/guard.log
#source ~/sol_git/setup/check.sh
GET_VOTING_IP
echo "voting  IP=$VOTING_IP" | tee -a ~/guard.log
echo "current IP=$CUR_IP" | tee -a ~/guard.log
echo -e "IDENTITY  = $GREEN$IDENTITY \033[0m" | tee -a ~/guard.log
echo -e "empty key = $GREY$(solana address -k $EMPTY_KEY) \033[0m" | tee -a ~/guard.log
if [ -z "$NAME" ]; then NAME=$(hostname); fi
if [ $rpcURL = https://api.testnet.solana.com ]; then 
NODE="test"
elif [ $rpcURL = https://api.mainnet-beta.solana.com ]; then 
NODE="main"
fi
echo " $NODE.$NAME $version-$client"

health_warning=0
behind_warning=0
remote_behind_warning=0
slots_remaining=0
CHECK_HEALTH() { # self check health every 5 seconds  ###########################################
 	# check behind slots
 	Request_OK='true'
	RPC_SLOT=$(timeout 5 solana slot -u $rpcURL 2>> ~/guard.log)
	if [[ $? -ne 0 ]]; then Request_OK='false'; echo "$(TIME) Error in solana slot RPC request" >> ~/guard.log; fi
	LOCAL_SLOT=$(timeout 5 solana slot -u localhost 2>> ~/guard.log)
 	if [[ $? -ne 0 ]]; then Request_OK='false'; echo "$(TIME) Error in solana slot localhost request" >> ~/guard.log; fi
	if [[ $Request_OK == 'true' && -n "$RPC_SLOT" && -n "$LOCAL_SLOT" ]]; then BEHIND=$((RPC_SLOT - LOCAL_SLOT)); fi
	
	# next slot time
	my_slot=$(timeout 5 solana leader-schedule -v | grep $IDENTITY | awk -v var=$RPC_SLOT '$1>=var' | head -n1 | cut -d ' ' -f3 2>> ~/guard.log)
	if [[ $? -ne 0 ]]; then echo "$(TIME) Error in leader schedule request" | tee -a ~/guard.log; fi
	if [[ -n "$RPC_SLOT" && -n "$my_slot" ]]; then slots_remaining=$((my_slot-RPC_SLOT)); fi
	next_slot_time=$((($slots_remaining * 459) / 60000))
	#if [[ $next_slot_time -lt 0 ]]; then next_slot_time='none'; fi 
	if [[ $next_slot_time -lt 2 ]]; then TIME_PRN="$RED$next_slot_time"; else TIME_PRN="$GREEN$next_slot_time"; fi
 
 	# check health
 	REQUEST=$(curl -s -m 5 http://localhost:8899/health)
  	if [ $? -ne 0 ]; then echo "$(TIME) Error, health request=$HEALTH " | tee -a ~/guard.log; 
	else HEALTH=$REQUEST; fi
	if [[ -z $HEALTH ]]; then # if $HEALTH is empty (must be 'ok')
		HEALTH="Warning!"
	fi
	
	if [[ $health_warning -eq 0 && $behind_warning -eq 0 ]]; then # check 'health' & 'behind' from last requests
		CHECK_UP='true' # 'health' and 'behind' must be fine twice: last and current requests
	else 	
		CHECK_UP='false' 
	fi	
 	if [[ $HEALTH == "ok" ]]; then
		health_warning=0
		HEALTH_PRN="$GREEN$HEALTH"
	else
		CHECK_UP='false' 
		HEALTH_PRN="$RED$HEALTH"
		let health_warning=health_warning+1
		echo "$(TIME) Health=$HEALTH, health_warning=$health_warning, CHECK_UP=$CHECK_UP    " | tee -a ~/guard.log  # log every warning_message
		if [[ $health_warning -ge 1 ]]; then # 
			health_warning=-12
			SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: Health: $HEALTH"
		fi
	fi  
	
	# check behind
	if [[ $BEHIND -le $BEHIND_OK_VAL && $BEHIND -gt -1000 ]]; then # must be: -1000<BEHIND<1 
		behind_warning=0
  		BEHIND_PRN="$GREEN$BEHIND"
	else
		CHECK_UP='false'
  		let behind_warning=behind_warning+1
		echo "$(TIME) Behind=$BEHIND    " | tee -a ~/guard.log  # log every warning_message
		BEHIND_PRN="$RED$BEHIND"
		if [[ $behind_warning -ge 3 ]] && [[ $BEHIND -ge 3 ]]; then # 
			behind_warning=-12 # sent next message after  12*5 seconds
	 		SEND_INFO "$SERV_TYPE ${NODE}.${NAME}: Behind=$BEHIND"
		fi
	fi
	REMOTE_BEHIND=$(cat $HOME/remote_behind)
	if [[ $REMOTE_BEHIND -lt 1 && $REMOTE_BEHIND -gt -1000 ]]; then # -1000<REMOTE_BEHIND<1
		remote_behind_warning=0
  		REMOTE_BEHIND_PRN="$GREEN$REMOTE_BEHIND"	
  	else	
    		let remote_behind_warning=remote_behind_warning+1
		REMOTE_BEHIND_PRN="$RED$REMOTE_BEHIND"; 
	fi
 	if [[ $CHECK_UP == 'true' ]]; then CHECK_PRN="$GREEN OK\033[0m"; else CHECK_PRN="$RED warn\033[0m"; fi
	echo -ne "$(TZ=Europe/Moscow date +"%H:%M:%S")  $SERV_TYPE ${NODE}.${NAME}, next:$TIME_PRN\033[0m, behind:$BEHIND_PRN\033[0m,$REMOTE_BEHIND_PRN\033[0m, health $HEALTH_PRN\033[0m, check$CHECK_PRN $YELLOW$primary_mode\033[0m      \r"

 	# check guard running on remote server
 	current_time=$(date +%s)
	SSH "echo '$BEHIND' > $HOME/remote_behind"
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
	SEND_INFO "PRIMARY ${NODE}.${NAME} $CUR_IP start"
	while [ "$SERV_TYPE" = "PRIMARY" ]; do
		CHECK_CONNECTION
		CHECK_HEALTH
		GET_VOTING_IP
		# sleep 5
	done
	echo -e "$(TIME) switch PRIMARY status to $VOTING_IP  " | tee -a ~/guard.log
	}
	
SECONDARY_SERVER(){ ##################################################################
	SEND_INFO "SECONDARY ${NODE}.${NAME} $CUR_IP start"
	# waiting remote server fail and selfcheck health
	set_primary=0 # 
	REASON=''
	until [[ $CHECK_UP == 'true' && $set_primary -ge 1 ]]; do # 
		# sleep 5
		VALIDATORS_LIST=$(timeout 5 solana validators --url $rpcURL --output json 2>/dev/null)
		if [ $? -ne 0 ]; then 
			echo "$(TIME) Error in validators list request" | tee -a ~/guard.log; 
			continue 
		fi
		if [ -z "$VALIDATORS_LIST" ]; then 
			echo "$(TIME) Error: validators list emty" | tee -a ~/guard.log;
			continue 
		fi
		JSON=$(echo "$VALIDATORS_LIST" | jq '.validators[] | select(.identityPubkey == "'"${IDENTITY}"'" )')
		LastVote=$(echo "$JSON" | jq -r '.lastVote')
		Delinquent=$(echo "$JSON" | jq -r '.delinquent')
		if [[ $Delinquent == true ]]; then
			set_primary=2; 	REASON="Delinquent"; echo "$(TIME) Warning! Delinquent detected! " | tee -a ~/guard.log;
		fi
		if [[ $behind_threshold -ge 1 ]] && [[ $remote_behind_warning -ge $behind_threshold ]]; then
			set_primary=2; 	REASON="Behind too long"; echo "$(TIME) Warning! Behind detected! " | tee -a ~/guard.log;
		fi
		if [[ $primary_mode == "permanent_primary" && next_slot_time -ge 1 ]]; then
			set_primary=2; 	REASON="set Permanent Primary mode"; 
		fi	
		CHECK_HEALTH #  self check node health
  		GET_VOTING_IP
  		if [ "$SERV_TYPE" = "PRIMARY" ]; then
    		return
       	fi
	done
		# STOP SOLANA on REMOTE server
  	echo "$(TIME) Let's stop voting on remote server " | tee -a ~/guard.log
   	echo "$(TIME) CHECK_UP=$CHECK_UP, HEALTH=$HEALTH, BEHIND=$BEHIND, REASON=$REASON, set_primary=$set_primary " | tee -a ~/guard.log
	MSG=$(printf "${NODE}.${NAME}: switch voting ${VOTING_IP} \n%s $REASON") # \n%s vote_off remote server
	SSH "$SOL_BIN/solana-validator -l $LEDGER set-identity $EMPTY_KEY 2>&1"
	if [ $command_exit_status -eq 0 ]; then
		echo -e "\033[32m  set empty identity on REMOTE server successful \033[0m" 
		MSG=$(printf "$MSG \n%s set empty identity")
	else
		SEND_ALARM "Can't set identity on remote server"
  		echo "$(TIME) Try to restart solana on remote server" | tee -a ~/guard.log
		SSH "systemctl restart solana 2>&1"
    	if [ $command_exit_status -eq 0 ]; then
			MSG=$(printf "$MSG \n%s restart solana on remote server")
      	else
			SEND_ALARM "Can't restart solana on REMOTE server"
			if ping -c 3 -W 3 "$REMOTE_IP" > /dev/null 2>&1; then
   				echo "$(TIME) Remote server ping OK, so can't start voting in current situation" | tee -a ~/guard.log
				return
			fi
			SEND_ALARM "Can't ping REMOTE server"
		fi
	fi
	# remove old tower before
 	echo "$(TIME) Let's start voting on current server" | tee -a ~/guard.log
	rm $LEDGER/tower-1_9-$IDENTITY.bin 
	remove_status=$?
	if [ $remove_status -eq 0 ]; then echo "$(TIME) remove old tower OK" | tee -a ~/guard.log
	else echo "$(TIME) remove old tower Error: $remove_status" | tee -a ~/guard.log
	fi
	# copy tower from remote server
	timeout 5 scp -P $PORT -i $KEYS/*.ssh $SERV:$LEDGER/tower-1_9-$IDENTITY.bin $LEDGER
	copy_status=$?
	if [ $copy_status -eq 0 ]; then echo "$(TIME) copy tower from $SERV OK" | tee -a ~/guard.log
	elif [ $copy_status -eq 124 ]; then echo "$(TIME) copy tower from $SERV timeout exceed" | tee -a ~/guard.log
	else echo "$(TIME) copy tower from $SERV Error: $copy_status" | tee -a ~/guard.log
	fi
	# stop telegraf service on remote server
	SSH "systemctl stop telegraf"
	if [ $command_exit_status -eq 0 ]; then echo "$(TIME) stop telegraf on remote server OK" | tee -a ~/guard.log
	elif [ $command_exit_status -eq 124 ]; then echo "$(TIME) stop telegraf on remote server timeout exceed" | tee -a ~/guard.log
 	else echo "$(TIME) stop telegraf on remote server Error" | tee -a ~/guard.log
	fi
 	# echo "  stop jito-relayer on REMOTE server"
	# ssh -o ConnectTimeout=5 REMOTE systemctl stop jito-relayer.service

	# START SOLANA on LOCAL server
	if [ -f $LEDGER/tower-1_9-$IDENTITY.bin ]; then 
		TOWER_STATUS=' with tower'; 	solana-validator -l $LEDGER set-identity --require-tower $VOTING_KEY;
	else
		TOWER_STATUS=' without tower'; 	solana-validator -l $LEDGER set-identity $VOTING_KEY;
	fi
	set_identity_status=$?
	if [ $set_identity_status -eq 0 ]; then echo "$(TIME) set identity$TOWER_STATUS OK" | tee -a ~/guard.log
	else echo "$(TIME) set identity Error: $set_identity_status" | tee -a ~/guard.log
	fi
	# update telegraf
	# sed -i "/^  hostname = /c\  hostname = \"$NAME\"" /etc/telegraf/telegraf.conf
	systemctl start telegraf
	# systemctl start jito-relayer.service
	# MSG=$(printf "$MSG \n%s VOTE ON$TOWER_STATUS")
	SEND_ALARM "$(printf "$MSG \n%s VOTE ON$TOWER_STATUS")"
	echo "$(TIME) waiting for PRIMARY status" | tee -a ~/guard.log
	while [ $SERV_TYPE = "SECONDARY" ]; do
 		# echo "$(TIME) waiting for PRIMARY status" | tee -a ~/guard.log
   		GET_VOTING_IP
     	CHECK_HEALTH
   		sleep 2
 	done
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
	echo -e "start guard in $YELLOW Permanent Primary mode\033[0m"
fi	
if [ "$SERV_TYPE" = "PRIMARY" ]; then # PRIMARY can't determine REMOTE_IP of SECONDARY
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
User $USER
Port $PORT
IdentityFile $KEYS/*.ssh
" > ~/.ssh/config

# check SSH connection to remote server
SSH "$SOL_BIN/solana address"
remote_identity=$command_output
if [ $command_exit_status -ne  0 ]; then
	echo -e "$RED SSH connection not available  \033[0m" 
	return
fi

if [ "$remote_identity" = "$IDENTITY" ]; then
	echo -e "$GREEN SSH connection succesful \033[0m" | tee -a ~/guard.log
else
    echo -e "$RED Warning! Servers identity are different \033[0m"
	echo "Current Identity = $IDENTITY"
	echo "Remote Identity  = $remote_identity"
	return
fi

echo '0' > $HOME/remote_behind # update local file for stop alarm next 600 seconds
SSH "echo '$CUR_IP' > $HOME/remote_ip" # send 'current IP' to remote server

while true  ###  main cycle   #################################################
do
	GET_VOTING_IP
	if [ "$SERV_TYPE" = "PRIMARY" ]; then
		PRIMARY_SERVER
	else
		SECONDARY_SERVER
	fi	
done
