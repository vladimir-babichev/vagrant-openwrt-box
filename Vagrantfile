Vagrant.configure("2") do |config|
  config.vm.box = "vladimir-babichev/openwrt-21.02"
  # config.vm.box_version = "0.3.0"

  # Uncomment bellow for continuous folder sync
  # config.trigger.after :up do |t|
  #   t.info = "rsync auto"
  #   t.run = {inline: "vagrant rsync-auto"}
  #   # If you want it running in the background switch these
  #   # t.run = {inline: "bash -c 'vagrant rsync-auto &'"}
  # end

  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--nic2", "nat"]
    v.customize ["modifyvm", :id, "--nic3", "bridged", "--bridgeadapter3", "en0"]
  end
end
