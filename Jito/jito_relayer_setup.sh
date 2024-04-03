#!/bin/bash
echo -e '\n\e[42m Run jito_relayer_setup.sh \e[0m\n'

# copy executable file without installation
mkdir -p /root/.cargo/bin
curl https://raw.githubusercontent.com/Hohlas/solana/main/Jito/jito.zip > ~/.cargo/bin/jito.zip
unzip ~/.cargo/bin/jito.zip -d ~/.cargo/bin
chmod +x /root/.cargo/bin/jito-transaction-relayer

# copu service file and restart
apt install chrony gcc -y 
cp ~/sol_git/Jito/jito-relayer.service ~/solana/jito-relayer.service
ln -sf ~/solana/jito-relayer.service /etc/systemd/system
RelayerKey=$(solana address -k ~/keys/${NAME,,}_relayer-keypair.json)
echo $RelayerKey
sed -i "/^--allowed-validators /c\--allowed-validators $RelayerKey" ~/solana/jito-relayer.service
#node_set
systemctl daemon-reload
systemctl restart chronyd.service
systemctl restart jito-relayer.service
journalctl -u jito-relayer -f
