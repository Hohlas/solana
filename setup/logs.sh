#!/bin/bash

# colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CLEAR='\e[0m'

LOG_FILE="$HOME/solana/solana.log"

if [ ! -f "$LOG_FILE" ]; then
  echo -e "${RED}Error: Log file $LOG_FILE does not exist${CLEAR}"
  exit 1
fi

# check arguments
if [ -z "$1" ]; then
  echo -e " logs from ${YELLOW}$LOG_FILE${CLEAR}"
  tail -f "$LOG_FILE"
else
  echo -e " logs from ${YELLOW}$LOG_FILE grep '$1'${CLEAR}"
  tail -f "$LOG_FILE" | grep --color=auto -i "$1"
fi
