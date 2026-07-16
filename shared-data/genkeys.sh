#!/bin/bash

##This script is used to regenerate the security keys for sshd and munge

#for ssh
ssh-keygen -t ed25519 -f ./slurm-rsa -N ""

#for munge
dd if=/dev/urandom bs=1 count=1024 of=./munge.key

## protect them
chmod 400 slurm-rsa munge.key

