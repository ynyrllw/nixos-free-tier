.PHONY: build build-emulated deploy destroy clean init

# Default target
all: build

build:
	@echo "Building NixOS OCI image for ARM64..."
	@if [ "$(shell uname -m)" = "aarch64" ] || [ "$(shell uname -m)" = "arm64" ]; then \
		echo "Building natively on ARM64..."; \
		nix build .#; \
	else \
		echo "WARNING: Building on x86_64 - this requires QEMU emulation and will be slow."; \
		echo "For faster builds, use an ARM machine or remote builder."; \
		nix build .#; \
	fi

init:
	cd terraform && terraform init

plan: init
	cd terraform && terraform plan

deploy: init
	cd terraform && terraform apply

destroy:
	cd terraform && terraform destroy

clean:
	rm -rf result
	cd terraform && rm -rf .terraform .terraform.lock.hcl

output-ip:
	@cd terraform && terraform output -raw instance_ip

ssh:
	@IP=$$(cd terraform && terraform output -raw instance_ip); \
	echo "Connecting to nixos@$$IP"; \
	ssh nixos@$$IP
