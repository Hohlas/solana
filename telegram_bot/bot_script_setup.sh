#!/bin/bash
echo "install telegram bot"
sudo apt update && sudo apt upgrade -y && sudo apt install jq cron iputils-ping -y
#echo "install solana"
#if [ ! -d ~/solana ]; then mkdir -p ~/solana; fi
#cd ~/solana
#sh -c "$(curl -sSfL https://release.solana.com/v1.17.5/install)" 
#export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
#echo 'export PATH='$PATH >> $HOME/.bashrc
#source $HOME/.bashrc
echo "download telegram scripts"
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegram_bot/watch_main.sh > $HOME/solana/watch_main.sh && chmod +x $HOME/solana/watch_main.sh
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegram_bot/watch_test.sh > $HOME/solana/watch_test.sh && chmod +x $HOME/solana/watch_test.sh
echo "create cron task"
crontab -l >$HOME/tmp.txt  # copy crontab to tmp.txt
echo "MAILTO=''
5,15,25,35,45,55 * * * * $HOME/solana/watch_main.sh
6,16,26,36,46,56 * * * * $HOME/solana/watch_test.sh
" >> ~/tmp.txt     # add 
crontab $HOME/tmp.txt  # copy tmp.txt to crontab
sudo rm $HOME/tmp.txt  # remove tmp file
sudo systemctl restart cron
echo "telegram bot installed successfully"
