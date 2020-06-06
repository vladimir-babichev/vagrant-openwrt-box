Vagrant.configure("2") do |config|
  config.ssh.username = "root"
  config.ssh.shell = "ash"

  config.vm.synced_folder ".", "/vagrant", disabled: true
end
