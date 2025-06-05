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


BASHRC_FILE="$HOME/.bashrc"
OLD_ALIAS="alias logs='tail -f ~/solana/solana.log'"
NEW_ALIAS="alias logs='~/sol_git/setup/logs.sh'"

: '
многострочный 
комментарий
'

if [ -f "$BASHRC_FILE" ]; then
    # Заменяем строку, если она существует, или добавляем её, если строки нет
    if grep -q "^$OLD_ALIAS" "$BASHRC_FILE"; then
        # Заменяем строку, начинающуюся с OLD_ALIAS
        sed -i.bak "s|^$OLD_ALIAS.*|$NEW_ALIAS|" "$BASHRC_FILE"
        echo "change alias [$OLD_ALIAS]  - >  [$NEW_ALIAS]"
    elif grep -q "^$NEW_ALIAS" "$BASHRC_FILE"; then
        echo "alias already in use"
    else
        echo "$NEW_ALIAS" >> "$BASHRC_FILE"
        echo "add new alias: [$NEW_ALIAS]"
    fi
else
    echo "file $BASHRC_FILE not found."
fi

echo "run: source ~/.bashrc"
