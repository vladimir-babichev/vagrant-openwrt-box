SHELL := bash

export ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
export BUILD_DIR ?= $(ROOT_DIR)/.build
export OUTPUT_DIR ?= $(ROOT_DIR)/.output
export PACKER_CACHE_DIR ?= $(BUILD_DIR)/packer_cache

export NAME ?= openwrt
export VERSION ?= 21.02.0-rc3
export TIMESTAMP := $(shell date +%s)
export BOX_NAME ?= $(NAME)-$(VERSION)
export VM_NAME ?= $(NAME)-$(VERSION)-$(TIMESTAMP)

.PHONY: dirs
dirs: ## Create build directory
	@@mkdir -p "$(BUILD_DIR)" "$(OUTPUT_DIR)"

.PHONY: fetch-image
fetch-image: ## Fetch OpenWrt disk image
	@@if [[ $(VERSION) =~ 21\..* ]]; then \
		wget -O "$(BUILD_DIR)/openwrt-$(VERSION).img.gz" "https://downloads.openwrt.org/releases/$(VERSION)/targets/x86/64/openwrt-$(VERSION)-x86-64-generic-ext4-combined.img.gz"; \
		gzip -d "$(BUILD_DIR)/openwrt-$(VERSION).img.gz" || exit 0; \
	else \
		wget -O "$(BUILD_DIR)/openwrt-$(VERSION).img.gz" "https://downloads.openwrt.org/releases/$(VERSION)/targets/x86/64/openwrt-$(VERSION)-x86-64-combined-ext4.img.gz"; \
		gzip -d "$(BUILD_DIR)/openwrt-$(VERSION).img.gz"; \
	fi

.PHONY: convert-image
convert-image: ## Convert RAW disk image to VDI format
	VBoxManage convertfromraw --format VDI "$(BUILD_DIR)/openwrt-$(VERSION).img" "$(BUILD_DIR)/openwrt-$(VERSION).vdi"

.PHONY: vm-image
vm: ## Create VirtualBox machine image
	VBoxManage createvm --name "$(VM_NAME)" --ostype "Linux_64" --register
	VBoxManage storagectl "$(VM_NAME)" --name SATA --add sata --controller IntelAHCI --portcount 1
	VBoxManage storageattach "$(VM_NAME)" --storagectl SATA --port 0 --device 0 --type hdd --medium "$(BUILD_DIR)/openwrt-$(VERSION).vdi"
	VBoxManage export "$(VM_NAME)" --output "$(BUILD_DIR)/$(VM_NAME).ovf"
	VBoxManage unregistervm "$(VM_NAME)" --delete

.PHONY: build
build: ## Build Vagrant Box
	packer build packer.json

.PHONY: clean
clean: ## Cleanup
	rm -rf $(BUILD_DIR) $(OUTPUT_DIR)

.PHONY: all
all: dirs fetch-image convert-image vm build ## Run all steps

.PHONY: help
help: ## This help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort
