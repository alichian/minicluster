#!/bin/bash

##This script is used to regenerate the security keys for sshd and munge

#for ssh
ssh-keygen -t ed25519f -f ./slurm-rsa

#for munge
dd if=/dev/urandom bs=1 count=1024 of=./munge.key
