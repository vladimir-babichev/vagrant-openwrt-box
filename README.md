# vagrant-openwrt-box
This repository builds OpenWrt Vagrant box from the [officially distributed disk images](https://downloads.openwrt.org/) according to [following instructions](https://openwrt.org/docs/guide-user/virtualization/virtualbox-vm).
Image has 3 preconfigured network interfaces:
* `mng` set to `eth0`
* `wan` set to `eth1`
* `lan` set to `eth2`

## Building
To build a box simply run `make all`. Created Vagrant artifact will be stored in the `.output` folder.
To build a specific OpenWrt version run `VERSION=19.07.3 make all`

## Using
### Simple use case
For the simple use case with only one pre-provisioned interface (`mng`) you will need to create `Vagrantfile` with the following content:
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "vladimir-babichev/openwrt-19.07.3"
  config.vm.network "forwarded_port", guest: 80, host: 8080
end
```

### Advanced use case
For more advanced use cases, with more interfaces:
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "vladimir-babichev/openwrt-19.07.3"
  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--nic2", "nat"]
    v.customize ["modifyvm", :id, "--nic3", "bridged", "--bridgeadapter3", "en0"]
  end
end
```
After startup Vagrant box will have 3 network adapters attached to it with the following configuration:
* `nic1` set to `NAT` and discovered as `eth0` (`mng`) interface
* `nic2` set to `NAT` and discovered as `eth1` (`wan`) interface
* `nic3` set to `bridge` with `en0` and discovered as `eth2` (`lan`) interface

More information about Vagrant can be found [here](https://www.vagrantup.com/intro/getting-started).

## Provisioning
### Inline Shell Scripts
Remember to include `privileged: false` in provisioner configuration, otherwise the inline script will fail due to the absence of `sudo` package in the default distribution.
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "vladimir-babichev/openwrt-19.07.3"
  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    opkg update
    opkg remove wpad-mini
    opkg install wpad
  SHELL
end
```

### Ansible Provisioner
Complete example of ansible provisioner can be found [here](https://github.com/vladimir-babichev/vagrant-openwrt-ansible).

## Notes
### Login credentials
* Username: `root`
* Password: `vagrant`

### Limitations
Vagrant doesn't natively support OpenWrt ([see this issue](https://github.com/hashicorp/vagrant/issues/11790)). Due to this fact, features like `synced folders`, `automatic network configuration` **do not work**.

### Network configuration
Because of the limitations mentioned above network configuration has to be done manually and split into two stages:
1. Attachment of network adapters to a virtual machine in `Vagrant` file. See [examples above](#advanced-use-case).
2. Network interface configuration from inside guest OS. See [this](packer.json#L29) and [this](scripts/network.sh).

By default, preconfigured network interfaces are set to DHCP mode.
