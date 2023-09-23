# vagrant-openwrt-box

This repository builds OpenWrt Vagrant box from the [officially distributed disk images](https://downloads.openwrt.org/) according to [following instructions](https://openwrt.org/docs/guide-user/virtualization/virtualbox-vm).
Image has 3 preconfigured network interfaces:

* `mng` set to `eth0`
* `wan` set to `eth1`
* `lan` set to `eth2`

## Building

* To build all boxes simply run `make all`. Created Vagrant artifact will be stored in the `.output` folder.
* To build a specific OpenWrt version run `VERSION=22.03.4 make all`
* To build the Virtualbox box only run: `make build-vb`
* To build the Libvirt box only run: `make build-lv`
* To build with a particular mirror server run `MIRROR_URL="https://mirrors.aliyun.com/openwrt" make all`

## Using

### Simple use case

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "vladimir-babichev/openwrt-22.03"
  config.vm.network "forwarded_port", guest: 80, host: 8080
end
```

### Advanced use case

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "vladimir-babichev/openwrt-22.03"
  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--nic2", "nat"]
    v.customize ["modifyvm", :id, "--nic3", "bridged", "--bridgeadapter3", "en0"]
  end
end
```

Provisioned VM will have 3 network adapters:

* `nic1` set to `NAT` and discovered as `eth0` (`mng`) interface
* `nic2` set to `NAT` and discovered as `eth1` (`wan`) interface
* `nic3` set to `bridge` with `en0` and discovered as `eth2` (`lan`) interface

More information about Vagrant can be found [here](https://www.vagrantup.com/intro/getting-started).

### Synced folders

Since [version 2.2.15](https://github.com/hashicorp/vagrant/blob/main/CHANGELOG.md#2215-march-30-2021) Vagrant supports [rsync synced folders](https://www.vagrantup.com/docs/synced-folders/rsync) for OpenWrt. By default, the content of the current folder synced into `/root` in the guest OS. To disable synchronization add the following snippet to your Vagrantfile:

```ruby
config.vm.synced_folder ".", "/root", disabled: true
```

### Network configuration

Vagrant does not support [`automatic network configuration`](https://github.com/hashicorp/vagrant/issues/12119) for OpenWrt. As a result, network setup split into two stages:

1. Attachment of network adapters to a virtual machine. See [examples above](#advanced-use-case).
2. Network interface configuration from guest OS. See [this](packer.json#L29) and [this](scripts/network.sh).

By default, preconfigured network interfaces set to DHCP mode.

## Provisioning

### Inline Shell Scripts

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "vladimir-babichev/openwrt-22.03"
  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provision "shell", inline: <<-SHELL
    opkg update
    opkg remove wpad-mini
    opkg install wpad
  SHELL
end
```

### Ansible Provisioner

Complete example of ansible provisioner can be found [here](https://github.com/vladimir-babichev/vagrant-openwrt-ansible).

## Notes

### Credentials

* Username: `root`
* Password: `vagrant`

### Extra packages

* `rsync`
* `sudo`
