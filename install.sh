#!/bin/bash

echo "Compiling asm..."
nasm -f bin mbr.asm -o mbr

echo "Copying files..."
scp -P 20022 mbr root@localhost:

echo "Installing mbr and aaaaa"
ssh root@localhost -p 20022 'dd bs=512 count=1 if=mbr of=/dev/c0d0 ; /sbin/reboot'

