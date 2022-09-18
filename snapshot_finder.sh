#!/bin/bash
# set -x # uncomment to enable debug
echo "###################### WARNING!!! ###################################"
echo "###   This script will perform the following operations:          ###"
echo "###   * delete ledger and snapshots                               ###"
echo "###   * download snapshot finder and run                          ###"
echo "###   * cluster definition and download snapshot                  ###"
echo "###   * wait for catchup                                          ###"
echo "###                                                               ###"
echo "###   *** Script provided by MARGUS.ONE                           ###"
echo "#####################################################################"

service_file="$HOME/solana/solana.service"
LEDGER=$(cat $service_file | grep "\--ledger" | awk '{ print $2 }' )
SNAPSHOTS=$(cat $service_file | grep "\--snapshots" | awk '{ print $2 }' )
if [ "$SNAPSHOTS" == "" ]; then SNAPSHOTS=$LEDGER
fi
networkrpcURL=$(cat /root/.config/solana/cli/config.yml | grep json_rpc_url | grep -o '".*"' | tr -d '"')

catchup_info() {
  while true; do
    rpcPort=$(ps aux | grep solana-validator | grep -Po "\-\-rpc\-port\s+\K[0-9]+")
    sudo -i -u root solana catchup --our-localhost $rpcPort
    status=$?
    if [ $status -eq 0 ];then
      exit 0
    fi
    echo "waiting next 30 seconds for rpc"
    sleep 30
  done
}

systemctl stop solana
cd /root/solana
rm -fr solana-snapshot-finder
rm -fr $LEDGER/*
rm -fr $SNAPSHOTS/*
if ! [ -d $SNAPSHOTS ]; then
mkdir $SNAPSHOTS
fi
sudo apt-get update
sudo apt-get install python3-venv git -y
git clone https://github.com/c29r3/solana-snapshot-finder.git

if [ $networkrpcURL = https://api.testnet.solana.com ]; then
cd solana-snapshot-finder
python3 -m venv venv
source ./venv/bin/activate
pip3 install -r requirements.txt
python3 snapshot-finder.py --snapshot_path $SNAPSHOTS -r https://api.testnet.solana.com --max_latency 150 --min_download_speed 40
systemctl start solana
catchup_info
elif [ $networkrpcURL = https://api.mainnet-beta.solana.com ]; then
cd solana-snapshot-finder
python3 -m venv venv
source ./venv/bin/activate
pip3 install -r requirements.txt
python3 snapshot-finder.py --snapshot_path $SNAPSHOTS
systemctl start solana
catchup_info
elif [ $networkrpcURL = https://api.devnet.solana.com ]; then
cd solana-snapshot-finder
python3 -m venv venv
source ./venv/bin/activate
pip3 install -r requirements.txt
python3 snapshot-finder.py --snapshot_path $SNAPSHOTS -r https://api.devnet.solana.com
systemctl start solana
catchup_info
fi
