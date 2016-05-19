# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "debian/jessie64"
  config.vm.synced_folder "shared", "/vagrant", type: "virtualbox"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 3072
    vb.cpus = 8
    if !File.exist?("disk.vdi")
       vb.customize [
            'createhd', 
            '--filename', 'disk', 
            '--format', 'VDI', 
            '--size', 60200
            ] 
       vb.customize [
            'storageattach', :id,
            '--storagectl', "SATA Controller",
            '--port', 1, '--device', 0,
            '--type', 'hdd', '--medium', 'disk.vdi'
            ]
     end 
  end
  config.vm.provision "file", source: "shared/vimrc", destination: "/home/vagrant/.vimrc"
  config.vm.provision "shell", inline: <<-SHELL
    systemctl enable systemd-timesyncd.service
    systemctl start systemd-timesyncd.service
    cp /vagrant/sources.list /etc/apt/
    chown root.root /etc/apt/sources.list
    echo "Acquire::Retries 5;" > /etc/apt/apt.conf.d/55retry-downloads
    curl http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add -
    dpkg --add-architecture armhf
    apt-get update
    apt-get -y dist-upgrade 
    apt-get -y install tree parted vim-nox build-essential crossbuild-essential-armhf tree p7zip-full linux-headers-amd64
    if [ ! -e /dev/sdb1 ]; then
      parted -s /dev/sdb -- \
        mklabel msdos \
        mkpart primary ext2 0 -1s
      mkfs.ext4 /dev/sdb1
      mkdir /data
      echo "/dev/sdb1  /data  ext4  defaults  0  0" >> /etc/fstab
    fi
    mount -a
    chown vagrant.vagrant /data
    wget http://download.virtualbox.org/virtualbox/5.0.20/VBoxGuestAdditions_5.0.20.iso
    sudo mkdir /media/VBoxGuestAdditions
    sudo mount -o loop,ro VBoxGuestAdditions_5.0.20.iso /media/VBoxGuestAdditions
    sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run
    sudo umount /media/VBoxGuestAdditions
    sudo rmdir /media/VBoxGuestAdditions
    rm VBoxGuestAdditions_5.0.20.iso
  SHELL
  config.vm.provision "shell", privileged: "false", inline: <<-SHELL
    cd /vagrant
    cp rootfs.sh qt.sh kernel.sh /data/
    /data/rootfs.sh
    /data/qt.sh
    /data/kernel.sh
  SHELL
end