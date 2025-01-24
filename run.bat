@echo off

nasm -fbin ./src/%1.s -o ./bin/%1.bin
qemu-system-x86_64 -hda ./bin/%1.bin