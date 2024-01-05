#!/bin/bash
cd ~/solana
tail -f ~/solana/solana.log | awk '/'$validator_key'.+within slot/ {printf "%d hr. %d min. %d sec.\n", ($18-$12)*0.459/3600, ($18-$12)*0.459/60-int((($18-$12)*0.459/3600))*60, ($18-$12)*0.459-int((($18-$12)*0.459/60))*60}'
