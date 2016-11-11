# acqua-qt5

This Vagrantfile creates a Debian Jessie VM, preparing it as a cross-compiling machine for Acmesystems Acqua A5.
Updated for Qt5.7.0 and Linux kernel 4.4.16.

## prerequisites

- Vagrant, with plugin vagrant-vbguest (``vagrant plugin install vagrant-vbguest``)
- VirtualBox
- 4GB of RAM and 25GB of free disk space
- internet connectivity

## usage

`` vagrant up ``

The initial provisioning will download and install everything for you, but it will take some time (about 2 and a half hours on my build machine).

To access the VM, use

`` vagrant ssh ``

## Qt5

Qt5 stuff will be in:
- /home/vagrant/Qt5/host for the compiling host
- /home/vagrant/Qt5/target for cross-compiling for Acqua
- /home/vagrant/target-rootfs/opt/Qt5 should be copied to the board

Compiling example:
```
git clone <<my qt project code>> src
mkdir -p build
cd build
/home/vagrant/Qt5/target/qmake ../src/<<my qt project>>.pro
make -j8
```

## Kernel

Kernel stuff is organized as follows:
- /home/vagrant/linux-4.4.16 contains the kernel tree
- /home/vagrant/build/kernel/src is the out-of-tree build directory
- /home/vagrant/build/kernel/deploy will contain the stuff to be deployed on the board

To produce a custom kernel:
```
export MAKE_ARGS="-j8 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-"
cd /home/vagrant/build/kernel/src
make $MAKE_ARGS menuconfig
make $MAKE_ARGS zImage modules
make $MAKE_ARGS modules_install INSTALL_MOD_PATH=../deploy/
make $MAKE_ARGS firmware_install INSTALL_MOD_PATH=../deploy/
cp arch/arm/boot/zImage ../deploy/boot/
```

To configure the devicetree:
```
export MAKE_ARGS="-j8 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-"
cd /home/vagrant/build/kernel/src
vi /home/vagrant/linux-4.4.16/arch/arm/boot/dts/acme-acqua.dts
make $MAKE_ARGS acme-acqua.dtb
cp arch/arm/boot/dts/acme-acqua.dtb ../deploy/boot/at91-sama5d3_acqua.dtb
```

