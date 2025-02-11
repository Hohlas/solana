## Firedancer setup

[Getting Started](https://firedancer-io.github.io/firedancer/guide/getting-started.html)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```
```bash
echo "alias logs='tail -f /var/log/dancer/solana.log'" >> $HOME/.bashrc
echo "alias monitor='agave-validator -l /root/solana/ledger monitor'" >> $HOME/.bashrc
export PATH="$HOME/firedancer/build/native/gcc/bin/:$PATH"
echo 'export PATH='$PATH >> ~/.bashrc
source ~/.bashrc
mkdir -p /mnt/disk1/accounts /mnt/ledger /mnt/snapshots /var/log/dancer /root/solana
ln -sf /mnt/ledger /root/solana/ledger
# chown -R root:root /mnt /var/log/dancer
chmod -R 777 /mnt /var/log/dancer /root/solana
curl https://raw.githubusercontent.com/Hohlas/solana/main/firedancer/dance_config.toml > /root/solana/dance_config.toml
curl https://raw.githubusercontent.com/Hohlas/solana/main/firedancer/dancer.service > /root/solana/solana.service
ln -sf /root/solana/solana.service /etc/systemd/system
systemctl daemon-reload
systemctl enable solana.service
# LogRotate #
curl https://raw.githubusercontent.com/Hohlas/solana/main/firedancer/dancer.logrotate > /etc/logrotate.d/dancer.logrotate
systemctl restart logrotate
```
```bash
DANCE_VER="v0.305.20111"
```
```bash
cd
git clone --recurse-submodules https://github.com/firedancer-io/firedancer.git
cd ~/firedancer
git checkout $DANCE_VER
git submodule update
./deps.sh # install libraries/dependencies
```
```bash
# make root
sed -i "/^[ \t]*results\[ 0 \] = pwd\.pw_uid/c results[ 0 ] = 1001;" ~/firedancer/src/app/fdctl/config.c
sed -i "/^[ \t]*results\[ 1 \] = pwd\.pw_gid/c results[ 1 ] = 1002;" ~/firedancer/src/app/fdctl/config.c
# build
make -j fdctl solana 
~/firedancer/build/native/gcc/bin/solana --version
```
copy 'vote.json' & 'validator-keypair.json' to /root/solana/ 
```bash
chmod -R 777 /mnt /var/log/dancer /root/solana
chmod 777 /root/solana/vote.json /root/solana/validator-keypair.json
chmod 755 /root/firedancer/build/native/gcc/bin/fdctl
chmod 755 /root
```
```bash
chmod 755 /root
chmod 755 /root/firedancer
chmod 755 /root/firedancer/build
chmod 755 /root/firedancer/build/native
chmod 755 /root/firedancer/build/native/gcc
chmod 755 /root/firedancer/build/native/gcc/bin
```
```bash
systemctl restart dancer
journalctl -u dancer -f
```
--- 

```bash
tail -f /var/log/dancer/solana.log
```
```bash
fdctl configure init all --config /root/solana/dance_config.toml
```
```bash
fdctl run --config /root/solana/dance_config.toml
```


