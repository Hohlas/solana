# # #   get IP to $SERV   # # #
#!/bin/bash
source $HOME/.bashrc
if [ -f ~/keys/ssh.key ]; then 
chmod 600 ~/keys/ssh.key; 
else 
echo -e "\033[1;31m Warning: there is no any ssh.key file in ~/keys \033[0m"
fi
addr='main'
if [[ $NODE == "main" ]]; then addr='test'; fi
echo 'addr='$addr
tmp=$(curl https://raw.githubusercontent.com/Hohlas/solana/main/$addr/${NAME,,})
SERV=$(echo "$tmp" | grep -o 'SERV=[^ ]*' | cut -d '=' -f2)
echo "$SERV"