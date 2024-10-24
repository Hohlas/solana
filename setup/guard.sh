#!/bin/bash
GUARD_VER=v1.4.3
#=================== guard.cfg ========================
PORT='2010' # remote server ssh port
KEYS=$HOME/keys
LEDGER=$HOME/solana/ledger
SOLANA_SERVICE="$HOME/solana/solana.service"
BEHIND_WARNING=false # 'false'- send telegramm INFO missage, when behind. 'true'-send ALERT message
WARNING_FREQUENCY=12 # max frequency of warning messages (WARNING_FREQUENCY x 5) seconds
BEHIND_OK_VAL=3 # behind, that seemed ordinary
RELAYER_SERVICE=false # use restarting jito-relayer service
configDir="$HOME/.config/solana"
# rpcURL2="https://mainnet.helius-rpc.com..." # Helius RPC
# CHAT_ALARM=-1001..5684
# CHAT_INFO=-1001..2888
# BOT_TOKEN=50762..CllWU
#======================================================
EMPTY_KEY=$(grep -oP '(?<=--identity\s).*' "$SOLANA_SERVICE" | tr -d '\\') # get key path from solana.service
VOTING_KEY=$(grep -oP '(?<=--authorized-voter\s).*' "$SOLANA_SERVICE" | tr -d '\\')
IDENTITY=$(solana address) 
VOTING_ADDR=$(solana address -k $VOTING_KEY)
rpcURL1=$(solana config get | grep "RPC URL" | awk '{print $3}')
rpcURL2="" # берется из файлла tg_bot_token. Нужен в качестве альтернативного RPC для сравнения значений
version=$(solana --version | awk '{print $2}')ec
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
SITES=("www.google.com" "www.bing.com")
SOL_BIN="$(cat ${configDir}/install/config.yml | grep 'active_release_dir\:' | awk '{print $2}')/bin"
GREY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CLEAR=$'\033[0m'
# ======================
if [ -f "$HOME/guard.cfg" ]; then
	if [ -r "$HOME/guard.cfg" ]; then
    	source "$HOME/guard.cfg" # get settings
     	KEYS=$(echo "$KEYS" | tr -d '\r') # Удаление символа \r, если он есть
		LEDGER=$(echo "$LEDGER" | tr -d '\r') # Удаление символа \r, если он есть
      	SOLANA_SERVICE=$(echo "$SOLANA_SERVICE" | tr -d '\r') # Удаление символа \r, если он есть
	   	configDir=$(echo "$configDir" | tr -d '\r') # Удаление символа \r, если он есть
	   	BOT_TOKEN=$(echo "$BOT_TOKEN" | tr -d '\r') # Удаление символа \r, если он есть
  	else
    	echo "Error: $HOME/guard.cfg exists but is not readable" >&2
  	fi
else
  	echo "Error: $HOME/guard.cfg does not exist, set default settings" >&2
fi
if [[ -z "$rpcURL2" ]]; then
    rpcURL2=$rpcURL1 # Присваиваем значение rpcURL2, чтобы не было ошибки
	echo -e "Warning! $RED rpcURL2 is not defined in $HOME/guard.cfg ! $CLEAR"
fi

TIME() {
	TZ=Europe/Moscow date +"%b %e  %H:%M:%S"
	}


REQUEST_IP(){
	sleep 0.5; echo "$(TIME) REQUEST_IP" >> ~/guard.log;
	local RPC_URL="$1"
	VALIDATOR_REQUEST=$(timeout 5 solana gossip --url $RPC_URL 2>> ~/guard.log)
	if [ $? -ne 0 ]; then 
		echo "$(TIME) Error in gossip request for RPC $RPC_URL" | tee -a ~/guard.log
		#return 1
	fi
	if [ -z "$VALIDATOR_REQUEST" ]; then
		echo "$(TIME) Error: validator request emty" | tee -a ~/guard.log;
		#return 1 
	fi	
	echo "$VALIDATOR_REQUEST" | grep "$IDENTITY" | awk '{print $1}'
	}
