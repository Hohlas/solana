#!/bin/bash
SOL_BIN="$HOME/.local/share/solana/install/active_release/bin"

if [ -z "$1" ]; then
	NEW_TAG=$TAG
else
	NEW_TAG=$1
fi

if [[ "$NEW_TAG" == *"jito"* ]]; then
  echo -e '\n\e[42m Install Jito-Solana \e[0m\n'
  sh -c "$(curl -sSfL https://release.jito.wtf/$NEW_TAG/install)"
else
  echo -e '\n\e[42m Install Solana Testnet \e[0m\n'
  #sh -c "$(curl -sSfL https://release.solana.com/$NEW_TAG/install)" 
  sh -c "$(curl -sSfL https://release.anza.xyz/$NEW_TAG/install)"
fi

# add path to ./bashrc
if ! grep -q "$SOL_BIN" ~/.bashrc; then
    export PATH="$SOL_BIN:$PATH"
    echo 'export PATH='$PATH >> ~/.bashrc
	echo "add solana bin PATH to ./bashrc"
else
	echo "solana bin PATH already exist in ./bashrc"	
fi

# create simlinks  agave -> solana
cd "$SOL_BIN/" || exit
for file in agave-*; do # Перебираем все файлы, начинающиеся с "agave-"
    if [ -f "$file" ]; then # файл существует ли 
        ln -sf "$file" "${file/agave-/solana-}" # Создаем символическую ссылку
        echo "create link for $file"
    fi
done

solana --version


