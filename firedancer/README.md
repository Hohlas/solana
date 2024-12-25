## Firedancer setup
```bash
ln -sfn $HOME/firedancer/build/native/gcc $HOME/.local/share/solana/install/active_release
cd $HOME/firedancer/build/native/gcc/bin
ln -sf $HOME/firedancer/build/native/gcc/bin/solana $HOME/firedancer/build/native/gcc/bin/solana-validator
```
[Firedancer setup](https://firedancer-io.github.io/firedancer/guide/getting-started.html)

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
