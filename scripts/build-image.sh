#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building NixOS OCI image for ARM64..."

if [[ "$(uname -m)" == "aarch64" || "$(uname -m)" == "arm64" ]]; then
    echo "Building natively on ARM64..."
    nix build .#
else
    echo "WARNING: Building on x86_64 - this requires QEMU emulation and will be slow."
    echo "For faster builds, use an ARM machine or remote builder."
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    # Check if binfmt_misc is configured for aarch64
    if ! qemu-aarch64-static -version &>/dev/null; then
        echo "ERROR: QEMU not available. Please install qemu-user-static or build on ARM hardware."
        exit 1
    fi
    
    nix build .#
fi

echo ""
echo "Image built successfully: result/nixos.qcow2"
echo "Now run 'make deploy' to deploy to Oracle Cloud."
