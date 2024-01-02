#!/bin/bash
source $HOME/.bashrc
empty=$(solana address -k ~/solana/empty-validator.json)
link=$(solana address -k ~/solana/validator_link.json)
validator=$(solana address -k ~/solana/validator-keypair.json)
vote=$(solana address -k ~/solana/vote.json)
echo '--'
echo $NODE'.'$NAME # 
echo 'epmty_validator: '$empty
echo 'validator_link: '$link
echo 'validator: '$validator
echo 'vote: '$vote
echo '--'
if [[ $link == $empty ]]; then echo 'link=empty: voting OFF'; fi
if [[ $link == $validator ]]; then echo 'link=validator: voting ON'; fi
### ###
###
