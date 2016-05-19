#!/bin/bash

set -e
MIRROR=http://httpredir.debian.org/debian

# install necessary host packages
sudo apt-get -y install realpath multistrap qemu qemu-user-static binfmt-support

BASE=$(dirname $(realpath $0))
ROOT=$BASE/target-rootfs
 
# fix for network errors: retry failed downloads 5 times
sudo mkdir -p $ROOT/etc/apt/apt.conf.d/
sudo cp /etc/apt/apt.conf.d/55retry-downloads $ROOT/etc/apt/apt.conf.d/

cd $BASE
(
# create a clean root filesystem with multistrap
(
cat<<EOF
[General]
directory=$ROOT
cleanup=false
noauth=false
unpack=true
debootstrap=Debian Net Utils Python Qt5
aptsources=Debian 

[Debian]
packages=apt kmod lsof
source=$MIRROR
keyring=debian-archive-keyring
suite=jessie
components=main contrib non-free

[Net]
#Basic packages to enable the networking
packages=netbase net-tools ethtool udev iproute iputils-ping ifupdown isc-dhcp-client host openssh-client
source=$MIRROR

[Utils]
#General purpose utilities
packages=locales adduser nano less wget dialog git usbutils
source=$MIRROR

#Python language
[Python]
packages=python python-serial
source=$MIRROR

[Qt5]
packages=libc6-dev libfontconfig1-dev libdbus-1-dev libfreetype6-dev libudev-dev libicu-dev libsqlite3-dev libxslt1-dev libssl-dev libasound2-dev libavcodec-dev libavformat-dev libswscale-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev gstreamer-tools gstreamer0.10-plugins-good gstreamer0.10-plugins-bad libpulse-dev libx11-dev libglib2.0-dev libcups2-dev freetds-dev libsqlite0-dev libpq-dev libiodbc2-dev libmysqlclient-dev firebird-dev libpng12-dev libgst-dev libxext-dev libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev libxcb-shm0 libxcb-shm0-dev libxcb-icccm4 libxcb-icccm4-dev libxcb-sync1 libxcb-sync-dev libxcb-render-util0 libxcb-render-util0-dev libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-glx0-dev libxi-dev libdrm-dev libjpeg-dev libgif-dev mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev libglw1-mesa-dev libdrm-dev libstdc++-4.9-dev libxcb-xinerama0-dev libusb-dev
source=$MIRROR
EOF
) > multistrap.conf
sudo multistrap -a armhf -f multistrap.conf

# qemu-arm-static is needed inside the chroot to emulate an ARM CPU
sudo cp /usr/bin/qemu-arm-static $ROOT/usr/bin/

# resolv.conf is needed for DNS to work inside chroot
sudo cp /etc/resolv.conf $ROOT/etc/

# make system mount points available in the chroot
for dir in dev dev/pts proc run sys
do
  grep $ROOT/$dir /etc/mtab >/dev/null || sudo mount --bind /$dir $ROOT/$dir
done

# preseed configuration for unattended installation
(
cat <<EOF
dash dash/sh boolean false
tzdata tzdata/Areas select Europe
tzdata tzdata/Zones/Europe select Rome
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
locales locales/default_environment_locale select en_US.UTF-8
EOF
) | sudo chroot $ROOT debconf-set-selections

# configure all packages
sudo DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C chroot $ROOT dpkg --configure -a

# shoot in the head any process still accessing the chroot, if any
for pid in `sudo lsof -Fp0 $ROOT|tr -d p`
do
  sudo kill -9 $pid
done

# umount system dirs from chroot
for dir in dev/pts dev proc run sys
do
  grep $ROOT/$dir /etc/mtab >/dev/null && sudo umount $ROOT/$dir || true
done

# fix absolute links inside rootfs or they will break Qt compile
(
  cd ${ROOT}/usr/lib
  sudo find -L . -type l -printf "%p:%l\n"| while read link
  do
    src=${link%:*}
    dst=${link#*:}
    if [ "${dst:0:1}" == "/" ]; then
      path="../../"
      depth=$(( $( echo "$src" | tr -d ' ' | tr / ' ' | wc -w ) - 2 ))
      for i in `seq $depth`; do path="../$path"; done
      echo "Linking $path${dst:1} to $src"
      sudo ln -f -s $path${dst:1} $src
    fi
  done
)

) 2>&1 | tee rootfs.log
