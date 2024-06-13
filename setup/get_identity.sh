#!/bin/bash
GRAY=$'\033[90m'; GREEN=$'\033[32m'; RED=$'\033[31m'

# write private_key to validator-keypair.json
if [[ -z $private_key ]]; then # if $private_key is empty
		echo -e "WARNING !"
    echo -e "\033[31m private_key is empty, run node_set \033[0m" 
    Identity_Addr="empty"
else
  echo $private_key>~/keys/validator.json
  Identity_Addr=$(solana address -k ~/keys/validator.json)
fi
# check validator-keypair.json address
if [ "$Identity_Addr" = "$validator_key" ]; then
    echo -e " set private_key $GREEN $NODE.$NAME \033[0m"
    KEY_CLR=$GREEN  
else
    echo -e "WARNING ! Wrong private_key=${private_key:0:9}...${private_key: -9}, run node_set "
    echo -e "$NAME key =$GREEN $validator_key \033[0m"
    echo -e "your key =$RED $Identity_Addr \033[0m" 
    KEY_CLR=$RED  
fi
# echo private_key=$private_key
sleep 10
echo "Hello, World!">~/keys/validator.json
shred -u ~/keys/validator.json
