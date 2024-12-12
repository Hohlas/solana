#!/bin/bash
# # #   ReSet Node
read -p "are you ready to RESET solana node? " RESP; if [ "$RESP" != "y" ]; then exit 1; fi
echo "Stop solana.service and delete Ledger"
systemctl stop solana
rm -rf ~/solana/ledger/* && echo "delete ledger"
rm -rf /mnt/disk1/* && echo "delete disk1/*"
rm -rf /mnt/disk2/* && echo "delete disk2/*"
rm -rf /mnt/disk3/* && echo "delete disk3/*"
if [ -d /mnt/ramdisk ]; then
    rm -r /mnt/ramdisk/*  && echo "delete RAMDISK/*"
fi
echo "Solana Node reset complete"
