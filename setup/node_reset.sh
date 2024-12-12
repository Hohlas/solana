#!/bin/bash
# # #   ReSet Node
read -p "are you ready to RESET solana node? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
echo "Stop solana.service and delete Ledger"
systemctl stop solana
rm -rf ~/solana/ledger/*
rm -rf /mnt/disk1/*
rm -rf /mnt/disk2/*
rm -rf /mnt/disk3/*
if [ -d /mnt/ramdisk ]; then
    rm -r /mnt/ramdisk/*
fi
echo "Solana Node reset complete"