REQUEST_DELINK(){
	sleep 0.5; echo "$(TIME) REQUEST_DELINK" >> ~/guard.log;
	local RPC_URL="$1"
	VALIDATORS_LIST=$(timeout 5 solana validators --url $RPC_URL --output json 2>> ~/guard.log)
	if [ $? -ne 0 ]; then 
		echo "$(TIME) Error in validators list request for RPC $RPC_URL" | tee -a ~/guard.log; 
		#return 1 
	fi
	if [ -z "$VALIDATORS_LIST" ]; then 
		echo "$(TIME) Error: validators list emty" | tee -a ~/guard.log;
		#return 1 
	fi	
	JSON=$(echo "$VALIDATORS_LIST" | jq '.validators[] | select(.identityPubkey == "'"${IDENTITY}"'" )')
	LastVote=$(echo "$JSON" | jq -r '.lastVote')
	echo "$JSON" | jq -r '.delinquent'
	}
REQUEST_ANSWER=""
RPC_REQUEST() {
    local REQUEST_TYPE="$1"
    local REQUEST1 REQUEST2


    if [[ "$REQUEST_TYPE" == "IP" ]]; then
		FUNCTION_NAME="REQUEST_IP" 
	elif [[ "$REQUEST_TYPE" == "DELINK" ]]; then
        FUNCTION_NAME="REQUEST_DELINK"
    fi    	
	
	REQUEST1=$(eval "$FUNCTION_NAME \"$rpcURL1\"") # вопрос_2
	REQUEST2=$(eval "$FUNCTION_NAME \"$rpcURL2\"")
	
	# Сравнение результатов
    if [[ "$REQUEST1" == "$REQUEST2" ]]; then
        REQUEST_ANSWER="$REQUEST1"
		sleep 3
    else    
		#echo "$(TIME) Warning! Different answers: RPC1=$REQUEST1, RPC2=$REQUEST2" >> ~/guard.log
		# Если результаты разные, опрашиваем в цикле 10 раз
		declare -A request_count
		for i in {1..10}; do 
			RQST1=$(eval "$FUNCTION_NAME \"$rpcURL1\"") # Вызов функции через eval
			RQST2=$(eval "$FUNCTION_NAME \"$rpcURL2\"")
			[[ -n "$RQST1" ]] && ((request_count["$RQST1"]++)) # Увеличиваем счётчики 
			[[ -n "$RQST2" ]] && ((request_count["$RQST2"]++)) # для каждого вызова
		done

		# Находим наиболее частый ответ
		most_frequent_answer=""
		max_count=0

		for answer in "${!request_count[@]}"; do
			if (( request_count["$answer"] > max_count )); then
				max_count=${request_count["$answer"]}
				most_frequent_answer=$answer
			fi
		done

		if [[ -z "$most_frequent_answer" ]]; then
			echo "$(TIME) Error: No valid request answer found after retries." | tee -a ~/guard.log
			return 1
		fi	
		REQUEST_ANSWER="$most_frequent_answer"
  		percentage=$(( (max_count * 100) / 20 ))
  		if [[ "$REQUEST1" == "$REQUEST_ANSWER" ]]; then 
       		CLR1=$GREEN; CLR2=$RED;
    	else 
      		CLR1=$RED; CLR2=$GREEN;
    	fi 
    	echo -e "$(TIME) Warning! Different answers $BLUE$percentage%$CLEAR: RPC1=$CLR1$REQUEST1$CLEAR, RPC2=$CLR2$REQUEST2$CLEAR"
		echo "$(TIME) Warning! Different answers[$percentage%]: RPC1=$REQUEST1, RPC2=$REQUEST2" >> ~/guard.log	
  		if [[ $percentage -lt 70 ]]; then 
			REQUEST_ANSWER="";
   			echo -e "$(TIME) Error: REQUEST_ANSWER not so correct, disable it" | tee -a ~/guard.log
	  		fi
	fi	
	# echo "$REQUEST_ANSWER"
	}





