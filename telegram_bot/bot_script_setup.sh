#!/bin/bash
echo "install telegram bot"
sudo apt update && sudo apt upgrade -y && sudo apt install jq cron iputils-ping -y
echo "install solana"
mkdir ~/solana && cd ~/solana
sh -c "$(curl -sSfL https://release.solana.com/v1.14.2/install)" 
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH='$PATH >> $HOME/.bashrc
source $HOME/.bashrc
echo "download telegram scripts"
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegram_bot/watch_main.sh > ~/solana/watch_main.sh && chmod +x ~/solana/watch_main.sh
curl https://raw.githubusercontent.com/Hohlas/solana/main/telegram_bot/watch_test.sh > ~/solana/watch_test.sh && chmod +x ~/solana/watch_test.sh
echo "create cron task"
crontab -l >$HOME/tmp.txt  # copy crontab to tmp.txt
echo "MAILTO=''
5,15,25,35,45,55 * * * * /root/solana/watch_test.sh && date +"watch_test: %b %e %H:%M:%S" >> ~/solana/watch.log
6,16,26,36,46,56 * * * * /root/solana/watch_main.sh && date +"watch_main: %b %e %H:%M:%S" >> ~/solana/watch.log
" >> ~/tmp.txt     # add 
crontab $HOME/tmp.txt  # copy tmp.txt to crontab
sudo rm $HOME/tmp.txt  # remove tmp file
sudo systemctl restart cron
echo "telegram bot installed successfully"
