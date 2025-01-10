#!/bin/bash
GUARD_VER=v1.6.3
#=================== guard.cfg ========================
PORT='2010' # remote server ssh port
KEYS=$HOME/keys
LOG_FILE=$HOME/guard.log
SOLANA_SERVICE="$HOME/solana/solana.service"
LEDGER="$HOME/solana/ledger"
BEHIND_WARNING=false # 'false'- send telegramm INFO missage, when behind. 'true'-send ALERT message
WARNING_FREQUENCY=12 # max frequency of warning messages (WARNING_FREQUENCY x 5) seconds
BEHIND_OK_VAL=3 # behind, that seemed ordinary
RELAYER_SERVICE=true # use restarting jito-relayer service
configDir="$HOME/.config/solana"
# CHAT_ALARM=-1001..5684
# CHAT_INFO=-1001..2888
# BOT_TOKEN=50762..CllWU
# список альтернативных rpcURL2 для сравнения значений
# RPC_LIST=(
# "https://mainnet.helius-rpc.com..."
# "https://mainnet.helius-rpc.com..."
# )
#======================================================
EMPTY_KEY=$(grep -oP '(?<=--identity\s).*' "$SOLANA_SERVICE" | tr -d '\\') # get key path from solana.service
VOTING_KEY=$(grep -oP '(?<=--authorized-voter\s).*' "$SOLANA_SERVICE" | tr -d '\\')
IDENTITY=$(solana address 2>/dev/null)
if [ $? -ne 0 ]; then  
	echo "Error! Can't run 'solana'"
	return
