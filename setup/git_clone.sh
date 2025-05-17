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
chmod +x ~/sol_git/guard/*.sh
chmod +x ~/sol_git/telegram_bot/watch_test.sh
chmod +x ~/sol_git/telegram_bot/watch_main.sh

# ##########################################


: '
многострочный 
комментарий
'

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CLEAR='\e[0m'

# Определение переменных
BASHRC_FILE="$HOME/.bashrc"
NEW_ALIAS="alias logs='~/sol_git/setup/logs.sh'"
OLD_ALIAS="alias logs='tail -f ~/solana/solana.log'"

if grep -q "^alias logs=" "$BASHRC_FILE"; then
        # Экранируем символы в OLD_ALIAS и NEW_ALIAS для sed
        ESCAPED_OLD_ALIAS=$(echo "$OLD_ALIAS" | sed 's/[\/&]/\\&/g')
        ESCAPED_NEW_ALIAS=$(echo "$NEW_ALIAS" | sed 's/[\/&]/\\&/g')
        # Заменяем старую строку на новую
        sed -i.bak "s|^alias logs=.*|$ESCAPED_NEW_ALIAS|" "$BASHRC_FILE"
        echo -e "${GREEN}Alias [$OLD_ALIAS] replaced with: [$NEW_ALIAS]${CLEAR}"
    else
        # Добавляем новую строку, если алиас не найден
        echo "$NEW_ALIAS" >> "$BASHRC_FILE"
        echo -e "${GREEN}Added new alias: [$NEW_ALIAS]${CLEAR}"
    fi

    


source ~/.bashrc
echo "source ~/.bashrc"
