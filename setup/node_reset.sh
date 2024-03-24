#!/bin/bash
# # #   ReSet Node

systemctl stop solana
rm -rf ~/solana/ledger/*
#rm -rf /mnt/disk1/snapshots/* 
rm -rf /mnt/disk1/accounts/*
rm -rf /mnt/disk2/ledger/*
rm -rf /mnt/disk3/accounts_index/*
rm -rf /mnt/disk3/accounts_hash_cache/*
echo "Solana Node reset complete"
