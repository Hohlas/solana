#!/bin/bash

curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
rustup component add rustfmt
rustup update

apt update
apt install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler -y

# TAG=v2.0.15-jito
if [ -d ~/jito-solana ]; then 
  cd ~/jito-solana; 
  git fetch origin; 
  git reset --hard origin/master # сбросить локальную ветку до последнего коммита из git
else 
  git clone https://github.com/jito-foundation/jito-solana.git
  cd jito-solana
fi
git fetch --tags # для загрузки всех тегов из удаленного репозитория
git checkout tags/$TAG
curl -o ~/jito/core/src/consensus.rs https://raw.githubusercontent.com/bji/solana/915909fc8539d4df7cc11ba14226ad6247c53cdb/core/src/consensus.rs
curl -o ~/jito/core/src/consensus/progress_map.rs https://github.com/bji/solana/blob/915909fc8539d4df7cc11ba14226ad6247c53cdb/core/src/consensus/progress_map.rs
curl -o ~/jito/core/src/replay_stage.rs https://github.com/bji/solana/blob/915909fc8539d4df7cc11ba14226ad6247c53cdb/core/src/replay_stage.rs
curl -o ~/jito/core/src/vote_simulator.rs https://github.com/bji/solana/blob/915909fc8539d4df7cc11ba14226ad6247c53cdb/core/src/vote_simulator.rs
curl -o ~/jito/programs/vote/src/vote_state/mod.rs https://github.com/bji/solana/blob/915909fc8539d4df7cc11ba14226ad6247c53cdb/programs/vote/src/vote_state/mod.rs
curl -o ~/jito/sdk/program/src/vote/state/mod.rs https://github.com/bji/solana/blob/915909fc8539d4df7cc11ba14226ad6247c53cdb/sdk/program/src/vote/state/mod.rs

./cargo build




solana --version
# create simlinks  agave -> solana
cd "/root/.local/share/solana/install/active_release/bin/" || exit
for file in agave-*; do # Перебираем все файлы, начинающиеся с "agave-"
    if [ -f "$file" ]; then # файл существует ли 
        ln -sf "$file" "${file/agave-/solana-}" # Создаем символическую ссылку
        echo "create link for $file"
    fi
done
