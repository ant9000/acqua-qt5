#!/bin/bash

set -e
BASE=$(dirname $(realpath $0))
cd $BASE

sudo apt-get -y install git libncurses5-dev
git config --global user.name vagrant
git config --global user.email vagrant@vagrant

if [ ! -d downloads ]; then
  mkdir downloads
fi

(
cd downloads 

if [ ! -f linux-4.4.16.tar.xz ]; then
  wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.4.16.tar.xz
fi

if [ ! -f linux-4.4.16.patch ]; then
  wget https://raw.githubusercontent.com/AcmeSystems/acmepatches/master/linux-4.4.16.patch
fi
)

if [ ! -d linux-4.4.16 ]; then
  tar xf downloads/linux-4.4.16.tar.xz
fi

(
cd linux-4.4.16
if [ ! -d .git ]; then
  git init .
  git add .
  git commit -m "Linux vanilla"
  git checkout -b acme
  patch -p1 < ../downloads/linux-4.4.16.patch
  git add .
  git commit -m "ACME configs, dts and LCD panels" -a
  patch -p1 < /vagrant/kernel-7panel.patch
  git commit -m '7" panel' -a
fi
)

if [ ! -d build/kernel/src ]; then
  mkdir -p build/kernel/src
  mkdir -p build/kernel/deploy
fi

########################################
MAKE_ARGS="ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-"
CPU_COUNT=`grep -c processor /proc/cpuinfo || true`
if [ $CPU_COUNT -gt 0 ]; then
  MAKE_ARGS="-j$CPU_COUNT $MAKE_ARGS"
fi

(
  cd linux-4.4.16/
  make mrproper
  make O=../build/kernel/src $MAKE_ARGS acme-acqua_defconfig

  cd $BASE/build/kernel/src
  make $MAKE_ARGS zImage modules
  make $MAKE_ARGS acme-acqua.dtb

  rm -rf ../deploy/*
  make $MAKE_ARGS modules_install INSTALL_MOD_PATH=../deploy/
  make $MAKE_ARGS firmware_install INSTALL_MOD_PATH=../deploy/
  mkdir ../deploy/boot/
  cp arch/arm/boot/zImage ../deploy/boot/
  cp arch/arm/boot/dts/acme-acqua.dtb ../deploy/boot/at91-sama5d3_acqua.dtb

) 2>&1 | tee $BASE/build/kernel.log
