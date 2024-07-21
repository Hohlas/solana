# solana guard
Скрипт бесшовного переключения голосования ноды соланы между основным и резервным серверами
## Основные функции
- Автоматическое переключение голосования при делинке ноды на основном сервере (Primary).
- Принудительное переключение голосования запуском на резервном сервере (Secondary) команды с аргументом 'guard p'. Предварительно проверяется запас времени до следующего блока и состояние (health, behind) резервного сервера.
- Циклическая работа - после автоматического переключения голосования перезапуск скрипта не требуется. Статус сервера Primary/Secondary меняетя в зависимости от режима голосования ноды.
- Взаимная проверка функционирования скриптов. Primary сервер контролирует работу скрипта на Secondary сервере, и наоборот, предотвращая случайное отключение мониторинга.
- Мониторинг состояния нод соланы на обоих серверах: next_slot_minutes, health, behind текущего сервера, behind удаленного сервера.

  ![2024-07-19_19-09-23](https://github.com/user-attachments/assets/eaa3d757-205c-4f57-a408-ca15d0f3de58)
  
- Запись всех событий в лог. Удобно отслеживать незначительные редкие отставания ноды.

  ![log1](https://github.com/user-attachments/assets/62f053d7-a9b5-4a56-a542-152af831bd0f)
  
- Алерты в телегу о переключениях и отставаниях на обоих серверах.

  ![telegram_alert](https://github.com/user-attachments/assets/5d8c989e-6bcb-45c4-b793-6d6f9d3ba2ba)
  
- Назначение приоритетного сервера для голосования запуском с аргументом 'guard p'. Голосование постоянно переключается обратно на приоритетный сервер после возвращения его состояния в норму (health, behind).

![permanent_primary](https://github.com/user-attachments/assets/419d5605-d125-4dee-b77b-f13576025e0a)

- Переключение голосования при отставании основного сервера на X слотов, не дожидаясь делинка ноды. Задается аргументом 'guard X'.
 
![behind_threshold](https://github.com/user-attachments/assets/8da43706-efb0-4270-9fc0-ee001cc06832)

- Перезапуск сервиса соланы в режиме "No Voting" на основном сервере при пропадании на нем интернета.
- Переключение сервиса 'telegraf' на обоих серверах в соответствии с их статусом Primaty/Secondary. 

## Алгоритм работы резервного сервереа Secondary
- Мониторинг состояния резервной и голосующей нод: 'health', 'behind'.
- Сравнивается IP адрес голосующей ноды с локальным IP адресом. Если они равны, сервер переходит в статус Primary.
- Переключение голосования с основного на резервный сервер происходит при отсутствии отставания резервной ноды и наступлении одного из трех событий:
	- Статус "Delinquent" голосующей ноды
	- Превышение 'behind' голосующей ноды порогового значения X, если guard запущен с аргументом 'guard X'.
	- Наличие флага "permanent_primary", если guard запущен с аргументом 'guard p'.
- Переключение голосования с основного на резервный сервер производится в следующей последовательности:
	- Смена ключа валидатора на неголосующий на основном сервере.
   	- Копирование тауэра с основного сервера, отключение  сервиса 'telegraf'.
   	- Включение голосования на резервном сервере и запуск на нем сервиса 'telegraf'.
- Обработка нештатных ситуаций.  
	- При неудачной попытке замены ключа на основном сервере, на нем производится перезапуск сервиса соланы в режиме "NoVoting".
	- Если перезапуск сервиса так же не удался, проверяется пинг до основного сервера.
 	- Если основной сервер не пингуется, делется вывод о том, что на нем отсутствует связь, и следовательно он самостоятельно перезапустит сервис соланы в режиме "NoVoting".
	- Если основной сервер пингуется, то попытки мониторинга основного сервера продолжаются начиная с замены на нем ключа.

## Алгоритм работы основного сервера Primary
- При пропадании интернет соединения более 15 секунд происходит перезапуск сервиса соланы в режиме "No Voting".
- Сравнивается IP адрес голосующей ноды с локальным IP адресом. Если они не равны, сервер переходит в статус Secondary.
- Мониторинг состояния голосующей и резервной нод: 'health', 'behind'. 

### загрузка последней версии guard.sh и добавление алиаса
```bash
# download guard.sh
LATEST_TAG_URL=https://api.github.com/repos/Hohlas/solana/releases/latest
TAG=$(curl -sSL "$LATEST_TAG_URL" | jq -r '.tag_name')
echo "download latest guard version: $TAG"
curl "https://raw.githubusercontent.com/Hohlas/solana/$TAG/setup/guard.sh" > $HOME/guard.sh
if [ $? -eq 0 ]; then echo "Downloaded guard.sh successfully"
else echo "Failed to download guard.sh";
fi
# set alias
if ! grep -q "guard" $HOME/.bashrc; then
  	echo "alias guard='source $HOME/guard.sh'" >> $HOME/.bashrc
	echo "Alias 'guard' added to .bashrc"
fi
source $HOME/.bashrc
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
