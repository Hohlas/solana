#!/bin/bash
# # #   ReSet Node
SOLANA_SERVICE="$HOME/solana/solana.service"
read -p "are you ready to RESET solana node? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
echo "Stop solana.service"
systemctl stop solana

# remoove LEDGER
RM_PATH=$(grep -oP '(?<=--ledger\s).*?(?=\s)' "$SOLANA_SERVICE") # извлечь путь от '--ledger' до следующего пробела.
if [[ -d "$RM_PATH" ]]; then
    echo "remoove $RM_PATH  "
    rm -r $RM_PATH/*
fi    

# remoove accounts
RM_PATH=$(grep -oP '(?<=--accounts\s).*?(?=\s)' "$SOLANA_SERVICE") # извлечь путь от '--ledger' до следующего пробела.
if [[ -d "$RM_PATH" ]]; then
    echo "remoove accounts "
    rm -r $RM_PATH/*
fi

# remoove accounts-hash-cache-path
RM_PATH=$(grep -oP '(?<=--accounts-hash-cache-path\s).*?(?=\s)' "$SOLANA_SERVICE") # извлечь путь от '--ledger' до следующего пробела.
if [[ -d "$RM_PATH" ]]; then
    echo "remoove $RM_PATH "
    rm -r $RM_PATH/*
fi

# remoove accounts-index-path
RM_PATH=$(grep -oP '(?<=--accounts-index-path\s).*?(?=\s)' "$SOLANA_SERVICE") # извлечь путь от '--ledger' до следующего пробела.
if [[ -d "$RM_PATH" ]]; then
    echo "remoove $RM_PATH "
    rm -r $RM_PATH/*
fi

# remoove mounted disks
#if [ -d /mnt/disk1 ]; then rm -rf /mnt/disk1/* && echo "delete disk1/*"; fi
#if [ -d /mnt/disk2 ]; then rm -rf /mnt/disk2/* && echo "delete disk2/*"; fi
#if [ -d /mnt/disk3 ]; then rm -rf /mnt/disk3/* && echo "delete disk3/*"; fi    
echo "Solana Node reset complete"
