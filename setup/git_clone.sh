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
NEW_ALIAS="alias patch='source ~/sol_git/setup/patch.sh'" # алиас на замену
OLD_ALIAS="${NEW_ALIAS%%=*}" # Вырезаем все после первого "="

: '
многострочный 
комментарий
'

if [ -f "$BASHRC_FILE" ]; then
    # Заменяем строку, если она существует, или добавляем её, если строки нет
    if grep -q "^$OLD_ALIAS" "$BASHRC_FILE"; then
        # Заменяем строку, начинающуюся с OLD_ALIAS
        sed -i.bak "s|^$OLD_ALIAS.*|$NEW_ALIAS|" "$BASHRC_FILE"
        echo "Строка успешно заменена на: $NEW_ALIAS"
    else
        echo "$NEW_ALIAS" >> "$BASHRC_FILE"
        echo "Новый алиас добавлен в $BASHRC_FILE: $NEW_ALIAS"
    fi
else
    echo "Файл $BASHRC_FILE не найден."
fi
source ~/.bashrc
