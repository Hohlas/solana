#!/bin/bash
solana-install init $TAG
solana --version
# create simlinks  agave -> solana
cd "/root/.local/share/solana/install/active_release/bin/" || exit
for file in agave-*; do # Перебираем все файлы, начинающиеся с "agave-"
    if [ -f "$file" ]; then # файл существует ли 
        ln -sf "$file" "${file/agave-/solana-}" # Создаем символическую ссылку
        echo "create link for $file"
    fi
done
