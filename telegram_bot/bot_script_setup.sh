#!/bin/bash
sudo apt update && sudo apt install jq
mkdir ~/solana && cd ~/solana
sudo apt install cron
sudo ln -s ~/solana/watch_main.sh /etc/cron.hourly
sudo ln -s ~/solana/watch_test.sh /etc/cron.hourly
sudo systemctl restart cron
