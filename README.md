# acqua-qt56

This Vagrantfile creates a Debian Jessie VM, preparing it as a cross-compiling machine for Acmesystems Acqua A5.
Updated for Qt5.6.0 and Linux kernel 4.4.10.

## prerequisites

- Vagrant 1.8.1
- VirtualBox 5.0.20
- 8 cores, 4GB of RAM and 25GB of free disk space
- internet connectivity

## usage

`` vagrant up ``

The initial provisioning will download and install everything for you, but it will take some time (about 2 and a half hours on my build machine).

To access the vm, use

`` vagrant ssh ``

Qt5 stuff will be in:
- /data/Qt5/host for the compiling host
- /data/Qt5/target for cross-compiling for Acqua
- /data/target-rootfs/opt/Qt5 should be copied to the board

Kernel stuff to be deployed on the board will be in:
- /data/build/kernel/deploy

Folder `shared/` on the host will be synced with `/vagrant` inside the VM.