fi	
VOTING_ADDR=$(solana address -k $VOTING_KEY)
EMPTY_ADDR=$(solana address -k $EMPTY_KEY)
rpcURL1=$(solana config get | grep "RPC URL" | awk '{print $3}')
version=$(solana-validator --version 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error! Can't run 'solana-validator'"
	return
else
	version=$(echo "$version" | awk -F '[ ()]' '{print $1, $2, $NF}' | sed 's/client://')
fi	
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
SITES=("www.google.com" "www.bing.com")
SOL_BIN="$(cat ${configDir}/install/config.yml | grep 'active_release_dir\:' | awk '{print $2}')/bin"
GRAY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CLEAR=$'\033[0m'
# ======================
if [ -f "$HOME/guard.cfg" ]; then
	if [ -r "$HOME/guard.cfg" ]; then
    	source "$HOME/guard.cfg" # get settings
     	KEYS=$(echo "$KEYS" | tr -d '\r') # Удаление символа \r, если он есть
      	SOLANA_SERVICE=$(echo "$SOLANA_SERVICE" | tr -d '\r') # Удаление символа \r, если он есть
	   	configDir=$(echo "$configDir" | tr -d '\r') # Удаление символа \r, если он есть
	   	BOT_TOKEN=$(echo "$BOT_TOKEN" | tr -d '\r') # Удаление символа \r, если он есть
  	else
    	echo "Error: $HOME/guard.cfg exists but is not readable" >&2
  	fi
else
  	echo "Error: $HOME/guard.cfg does not exist, set default settings" >&2
fi
if [[ -f $LOG_FILE ]]; then
    rpc_index=$(grep -oP 'rpc_index=\K\d+' "$LOG_FILE" | tail -n 1) # Читаем последний rpc_index из лог-файла
fi
if [[ -z "$RPC_LIST" ]]; then
    RPC_LIST=($rpcURL1) # Записываем в массив RPC сервер соланы, чтобы не было ошибки
	rpc_index=0
	echo -e "Warning! $RED RPC_LIST is not defined in $HOME/guard.cfg ! $CLEAR"
fi
if [[ -z "$BOT_TOKEN" ]]; then
	echo -e "Warning! $RED Telegram BOT_TOKEN is not defined in $HOME/guard.cfg ! $CLEAR"
fi
# solana-validator -l /root/solana/ledger/ contact-info

TIME() {
	TZ=Europe/Moscow date +"%b %e  %H:%M:%S"
	}
LOG() {
    local message="$1"
    echo "$(TIME) $message" | tee -a $LOG_FILE  # Записываем в лог
	}
SEND_INFO(){
	local message="$1"
	curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_INFO -d text="$message" > /dev/null
	echo "$(TIME) $message" >> $LOG_FILE
 	echo -e "$(TIME) $GREEN $message $CLEAR"
	}
SEND_ALARM(){
	local message="$1"
	curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_ALARM -d text="$message" > /dev/null
	echo "$(TIME) $message" >> $LOG_FILE
 	echo -e "$(TIME) $RED $message $CLEAR"
	}
 
REQUEST_IP(){
	sleep 0.5
	local RPC_URL="$1"
	VALIDATOR_REQUEST=$(timeout 5 solana gossip --url $RPC_URL 2>> $LOG_FILE)
	if [ $? -ne 0 ]; then 
		echo "$(TIME) Error in REQUEST_IP for RPC $RPC_URL" >> $LOG_FILE
	fi
	if [ -z "$VALIDATOR_REQUEST" ]; then
		echo "$(TIME) Error in REQUEST_IP: validator request emty" >> $LOG_FILE
	fi	
	echo "$VALIDATOR_REQUEST" | grep "$IDENTITY" | awk '{print $1}'
	}

REQUEST_DELINK(){
	sleep 0.5
	local RPC_URL="$1"
	VALIDATORS_LIST=$(timeout 5 solana validators --url $RPC_URL --output json 2>> $LOG_FILE)
	if [ $? -ne 0 ]; then 
		echo "$(TIME) Error in REQUEST_DELINK for RPC $RPC_URL" >> $LOG_FILE
	fi
	if [ -z "$VALIDATORS_LIST" ]; then 
		echo "$(TIME) Error in REQUEST_DELINK: validators list emty" >> $LOG_FILE
	fi	
	JSON=$(echo "$VALIDATORS_LIST" | jq '.validators[] | select(.identityPubkey == "'"${IDENTITY}"'" )')
	LastVote=$(echo "$JSON" | jq -r '.lastVote')
	echo "$JSON" | jq -r '.delinquent'
	}

REQUEST_ANSWER=""
Wrong_request_count=0
RPC_REQUEST() {
    local REQUEST_TYPE="$1"
    local REQUEST1 REQUEST2


    if [[ "$REQUEST_TYPE" == "IP" ]]; then
		FUNCTION_NAME="REQUEST_IP" 
	elif [[ "$REQUEST_TYPE" == "DELINK" ]]; then
        FUNCTION_NAME="REQUEST_DELINK"
	else
 		REQUEST_ANSWER=""; return
    fi    	
	rpcURL2="${RPC_LIST[$rpc_index]}" # Получаем текущий RPC URL из списка
	REQUEST1=$(eval "$FUNCTION_NAME \"$rpcURL1\"") # запрос к РПЦ соланы
	REQUEST2=$(eval "$FUNCTION_NAME \"$rpcURL2\"") # запрос к одному из РПЦ хелиуса из списка RPC_LIST
	
	# Сравнение результатов
    if [[ "$REQUEST1" == "$REQUEST2" ]]; then
        REQUEST_ANSWER="$REQUEST1";	return 
    fi    
		#echo "$(TIME) Warning! Different answers: RPC1=$REQUEST1, RPC2=$REQUEST2" >> $LOG_FILE
		# Если результаты разные, опрашиваем в цикле 10 раз
	declare -A request_count
	RQST1_counter=0; RQST2_counter=0
	for i in {1..10}; do 
		RQST1=$(eval "$FUNCTION_NAME \"$rpcURL1\"") # Вызов функции через eval
		RQST2=$(eval "$FUNCTION_NAME \"$rpcURL2\"")

		if [[ -z "$RQST1" ]]; then 
			RQST1="NULL" # Чтобы не пихать в массив пустые значения, пропишем 'NULL'
		else 
			((request_count["$RQST1"]++)) # Увеличиваем счётчики для непустых значений	
			((RQST1_counter++))
		fi

		if [[ -z "$RQST2" ]]; then 
			RQST2="NULL" 
		else 
			((request_count["$RQST2"]++)) # Увеличиваем счётчики для непустых значений
			((RQST2_counter++))	
		fi 
		echo "$(TIME) RPC1='$RQST1', RPC2='$RQST2'" >> $LOG_FILE
	done

	if [[ $RQST2_counter -eq 0 ]]; then # резервный РПЦ молчит, скорее всего кончился лимит бесплатного аккаунта Helius. 
    	((rpc_index++)) # Увеличиваем индекс, т.е. переключимся на следующий RPC сервер из списка.
		if [[ $rpc_index -ge ${#RPC_LIST[@]} ]]; then rpc_index=0; fi # проверяем, не вышли ли мы за пределы списка РПЦ серверов
		LOG "Change Helius rpc_index=$rpc_index"
	fi



	# Находим наиболее частый ответ
	most_frequent_answer=""
	max_count=0
	RQST_counter=$((RQST1_counter + RQST2_counter))

	for answer in "${!request_count[@]}"; do
		if (( request_count["$answer"] > max_count )); then
			max_count=${request_count["$answer"]}
			most_frequent_answer=$answer
		fi
	done

	if [[ -z "$most_frequent_answer" || "$most_frequent_answer" == "NULL" || $RQST_counter -lt 5 ]]; then
 		REQUEST_ANSWER=""
		LOG "Warnign! most_frequent_answer='$most_frequent_answer', RPC.1 requests=$RQST_counter, RPC.2 requests=$RQST2_counter"
		return
	else
		percentage=$(( (max_count * 100) / RQST_counter ))
		# LOG "Requests=$RQST_counter percentage=$percentage"
	fi	
		
   	if [[ $percentage -lt 70 ]]; then # не принимаем ответ, если он встречается в менее 70% запросов
  		((Wrong_request_count++))
		if [[ $Wrong_request_count -ge 5 ]]; then # дохрена ошибок запросов RPC
            SEND_ALARM "$SERV_TYPE ${NODE}.${NAME} RPC.sol='$REQUEST1'/$RQST1_counter, RPC.$rpc_index='$REQUEST2'/$RQST2_counter, differ$percentage%"
            Wrong_request_count=0  # Сбрасываем счетчик после предупреждения
        fi
		LOG "Error! Empty answer: RPC.sol='$REQUEST1'/$RQST1_counter, RPC.$rpc_index='$REQUEST2'/$RQST2_counter, dominate[$percentage%]='$most_frequent_answer'"
	 	REQUEST_ANSWER="";
	else
 		REQUEST_ANSWER="$most_frequent_answer"	
   		Wrong_request_count=0
		LOG "Warning! Different answers: RPC.sol='$REQUEST1'/$RQST1_counter, RPC.$rpc_index='$REQUEST2'/$RQST2_counter, dominate[$percentage%]='$most_frequent_answer'"
	fi
		
	# echo "$(TIME) REQUEST_ANSWER: $REQUEST_ANSWER" >>  $LOG_FILE
	}

GET_VOTING_IP(){
    # Получаем IP-адрес голосующего валидатора 
	RPC_REQUEST "IP"  
 	if [ -z "$REQUEST_ANSWER" ]; then
		LOG "Error in GET_VOTING_IP: VOTING_IP empty, keep previous value"
		return 1 
	fi
	VOTING_IP=$REQUEST_ANSWER
    SERV="$USER@$VOTING_IP"
    # Получаем локальный валидатор
    #local_validator=$(timeout 3 stdbuf -oL solana-validator --ledger $LEDGER monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}')
    local_validator=$(solana-validator --ledger $LEDGER contact-info | grep "Identity:" | awk '{print $2}') # identity
    if [[ $? -ne 0 ]]; then
        LOG "Error in GET_VOTING_IP: define local_validator"
        # return 1
    fi
	#local_validator=$(cat $HOME/tmp); LOG "local_validator=$local_validator"
    # Проверяем текущий IP и устанавливаем тип сервера
    if [[ "$CUR_IP" == "$VOTING_IP" && "$local_validator" == "$IDENTITY" ]]; then
        SERV_TYPE='PRIMARY'
    elif [[ "$local_validator" == "$EMPTY_ADDR" ]]; then
        SERV_TYPE='SECONDARY'
	else
		SERV_TYPE='UNDEFINED'
		LOG "Warning! SERV_TYPE='UNDEFINED'. 
  		CUR_IP=$CUR_IP, VOTING_IP=$VOTING_IP, 
		local_validator=$local_validator, 
  		IDENTITY=$IDENTITY, 
		EMPTY_ADDR=$EMPTY_ADDR"
    fi
	}

command_exit_status=0; command_output='' # set global variable
SSH(){
	local ssh_command="$1"
  	command_output=$(ssh -o ConnectTimeout=5 REMOTE $ssh_command 2>> $LOG_FILE)
  	command_exit_status=$?
  	if [ $command_exit_status -ne 0 ]; then
    	LOG "SSH Error: command_output=$command_output"
    	LOG "SSH Error: command_exit_status=$command_exit_status"
    	if ping -c 3 -W 3 "$REMOTE_IP" > /dev/null 2>&1; then
			LOG "remote server $REMOTE_IP ping OK"
		else
			LOG "Error: remote server $REMOTE_IP did not ping"
			if ping -c 3 -W 3 "www.google.com" > /dev/null 2>&1; then
				LOG "Google ping OK"
			else
				LOG "Error: Google did not ping too"
			fi
		fi
		if [ $((current_time - ssh_alarm_time)) -ge 120 ]; then
      		SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: SSH Error $REMOTE_IP"
      		ssh_alarm_time=$current_time
    	fi
  	fi
	}

health_counter=0
behind_counter=0
remote_behind_counter=0
slots_remaining=0
disconnect_counter=0
CHECK_HEALTH() { # self check health every 5 seconds  ###########################################
 	# check behind slots
 	Request_OK='true'
	RPC_SLOT=$(timeout 5 solana slot -u $rpcURL1 2>> $LOG_FILE)
 	if [[ -z "$RPC_SLOT" ]]; then
  		echo "$(TIME) RPC_SLOT request empty from $rpcURL1, try from $rpcURL2" >> $LOG_FILE
    	RPC_SLOT=$(timeout 5 solana slot -u "$rpcURL2" 2>> "$LOG_FILE")
	fi
	if [[ $? -ne 0 ]]; then 
 		Request_OK='false'; 
   		echo "$(TIME) Error in solana slot RPC request" >> $LOG_FILE
	fi
	LOCAL_SLOT=$(timeout 5 solana slot -u localhost 2>> $LOG_FILE)
 	if [[ $? -ne 0 ]]; then 
  		Request_OK='false'; 
		LOG "Error in solana slot localhost request" 
  	fi
	if [[ $Request_OK == 'true' && -n "$RPC_SLOT" && -n "$LOCAL_SLOT" ]]; then 
 		BEHIND=$((RPC_SLOT - LOCAL_SLOT)); 
   	else
   		BEHIND=555;
   	fi
	sleep 1
	# epoch info
	EPOCH_INFO=$(timeout 5 solana epoch-info --output json 2>> $LOG_FILE)
	if [[ $? -ne 0 ]]; then
    	echo "$(TIME) Error retrieving epoch info: $EPOCH_INFO" >> $LOG_FILE
	 	SLOTS_UNTIL_EPOCH_END=0
	else
		SLOTS_IN_EPOCH=$(echo "$EPOCH_INFO" | jq '.slotsInEpoch')
		SLOT_INDEX=$(echo "$EPOCH_INFO" | jq '.slotIndex')
		SLOTS_UNTIL_EPOCH_END=$(echo "$SLOTS_IN_EPOCH - $SLOT_INDEX" | bc)
 	fi
	# next slot time
 	output=$(timeout 5 solana leader-schedule -v 2>> $LOG_FILE)
	if [[ $? -ne 0 ]]; then
		echo "$(TIME) Error in leader schedule request" >> $LOG_FILE
  		Request_OK='false';
	else
		my_slot=$(echo "$output" | grep "$IDENTITY" | awk -v var="$RPC_SLOT" '$1 >= var' | head -n1 | cut -d ' ' -f3)
  		if [[ $? -ne 0 ]]; then
			echo "$(TIME) Error processing leader schedule request output" >> $LOG_FILE
   			Request_OK='false';
	  	fi
	fi
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
   		HEALTH="RequestError!"
	 	LOG "Error, health request=$REQUEST " 
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
		LOG "Health=$HEALTH, health_counter=$health_counter, CHECK_UP=$CHECK_UP    "  # log every warning_message
		if [[ $health_counter -ge 1 && $HEALTH != "behind" ]]; then # 
			health_counter=-$WARNING_FREQUENCY
			SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: Health: $HEALTH"
		fi
	fi  
	
	# check behind
	if [[ $BEHIND -le $BEHIND_OK_VAL ]]; then #  && $BEHIND -gt -1000  проверка на "число" и -1000<BEHIND<1 
		behind_counter=0
  		BEHIND_PRN="$GREEN$BEHIND"
	else
		CHECK_UP='false'
  		let behind_counter=behind_counter+1
		LOG "Behind=$BEHIND    "  # log every warning_message
		BEHIND_PRN="$RED$BEHIND"
		if [[ $behind_counter -ge 3 ]] && [[ $BEHIND -ge $BEHIND_OK_VAL ]]; then # 
			behind_counter=-$WARNING_FREQUENCY # sent next message after  12*5 seconds
	 		if [[ $BEHIND_WARNING == 'true' ]]; then SEND_ALARM "$SERV_TYPE ${NODE}.${NAME}: Behind=$BEHIND";
			else SEND_INFO "$SERV_TYPE ${NODE}.${NAME}: Behind=$BEHIND"; fi
		fi
	fi
	REMOTE_BEHIND=$(cat $HOME/remote_behind)
	if [[ $REMOTE_BEHIND -le $BEHIND_OK_VAL ]]; then #  && $REMOTE_BEHIND -gt -1000 проверка на "число" и -1000<REMOTE_BEHIND<1
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
        LOG "connection failed, attempt $disconnect_counter"
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
  		sleep 1
	done
	LOG "PRIMARY status ended"
 	sleep 20
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
			set_primary=2; 	REASON="Delinquent"; LOG "Warning!$RED Delinquent detected! $CLEAR"
		fi
		if [[ $behind_threshold -ge 1 ]] && [[ $remote_behind_counter -ge $behind_threshold ]]; then
			set_primary=2; 	REASON="Behind too long"; LOG "Warning! Behind detected! "
		fi
		if [[ $primary_mode == "permanent_primary" && next_slot_time -ge 1 ]]; then
			set_primary=2; 	REASON="set Permanent Primary mode"; 
		fi	
		CHECK_HEALTH #  self check node health
  		GET_VOTING_IP
  		if [[ "$SERV_TYPE" == "PRIMARY" ]]; then
    		return
       	fi
	done
		# STOP SOLANA on REMOTE server
  	LOG "Let's stop voting on remote server "
   	LOG "CHECK_UP=$CHECK_UP, HEALTH=$HEALTH, BEHIND=$BEHIND, REASON=$REASON, set_primary=$set_primary, Delinquent=$Delinquent, VOTING_IP=$VOTING_IP  "
	SEND_INFO "${NODE}.${NAME}: switch voting from ${VOTING_IP} $REASON" # \n%s vote_off remote server
	switch_start_time=$(($(date +%s%N) / 1000000)) #
 	SSH "$SOL_BIN/solana-validator -l $LEDGER set-identity $EMPTY_KEY 2>&1"
	if [ $command_exit_status -eq 0 ]; then
		SEND_INFO "set empty identity on REMOTE server"
	else
		SEND_ALARM "Can't set identity on remote server"
  		LOG "Try to restart solana on remote server"
		SSH "systemctl restart solana 2>&1"
    	if [ $command_exit_status -eq 0 ]; then
			SEND_INFO "restart solana on remote server"
      	else
			SEND_ALARM "Can't restart solana on REMOTE server"
			if ping -c 3 -W 3 "$REMOTE_IP" > /dev/null 2>&1; then
   				LOG "Remote server ping OK, so can't start voting in current situation"
				return
			fi
			SEND_ALARM "Can't ping REMOTE server"
		fi
	fi
 	LOG "Let's start voting on current server"

	# remove old tower
	#if [[ -f $LEDGER/tower-1_9-$IDENTITY.bin ]]; then
	#	rm $LEDGER/tower-1_9-$IDENTITY.bin 
	#	if [ $? -eq 0 ]; then LOG "remove old tower OK"
	#	else LOG "remove old tower Error: $remove_status"
	#	fi
	#fi

	# copy tower from remote server
	timeout 5 scp -P $PORT -i $KEYS/*.ssh -p $SERV:$LEDGER/tower-1_9-$IDENTITY.bin $LEDGER
	copy_status=$?
	if [ $copy_status -eq 0 ]; then LOG "copy tower from $SERV OK"
	elif [ $copy_status -eq 124 ]; then LOG "Error! Copy tower from $SERV timeout exceed"
	else LOG "Error! Copy tower from $SERV $copy_status"
	fi

 	# check tower age
  	time_diff=200000
  	if [[ -f $LEDGER/tower-1_9-$IDENTITY.bin ]]; then
		current_time=$(($(date +%s%N) / 1000000)) # текущее время в миллисекундах
		last_modified=$(($(date -r "$LEDGER/tower-1_9-$IDENTITY.bin" +%s%N) / 1000000)) # время последнего изменения файла в миллисекундах
		time_diff=$((current_time - last_modified)); 
  		time_diff=$(echo "scale=2; $time_diff / 1000" | bc) # convert to seconds
	fi	

 	# check, if remote validator 'changing' / 'stop voting'
	SSH "$SOL_BIN/solana-validator --ledger '$LEDGER' contact-info" # get remote validator info
	remote_validator=$(echo "$command_output" | grep "Identity:" | awk '{print $2}') # get remote voting identity
	if [[ "$remote_validator" == "$IDENTITY" ]]; then
		SEND_ALARM "Error! remote_validator still voting, so try to start voting later"
		LOG "remote_validator=$remote_validator, IDENTITY=$IDENTITY"
		return
	else
		LOG "remote_validator change OK, so can start voting"
	fi
   
   # START SOLANA on LOCAL server
   	if (( $(echo "$time_diff >= 120.000" | bc -l) )); then # more than 120 seconds
		SEND_ALARM "tower too old = ${time_diff}s"
   		TOWER_STATUS=' without tower'; 	
	 	solana-validator -l $LEDGER set-identity $VOTING_KEY;
	else
	  	TOWER_STATUS=" with tower/${time_diff}s"; 	
		solana-validator -l $LEDGER set-identity --require-tower $VOTING_KEY;
	fi
 	
	set_identity_status=$?
	switch_stop_time=$(($(date +%s%N) / 1000000))
  	switch_time=$((switch_stop_time - switch_start_time))
   	switch_time=$(echo "scale=2; $switch_time / 1000" | bc) # convert to seconds
 	if [ $set_identity_status -eq 0 ]; then 
		SEND_INFO "Start voting$TOWER_STATUS for ${switch_time}s"
	else 
		SEND_ALARM "Start voting Error: $set_identity_status, can't set identity"
  		return
	fi
 	
	# stop relayer service on remote server
 	if [[ $RELAYER_SERVICE == 'true' ]]; then 
 		SSH "systemctl stop relayer.service" 
   		if [ $command_exit_status -eq 0 ]; then LOG "stop relayer on remote server OK"
		elif [ $command_exit_status -eq 124 ]; then LOG "stop relayer on remote server timeout exceed"
 		else LOG "stop relayer on remote server Error"
		fi
		systemctl start relayer.service
  		LOG "restart relayer service"
	fi
	### stop telegraf service on remote server
	SSH "systemctl stop telegraf"
	if [ $command_exit_status -eq 0 ]; then LOG "stop telegraf on remote server OK"
	elif [ $command_exit_status -eq 124 ]; then LOG "stop telegraf on remote server timeout exceed"
 	else LOG "stop telegraf on remote server Error"
	fi
	### start telegraf service on local server
 	systemctl start telegraf
  	if [[ $? -ne 0 ]]; then LOG "Error! start telegraf"
   	else LOG "start telegraf OK"
	fi
	LOG "waiting for PRIMARY status"
 	sleep 2
	#while [ $SERV_TYPE = "SECONDARY" ]; do
 		# LOG "waiting for PRIMARY status"
   		#GET_VOTING_IP
     	#CHECK_HEALTH
 	#done
	}

##########################################################################

echo ""; echo "";
echo -e " == SOLANA GUARD $BLUE$GUARD_VER $CLEAR ==  " | tee -a $LOG_FILE
#source ~/sol_git/setup/check.sh
GET_VOTING_IP
echo "ledger path: [$LEDGER]"
echo "voting  IP=$VOTING_IP" | tee -a $LOG_FILE
echo "current IP=$CUR_IP" | tee -a $LOG_FILE
echo -e "IDENTITY  = $GREEN$IDENTITY $CLEAR" | tee -a $LOG_FILE
echo -e "empty addr = $GRAY$EMPTY_ADDR $CLEAR" | tee -a $LOG_FILE
if [[ -z "$rpc_index" ]]; then # rpc_index not defined
	echo "rpc_index not defined in $LOG_FILE, set default value rpc_index=0"
	rpc_index=0; # Устанавливаем значение по умолчанию
fi
echo " Helius rpc_index=$rpc_index, rpcURL list:"
for rpcURL in "${RPC_LIST[@]}"; do
	echo -e "$GRAY$rpcURL$CLEAR" | tee -a $LOG_FILE
done
rpcURL2="${RPC_LIST[$rpc_index]}" # Получаем текущий RPC URL из списка
if [ -z "$NAME" ]; then NAME=$(hostname); fi
if [ $rpcURL1 = https://api.testnet.solana.com ]; then 
NODE="test"
elif [ $rpcURL1 = https://api.mainnet-beta.solana.com ]; then 
NODE="main"
fi
echo -e " $BLUE$NODE.$NAME $YELLOW$version $client $CLEAR"


# GET_VOTING_IP
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
if [[ "$SERV_TYPE" == "PRIMARY" ]]; then # PRIMARY can't determine REMOTE_IP of SECONDARY
	if [ -f $HOME/remote_ip ]; then # SECONDARY should have written its IP to PRIMARY
		REMOTE_IP=$(cat $HOME/remote_ip) # echo "get REMOTE_IP of SECONDARY_SERVER from $HOME/remote_ip: $REMOTE_IP"
	else 
		REMOTE_IP=''	
	fi
	if [[ -z $REMOTE_IP ]]; then # if $REMOTE_IP empty
		echo -e "Warning! Run guard on SECONDARY server first to get it's IP"
		return
	fi
elif [[ "$SERV_TYPE" == "SECONDARY" ]]; then # SECONDARY
	REMOTE_IP=$VOTING_IP # it's true for SECONDARY
else
	echo -e "Warning! Server type (PRIMARY/SECONDARY) undefined"
	echo "local_validator=$local_validator"
	echo "SERV_TYPE=$SERV_TYPE"
	return	
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

# check remote server SSH connection (by reading Identity addr)
SSH "$SOL_BIN/solana address"
remote_identity=$command_output
if [ $command_exit_status -ne  0 ]; then
	echo -e "$RED SSH connection not available  $CLEAR" 
	return
fi

if [ "$remote_identity" = "$IDENTITY" ]; then
	echo -e "$GREEN SSH connection succesful $CLEAR" | tee -a $LOG_FILE
else
    echo -e "$RED Warning! Servers identities are different $CLEAR"
	echo "Current Identity = $IDENTITY"
	echo "Remote Identity  = $remote_identity"
	return
fi

# check remote server validator addr
SSH "$SOL_BIN/solana-validator --ledger '$LEDGER' contact-info" # get remote validator info
remote_validator=$(echo "$command_output" | grep "Identity:" | awk '{print $2}') # get remote voting identity
if [ -z "$remote_validator" ]; then
	echo -e "$RED remote_validator is missing  $CLEAR"
	echo "is remote server running?"	
	return
fi

# check remote empty addr
SSH "$SOL_BIN/solana address -k $EMPTY_KEY"
remote_empty=$command_output
if [ -z "$remote_empty" ]; then
	echo -e "$RED remote_empty_key is missing  $CLEAR"	
	return
fi

# check remote status
if [[ "$remote_validator" == "$IDENTITY" ]]; then
	REMOTE_SERVER_STATUS="Primary"
elif [[ "$remote_validator" == "$remote_empty" ]]; then
	REMOTE_SERVER_STATUS="Secondary"
else
	echo -e "$RED remote server unknown status  $CLEAR" 
	return
fi

echo -e "$GREEN remote server checkup successfully complete $CLEAR" | tee -a $LOG_FILE
LOG " remote identity  = $remote_identity"
LOG " remote validator = $remote_validator"
LOG " remote empty_adr = $remote_empty"
LOG " remote IP = $REMOTE_IP"
LOG " remote server is $REMOTE_SERVER_STATUS"

echo '0' > $HOME/remote_behind # update local file for stop alarm next 600 seconds
SSH "echo '$CUR_IP' > $HOME/remote_ip" # send 'current IP' to remote server

while true  ###  main cycle   #################################################
do
	GET_VOTING_IP
	if [[ "$SERV_TYPE" == "PRIMARY" ]]; then
		PRIMARY_SERVER
	elif [[ "$SERV_TYPE" == "SECONDARY" ]]; then
		SECONDARY_SERVER
	else
		SEND_ALARM "Server type undefined"	
	fi	
done
