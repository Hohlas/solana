#!/bin/bash

# Создаем временный файл для хранения crontab
TMP_FILE=$(mktemp)

# Копируем текущий crontab в временный файл
sudo crontab -l > "$TMP_FILE" 2>/dev/null || echo "" > "$TMP_FILE"

# Добавляем MAILTO и новую задачу в временный файл
echo "MAILTO=''" >> "$TMP_FILE"
#echo "*/10 * * * * $HOME/sol_git/setup/trim.sh" >> "$TMP_FILE"
echo "*/10 * * * * /home/yourusername/.local/share/solana/install/active_release/bin/solana-validator --ledger /home/yourusername/solana/ledger wait-for-restart-window --skip-new-snapshot-check --max-delinquent-stake 50 --min-idle-time 2 && (date '+%b %e %H:%M:%S' && sudo fstrim -av) >> /home/yourusername/trim.log 2>&1" >> "$TMP_FILE"

# Копируем временный файл обратно в crontab для root
sudo crontab "$TMP_FILE"

# Удаляем временный файл
sudo rm "$TMP_FILE"

# Перезапускаем cron (обычно не обязательно, но можно сделать)
sudo systemctl restart cron
