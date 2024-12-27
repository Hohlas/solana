#!/bin/bash
GUARD_VER=v1.6.0
#=================== guard.cfg ========================
PORT='2010' # remote server ssh port
KEYS=$HOME/keys
LEDGER=$HOME/solana/ledger
LOG_FILE=$HOME/guard.log
SOLANA_SERVICE="$HOME/solana/solana.service"
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

	# Сохранение IP-адресов валидаторов в файл
    echo "$VALIDATOR_REQUEST" | awk '{print $1}' > ~/validator_ips.txt
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
    #local_validator=$(timeout 3 stdbuf -oL solana-validator --ledger "$LEDGER" monitor 2>/dev/null | grep -m1 Identity | awk -F': ' '{print $2}')
    local_validator=$(solana-validator --ledger $HOME/solana/ledger contact-info | grep "Identity:" | awk '{print $2}') # identity
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
	




echo -e "start $YELLOW firewall  $CLEAR"
RPC_REQUEST "IP" 


# Укажите интерфейс, который вы хотите мониторить
#INTERFACE="enp5s0"
INTERFACE=$(ip link show | awk '/^[0-9]+: / {print $2}' | tr -d ':' | xargs -I {} ip addr show {} | awk '/state UP/ {print $2; exit}' | tr -d ':')
# Укажите файл, в который будут записаны IP-адреса
OUTPUT_FILE="$HOME/ip_addresses.txt"

# Укажите файл с IP-адресами валидаторов
VALIDATOR_FILE="$HOME/validator_ips.txt"

# Укажите файл для списка потенциальных DDoS-атак
DDoS_LIST_FILE="$HOME/DDOS_LIST.txt"

# Функция для поиска DDoS-атак
DDOS_SEARCH() {
    # Получаем список IP-адресов с помощью ss, игнорируя заголовки
    iftop -i "$INTERFACE" -t -s 10 | grep -oP '(\d{1,3}\.){3}\d{1,3}' | sort -u > "$OUTPUT_FILE"
    ss -tnp | awk 'NR > 1 {print $5}' | cut -d: -f1 | sort -u > "$OUTPUT_FILE"

    echo "Список IP-адресов сохранен в файле $OUTPUT_FILE"

    # Проверка каждого IP-адреса на наличие в списке валидаторов
    while read -r ip; do
        echo "read ip $ip"
        if ! grep -q "$ip" "$VALIDATOR_FILE"; then
            # Проверка на наличие IP в списке DDoS
            if ! grep -q "$ip" "$DDoS_LIST_FILE"; then
                echo "$(TIME) $ip" >> "$DDoS_LIST_FILE"
                echo "Добавлен в DDoS список: $ip"
            fi
        fi
    done < "$OUTPUT_FILE"
}

# Основной цикл
while true; do
    DDOS_SEARCH
    sleep 1  # Задержка между итерациями (например, 5 секунд)
done



while true  ###  main cycle   #################################################
do
	echo "h"
	sleep 2
done