GET_VOTING_IP(){
    # Получаем IP-адрес голосующего валидатора 
	RPC_REQUEST "IP"  
 	if [ -z "$REQUEST_ANSWER" ]; then
		echo "$(TIME) Error: VOTING_IP empty, keep previous value" | tee -a ~/guard.log;
		return 1 
	fi
	VOTING_IP=$REQUEST_ANSWER
    SERV="$USER@$VOTING_IP"
    # Получаем локальный валидатор
    local_validator=$(timeout 3 stdbuf -oL solana-validator --ledger "$LEDGER" monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}')
    if [[ $? -ne 0 ]]; then
        echo "$(TIME) Error defining local_validator" >> ~/guard.log
        return 1
    fi
    # Проверяем текущий IP и устанавливаем тип сервера
    if [[ "$CUR_IP" == "$VOTING_IP" ]]; then
        SERV_TYPE='PRIMARY'
    else 
        SERV_TYPE='SECONDARY'
    fi
	}

SEND_INFO(){
	local message="$1"
	curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_INFO -d text="$message" > /dev/null
	echo "$(TIME) $message" >> ~/guard.log
 	echo -e "$(TIME) $message $CLEAR"
	}
SEND_ALARM(){
	local message="$1"
	curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_ALARM -d text="$message" > /dev/null
	echo "$(TIME) $message" >> ~/guard.log
 	echo -e "$(TIME) $RED $message $CLEAR"
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

echo -e " == SOLANA GUARD $GREEN$GUARD_VER $CLEAR" | tee -a ~/guard.log
#source ~/sol_git/setup/check.sh
GET_VOTING_IP
echo "voting  IP=$VOTING_IP" | tee -a ~/guard.log
echo "current IP=$CUR_IP" | tee -a ~/guard.log
echo -e "IDENTITY  = $GREEN$IDENTITY $CLEAR" | tee -a ~/guard.log
echo -e "empty key = $GREY$(solana address -k $EMPTY_KEY) $CLEAR" | tee -a ~/guard.log
echo -e "RPC1:$BLUE$rpcURL1$CLEAR" | tee -a ~/guard.log
echo -e "RPC2:$BLUE$rpcURL2$CLEAR" | tee -a ~/guard.log
if [ -z "$NAME" ]; then NAME=$(hostname); fi
if [ $rpcURL1 = https://api.testnet.solana.com ]; then 
NODE="test"
elif [ $rpcURL1 = https://api.mainnet-beta.solana.com ]; then 
NODE="main"
fi
echo " $NODE.$NAME $version-$client"

health_counter=0
behind_counter=0
remote_behind_counter=0
slots_remaining=0
disconnect_counter=0
CHECK_HEALTH() { # self check health every 5 seconds  ###########################################
 	# check behind slots
 	Request_OK='true'
	RPC_SLOT=$(timeout 5 solana slot -u $rpcURL1 2>> ~/guard.log)
	if [[ $? -ne 0 ]]; then Request_OK='false'; echo "$(TIME) Error in solana slot RPC request" >> ~/guard.log; fi
	LOCAL_SLOT=$(timeout 5 solana slot -u localhost 2>> ~/guard.log)
 	if [[ $? -ne 0 ]]; then Request_OK='false'; echo "$(TIME) Error in solana slot localhost request" >> ~/guard.log; fi
	if [[ $Request_OK == 'true' && -n "$RPC_SLOT" && -n "$LOCAL_SLOT" ]]; then BEHIND=$((RPC_SLOT - LOCAL_SLOT)); fi
	sleep 0.2
	# epoch info
	EPOCH_INFO=$(timeout 5 solana epoch-info --output json 2>> ~/guard.log)
	if [[ $? -ne 0 ]]; then
    	echo "$(date) Error retrieving epoch info: $EPOCH_INFO" >> ~/guard.log
	 	SLOTS_UNTIL_EPOCH_END=0
	else
		SLOTS_IN_EPOCH=$(echo "$EPOCH_INFO" | jq '.slotsInEpoch')
		SLOT_INDEX=$(echo "$EPOCH_INFO" | jq '.slotIndex')
		SLOTS_UNTIL_EPOCH_END=$(echo "$SLOTS_IN_EPOCH - $SLOT_INDEX" | bc)
 	fi
	# next slot time
	my_slot=$(timeout 5 solana leader-schedule -v | grep $IDENTITY | awk -v var=$RPC_SLOT '$1>=var' | head -n1 | cut -d ' ' -f3 2>> ~/guard.log)
	if [[ $? -ne 0 ]]; then Request_OK='false'; echo "$(TIME) Error in leader schedule request" | tee -a ~/guard.log; fi
	if [[ $Request_OK == 'true' && "$my_slot" =~ ^-?[0-9]+$ && "$RPC_SLOT" =~ ^-?[0-9]+$ ]]; then  # переменные являются числами
    	slots_remaining=$((my_slot - RPC_SLOT))
	 	NEXT_CLR=$BLUE
	elif [[ "$SLOTS_UNTIL_EPOCH_END" =~ ^-?[0-9]+$ ]]; then # переменная является числом
    	slots_remaining=$SLOTS_UNTIL_EPOCH_END
		NEXT_CLR=$YELLOW
	else 
    	slots_remaining=0		
	fi
	next_slot_time=$((($slots_remaining * 459) / 60000))
	if [[ $next_slot_time -lt 2 ]]; then NEXT_CLR=$RED; fi
 
 	# check health
 	REQUEST=$(curl -s -m 5 http://localhost:8899/health)
  	if [ $? -ne 0 ]; then 
   		echo "$(TIME) Error, health request=$HEALTH " | tee -a ~/guard.log; 
	else 
 		HEALTH=$REQUEST; 
   	fi
	if [[ -z $HEALTH ]]; then # if $HEALTH is empty (must be 'ok')
		HEALTH="Warning!"
	fi
	
	if [[ $health_counter -eq 0 && $behind_counter -eq 0 ]]; then # check 'health' & 'behind' from last requests
		CHECK_UP='true' # 'health' and 'behind' must be fine twice: last and current requests
	else 	
		CHECK_UP='false' 
	fi	
 	if [[ $HEALTH == "ok" ]]; then
		health_counter=0
		HEALTH_PRN="$GREEN$HEALTH"
	else
		CHECK_UP='false' 
		HEALTH_PRN="$RED$HEALTH"
		let health_counter=health_counter+1
		echo "$(TIME) Health=$HEALTH, health_counter=$health_counter, CHECK_UP=$CHECK_UP    " | tee -a ~/guard.log  # log every warning_message
		if [[ $health_counter -ge 1 ]]; then # 
			health_counter=-$WARNING_FREQUENCY
			SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: Health: $HEALTH"
		fi
	fi  
	
	# check behind
	if [[ $BEHIND -le $BEHIND_OK_VAL && $BEHIND -gt -1000 ]]; then # must be: -1000<BEHIND<1 
		behind_counter=0
  		BEHIND_PRN="$GREEN$BEHIND"
	else
		CHECK_UP='false'
  		let behind_counter=behind_counter+1
		echo "$(TIME) Behind=$BEHIND    " | tee -a ~/guard.log  # log every warning_message
		BEHIND_PRN="$RED$BEHIND"
		if [[ $behind_counter -ge 3 ]] && [[ $BEHIND -ge $BEHIND_OK_VAL ]]; then # 
			behind_counter=-$WARNING_FREQUENCY # sent next message after  12*5 seconds
	 		if [[ $BEHIND_WARNING == 'true' ]]; then SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: Behind=$BEHIND";
			else SEND_INFO "$SERV_TYPE ${NODE}.${NAME}: Behind=$BEHIND"; fi
		fi
	fi
	REMOTE_BEHIND=$(cat $HOME/remote_behind)
	if [[ $REMOTE_BEHIND -le $BEHIND_OK_VAL && $REMOTE_BEHIND -gt -1000 ]]; then # -1000<REMOTE_BEHIND<1
		remote_behind_counter=0
  		REMOTE_BEHIND_PRN="$GREEN$REMOTE_BEHIND"	
  	else	
    	let remote_behind_counter=remote_behind_counter+1
		REMOTE_BEHIND_PRN="$RED$REMOTE_BEHIND"; 
	fi
 	if [[ $CHECK_UP == 'true' ]]; then CHECK_PRN="$GREEN OK$CLEAR"; else CHECK_PRN="$RED warn$CLEAR"; fi
	echo -ne "$(TZ=Europe/Moscow date +"%H:%M:%S")  $SERV_TYPE ${NODE}.${NAME}, next:$NEXT_CLR$next_slot_time$CLEAR, behind:$BEHIND_PRN$CLEAR,$REMOTE_BEHIND_PRN$CLEAR, health $HEALTH_PRN$CLEAR, check$CHECK_PRN $YELLOW$primary_mode$CLEAR      \r"

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
        let disconnect_counter=disconnect_counter+1
        echo "$(TIME) connection failed, attempt $disconnect_counter" | tee -a ~/guard.log
    else
        disconnect_counter=0
    fi
    # connection loss for 15 seconds (5sec * 3)
    if [ $disconnect_counter -ge 3 ]; then
        # bash "$CONNECTION_LOSS_SCRIPT" # no need to vote_off in offline
        systemctl restart solana
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
	done
	echo -e "$(TIME) switch PRIMARY status to $VOTING_IP  " | tee -a ~/guard.log
	}
	
SECONDARY_SERVER(){ ##################################################################
	SEND_INFO "SECONDARY ${NODE}.${NAME} $CUR_IP start"
	# waiting remote server fail and selfcheck health
	set_primary=0 # 
	REASON=''
	until [[ $CHECK_UP == 'true' && $set_primary -ge 1 ]]; do # 
		RPC_REQUEST "DELINK"
		Delinquent=$REQUEST_ANSWER
		if [[ $Delinquent == true ]]; then
			set_primary=2; 	REASON="Delinquent"; echo "$(TIME) Warning! Delinquent detected! " | tee -a ~/guard.log;
		fi
		if [[ $behind_threshold -ge 1 ]] && [[ $remote_behind_counter -ge $behind_threshold ]]; then
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
		echo -e "\033[32m  set empty identity on REMOTE server successful $CLEAR" 
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
	if [[ $RELAYER_SERVICE == 'true' ]]; then 
 		SSH "systemctl stop relayer.service"
		systemctl start relayer.service
  		MSG=$(printf "$MSG \n%s restart jito-relayer service")
	fi
 	systemctl start telegraf
	SEND_ALARM "$(printf "$MSG \n%s VOTE ON$TOWER_STATUS")"
	echo "$(TIME) waiting for PRIMARY status" | tee -a ~/guard.log
	while [ $SERV_TYPE = "SECONDARY" ]; do
 		# echo "$(TIME) waiting for PRIMARY status" | tee -a ~/guard.log
   		GET_VOTING_IP
     	CHECK_HEALTH
 	done
	}


GET_VOTING_IP
argument=$1 # read script argument
primary_mode=''
if [[ $argument =~ ^[0-9]+$ ]] && [ "$argument" -gt 0 ]; then
    	behind_threshold=$argument # 
	echo -e "$RED behind threshold = $behind_threshold  $CLEAR"
else
    behind_threshold="0"
	primary_mode=$argument 
fi
if [[ $primary_mode == "p" ]]; then 
	primary_mode='permanent_primary'; 
	echo -e "start guard in $YELLOW Permanent Primary mode$CLEAR"
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
	echo -e "$RED SSH connection not available  $CLEAR" 
	exit 0
fi

if [ "$remote_identity" = "$IDENTITY" ]; then
	echo -e "$GREEN SSH connection succesful $CLEAR" | tee -a ~/guard.log
else
    echo -e "$RED Warning! Servers identity are different $CLEAR"
	echo "Current Identity = $IDENTITY"
	echo "Remote Identity  = $remote_identity"
	exit 0
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
