# solana guard
Скрипт бесшовного переключения голосования ноды соланы между основным и резервным серверами
## Основные функции
- Автоматическое переключение голосования при делинке ноды на основном сервере (Primary).
- Принудительное переключение голосования запуском на резервном сервере (Secondary) команды с аргументом 'guard p'. Предварительно проверяется запас времени до следующего блока и состояние (health, behind) резервного сервера.
- Циклическая работа - после автоматического переключения голосования перезапуск скрипта не требуется. Статус сервера Primary/Secondary меняетя в зависимости от режима голосования ноды.
- Взаимная проверка функционирования скриптов. Primary сервер контролирует работу скрипта на Secondary сервере, и наоборот, предотвращая случайное отключение мониторинга.
- Мониторинг состояния нод соланы на обоих серверах: next_slot_minutes, health, behind текущего сервера, behind удаленного сервера.

  ![ok1](https://github.com/user-attachments/assets/ede98b4d-320c-4381-94ec-f54c59c0977a)
  
- Запись всех событий в лог. Фиксируются все отставания ноды.

  ![log](https://github.com/user-attachments/assets/3f14e55c-8078-4ce9-b1a2-f88d76da50bf)
  
- Алерты в телегу о переключениях и отставаниях на обоих серверах.

  ![tg_delink](https://github.com/user-attachments/assets/8dd296c8-11ca-46d4-9f8a-920480c66795)
  
- Назначение приоритетного сервера для голосования запуском с аргументом 'guard p'. Голосование постоянно переключается обратно на приоритетный сервер после возвращения его состояния в норму (health, behind).

![guard_p](https://github.com/user-attachments/assets/3e929797-4edf-4ac8-beb4-ad9684c649d2)

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
   	- Ожидание смены IP адреса ноды в сети для изменения статуса Secondary->Primary.
- Обработка нештатных ситуаций.  
	- При неудачной попытке замены ключа на основном сервере, на нем производится перезапуск сервиса соланы в режиме "NoVoting".
	- Если перезапуск сервиса так же не удался, проверяется пинг до основного сервера.
 	- Если основной сервер не пингуется, делется вывод о том, что на нем отсутствует связь, и следовательно он самостоятельно перезапустит сервис соланы в режиме "NoVoting".
	- Если основной сервер пингуется, то попытки отключения на нем голосования продолжаются.
 
## Алгоритм работы основного сервера Primary
- При пропадании интернет соединения более 15 секунд происходит перезапуск сервиса соланы в режиме "No Voting".
- Сравнивается IP адрес голосующей ноды с локальным IP адресом. Если они не равны, сервер переходит в статус Secondary.
- Мониторинг состояния голосующей и резервной нод: 'health', 'behind'. 

## Установка guard.sh
Загрузка последней версии guard.sh и добавление алиаса
```bash
# download guard.sh
LATEST_TAG_URL=https://api.github.com/repos/Hohlas/solana/releases/latest
TAG=$(curl -sSL "$LATEST_TAG_URL" | jq -r '.tag_name')
curl "https://raw.githubusercontent.com/Hohlas/solana/$TAG/setup/guard.sh" > $HOME/guard.sh
if [ $? -eq 0 ]; then echo "Downloaded guard.sh ($TAG) successfully"
else echo "Failed to download guard.sh";
fi
# set alias
if ! grep -q "guard" $HOME/.bashrc; then
  	echo "alias guard='source $HOME/guard.sh'" >> $HOME/.bashrc
	echo "Alias 'guard' added to .bashrc"
fi
source $HOME/.bashrc
```
При необходимости изменить пути в guard.sh
```bash
KEYS=$HOME/keys
LEDGER=$HOME/solana/ledger
SOLANA_SERVICE="$HOME/solana/solana.service"
```
Сервис соланы всегда должен запускаться с неголосующим ключем 'empty-validator.json'.
Генерация неголосующего ключа
```bash
if [ ! -f ~/solana/empty-validator.json ]; then 
solana-keygen new -s --no-bip39-passphrase -o ~/solana/empty-validator.json
fi
```
Изменение solana.service
```bash
--identity /root/solana/empty-validator.json \
--authorized-voter /root/solana/validator-keypair.json \
--vote-account /root/solana/vote.json \
```
Создание папки ~/keys на рамдиске
```bash
if [ ! -d "$HOME/keys" ]; then
    mkdir -p /mnt/keys
    chmod 600 /mnt/keys 
	echo "# KEYS to RAMDISK 
	tmpfs /mnt/keys tmpfs nodev,nosuid,noexec,nodiratime,size=1M 0 0" | sudo tee -a /etc/fstab
	mount /mnt/keys
	echo "create and mount ~/keys in RAMDISK"
else
    echo "~/keys exist"
fi
```
Создание символических ссылок на папку с ключами /mnt/keys
```bash
# create links
ln -sf /mnt/keys ~/keys
ln -sf /mnt/keys/vote-keypair.json ~/solana/vote.json
ln -sf /mnt/keys/validator-keypair.json ~/solana/validator-keypair.json
```
Для работы телеграм бота требуется файл ~/keys/tg_bot_token вида
```bash
CHAT_ALARM=-1001...3684
CHAT_INFO=-1001...2888
BOT_TOKEN=507625......VICllWU
```
Ключи private_key.ssh от обоих серверов должны находиться в папках ~/keys.
В первый раз скрипт резервного сервера должен запускаться перед запуском на основном сервере. 
При этом на основной сервер копируется файл с IP адресом резервного. Даллее порядок запуска не имеет значения.  
