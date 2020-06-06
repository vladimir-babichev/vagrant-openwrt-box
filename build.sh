 #!/usr/bin/env bash

set -euxo pipefail

export BASE_DIR="$PWD"
export BUILD_DIR="$BASE_DIR/.build"
export OPENWRT_VERSION="19.07.3"
export VM_NAME="openwrt"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

wget -O "$BUILD_DIR/openwrt-$OPENWRT_VERSION.img.gz" "https://downloads.openwrt.org/releases/$OPENWRT_VERSION/targets/x86/64/openwrt-$OPENWRT_VERSION-x86-64-combined-ext4.img.gz"
gzip -d "$BUILD_DIR/openwrt-$OPENWRT_VERSION.img.gz"

VBoxManage convertfromraw --format VDI "$BUILD_DIR/openwrt-$OPENWRT_VERSION.img" "$BUILD_DIR/openwrt-$OPENWRT_VERSION.vdi"

VBoxManage createvm --name "$VM_NAME" --ostype "Linux_64" --register
VBoxManage storagectl "$VM_NAME" --name SATA --add sata --controller IntelAHCI --portcount 1
VBoxManage storageattach "$VM_NAME" --storagectl SATA --port 0 --device 0 --type hdd --medium "$BUILD_DIR/openwrt-$OPENWRT_VERSION.vdi"
VBoxManage export "$VM_NAME" --output "$BUILD_DIR/$VM_NAME.ovf"
VBoxManage unregistervm "$VM_NAME" --delete

packer build ../packer.json
