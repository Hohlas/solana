## Firedancer setup

[Getting Started](https://firedancer-io.github.io/firedancer/guide/getting-started.html)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```
```bash
SOL_DIR="/home/dancer" # SOL_DIR="/root/solana"
echo 'export SOL_DIR='$SOL_DIR >> $HOME/.bashrc
export PATH="$HOME/firedancer/build/native/gcc/bin/:$PATH"
echo 'export PATH='$PATH >> ~/.bashrc
echo "alias logs='tail -f /var/log/dancer/solana.log'" >> $HOME/.bashrc
echo "alias monitor='agave-validator -l /home/dancer/ledger monitor'" >> $HOME/.bashrc
source .bashrc
DANCE_VER="v0.305.20111"
adduser dancer
```
```bash
mkdir -p $SOL_DIR/ledger
mkdir -p /mnt/disk1/accounts
mkdir -p /var/log/dancer
chown -R dancer:dancer $SOL_DIR /mnt /var/log/dancer
chmod -R 755 $SOL_DIR /mnt /var/log/dancer
```
```bash
cd
git clone --recurse-submodules https://github.com/firedancer-io/firedancer.git
cd ~/firedancer
git checkout $DANCE_VER
git submodule update
./deps.sh # install libraries/dependencies
make -j fdctl solana # build Firedancer
~/firedancer/build/native/gcc/bin/solana --version
```
```bash
curl https://raw.githubusercontent.com/Hohlas/solana/main/firedancer/dance_config.toml > $SOL_DIR/dance_config.toml
curl https://raw.githubusercontent.com/Hohlas/solana/main/firedancer/dancer.service > $SOL_DIR/dancer.service
ln -sf $SOL_DIR/dancer.service /etc/systemd/system
systemctl daemon-reload
systemctl enable dancer.service
systemctl disable solana
```

```bash
systemctl restart dancer
journalctl -u dancer -f
```
```bash
tail -f /var/log/dancer/solana.log
```
```bash
/root/firedancer/build/native/gcc/bin/fdctl configure init all --config /home/dancer/dance_config.toml
```
```bash
/root/firedancer/build/native/gcc/bin/fdctl run --config /home/dancer/dance_config.toml
```
```bash
# LogRotate #
curl https://raw.githubusercontent.com/Hohlas/solana/main/firedancer/dancer.logrotate > /etc/logrotate.d/dancer.logrotate
systemctl restart logrotate
```


```bash
# configure and check: hugetlbfs, sysctl, ethtool-channels, ethtool-gro
fdctl configure init all
fdctl configure check all 
```


