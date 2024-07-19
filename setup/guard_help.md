# solana guard
Скрипт бесшовного переключения голосования ноды соланы между основным и резервным серверами
## Основные функции
- Автоматическое переключение голосования при делинке ноды на основном сервере (Primary).
- Принудительное переключение голосования на резервный сервер (Secondary) командой 'guard p'.
- Циклическая работа - после автоматического переключения голосования не требуется перезапуск скрипта, он самостоятельно меняет статус Primary/Secondary в зависимости от текущего состояния ноды и продолжает мониторинг.
- Взаимная проверка работы скриптов. Primary сервер мониторит, запущен ли скрипт на Secondary сервере, и наоборот.
- Мониторинг состояния нод соланы на обоих серверах - статусы health,behind.
  ![2024-07-19_19-09-23](https://github.com/user-attachments/assets/eaa3d757-205c-4f57-a408-ca15d0f3de58)
  
- Ведение логов.
  ![log1](https://github.com/user-attachments/assets/62f053d7-a9b5-4a56-a542-152af831bd0f)
  
- Алерты в телегу.
  ![telegram_alert](https://github.com/user-attachments/assets/5d8c989e-6bcb-45c4-b793-6d6f9d3ba2ba)
  
- Назначение приоритетного сервера для голосования. 

## Алгоритм работы резервного сервереа Secondary
## Алгоритм работы основного сервера Primary

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
