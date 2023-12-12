# JITO 

## Setup

install the rust compiler and a few related packages
```bash
curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
rustup component add rustfmt
rustup update
sudo apt-get update
sudo apt-get install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler
```
```bash
export TAG=v1.16.23-jito
```
```bash
Setup
```bash
git clone https://github.com/jito-foundation/jito-solana.git --recurse-submodules
cd jito-solana
git checkout tags/$TAG
git submodule update --init --recursive

CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only ~/.local/share/solana/install/releases/"$TAG"
```
## Upgrade

```bash
cd jito-solana
git pull
git checkout tags/$TAG
git submodule update --init --recursive
CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only ~/.local/share/solana/install/releases/"$TAG"
```
