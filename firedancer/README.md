## Firedancer setup

[Getting Started](https://firedancer-io.github.io/firedancer/guide/getting-started.html)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```
```bash
cd
git clone --recurse-submodules https://github.com/firedancer-io/firedancer.git
cd firedancer
git checkout v0.302.20104 # Or the latest Frankendancer release
./deps.sh # script to install system packages and compile library dependencies
```
```bash
make -j fdctl solana # build Firedancer
```
```bash
# ln -sfn $HOME/firedancer/build/native/gcc $HOME/.local/share/solana/install/active_release
# cd $HOME/firedancer/build/native/gcc/bin
# ln -sf $HOME/firedancer/build/native/gcc/bin/solana $HOME/firedancer/build/native/gcc/bin/solana-validator
mkdir -p $HOME/solana/ledger
export PATH="$HOME/firedancer/build/native/gcc/bin/:$PATH"
echo 'export PATH='$PATH >> ~/.bashrc
curl https://raw.githubusercontent.com/Hohlas/solana/main/firedancer/dance_config.toml > $HOME/solana/dance_config.toml
curl https://raw.githubusercontent.com/Hohlas/solana/main/firedancer/solana.service > $HOME/solana/solana.service
```
<details>
<summary>GRUB update</summary>

```bash
nano /etc/default/grub
cat /sys/devices/system/node/node0/hugepages/hugepages-1048576kB/free_hugepages # check
```

```bash
sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT/c GRUB_CMDLINE_LINUX_DEFAULT=\'default_hugepagesz=1G hugepagesz=1G hugepages=52\'" /etc/default/grub
update-grub
```

</details>

```bash
fdctl --config $HOME/solana/dance_config.toml
```
```bash
echo '#!/bin/bash
$HOME/firedancer/build/native/gcc/bin/fdctl configure init hugetlbfs' > /usr/local/bin/fdctl-hugetlbfs-init.sh
chmod +x /usr/local/bin/fdctl-hugetlbfs-init.sh


echo "[Unit]
Description=Initialize hugetlbfs for Firedancer
After=network.target

[Service]
User=root
Type=oneshot
ExecStart=/usr/local/bin/fdctl-hugetlbfs-init.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/fdctl-hugetlbfs.service

systemctl daemon-reload
systemctl enable fdctl-hugetlbfs.service
```
```bash
cat /proc/mounts | grep \\.fd
cat /sys/kernel/mm/hugepages/hugepages-1048576kB/free_hugepages
```
