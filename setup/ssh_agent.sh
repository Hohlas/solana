#!/bin/bash
# used for public key authentication. 
# Once you add your private key to ssh-agent, 
# you won’t need to enter your passphrase every time.

eval "$(ssh-agent -s)"  # Start ssh-agent in the background
ssh-add ~/keys/*.ssh # Add SSH private key to the ssh-agent
