#!/bin/bash
if [ -d ~/sol_git ]; then 
cd ~/sol_git; 
git fetch origin; # get last updates from git
git reset --hard origin/main # сбросить локальную ветку до последнего коммита из git
else git clone https://github.com/Hohlas/solana.git ~/sol_git
fi
chmod +x ~/sol_git/setup/*.sh
