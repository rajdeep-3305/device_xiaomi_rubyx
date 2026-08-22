#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[patches]${NC} $*"; }
warn()  { echo -e "${YELLOW}[patches] WARNING:${NC} $*"; }
error() { echo -e "${RED}[patches] ERROR:${NC} $*"; }

apply_patch_dir() {
    local repo_path="$1"
    local patch_dir="$PATCHES_DIR/$repo_path"
    local target_dir="$ANDROID_ROOT/$repo_path"

    if [ ! -d "$target_dir" ]; then
        warn "$repo_path not found — skipping"
        return 0
    fi

    if [ ! -d "$patch_dir" ] || [ -z "$(ls "$patch_dir"/*.patch 2>/dev/null)" ]; then
        warn "No patches found for $repo_path — skipping"
        return 0
    fi

    pushd "$target_dir" > /dev/null

    for patch in "$patch_dir"/*.patch; do
        [ -f "$patch" ] || continue
        local patch_name
        patch_name="$(basename "$patch")"
        local subject
        subject="$(grep '^Subject: ' "$patch" | sed 's/Subject: \[PATCH[^]]*\] //' | head -1)"

        if git log --oneline | grep -qF "$subject"; then
            info "Already applied: $patch_name — skipping"
        else
            info "Applying: $patch_name → $repo_path"
            if git am --3way "$patch"; then
                info "✓ $patch_name"
            else
                error "Failed to apply $patch_name"
                git am --abort
                error "Fix conflict manually in $repo_path then re-run."
                popd > /dev/null
                return 1
            fi
        fi
    done

    popd > /dev/null
}

echo ""
info "========================================="
info "   Applying required patches for rubyx"
info "========================================="
echo ""

# 1. system/core [miuicamera]
apply_patch_dir "system/core"

# 2. system/memory/libdmabufheap [ION fallback for 4.19]
apply_patch_dir "system/memory/libdmabufheap"

# 3. system/memory/libion [anyapex header]
apply_patch_dir "system/memory/libion"

# 4. vendor/lineage [soong generator]
apply_patch_dir "vendor/lineage"

echo ""
info "========================================="
info "    All patches applied successfully"
info "========================================="
echo ""
