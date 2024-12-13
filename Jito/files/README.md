## Jito setup

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
# REPO_URL="https://github.com/anza-xyz/agave.git"
REPO_URL="https://github.com/jito-foundation/jito-solana.git"
REPO_DIR=$HOME/jito-solana
# rm -r $REPO_DIR
```

```bash
if [ -d $REPO_DIR ]; then 
  cd $REPO_DIR; 
  git fetch origin; 
  git reset --hard origin/master # сбросить локальную ветку до последнего коммита из git
else 
  git clone $REPO_URL --recurse-submodules $REPO_DIR
  cd $REPO_DIR
fi
git fetch --tags # для загрузки всех тегов из удаленного репозитория
```

```bash
TAG=v2.0.19-jito
# TAG=$(git describe --tags `git rev-list --tags --max-count=1`) # get last TAG
```

```bash
echo -e "current TAG: \033[32m $TAG \033[0m"
echo "export TAG=$TAG" >> $HOME/.bashrc
git checkout tags/$TAG
git submodule update --init --recursive
```

<details>
<summary>check TAGs differences </summary>

[JitoGit](https://github.com/jito-foundation/jito-solana/releases) | [AgaveGit](https://github.com/anza-xyz/agave/releases)
```bash
TAG=v2.0.18-jito
```

```bash
GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; CLEAR=$'\033[0m'
FILES=(
    "core/src/consensus.rs"
    "core/src/consensus/progress_map.rs"
    "core/src/consensus/fork_choice.rs"
    "core/src/replay_stage.rs"
    "core/src/vote_simulator.rs"
    "programs/vote/src/vote_state/mod.rs"
    "sdk/program/src/vote/state/mod.rs"
)
echo -e "\n  - TAGs $BLUE$TAG$CLEAR & $BLUE$TAG1$CLEAR differences - "
for FILE in "${FILES[@]}"; do
    DIFF=$(git diff "$TAG" "$TAG1" -- "$FILE") # различия между тегами
    if [ -n "$DIFF" ]; then
        echo -e "${RED}files are different:${CLEAR} $FILE"
        # echo "$DIFF"  # Выводим различия
    else
        echo -e "${GREEN}files the same:${CLEAR} $FILE"
    fi
done

```

</details>

<details>
<summary> Update files </summary>

### v2.1.xx
```bash

curl -o $REPO_DIR/core/src/consensus.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.1/consensus.rs
curl -o $REPO_DIR/core/src/consensus/progress_map.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.1/progress_map.rs
curl -o $REPO_DIR/core/src/consensus/fork_choice.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.1/fork_choice.rs
curl -o $REPO_DIR/core/src/replay_stage.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.1/replay_stage.rs
curl -o $REPO_DIR/core/src/vote_simulator.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.1/vote_simulator.rs
curl -o $REPO_DIR/programs/vote/src/vote_state/mod.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.1/mod.rs
curl -o $REPO_DIR/sdk/program/src/vote/state/mod.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.1/mod_sdk.rs
curl -o $HOME/solana/mostly_confirmed_threshold https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.1/mostly_confirmed_threshold
echo -e "replace files for \033[32m V2.1.x \033[0m versions "
```


### v2.0.xx
```bash

curl -o $REPO_DIR/core/src/consensus.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.0/consensus.rs
curl -o $REPO_DIR/core/src/consensus/progress_map.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.0/progress_map.rs
curl -o $REPO_DIR/core/src/replay_stage.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.0/replay_stage.rs
curl -o $REPO_DIR/core/src/vote_simulator.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.0/vote_simulator.rs
curl -o $REPO_DIR/programs/vote/src/vote_state/mod.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.0/mod.rs
curl -o $REPO_DIR/sdk/program/src/vote/state/mod.rs https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.0/mod_sdk.rs
curl -o $HOME/solana/mostly_confirmed_threshold https://raw.githubusercontent.com/Hohlas/solana/main/Jito/files/v2.0/mostly_confirmed_threshold
echo -e "replace files for \033[32m V2.0.x \033[0m versions "
```
---

</details>

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
```
check settings
```bash
tail -f ~/solana/solana.log | grep -A 5 'Checking for change to mostly_confirmed_threshold'
```

<details>
<summary>download original files</summary>

