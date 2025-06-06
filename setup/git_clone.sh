#!/bin/bash
# solana-setup
if [ -d ~/sol_git ]; then 
    echo "update solana scripts"
    cd ~/sol_git; 
    git fetch origin; # get last updates from git
    git reset --hard origin/main # сбросить локальную ветку до последнего коммита из git
else 
    echo "clone solana scripts"
    git clone https://github.com/Hohlas/solana.git ~/sol_git
fi
chmod +x ~/sol_git/setup/*.sh
chmod +x ~/sol_git/telegram_bot/watch_test.sh
chmod +x ~/sol_git/telegram_bot/watch_main.sh

# solana-guard
if [ -d ~/solana-guard ]; then 
    echo "update solana-guard"
    curl -sSL https://raw.githubusercontent.com/Hohlas/solana-guard/main/guard.sh > $HOME/solana-guard/guard.sh
    curl -sSL https://raw.githubusercontent.com/Hohlas/solana-guard/main/check.sh > $HOME/solana-guard/check.sh
else 
    echo "clone solana-guard"
    git clone https://github.com/Hohlas/solana-guard.git $HOME/solana-guard
fi
chmod +x $HOME/solana-guard/guard.sh
chmod +x $HOME/solana-guard/check.sh

########  ADD/CHANGE  ALIAS  #########

: '
многострочный 
комментарий
'

BASHRC_FILE="$HOME/.bashrc"
OLD_ALIAS="alias guard='source ~/sol_git/guard/guard.sh'"
NEW_ALIAS="alias guard='source ~/solana-guard/guard.sh'"
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


OLD_ALIAS="alias check='source ~/sol_git/setup/check.sh'"
NEW_ALIAS="alias check='source ~/solana-guard/check.sh'"
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
