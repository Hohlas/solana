#!/bin/bash
if [ -d ~/sol_git ]; then 
  cd ~/sol_git; 
  git fetch origin; # get last updates from git
  #git diff # просмотреть изменения, 
  #git merge # применить изменения к локальному репу
  git reset --hard origin/main # сбросить локальную ветку до последнего коммита из git
else 
  git clone https://github.com/Hohlas/solana.git ~/sol_git
fi
chmod +x ~/sol_git/setup/*.sh
chmod +x ~/sol_git/telegram_bot/watch_test.sh
chmod +x ~/sol_git/telegram_bot/watch_main.sh
