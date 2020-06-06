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
For the simple use case with only one pre-provisioned interface (`mng`) you will need to create `Vagrantfile` with the following content:
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "vladimir-babichev/openwrt-19.07.3"
end
```

For more advanced use cases, with more interfaces:
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "vladimir-babichev/openwrt-19.07.3"

  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--nic2", "nat"]
    v.customize ["modifyvm", :id, "--nic3", "bridged", "--bridgeadapter3", "en0"]
  end
end
```
After starttup Vagrant box will have 3 network adapters attached to it with following configuration:
* `nic1` set to `NAT` and discovered as `eth0` (`mng`) interface
* `nic2` set to `NAT` and discovered as `eth1` (`wan`) interface
* `nic3` set to `bridge` with `en0` and discovered as `eth2` (`lan`) interface

More information about Vagrant can be found [here](https://www.vagrantup.com/intro/getting-started)
