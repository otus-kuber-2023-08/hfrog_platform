#!/bin/bash
set -x
set -e

mkdir ~/.ssh
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_ed25519
chmod 400 ~/.ssh/id_ed25519
