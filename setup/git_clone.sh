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

# ##########################################

BASHRC_FILE="$HOME/.bashrc"
NEW_ALIAS="alias guard='source ~/sol_git/guard/guard.sh'"

#if [ -f "$BASHRC_FILE" ]; then
    # Заменяем строку, если она существует, или добавляем её, если строки нет
    #if grep -q "^alias guard" "$BASHRC_FILE"; then
        # Заменяем строку, начинающуюся с "alias guard"
        #sed -i.bak "s|^alias guard.*|$NEW_ALIAS|" "$BASHRC_FILE"
        #echo "Строка успешно заменена на: $NEW_ALIAS"
    #else
       # echo "Строка 'alias guard' не найдена. Добавьте её вручную."
    #fi
#else
    #echo "Файл $BASHRC_FILE не найден."
#fi
source ~/.bashrc
