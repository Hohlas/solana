#!/bin/bash
curl https://raw.githubusercontent.com/Hohlas/solana/main/$NODE/$NAME > ~/name
# chmod +x ~/name; source ~/name 
echo 

# you won’t need to enter your passphrase every time.
chmod 600 ~/keys/$NAME.ssh
eval "$(ssh-agent -s)"  # Start ssh-agent in the background
ssh-add ~/keys/$NAME.ssh # Add SSH private key to the ssh-agent

VALIDATOR=$(solana-keygen pubkey ~/solana/validator-keypair.json)
SOL=/root/.local/share/solana/install/active_release/bin

echo 'VALIDATOR: '$VALIDATOR
SERV=$1
if [ -z "$SERV" ]
then
  SERV='root@'$(solana gossip | grep $VALIDATOR | awk '{print $1}')
fi
IP=$(echo "$SERV" | cut -d'@' -f2)
echo 'IP='$IP
sudo tee <<EOF >/dev/null ~/.ssh/config
Host REMOTE
HostName $IP
User root
Port 2010
#IdentityFile /root/keys/$NAME.ssh
IdentityFile /root/keys/*.ssh
EOF

ssh REMOTE $SOL/solana catchup ~/solana/validator_link.json --our-localhost
