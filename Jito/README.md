# JITO 

* [Setup](#setup)
* [Upgrade](#upgrade)
* [Command Line Arguments](#Command Line Arguments)

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
Local Testing
```bash
nohup ./start > faucet.log &
nohup ./bootstrap > validator.log &
```
stop local validator
```bash
pkill solana-faucet && pkill -f 'bash ./.*bootstrap'
```

## Command Line Arguments
```bash
--tip-payment-program-pubkey T1pyyaTNZsKv2WcRAB8oVnk93mLJw2XzjtVYqCsaHqt \
--tip-distribution-program-pubkey 4R3gSG8BpU4t19KYj8CfnbtRpnT8gtk4dvTHxVRwc2r7 \
--merkle-root-upload-authority GZctHpWXmsZC1YHACTGGcHhYxjdRqQvTpYkb9LMvxDib \
--commission-bps 800 \
--relayer-url http://amsterdam.mainnet.relayer.jito.wtf:8100 \
--block-engine-url https://amsterdam.mainnet.block-engine.jito.wtf \
--shred-receiver-address 74.118.140.240:1002 \
```
