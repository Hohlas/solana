## Paladin setup

[Paladin GitHub](https://github.com/paladin-bladesmith/paladin-solana#about) | [Paladin - P3 Runbook](https://docs.paladin.one)

<details>
<summary>rust setup</summary>

```bash
curl https://sh.rustup.rs -sSf | sh
source $HOME/.cargo/env
rustup component add rustfmt
```

```bash
. "$HOME/.cargo/env"
rustup show
```

```bash
apt update
apt install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler -y
```

</details>


```bash
REPO_URL="https://github.com/paladin-bladesmith/paladin-solana.git"
REPO_DIR=$HOME/paladin-solana
# rm -r $REPO_DIR
```

```bash
if [ -d $REPO_DIR ]; then 
  cd $REPO_DIR; 
  git fetch origin; 
  git reset --hard origin/master # сбросить локальную ветку до последнего коммита из git
else
  cd
  git clone $REPO_URL --recurse-submodules $REPO_DIR
  cd $REPO_DIR
fi
git fetch --tags # для загрузки всех тегов из удаленного репозитория
```

```bash
TAG=v2.1.14-paladin.3
# TAG=$(git describe --tags `git rev-list --tags --max-count=1`) # get last TAG
```

```bash
echo -e "current TAG: \033[32m $TAG \033[0m"
echo "export TAG=$TAG" >> $HOME/.bashrc
git checkout tags/$TAG
git submodule update --init --recursive
```

---

```bash
cd $REPO_DIR;
rm -r $REPO_DIR/target/*
# rm -r $HOME/.local/share/solana/install/releases/$TAG
# ./cargo build # to target/debug/
CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only ~/.local/share/solana/install/releases/"$TAG"/solana-release
```

make agave -> solana links
```bash
if ! grep -q "$HOME/.local/share/solana/install/active_release/bin" ~/.bashrc; then
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
    echo 'export PATH='$PATH >> ~/.bashrc
fi
ln -sfn $HOME/.local/share/solana/install/releases/$TAG/solana-release $HOME/.local/share/solana/install/active_release
cd "$HOME/.local/share/solana/install/releases/$TAG/solana-release/bin/"
for file in agave-*; do # Перебираем все файлы, начинающиеся с "agave-"
    if [ -f "$file" ]; then # файл существует ли 
        ln -sf "$file" "${file/agave-/solana-}" # Создаем символическую ссылку
        echo "create link for $file"
    fi
done
solana --version
solana-validator --version
```
check settings
```bash
tail -f ~/solana/solana.log | grep -A 5 'Checking for change to mostly_confirmed_threshold'
```

<details>
<summary>download original files</summary>

```bash
FILES_DIR="$HOME/files_$TAG"
mkdir -p $FILES_DIR
REPO_URL="paladin-bladesmith/paladin-solana/refs/tags/$TAG"
```

```bash
rm -r $FILES_DIR/*
curl -o $FILES_DIR/consensus.rs https://raw.githubusercontent.com/$REPO_URL/core/src/consensus.rs
curl -o $FILES_DIR/progress_map.rs https://raw.githubusercontent.com/$REPO_URL/core/src/consensus/progress_map.rs
curl -o $FILES_DIR/replay_stage.rs https://raw.githubusercontent.com/$REPO_URL/core/src/replay_stage.rs
curl -o $FILES_DIR/fork_choice.rs https://raw.githubusercontent.com/$REPO_URL/core/src/consensus/fork_choice.rs
curl -o $FILES_DIR/vote_simulator.rs https://raw.githubusercontent.com/$REPO_URL/core/src/vote_simulator.rs
curl -o $FILES_DIR/mod.rs https://raw.githubusercontent.com/$REPO_URL/programs/vote/src/vote_state/mod.rs
curl -o $FILES_DIR/mod_sdk.rs https://raw.githubusercontent.com/$REPO_URL/sdk/program/src/vote/state/mod.rs
echo -e "get files from \033[32m $REPO_URL \033[0m ok "
```

</details>


<details>
<summary>about</summary>

Является ли Paladin мемпулом?
Нет, Paladin не является мемпулом. Paladin — это клиент для валидаторов в экосистеме Solana, разработанный для защиты валидаторов от "сэндвичинга" (sandwiching) и увеличения их вознаграждений за блоки за счёт извлечения MEV (Maximal Extractable Value). В отличие от мемпула, который представляет собой очередь неподтверждённых транзакций, ожидающих обработки (как это было, например, в Jito до его отключения в марте 2024 года), Paladin работает непосредственно внутри узла валидатора и активируется только тогда, когда этот валидатор становится лидером блока. Он использует бот (Paladin bot), интегрированный с Jito-клиентом, для выполнения арбитражных операций и распределения прибыли, но не создаёт и не поддерживает отдельный мемпул. Solana сама по себе не имеет встроенного мемпула благодаря своей архитектуре (например, Gulf Stream), а Paladin следует этой философии, обрабатывая транзакции локально и без промежуточного "хранилища".

Получал ли Paladin одобрение от Solana Foundation Development Program (SFDP)?
На основе доступной информации нет прямых доказательств того, что Paladin получил официальное одобрение от Solana Foundation Development Program (SFDP). SFDP — это программа делегирования Solana Foundation, которая предоставляет валидаторам дополнительную поддержку в виде делегированного стейка SOL для стимулирования участия в сети. Однако Paladin — это сторонний проект, разработанный независимой командой, и его создатели подчёркивают, что они не связаны с Solana Foundation или Solana Labs. Например, в публикациях команды Paladin (таких как статья Uri Klarman на Medium) говорится, что после запуска проект полностью децентрализован и находится в руках сообщества Solana, без прямого управления со стороны каких-либо официальных структур, включая Foundation.
Тем не менее, Paladin активно взаимодействует с экосистемой Solana, и его разработка получила положительные отзывы от участников сообщества, включая команды Jito, Firedancer и Anza. Также известно, что крупные игроки, такие как Chorus One, интегрировали Paladin в свои валидаторы, что указывает на определённый уровень признания в экосистеме. Однако это не то же самое, что формальное одобрение или включение в SFDP. Более того, Solana Foundation в 2024 году ужесточила политику в отношении валидаторов, участвующих в приватных мемпулах, исключая их из SFDP, но Paladin, не будучи мемпулом и позиционируясь как решение против "плохого MEV", вряд ли подпадает под эти санкции. Тем не менее, конкретного упоминания о его статусе в SFDP в открытых источниках нет.

Как осуществляются начисления валидатору от Paladin?
Paladin — это клиент для валидаторов Solana, который интегрируется с узлом валидатора и работает в паре с Jito-клиентом, чтобы извлекать MEV (Maximal Extractable Value) через атомарный арбитраж. Начисления валидатору от Paladin происходят следующим образом:
Механизм работы Paladin Bot:
Paladin Bot активируется только в слотах, когда валидатор становится лидером блока (т.е. имеет право предлагать следующий блок в сети Solana).

Бот сканирует возможности для атомарного арбитража — операций, где транзакции внутри одного блока могут приносить прибыль за счёт разницы в ценах активов (например, на децентрализованных биржах).

Эти операции включаются в блок, который валидатор отправляет в сеть, и прибыль от арбитража начисляется валидатору.

Распределение прибыли:
Paladin не создаёт отдельный мемпул или рынок для ставок (как это делает Jito с его системой "bundles" и "tips"). Вместо этого он работает локально на узле валидатора, напрямую извлекая MEV.

Прибыль от арбитража полностью остаётся у валидатора, который использует Paladin, за вычетом любых операционных издержек (например, транзакционных сборов сети Solana, которые минимальны).

Если валидатор делегирует часть наград своим стейкерам, то распределение зависит от установленной комиссии валидатора (commission rate), но Paladin сам по себе не регулирует этот аспект — это стандартная механика Solana.

Техническая интеграция:
Paladin требует установки бота на узел валидатора и настройки через интерфейс командной строки (CLI). После установки он автоматически запускается в соответствующих слотах лидера.

Для участия в бета-версии Paladin (по состоянию на последнюю информацию) валидатор должен быть в белом списке (whitelist), что ограничивает доступность начислений только утверждённым участникам.

Приблизительная величина оплаты
Точная сумма начислений зависит от нескольких факторов: частоты лидерства валидатора (определяется его долей стейка в сети), объёма доступных арбитражных возможностей и конкуренции с другими MEV-ботами (например, Jito). Однако можно привести приблизительные оценки на основе доступных данных:
Рынок атомарного арбитража:
По оценкам команды Chorus One (опубликованным в их анализе), рынок атомарного арбитража на Solana составляет около $42 млн в год (по состоянию на 2023–2024 годы).

Paladin захватывает часть этого рынка. Например, в тестовых слотах он обеспечивал около 16% всех атомарных арбитражей, что эквивалентно примерно $6,7 млн годовой прибыли, распределённой между всеми валидаторами, использующими Paladin.

Влияние на APY валидатора:
Использование Paladin добавляет к доходности валидатора (APY) примерно 0,01% в годовом исчислении на момент анализа Chorus One (при 16% захвата рынка).

Если Paladin будет работать на 50% валидаторов Solana при неизменных рыночных условиях, это может увеличить APY до 0,03% в год.

Для сравнения, базовая доходность от инфляционных наград Solana составляет около 5–6% в год (с учётом текущей инфляции ~5% и комиссии валидатора), так что Paladin обеспечивает дополнительный прирост.

Примерный расчёт для отдельного валидатора:
Предположим, валидатор имеет 1 млн SOL в стейке (примерно 0,5% от общей суммы застейканных SOL в сети, которая сейчас составляет ~370 млн SOL).

Базовая доходность от инфляции: 1 млн SOL × 5% = 50,000 SOL в год.

Дополнительно от Paladin (при 0,03% APY): 1 млн SOL × 0,03% = 300 SOL в год.

Итоговая дополнительная прибыль: 300 SOL в год, что при текущей цене SOL ($180 на март 2025) составляет около $54,000 в год для валидатора с таким стейком.

Переменные факторы:
Чем больше стейк у валидатора, тем чаще он становится лидером блока и тем больше возможностей для Paladin извлечь MEV.

Объём арбитражных возможностей может варьироваться в зависимости от активности на рынке DeFi Solana (например, торгов на Orca или Raydium).

Конкуренция с другими MEV-решениями (например, Jito) может снижать долю Paladin в общем пироге.

Итог
Paladin начисляет валидатору прибыль от атомарного арбитража непосредственно в слотах лидерства, добавляя её к стандартным инфляционным наградам и транзакционным сборам. Приблизительная дополнительная оплата составляет от 0,01% до 0,03% APY в зависимости от普及度 (распространённости) Paladin среди валидаторов и рыночных условий. Для валидатора с 1 млн SOL это может быть порядка 300 SOL в год ($54,000 при $180/SOL), но сумма сильно зависит от размера стейка и активности DeFi-экосистемы Solana. Если вам нужны более точные расчёты для конкретного валидатора, уточните его параметры (например, объём стейка), и я постараюсь скорректировать оценку!



</details>
