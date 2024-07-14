#!/bin/bash

if [ -z "$1" ]; then
	NEW_TAG=$TAG
else
	NEW_TAG=$1
fi

if [[ "$NEW_TAG" == *"jito"* ]]; then
  echo -e '\n\e[42m Install Jito-Solana \e[0m\n'
  sh -c "$(curl -sSfL https://release.jito.wtf/$NEW_TAG/install)"
  chmod +x ~/sol_git/Jito/jito_relayer_setup.sh
  # ~/sol_git/Jito/jito_relayer_setup.sh
else
  echo -e '\n\e[42m Install Solana Testnet \e[0m\n'
  #sh -c "$(curl -sSfL https://release.solana.com/$NEW_TAG/install)" 
  sh -c "$(curl -sSfL https://release.anza.xyz/$NEW_TAG/install)"
fi

# create simlinks  agave -> solana
cd "/root/.local/share/solana/install/active_release/bin/" || exit
for file in agave-*; do # Перебираем все файлы, начинающиеся с "agave-"
    if [ -f "$file" ]; then # файл существует ли 
        ln -sf "$file" "${file/agave-/solana-}" # Создаем символическую ссылку
        echo "create link for $file"
    fi
done

solana --version

if ! grep -q "$HOME/.local/share/solana/install/active_release/bin" ~/.bashrc; then
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    echo 'export PATH='$PATH >> ~/.bashrc
fi
