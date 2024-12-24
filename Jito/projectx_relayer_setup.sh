#!/bin/bash
echo -e '\n\e[42m Run projectx_relayer_setup.sh \e[0m\n'

# neccesary software install
sudo apt update && sudo apt upgrade -y
sudo apt install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler -y
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Clone relayer repo and build binary
cd $HOME
git clone https://github.com/projectxsol/lite-relayer.git
cd lite-relayer
git fetch
git submodule update --init --recursive
cargo build --release --bin transaction-relayer

X_BLOCK_ENGINE=http://de.projectx.run:11227 # EU location
echo $X_BLOCK_ENGINE

# copy service file and restart
cp ~/sol_git/Jito/projectx_relayer.service ~/solana/relayer.service
ln -sf ~/solana/relayer.service /etc/systemd/system
RelayerKey=$(solana address -k ~/solana/relayer-keypair.json)
echo "RelayerKey $RelayerKey"
# sed -i "/^--allowed-validators /c\--allowed-validators $RelayerKey" ~/solana/jito-relayer.service

systemctl daemon-reload
systemctl enable relayer.service
# systemctl restart relayer
ufw allow 11228,11229/udp

# copy executable file without installation
#mkdir -p $HOME/lite-relayer/target/release/
#curl https://raw.githubusercontent.com/Hohlas/solana/main/Jito/projectx_relayer.zip > $HOME/lite-relayer/target/release/projectx_relayer.zip
#unzip -j $HOME/lite-relayer/target/release/projectx_relayer.zip -d $HOME/lite-relayer/target/release
#chmod +x $HOME/lite-relayer/target/release/projectx_relayer


