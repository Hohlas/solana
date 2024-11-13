#!/bin/bash

curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
rustup component add rustfmt
rustup update

apt update
apt install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler -y

if [ -d ~/agave ]; then 
  cd ~/agave; 
  git fetch origin; # get last updates from git
  #git diff # просмотреть изменения, 
  #git merge # применить изменения к локальному репу
  git reset --hard origin/main # сбросить локальную ветку до последнего коммита из git
else 
  git clone https://github.com/anza-xyz/agave.git ~/agave
fi








solana --version
# create simlinks  agave -> solana
cd "/root/.local/share/solana/install/active_release/bin/" || exit
for file in agave-*; do # Перебираем все файлы, начинающиеся с "agave-"
    if [ -f "$file" ]; then # файл существует ли 
        ln -sf "$file" "${file/agave-/solana-}" # Создаем символическую ссылку
        echo "create link for $file"
    fi
done
