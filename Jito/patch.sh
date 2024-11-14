#!/bin/bash

curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
rustup component add rustfmt
. "$HOME/.cargo/env"

apt update
apt install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler -y

# export TAG=v2.0.15-jito
if [ -d ~/jito-solana ]; then 
  cd ~/jito-solana; 
  git fetch origin; 
  git reset --hard origin/master # сбросить локальную ветку до последнего коммита из git
else 
  git clone https://github.com/jito-foundation/jito-solana.git --recurse-submodules
  cd jito-solana
fi

git fetch --tags # для загрузки всех тегов из удаленного репозитория
git checkout tags/$TAG
git submodule update --init --recursive

curl -o ~/jito-solana/core/src/consensus.rs https://raw.githubusercontent.com/bji/solana/915909fc8539d4df7cc11ba14226ad6247c53cdb/core/src/consensus.rs
curl -o ~/jito-solana/core/src/consensus/progress_map.rs https://raw.githubusercontent.com/bji/solana/915909fc8539d4df7cc11ba14226ad6247c53cdb/core/src/consensus/progress_map.rs
curl -o ~/jito-solana/core/src/replay_stage.rs https://raw.githubusercontent.com/bji/solana/915909fc8539d4df7cc11ba14226ad6247c53cdb/core/src/replay_stage.rs
curl -o ~/jito-solana/core/src/vote_simulator.rs https://raw.githubusercontent.com/bji/solana/915909fc8539d4df7cc11ba14226ad6247c53cdb/core/src/vote_simulator.rs
curl -o ~/jito-solana/programs/vote/src/vote_state/mod.rs https://raw.githubusercontent.com/bji/solana/915909fc8539d4df7cc11ba14226ad6247c53cdb/programs/vote/src/vote_state/mod.rs
curl -o ~/jito-solana/sdk/program/src/vote/state/mod.rs https://raw.githubusercontent.com/bji/solana/915909fc8539d4df7cc11ba14226ad6247c53cdb/sdk/program/src/vote/state/mod.rs

# ./cargo build
CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only ~/.local/share/solana/install/releases/"$TAG"



solana --version
# create simlinks  agave -> solana
cd "/root/.local/share/solana/install/active_release/bin/" || exit
for file in agave-*; do # Перебираем все файлы, начинающиеся с "agave-"
    if [ -f "$file" ]; then # файл существует ли 
        ln -sf "$file" "${file/agave-/solana-}" # Создаем символическую ссылку
        echo "create link for $file"
    fi
done
