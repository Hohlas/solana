## Jito patch setup

<details>
<summary>rust setup</summary>

```bash
curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
rustup component add rustfmt
```

```bash
. "$HOME/.cargo/env"
rustup show
```

```bash
apt update
apt install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler -y
```

</details>


```bash
export TAG=v2.0.15-jito
```

```bash
if [ -d ~/jito-solana ]; then 
  cd ~/jito-solana; 
  git fetch origin; 
  git reset --hard origin/master # сбросить локальную ветку до последнего коммита из git
else 
  git clone https://github.com/jito-foundation/jito-solana.git --recurse-submodules && \
  cd jito-solana
fi
git fetch --tags # для загрузки всех тегов из удаленного репозитория
echo $TAG; git checkout tags/$TAG
git submodule update --init --recursive
```

```bash
curl -o ~/jito-solana/core/src/consensus.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/patch/v2/consensus.rs
curl -o ~/jito-solana/core/src/consensus/progress_map.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/patch/v2/progress_map.rs
curl -o ~/jito-solana/core/src/replay_stage.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/patch/v2/replay_stage.rs
curl -o ~/jito-solana/core/src/vote_simulator.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/patch/v2/vote_simulator.rs
curl -o ~/jito-solana/programs/vote/src/vote_state/mod.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/patch/v2/mod.rs
curl -o ~/jito-solana/sdk/program/src/vote/state/mod.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/patch/v2/mod_sdk.rs
```

```bash
# rm -r ~/jito-solana/target/*
# ./cargo build # to target/debug/
CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only ~/.local/share/solana/install/releases/"$TAG"
```


