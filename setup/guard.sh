#!/bin/bash

PORT='2010'
PUB_KEY=$(solana-keygen pubkey ~/solana/validator-keypair.json)
SOL=$HOME/.local/share/solana/install/active_release/bin
rpcURL=$(solana config get | grep "RPC URL" | awk '{print $3}')
version=$(solana --version | awk '{print $2}')
client=$(solana --version | awk -F'client:' '{print $2}' | tr -d ')')
CUR_IP=$(wget -q -4 -O- http://icanhazip.com)
SITES=("www.google.com" "www.bing.com")
#SITES=("www.googererle.com" "www.bindfgdgg.com") # uncomment to check CHECK_CONNECTION()
CONNECTION_LOSS_SCRIPT="$HOME/sol_git/setup/vote_off.sh"
DISCONNECT_COUNTER=0
SERV='root@'$(solana gossip | grep $PUB_KEY | awk '{print $1}')
SERV_TYPE='Secondary'
IP=$(echo "$SERV" | cut -d'@' -f2) # cut IP from root@IP
#===
BOT_TOKEN=5076252443:AAF1rtoCAReYVY8QyZcdXGmuUOrNVICllWU
CHAT_ALARM=-1001611695684
CHAT_INFO=-1001548522888
GREY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'

echo ' == SOLANA GUARD =='
#source ~/sol_git/setup/check.sh
echo 'voting  IP='$IP
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
last_missage_time=12
CHECK_HEALTH() { # self check health every 5 seconds
 	# check behind slots
 	WARN_MSG="" # set warning_message empty
  RPC_SLOT=$(solana slot -u $rpcURL)
	LOCAL_SLOT=$(solana slot -u localhost)
  BEHIND=$((RPC_SLOT - LOCAL_SLOT))
  if [[ $BEHIND -lt 1 ]]; then # if BEHIND<1 it's OK
		behind_warning=0
  else
    let behind_warning=behind_warning+1
		WARN_MSG="Behind=$BEHIND"
	fi
 
 	# check health
 	HEALTH=$(curl -s http://localhost:8899/health)
	if [[ -z $HEALTH ]]; then # if $HEALTH is empty (must be 'ok')
		HEALTH="Warning!"
	fi
  if [[ $HEALTH == "ok" ]]; then
  	health_warning=0
  else
  	let health_warning=health_warning+1
    WARN_MSG="Health: $HEALTH"
  fi  

 # send missage if behind or unhealth status
 let last_missage_time=last_missage_time+1
 if [[ ! -z $WARN_MSG ]]; then # if warning_message not empty 
    echo "$WARN_MSG $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log  # log every warning_message
		if [ $health_warning -ge 3 ] || [ $behind_warning -ge 3 ]; then # if any warning_messages > 3 
			if [[ $last_missage_time -ge 12 ]]; then # if last warning_message was sent later than a minute
				last_missage_time=0 # next tg messages every 12*5 seconds
				echo "send message $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log  # log every warning_message
				curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_ALARM -d text="$SERV_TYPE ${NODE}.${NAME}: $WARN_MSG" > /dev/null
  		fi
		fi
  fi
  }


CHECK_CONNECTION() { # self check connection every 5 seconds
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
    # connection loss for 20 seconds (5sec * 4)
    if [ $DISCONNECT_COUNTER -ge 4 ]; then
        echo "CONNECTION LOSS"
        bash "$CONNECTION_LOSS_SCRIPT"
        echo "RESTART SOLANA $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log
        systemctl restart solana && echo -e "\033[31m restart solana \033[0m"
        systemctl stop jito-relayer.service && echo -e "\033[31m stop jito-relayer \033[0m"
    fi
  }



if [ "$CUR_IP" == "$IP" ]; then
  echo -e "\n = PRIMARY  SERVER ="
  MSG=$(printf "Primary server start \n%s ${NODE}.${NAME} \n%s on $CUR_IP")
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_INFO -d text="$MSG" > /dev/null
  echo "$MSG $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log
  SERV_TYPE='Primary'
  # CHECK_CONNECTION_LOOP 
  until [ $DISCONNECT_COUNTER -ge 4 ]; do
    CHECK_CONNECTION
    CHECK_HEALTH
    SERV='root@'$(solana gossip | grep $PUB_KEY | awk '{print $1}')
    IP=$(echo "$SERV" | cut -d'@' -f2) # cu
    if [ "$CUR_IP" != "$IP" ]; then
	echo -e "$RED VOTING IP change to $IP \033[0m  $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S") MSK         \r"
	echo "VOTING IP change to $IP $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S") MSK" >> ~/guard.log
	# exit
    fi
    if [[ $HEALTH == "ok" ]]; then
      CLR=$GREEN
    else
      CLR=$RED
    fi
    echo -ne " Check connection $(TZ=Europe/Moscow date +"%H:%M:%S") MSK,${CLR} Health $HEALTH   \r \033[0m"
    sleep 5
  done
  exit
fi

echo -e "\n = SECONDARY  SERVER ="
chmod 600 ~/keys/*.ssh
eval "$(ssh-agent -s)"  # Start ssh-agent in the background
ssh-add ~/keys/*.ssh # Add SSH private key to the ssh-agent

# create ssh alias for remote server
echo " 
Host REMOTE
HostName $IP
User root
Port $PORT
IdentityFile /root/keys/*.ssh
" > ~/.ssh/config

# check SSH connection with primary node server
command_output=$(ssh REMOTE 'echo "SSH connection succesful" > ~/check_ssh')
command_exit_status=$?
if [ $command_exit_status -eq 0 ]; then
  echo "ok"
else
  echo -e "$RED SSH connection can not be established  \033[0m"
  exit
fi
scp -P $PORT -i /root/keys/*.ssh $SERV:~/check_ssh ~/
ssh REMOTE rm ~/check_ssh
echo -e "\033[32m$(cat ~/check_ssh)\033[0m"
rm ~/check_ssh

echo "  Start monitoring $(TZ=Europe/Moscow date +"%b %e %H:%M:%S") MSK"
MSG=$(printf "Secondary server start \n%s ${NODE}.${NAME} \n%s on $CUR_IP")
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_INFO -d text="$MSG" > /dev/null
echo "$MSG $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log
# waiting remote server fail
Delinquent=false
until [[ $Delinquent == true ]]; do
  JSON=$(solana validators --url $rpcURL --output json-compact 2>/dev/null | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY}"'" )')
  LastVote=$(echo "$JSON" | jq -r '.lastVote')
  Delinquent=$(echo "$JSON" | jq -r '.delinquent')
  CHECK_HEALTH #  check primary node health
  if [[ $HEALTH == "ok" ]]; then
      CLR=$GREEN
  else
     CLR=$RED
  fi
  echo -ne " Looking for ${NODE}.${NAME}. LastVote=$LastVote $(TZ=Europe/Moscow date +"%H:%M:%S") MSK,${CLR}  Health $HEALTH     \r \033[0m"
  sleep 5
done

echo -e "\033[31m  REMOTE server fail at $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S") MSK          \033[0m"

# STOP SOLANA on REMOTE server
MSG=$(printf "${NODE}.${NAME} RESTART ${IP} \n%s STOP REMOTE SERVER:")
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
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -d chat_id=$CHAT_ALARM -d text="$MSG" > /dev/null
echo "$MSG $(TZ=Europe/Moscow date +"%b %e  %H:%M:%S")" >> ~/guard.log
# solana-validator --ledger ~/solana/ledger monitor
# ssh REMOTE $SOL/solana-validator --ledger ~/solana/ledger monitor
#ssh REMOTE $SOL/solana catchup ~/solana/validator_link.json --our-localhost
