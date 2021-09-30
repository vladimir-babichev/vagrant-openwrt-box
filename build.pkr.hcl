variable "box_name" {
  type    = string
  default = "${env("BOX_NAME")}"
}

variable "build_dir" {
  type    = string
  default = "${env("BUILD_DIR")}"
}

variable "output_dir" {
  type    = string
  default = "${env("OUTPUT_DIR")}"
}

variable "version" {
  type    = string
  default = "${env("VERSION")}"
}

variable "vm_name" {
  type    = string
  default = "${env("VM_NAME")}"
}

locals { 
  timestamp    = regex_replace(timestamp(), "[- TZ:]", "")
  boot_command = [
    "<enter><wait>",
    "passwd <<EOF<enter>vagrant<enter>vagrant<enter>EOF<enter>",
    "uci delete network.lan<enter>",
    "uci set network.mng=interface<enter>",
    "uci set network.mng.ifname='eth0'<enter>",
    "uci set network.mng.proto='dhcp'<enter>",
    "uci commit<enter>",
    "fsync /etc/config/network<enter>",
    "/etc/init.d/network restart<enter>"
  ]
}

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "qemu" "openwrt-libvirt" {
  boot_command     = local.boot_command
  boot_wait        = "20s"
  cpus             = 1
  disk_image       = true
  disk_interface   = "virtio"
  format           = "qcow2"
  headless         = true
  iso_checksum     = "none"
  iso_url          = "file://${var.build_dir}/openwrt-${var.version}.img"
  memory           = 128
  net_device       = "virtio-net"
  shutdown_command = "poweroff"
  ssh_password     = "vagrant"
  ssh_username     = "root"
  ssh_wait_timeout = "300s"
  vm_name          = "${var.box_name}-${local.timestamp}"
}

source "virtualbox-ovf" "openwrt-virtualbox" {
  boot_command         = local.boot_command
  boot_wait            = "20s"
  guest_additions_mode = "disable"
  headless             = true
  shutdown_command     = "poweroff"
  source_path          = "${var.build_dir}/${var.vm_name}.ovf"
  ssh_password         = "vagrant"
  ssh_username         = "root"
  ssh_wait_timeout     = "300s"
  vboxmanage           = [
    ["modifyvm", "{{ .Name }}", "--audio", "none"],
    ["modifyvm", "{{ .Name }}", "--boot1", "disk"],
    ["modifyvm", "{{ .Name }}", "--memory", "128", "--vram", 16],
    ["modifyvm", "{{ .Name }}", "--nic1", "nat"],
    ["modifyvm", "{{ .Name }}", "--usb", "off"],
    ["modifyvm", "{{ .Name }}", "--usbxhci", "off"]
  ]
  vm_name              = "${var.box_name}-${local.timestamp}"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = [
    "source.qemu.openwrt-libvirt",
    "source.virtualbox-ovf.openwrt-virtualbox"
  ]

  provisioner "shell" {
    expect_disconnect   = "true"
    scripts             = ["scripts/network.sh", "scripts/packages.sh", "scripts/vagrant.sh", "scripts/cleanup.sh"]
    start_retry_timeout = "15m"
  }

  post-processor "vagrant" {
    output               = "${var.output_dir}/${var.box_name}-${source.type}.box"
    vagrantfile_template = "tpl/vagrantfile.rb"
  }
}
