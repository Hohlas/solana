#!/bin/bash
sudo apt update && sudo apt install jq cron
mkdir ~/solana && cd ~/solana
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegram_bot/watch_main.sh > ~/solana/watch_main.sh && chmod +x ~/solana/watch_main.sh
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegram_bot/watch_test.sh > ~/solana/watch_test.sh && chmod +x ~/solana/watch_test.sh
sh -c "$(curl -sSfL https://release.solana.com/v1.14.1/install)" 
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH='$PATH >> ~/.bashrc
source ~/.bashrc
sudo ln -s ~/solana/watch_main.sh /etc/cron.hourly
sudo ln -s ~/solana/watch_test.sh /etc/cron.hourly
sudo systemctl restart cron
