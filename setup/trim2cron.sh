#!/bin/bash
crontab -l >$HOME/tmp.txt  # copy crontab to tmp.txt
echo "MAILTO=''  # to avoid error: 'No MTA installed, discarding output'. 
*/10 * * * * ~/.local/share/solana/install/active_release/bin/solana-validator --ledger ~/solana/ledger wait-for-restart-window --skip-new-snapshot-check --max-delinquent-stake 50 --min-idle-time 2 && (date +"  %b %e %H:%M:%S" && sudo fstrim -av)" >> ~/trim.log 2>&1
crontab $HOME/tmp.txt  # copy tmp.txt to crontab
sudo rm $HOME/tmp.txt  # remove tmp file
sudo systemctl restart cron
