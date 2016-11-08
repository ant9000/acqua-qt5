#!/bin/bash

set -e
BASE=$(dirname $(realpath $0))
ROOTFS_PATH=$BASE/target-rootfs
cd $BASE

# install packages required for compiling on host (TODO: trim this list)
sudo apt-get -y install build-essential libc6-dev libfontconfig1-dev libdbus-1-dev libfreetype6-dev libudev-dev libicu-dev libsqlite3-dev libxslt1-dev libssl-dev libasound2-dev libavcodec-dev libavformat-dev libswscale-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev gstreamer-tools gstreamer0.10-plugins-good gstreamer0.10-plugins-bad libpulse-dev libx11-dev libglib2.0-dev libcups2-dev freetds-dev libsqlite0-dev libpq-dev libiodbc2-dev libmysqlclient-dev firebird-dev libpng12-dev libgst-dev libxext-dev libxcb1 libxcb1-dev libx11-xcb1 libx11-xcb-dev libxcb-keysyms1 libxcb-keysyms1-dev libxcb-image0 libxcb-image0-dev libxcb-shm0 libxcb-shm0-dev libxcb-icccm4 libxcb-icccm4-dev libxcb-sync1 libxcb-sync-dev libxcb-render-util0 libxcb-render-util0-dev libxcb-xfixes0-dev libxrender-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-glx0-dev libxi-dev libdrm-dev libdirectfb-dev libjpeg62-turbo-dev libgif-dev mesa-common-dev libgl1-mesa-dev libglu1-mesa-dev libglw1-mesa-dev libdrm-dev libcap-dev zlib1g-dev libxcb-xinerama0 libxcb-xinerama0-dev libusb-dev libproxy-dev

if [ ! -d downloads ]; then
  mkdir downloads
fi

(
cd downloads 

if [ ! -f qt-everywhere-opensource-src-5.7.0.7z ]; then
  wget http://download.qt.io/archive/qt/5.7/5.7.0/single/qt-everywhere-opensource-src-5.7.0.7z
fi
)

if [ ! -d qt-everywhere-opensource-src-5.7.0 ]; then
  7z x downloads/qt-everywhere-opensource-src-5.7.0.7z
fi

if [ ! -d qt-everywhere-opensource-src-5.7.0/qtbase/mkspecs/devices/linux-arm-acqua-a5-g++ ]; then
  (
    cd qt-everywhere-opensource-src-5.7.0/qtbase/mkspecs/devices/
    cp -r linux-beagleboard-g++/ linux-arm-acqua-a5-g++/
    perl -i -ne '/Extra stuff|EGL|OPENGL|OPENVG/ || print' linux-arm-acqua-a5-g++/qmake.conf
    perl -i -pe 's/^(# qmake configuration for).*/$1 AcmeSystems Acqua A5/' linux-arm-acqua-a5-g++/qmake.conf
    perl -i -pe 's{^# http://beagleboard.org.*}{# http://www.acmesystems.it/acqua}' linux-arm-acqua-a5-g++/qmake.conf
    perl -i -pe 's{^(QT_QPA_DEFAULT_PLATFORM\s*=).*}{$1 xcb}' linux-arm-acqua-a5-g++/qmake.conf
    perl -i -pe 's{^(COMPILER_FLAGS\s*=).*}{$1 -mfloat-abi=hard -march=armv7}' linux-arm-acqua-a5-g++/qmake.conf
  )
fi

if [ ! -d build/host ]; then
  mkdir -p build/host
fi

if [ ! -d build/target ]; then
  mkdir -p build/target
fi

########################################
MAKE_ARGS=
CPU_COUNT=`grep -c processor /proc/cpuinfo || true`
if [ $CPU_COUNT -gt 0 ]; then
  MAKE_ARGS="-j$CPU_COUNT"
fi

unset QMAKESPEC
PREFIX=$BASE/Qt5

# compile Qt5 for host
(
  unset PKG_CONFIG_DIR PKG_CONFIG_LIBDIR PKG_CONFIG_SYSROOT_DIR
  cd $BASE/build/host
  time $BASE/qt-everywhere-opensource-src-5.7.0/configure \
    -prefix $PREFIX/host \
    -opensource          \
    -confirm-license     \
    -release             \
    -nomake tests        \
    -skip qtwebengine    \
    -no-directfb         \
    -verbose
  make $MAKE_ARGS
  sudo make $MAKE_ARGS install
) 2>&1 | tee $BASE/build/host.log

unset QMAKESPEC
# cross-compile Qt5 for target
(
  export PKG_CONFIG_DIR=
  export PKG_CONFIG_LIBDIR=$ROOTFS_PATH/usr/lib/pkgconfig/:$ROOTFS_PATH/usr/lib/arm-linux-gnueabihf/pkgconfig/:$ROOTFS_PATH/usr/share/pkgconfig
  export PKG_CONFIG_SYSROOT_DIR=$ROOTFS_PATH
  cd $BASE/build/target
  time $BASE/qt-everywhere-opensource-src-5.7.0/configure \
    -device-option CROSS_COMPILE=arm-linux-gnueabihf- \
    -device linux-arm-acqua-a5-g++ \
    -hostprefix $PREFIX/target/    \
    -sysroot $ROOTFS_PATH          \
    -prefix /opt/Qt5               \
    -opensource                    \
    -confirm-license               \
    -release                       \
    -nomake tests                  \
    -skip qtwebengine              \
    -no-directfb                   \
    -verbose
  make $MAKE_ARGS
  sudo make $MAKE_ARGS install
) 2>&1 | tee $BASE/build/target.log
