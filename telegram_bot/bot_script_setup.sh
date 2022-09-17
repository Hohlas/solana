#!/bin/bash
sudo apt update && sudo apt install jq cron
mkdir ~/solana && cd ~/solana
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegram_bot/watch_main.sh > ~/solana/watch_main.sh && chmod +x ~/solana/watch_main.sh
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegram_bot/watch_test.sh > ~/solana/watch_test.sh && chmod +x ~/solana/watch_test.sh
# install solana
sh -c "$(curl -sSfL https://release.solana.com/v1.14.1/install)" 
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH='$PATH >> ~/.bashrc
source ~/.bashrc
# create cron
sudo tee <<EOF >/dev/null ~/crontab.txt  
MAILTO=""
*/10 * * * * ~/solana/watch_test.sh 
*/10 * * * * ~/solana/watch_main.sh
EOF
crontab ~/crontab.txt  # copy crontab.txt to crontab
sudo rm ~/crontab.txt  # remove tmp file
sudo systemctl restart cron
