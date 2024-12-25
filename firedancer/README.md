## Firedancer setup

[Firedancer setup](https://firedancer-io.github.io/firedancer/guide/getting-started.html)
```bash
ln -sfn $HOME/firedancer/build/native/gcc $HOME/.local/share/solana/install/active_release
# cd $HOME/firedancer/build/native/gcc/bin
ln -sf $HOME/firedancer/build/native/gcc/bin/solana $HOME/firedancer/build/native/gcc/bin/solana-validator
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
echo '#!/bin/bash
$HOME/firedancer/build/native/gcc/bin/fdctl configure init hugetlbfs' > /usr/local/bin/fdctl-hugetlbfs-init.sh
chmod +x /usr/local/bin/fdctl-hugetlbfs-init.sh


echo "[Unit]
Description=Initialize hugetlbfs for Firedancer
After=network.target

[Service]
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
```
