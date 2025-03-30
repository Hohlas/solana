#!/bin/bash
BEHIND_VER=v1.1.2
#===================++++++++++========================
LOG_FILE=$HOME/behind.log
BEHIND_OK_VAL=1 # behind, that seemed ordinary
#======================================================
rpcURL1=$(solana config get | grep "RPC URL" | awk '{print $3}')
GRAY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CLEAR=$'\033[0m'



TIME() {
	TZ=Europe/Moscow date +"%b %e  %H:%M:%S"
	}
LOG() {
    local message="$1"
    echo "$(TIME) $message" >> $LOG_FILE  # Записываем в лог
    echo "$(TIME) $message"
	}
 
echo -e " == SOLANA BEHIND $BLUE$BEHIND_VER $CLEAR ==  " | tee -a $LOG_FILE

while true  ###  main cycle   #################################################
do
 	Request_OK='true'
	RPC_SLOT=$(timeout 5 solana slot -u $rpcURL1 2>> $LOG_FILE)
 	if [[ -z "$RPC_SLOT" ]]; then
  		echo "$(TIME) RPC_SLOT request empty from $rpcURL1" >> $LOG_FILE
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
	sleep 2
	
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
	
	if [[ $HEALTH == "ok" ]]; then
		HEALTH_PRN="$GREEN$HEALTH"
	else
		HEALTH_PRN="$RED$HEALTH"
		LOG "Health=$HEALTH "  # log every warning_message
	fi  
	
	# check behind
	if [[ $BEHIND -le $BEHIND_OK_VAL ]]; then #  && $BEHIND -gt -1000  проверка на "число" и -1000<BEHIND<1 
  		BEHIND_PRN="$GREEN$BEHIND"
	else
		LOG "Behind=$BEHIND    "  # log every warning_message
		BEHIND_PRN="$RED$BEHIND"
	fi
	echo -ne "$(TZ=Europe/Moscow date +"%H:%M:%S")  behind:$BEHIND_PRN$CLEAR, health $HEALTH_PRN$CLEAR        \r"

done
