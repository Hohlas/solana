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
NEW_ALIAS="alias mon='~/sol_git/setup/mon.sh'"$'\n'"alias monitor='solana-validator --ledger ~/solana/ledger monitor'"
OLD_ALIAS="alias mon" # Используем только первый алиас для поиска

: '
многострочный 
комментарий
'

if [ -f "$BASHRC_FILE" ]; then
    # Проверяем наличие обоих алиасов
    if grep -q "^alias mon=" "$BASHRC_FILE" && grep -q "^alias monitor=" "$BASHRC_FILE"; then
        # Заменяем оба алиаса
        sed -i.bak '/^alias mon=/d;/^alias monitor=/d' "$BASHRC_FILE"
        echo "$NEW_ALIAS" >> "$BASHRC_FILE"
        echo "Алиасы 'mon' и 'monitor' обновлены"
    else
        # Добавляем оба алиаса
        echo "$NEW_ALIAS" >> "$BASHRC_FILE"
        echo "Добавлены новые алиасы: 'mon' и 'monitor'"
    fi
else
    echo "Файл $BASHRC_FILE не найден."
fi
source ~/.bashrc
