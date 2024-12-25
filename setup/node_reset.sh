#!/bin/bash
# # #   ReSet Node
SOLANA_SERVICE="$HOME/solana/solana.service"
read -p "are you ready to RESET solana node? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
echo "Stop solana.service"
systemctl stop solana

LEDGER_PATH=$(grep -oP '(?<=--ledger\s).*' "$SOLANA_SERVICE" | tr -d '\\')
if [[ -z "$LEDGER_PATH" ]]; then
    echo "remoove $LEDGER_PATH "
    rm -r $LEDGER_PATH/*
fi    


echo -e "snapshot path =\033[32m $SNAPSHOT_PATH \033[0m "




rm -rf ~/solana/ledger/* && echo "delete ledger/*"
rm -rf /mnt/disk1/* && echo "delete disk1/*"
rm -rf /mnt/disk2/* && echo "delete disk2/*"
rm -rf /mnt/disk3/* && echo "delete disk3/*"
if [ -d /mnt/ramdisk ]; then
    rm -r /mnt/ramdisk/*  && echo "delete RAMDISK/*"
fi
echo "Solana Node reset complete"
