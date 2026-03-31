#!/usr/bin/env bash
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

# Apply source patches from device tree
bash "$MY_DIR/apply_patches.sh"
