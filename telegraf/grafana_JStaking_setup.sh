#!/bin/bash
#set -x -e

echo "###################### WARNING!!! ######################"
echo "###   This script will install and/or reconfigure    ###"
echo "### telegraf and point it to solana.thevalidators.io ###"
echo "########################################################"
ln -sf ~/keys/${NAME,,}_${NODE,,}_vote.json ~/solana/vote-account-keypair.json



  
  if [[ $NODE == "main" ]]; then
    inventory="mainnet.yaml";
  elif [[ $NODE == "test" ]]; then
     inventory="testnet.yaml"; 
    else
    echo -e "\033[31m Warning, unknown node type: $NODE \033[0m"
    exit
    fi
  
  # echo "### Please type your validator name: "
  VALIDATOR_NAME=$NAME
  # echo "### Please type the full path to your validator keys: "
  PATH_TO_VALIDATOR_KEYS="/root/solana"

  if [ ! -f "$PATH_TO_VALIDATOR_KEYS/validator-keypair.json" ]
  then
    echo "key $PATH_TO_VALIDATOR_KEYS/validator-keypair.json not found. Pleas verify and run the script again"
    exit
  fi

  read -e -p "### Please tell which user is running validator: " SOLANA_USER
  cd
  rm -rf sv_manager/

  if [[ $(which apt | wc -l) -gt 0 ]]
  then
  pkg_manager=apt
  elif [[ $(which yum | wc -l) -gt 0 ]]
  then
  pkg_manager=yum
  fi

  echo "### Update packages... ###"
  $pkg_manager update
  echo "### Install ansible, curl, unzip... ###"
  $pkg_manager install ansible curl unzip --yes
  
  # fix for eventually hanging of pip
  export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring

  ansible-galaxy collection install ansible.posix
  ansible-galaxy collection install community.general

  echo "### Download Solana validator manager"
  cmd="https://github.com/mfactory-lab/sv-manager/archive/refs/tags/$1.zip"
  echo "starting $cmd"
  curl -fsSL "$cmd" --output sv_manager.zip
  echo "### Unpack Solana validator manager ###"
  unzip ./sv_manager.zip -d .

  mv sv-manager* sv_manager
  rm ./sv_manager.zip
  cd ./sv_manager || exit
  cp -r ./inventory_example ./inventory

  #echo $(pwd)
  ansible-playbook --connection=local --inventory ./inventory/$inventory --limit localhost  playbooks/pb_config.yaml --extra-vars "{ \
  'solana_user': '$SOLANA_USER', \
  'validator_name':'$VALIDATOR_NAME', \
  'local_secrets_path': '$PATH_TO_VALIDATOR_KEYS' \
  }"

  ansible-playbook --connection=local --inventory ./inventory/$inventory --limit localhost  playbooks/pb_install_monitoring.yaml --extra-vars "@/etc/sv_manager/sv_manager.conf"

  echo "### Cleanup install folder ###"
  cd ..
  rm -r ./sv_manager
  echo "### Cleanup install folder done ###"
  echo "### Check your dashboard: https://solana.thevalidators.io/d/e-8yEOXMwerfwe/solana-monitoring?&var-server="$VALIDATOR_NAME

  


