# solana guard | [guard.sh](https://github.com/Hohlas/solana/blob/v1.1.3/setup/guard.sh)
Скрипт бесшовного перелючения голосования ноды соланы между основным и резервным серверами
## Основные функции
Автоматический переключение голосования при делинке основного сервера.
Ручное переключение, например, при обновлении версии.
Циклическая работа - после автоматического переключения голосования скрипт теперь не нужно перезапускать, он самостоятельно меняет статус Primary/Secondary и продолжает мониторинг.
Проверка состояния нод соланы на обоих серверах - статусы health,behind. Ведение логов отправка алертов в телегу.
Взаимная проверка работы скрипта на удаленном сервере. Primary сервер мониторит, работает ли скрипт на Secondary сервере, и наоборот. 

Для ручного переключения голосования достаточно запустить скрипт на резервном сервере с любым аргументом, например ~/guard.sh x. При этом скрипт отключает голосование на основном сервере, копирует с него тауэр, и включает голосование у себя, переходя в статус Primary. Второй сервер соответственно сам принимает статус Secondary, и мониторинг продолжается в штатном режиме.

```bash


# download guard.sh
LATEST_TAG_URL=https://api.github.com/repos/Hohlas/solana/releases/latest
TAG=$(curl -sSL "$LATEST_TAG_URL" | jq -r '.tag_name')
echo "download latest guard version: $TAG"
curl https://raw.githubusercontent.com/Hohlas/solana/v$TAG/setup/solana.service > $HOME/guard.sh
# set alias
if ! grep -q "guard" ~/.bashrc; then
  echo "alias guard='source $HOME/guard.sh'" >> $HOME/.bashrc
fi
```

[guard.sh](https://github.com/Hohlas/solana/blob/v1.1.3/setup/guard.sh)
