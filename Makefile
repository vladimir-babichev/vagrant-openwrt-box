SHELL := bash

export ROOT_DIR := $(shell git rev-parse --show-toplevel)
export BUILD_DIR ?= $(ROOT_DIR)/.build
export OUTPUT_DIR ?= $(ROOT_DIR)/.output
export PACKER_CACHE_DIR ?= $(BUILD_DIR)/packer_cache

export NAME ?= openwrt
export VERSION ?= 22.03.2
export TIMESTAMP := $(shell date +%s)
export BOX_NAME ?= $(NAME)-$(VERSION)
export VM_NAME ?= $(NAME)-$(VERSION)-$(TIMESTAMP)


.PHONY: lint
lint: ## Run pre-commit checks
	pre-commit run --color=always --show-diff-on-failure

.PHONY: lint-all
lint-all: ## Run pre-commit checks against all files
	pre-commit run --color=always --show-diff-on-failure --all-files

.PHONY: dirs
dirs: ## Create build directory
	@@mkdir -p "$(BUILD_DIR)" "$(OUTPUT_DIR)"

.PHONY: fetch-image
fetch-image: dirs ## Fetch OpenWrt disk image
	@@if [[ $(VERSION) =~ 19\..* ]]; then \
		wget -O "$(BUILD_DIR)/openwrt-$(VERSION).img.gz" "https://downloads.openwrt.org/releases/$(VERSION)/targets/x86/64/openwrt-$(VERSION)-x86-64-combined-ext4.img.gz"; \
		gzip -f -d "$(BUILD_DIR)/openwrt-$(VERSION).img.gz"; \
	else \
		wget -O "$(BUILD_DIR)/openwrt-$(VERSION).img.gz" "https://downloads.openwrt.org/releases/$(VERSION)/targets/x86/64/openwrt-$(VERSION)-x86-64-generic-ext4-combined.img.gz"; \
		gzip -f -d "$(BUILD_DIR)/openwrt-$(VERSION).img.gz" || exit 0; \
	fi

.PHONY: convert-image
convert-image: fetch-image ## Convert RAW disk image to VDI format
	VBoxManage convertfromraw --format VDI "$(BUILD_DIR)/openwrt-$(VERSION).img" "$(BUILD_DIR)/openwrt-$(VERSION).vdi"

.PHONY: vm
vm: convert-image ## Create VirtualBox machine image
	VBoxManage createvm --name "$(VM_NAME)" --ostype "Linux_64" --register
	VBoxManage storagectl "$(VM_NAME)" --name SATA --add sata --controller IntelAHCI --portcount 1
	VBoxManage storageattach "$(VM_NAME)" --storagectl SATA --port 0 --device 0 --type hdd --medium "$(BUILD_DIR)/openwrt-$(VERSION).vdi"
	VBoxManage export "$(VM_NAME)" --output "$(BUILD_DIR)/$(VM_NAME).ovf"
	VBoxManage unregistervm "$(VM_NAME)" --delete

.PHONY: build
build: vm ## Build all boxes
	packer build build.pkr.hcl

.PHONY: build-vb
build-vb: vm ## Build Vagrant Box only
	packer build -only=virtualbox-ovf.openwrt-virtualbox build.pkr.hcl

.PHONY: build-lv
build-lv: fetch-image ## Build Libvirt/Qemu Box only
	packer build -only=qemu.openwrt-libvirt build.pkr.hcl

.PHONY: clean
clean: ## Cleanup
	rm -rf $(BUILD_DIR) $(OUTPUT_DIR)

.PHONY: all
all: build shasums ## Build all boxes and print SHA sums

.PHONY: shasums
shasums: ## Print SHA sums
	@echo ""
	@shasum -a 512 $(OUTPUT_DIR)/*.box

.PHONY: help
help: ## This help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort
