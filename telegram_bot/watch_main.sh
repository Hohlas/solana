#!/bin/bash
# мониторинг нод, ставится на удаленный сервер.
export LC_NUMERIC="en_US.UTF-8"
SOLANA_PATH="$HOME/.local/share/solana/install/active_release/bin/solana" #Поменять на свой путь к active_release. обрати вниманеи что путь со словом "solana" его не удалять!!!
#Cluster: m-mainnet-beta или t-testnet
CLUSTER=m
#если хочешь 1 ноду то в скобках указывается только один pub,vote,ip,TEXT и т.д. Добавить можно сколько угодно нод но каждый новый параметр через пробел!  
PUB_KEY=(5NiHw5LZn1FiL848XzbEBxuygbNvMJ7CsPvXNC8VmCLN AptafqHRpGk3KCQrGtuPGuPvWMuPc4N15X7NN7VUsfbd A4fxKaaNPBCaMwqKyhHxoWKJ5ybgvmmwTQmNmGtt2aoC 9SjGU3tzdEXfLaVsLpnTwP3inBNhAPMq4XKupUf9Ms5E)
VOTE=(5WVvtQDDd3Gsdm3eyDrRAczP9greGmdBjNoyD93iYw9F 3FLezD8GJgnawEHhZcsjdPxZVar9FzqEdViusQ5ZdSwe 9esjPxaUdD7yg4yDrBkP3jLipcAGVjpLDXsddF89avzW HG574XwiowrjLx8h91KhHUhPeMfmUPBLfC9XrXynj9x)
IP=(149.50.110.199 149.50.110.94 149.50.110.231 80.77.161.200)
#==== tg_bot_token ====
# CHAT_ALARM=-100...684
# CHAT_INFO=-100...888
# BOT_TOKEN=507...lWU
#======================
source $HOME/keys/tg_bot_token # get CHAT_ALARM, CHAT_INFO, BOT_TOKEN
NODE_NAME=("BUKA" "HOHLA" "VALERA" "Stepan")
BALANCEWARN=(1 1 1 1) # если меньше этого числа на балансе то будет тревожное сообщение!
echo -e
date
for index in ${!PUB_KEY[*]}
do
    PING=$(ping -c 3 ${IP[$index]} | grep transmitted | awk '{print $4}')
    DELINQUEENT=$($SOLANA_PATH -u$CLUSTER validators --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY[$index]}"'" ) | .delinquent ')
    BALANCE_TEMP=$($SOLANA_PATH balance ${PUB_KEY[$index]} -u$CLUSTER | awk '{print $1}')
    BALANCE=$(printf "%.2f" $BALANCE_TEMP)
      
    if (( $(bc <<< "$BALANCE < ${BALANCEWARN[$index]}") && $(bc <<< "$BALANCE != 0") ));  then
    curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ALARM"'","text":" '"Balance! "' '"${NODE_NAME[$index]}"' '"\nBalance=$BALANCE"'"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" 
    fi
    if [[ $PING == 0 ]]; then
	curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ALARM"'","text":" '"No Ping! "' '"${NODE_NAME[$index]}"'"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    fi
	if [[ $DELINQUEENT == true ]]; then
	curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ALARM"'","text":" '"Delinq! "'  '"${NODE_NAME[$index]}"'"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    fi
done

if (( $(echo "$(date +%M) < 10" | bc -l) )); then
INFO=""
for index in ${!PUB_KEY[*]}
do
	Credits=$($SOLANA_PATH -u$CLUSTER validators --output json-compact | jq '.validators[] | select(.identityPubkey == "'"${PUB_KEY[$index]}"'" ) | .epochCredits ')
#dali blokov
    All_block=$($SOLANA_PATH leader-schedule -u$CLUSTER | grep ${PUB_KEY[$index]} | wc -l)
#done,skipnul, skyp%
    STRING2=$($SOLANA_PATH -v block-production -u$CLUSTER | grep ${PUB_KEY[$index]} | awk 'NR == 1'| awk '{print $2,$4,$5}')
    Done=$(echo "$STRING2" | awk '{print $1}')
    if [[ -z "$Done" ]]; then Done=0
        fi
    skipped=$(echo "$STRING2" | awk '{print $2}')
    if [[ -z "$skipped" ]]; then skipped=0
        fi
    skip=$(echo "$STRING2" | awk '{print $3}')
    if [[ -z "$skip" ]]; then skip=0%
        fi
    Average=$($SOLANA_PATH validators -u$CLUSTER | grep "Average Stake-Weighted Skip Rate" | awk '{print $5}')
    if [[ -z "$Average" ]]; then Average=0%
        fi
    BALANCE_TEMP=$($SOLANA_PATH balance ${PUB_KEY[$index]} -u$CLUSTER | awk '{print $1}')
    BALANCE=$(printf "%.2f" $BALANCE_TEMP) 
    score=$($SOLANA_PATH -u$CLUSTER validators --sort=credits -r -n | grep ${PUB_KEY[$index]} | awk '{print $1}'); 
    INFO="${INFO}"$'\n'"${NODE_NAME[$index]}"": $skip | $score"
done
    echo "${INFO}"
    RESPONSE_EPOCH=$($SOLANA_PATH epoch-info -u$CLUSTER > ~/temp.txt)
    EPOCH=$(cat ~/temp.txt | grep "Epoch:" | awk '{print $2}')
    EPOCH_PERCENT=$(printf "%.2f" $(cat ~/temp.txt | grep "Epoch Completed Percent" | awk '{print $4}' | grep -oE "[0-9]*|[0-9]*.[0-9]*" | awk 'NR==1 {print; exit}'))"%"
    END_EPOCH=$(echo $(cat ~/temp.txt | grep "Epoch Completed Time" | grep -o '(.*)' | sed "s/^(//; s/ remaining)//; s/ \([0-9]*s\)//"))   
curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_INFO"'","text":"<b>'"${INFO}"' '"\n AvgSkip: "$Average""' </b> <code>
End: '"$END_EPOCH"'</code>", "parse_mode": "html"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
    fi
