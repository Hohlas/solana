# solana guard
Скрипт бесшовного перелючения голосования ноды соланы между основным и резервным серверами
## Основные функции
Автоматический переключение голосования при делинке основного сервера.
Ручное переключение, например, при обновлении версии.
Циклическая работа - после автоматического переключения голосования скрипт теперь не нужно перезапускать, он самостоятельно меняет статус Primary/Secondary и продолжает мониторинг.
Проверка состояния нод соланы на обоих серверах - статусы health,behind. Ведение логов отправка алертов в телегу.
Взаимная проверка работы скрипта на удаленном сервере. Primary сервер мониторит, работает ли скрипт на Secondary сервере, и наоборот. 

Для ручного переключения голосования достаточно запустить скрипт на резервном сервере с любым аргументом, например ~/guard.sh x. При этом скрипт отключает голосование на основном сервере, копирует с него тауэр, и включает голосование у себя, переходя в статус Primary. Второй сервер соответственно сам принимает статус Secondary, и мониторинг продолжается в штатном режиме.

### загрузка последней версии guard.sh и добавление алиаса
```bash
# download guard.sh
LATEST_TAG_URL=https://api.github.com/repos/Hohlas/solana/releases/latest
TAG=$(curl -sSL "$LATEST_TAG_URL" | jq -r '.tag_name')
echo "download latest guard version: $TAG"
curl "https://raw.githubusercontent.com/Hohlas/solana/$TAG/setup/guard.sh" > $HOME/guard.sh
# set alias
if ! grep -q "guard" ~/.bashrc; then
  echo "alias guard='source $HOME/guard.sh'" >> $HOME/.bashrc
fi
```

### создание папки ~/keys на рамдиске и символических ссылок
```bash
if [ ! -d "$HOME/keys" ]; then
    mkdir -p /mnt/keys
    ln -sf /mnt/keys "$HOME/keys"
    chmod 600 /mnt/keys 
	echo "# KEYS to RAMDISK 
	tmpfs /mnt/keys tmpfs nodev,nosuid,noexec,nodiratime,size=1M 0 0" | sudo tee -a /etc/fstab
	mount /mnt/keys
	echo "create and mount ~/keys in RAMDISK"
else
    echo "~/keys exist"
fi
# create links
ln -sf ~/keys/vote-keypair.json ~/solana/vote.json
ln -sf ~/keys/validator-keypair.json ~/solana/validator-keypair.json
```
### изменение solana.service
```bash
--identity /root/solana/empty-validator.json \
--authorized-voter /root/solana/validator-keypair.json \
--vote-account /root/solana/vote.json \
```

### создание 'пустого' ключа
```bash
if [ ! -f ~/solana/empty-validator.json ]; then 
solana-keygen new -s --no-bip39-passphrase -o ~/solana/empty-validator.json
fi
```
