# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "antoniogalea/debian-jessie64-bigdisk"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 4096
    vb.cpus = 8
  end
  config.vm.provision "shell", inline: <<-SHELL
    systemctl enable systemd-timesyncd.service
    systemctl start systemd-timesyncd.service
    apt-get update
    apt-get -y dist-upgrade
    apt-get -y install curl
    curl http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
    dpkg --add-architecture armhf
    cat /vagrant/emdebian.list > /etc/apt/sources.list.d/emdebian.list
    apt-get update
    apt-get -y install tree parted vim-nox build-essential crossbuild-essential-armhf tree p7zip-full
  SHELL
  config.vm.provision "file", source: "vimrc", destination: "/home/vagrant/.vimrc"
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    /vagrant/rootfs.sh
    /vagrant/qt.sh
    /vagrant/kernel.sh
  SHELL
end
