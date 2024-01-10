#!/bin/bash
# # #   set links/keys/names
ln -sf ~/keys/${NAME,,}_${NODE}_vote.json ~/solana/vote.json
ln -sf ~/keys/${NAME,,}_${NODE}_validator.json ~/solana/validator-keypair.json
echo '# --- #' >> $HOME/.bashrc
echo 'export TAG='$TAG >> $HOME/.bashrc
echo 'export NODE='$NODE >> $HOME/.bashrc
echo 'export NAME='$NAME >> $HOME/.bashrc
echo 'export validator_key='$(solana address -k ~/solana/validator-keypair.json) >> $HOME/.bashrc
echo 'export vote_account='$(solana address -k ~/solana/vote.json) >> $HOME/.bashrc
