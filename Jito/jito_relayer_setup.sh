#!/bin/bash
echo -e '\n\e[42m Run jito_relayer_setup.sh \e[0m\n'

apt install chrony -y
cp ~/sol_git/Jito/jito-relayer.service ~/solana/jito-relayer.service
ln -sf ~/solana/jito-relayer.service /etc/systemd/system
RelayerKey=$(sed -n -e "/${NAME,,}_relayer/ s/^[^ ]* //p" ~/sol_git/Jito/relayer_address.txt)
echo $RelayerKey
sed -i "/^--allowed-validators /c\--allowed-validators $RelayerKey" ~/solana/jito-relayer.service
systemctl restart chronyd.service
# systemctl restart jito-relayer.service
# journalctl -u jito-relayer -f
