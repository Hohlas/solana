#!/bin/bash
sudo ~/.local/share/solana/install/active_release/bin/solana-validator --ledger ~/solana/ledger wait-for-restart-window --skip-new-snapshot-check --max-delinquent-stake 90 --min-idle-time 5 && sudo fstrim -av && date +"start trim: %b %e %H:%M:%S" >> ~/trim.log