```bash
TAG=v2..
FILES_DIR=$HOME/files
mkdir -p $HOME/files
rm -r $HOME/files/*
REPO_URL="jito-foundation/jito-solana/refs/tags/$TAG-jito"
REPO_URL="anza-xyz/agave/refs/tags/$TAG"
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
<summary>discord post</summary>

[Shinobi discord post](https://discord.com/channels/428295358100013066/673718028323782674/1281017905454121035)
Some of this was implemented before I really even knew Rust so it's a little hokey.  In particular, the configuration mechanism that provides tunable parameters is gross and just re-reads a config file once per minute to get updated values.

The config file is stored in the validator's root directory and is called "mostly_confirmed_threshold".  If it doesn't exist, the mods do nothing.  If it does exist, then it is a simple file with four values in sequence:

The first number is the "mostly confirmed threshold".  A slot is considered "mostly confirmed" if it has achieved this fraction of stake-weighted votes.  For example, 0.55 would mean that once a slot has received 55% of stake-weighted votes, it is "mostly confirmed".  The higher this number, the more "conservative" the voting -- a high number will prevent the validator from voting until a large fraction of the rest of the cluster has already voted on a slot.  Higher numbers cause a greater degree of "induced lag".
The second number is the number of slots beyond the most recent "mostly confirmed" slot that will be voted on regardless of how much stake weight it has on it.  For example, 2 would mean that the validator will vote two slots ahead of the most recent mostly confirmed slot without making any other considerations.  Lower numbers cause a greater degree of "induced lag".
The third number is either 0, 1 or 2.  If 0, no additional processing is done.  If 1, then after a skip (i.e. after a gap in votable slots), the validator will not vote on the next slot after the skip until that slot has achieved "mostly confirmed threshold".  This essentially makes the second value ("slots beyond the most recent mostly confirmed slot that will be voted on) 0 right after a skip.  If 2, then the same will apply except that rather than "mostly confirmed threshold", actual consensus would be used.  2 is a very laggy parameter and should not be used; it means that after skips, the validator will not contribute to consensus, ever, and will always wait for consensus before voting after a skip.  I personally don't think any value other than 0 for this parameter is worthwhile.  I used to try enabling 1 but I don't think it had an appreciable benefit.
The fourth number is the "escape hatch" distance, which will cause the mods to turn themselves off temporarily if there have been this number of slots without any votes cast by the current validator.  This is meant to be a safeguard in case there is something wrong with the mods that causes voting to stop due to a bug or mis-design, or in case the whole cluster for some reason is having a hard time achieving consensus and the mods might be partially the cause.

I personally use these values: 0.45 4 0 24.  These add extremely little lag, an imperceptible amount, because the "mostly confirmed threshold" is pretty low at 0.45, and the "number of slots beyond" is relatively high at 4.

---

The mods work by taking the next votable slot that the stock code base detects as potentially ready to be voted for, and then applying some additional criteria before voting.  Those criteria are defined by the values I just presented above.  The mod does not alter any of the existing code for selecting when a slot is votable; so existing fork avoidance in the stock code is always applied.  The only additional fork avoidance applied after that is due to the parameters listed above.

In addition, the mods:

Backfill votes.  This is the technique where if slot A has been voted on in the past, and the next slot that the existing validator code base says could be voted on is slot E, then if B, C, and D are also votable, then votes for these slots are added in.  This is a big part of creating "higher committment" to the current fork which gets more vote credits but then becomes more penalized if the current fork ends up dying.

Don't expire slots that don't need to be expired.  The existing code base still "acts like" the old "Vote tx" based code, that expires votes out of the tower according to the original tower design.  But that's no longer necessary with VoteStateUpdate which changed consensus rules and doesn't require this expiration.  Not expiring these votes leaves more votes in the tower which then earns more credits; but again, this leads to being more committed to the current fork so more penalized if the current fork dies.

Also the mods prune out votes that haven't been cast yet if voting on those slots would take committment to the current fork beyond 64 slots.  This is a counterbalance to the extra committment that can result from backfill and non-expiry.  It can result in slightly fewer credits earned in rare cases (this occurs a couple of times per epoch typically) but can prevent a very long lockout that could occur without this.

---

The way I visualize voting on Solana is like this: we're all a part of a giant pack of wolves all trying to hunt the same prey.  At any given time, some wolves will be at the forefront of the pack and a few steps closer to the prey than others; but if these wolves get too far out ahead, it may end up being the case that the pack as a whole moves elsewhere (new prey is discovered) and they are segregated and then have to catch up again.  As a wolf in the pack, I am willing to go a few steps ahead of most of the pack (in my case, 4 steps ahead of 45% of the rest of the pack), but once most of the pack gets too far behind (another way of saying, I get too far ahead), I stop and wait for them to catch up.

Stopping and waiting for them to catch up can be seen as a kind of lag (because I'm no longer running as fast as I can, I'm pausing while waiting for the rest of the group), but at the same time, it's also a valid safety net to prevent me from getting so far ahead that I am very likely to lose the pack.

I don't feel obligated to go as far ahead of the pack as I can, I only need to be willing to always go a bit ahead.  If all wolves allow themselves to go a bit ahead, but none allow themselves to go too far ahead, then the pack always progresses because there are always some wolves at the forefront leading the way.

The existing code base already has its own criteria: it will go up to 8 steps ahead of 38% of the pack.  One could argue that this is more pack-friendly because the leaders are willing to lead from that much further ahead; but in my opinion, if the pack can't keep up, then there's no real value in going that much further ahead.  4 steps is fine.

---

FWIW I've been using these specific mods for over a year, and similar mods (implemented much more poorly but with approximately the same effect) for two years before that.  Never an issue.
Also be aware that if you use really extreme values (i.e. greater than 0.66 for mostly confirmed threshold, greater than 8 for vote-ahead), it's possible for your voting to break.  I have experimented with values like that in the past and had some issues.  I would not recommend greater than 0.6 for mostly confirmed threshold, or greater than 4 for vote-ahead.

In terms of what could be improved to get those additional credits:
There may be edge cases I don't understand/haven't thought through where votes are being pruned out for safety that they don't need to be.  In other words, this code might be a little too conservative and might be missing some votes sometimes.
There may be other ways to do fork avoidance that would be better at avoiding forks; although if those techniques introduce more waiting for info sometimes then they are inducing more artificial lag and that needs to be considered.
There may be ways to alter the existing code base's selection of "next slot to vote on" so that it is either faster or less likely to choose a dying fork or both; I didn't mess with that code because I didn't want to break it and it has to deal with a lot of edge cases that could cause cluster breakage.  So tread carefully.
Heuristics for predicting when a fork is likely to die.  Could keep historical data from which the likelihood that a slot is going to be skipped on factors like how often the leader is skipped, how slow the shreds are coming, whether or not the subsequent leader often skips its predecessor, etc.  Better prediction would mean voting on the wrong fork less often, and voting on the wrong fork is almost entirely the reason that vote credits are missed, so more accurate fork prediction leading to better dead-fork avoidance would be very beneficial.



</details>
