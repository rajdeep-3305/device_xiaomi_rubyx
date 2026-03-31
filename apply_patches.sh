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

apply_patch_file() {
    local repo_path="$1"
    local patch_file="$2"
    local target_dir="$ANDROID_ROOT/$repo_path"
    local patch_name
    patch_name="$(basename "$patch_file")"

    if [ ! -d "$target_dir" ]; then
        warn "$repo_path not found — skipping $patch_name"
        return 0
    fi

    pushd "$target_dir" > /dev/null

    local subject
    subject="$(grep '^Subject: ' "$patch_file" | sed 's/Subject: \[PATCH[^]]*\] //' | head -1)"

    if git log --oneline | grep -qF "$subject"; then
        info "Already applied: $patch_name — skipping"
    else
        info "Applying: $patch_name → $repo_path"
        if git am --3way "$patch_file"; then
            info "✓ $patch_name"
        else
            error "Failed to apply $patch_name"
            git am --abort
            error "Fix the conflict manually in $repo_path then re-run."
            popd > /dev/null
            return 1
        fi
    fi

    popd > /dev/null
}

apply_gerrit_commit() {
    local repo_path="$1"
    local remote_url="$2"
    local gerrit_ref="$3"
    local target_dir="$ANDROID_ROOT/$repo_path"

    if [ ! -d "$target_dir" ]; then
        warn "$repo_path not found — skipping Gerrit ref $gerrit_ref"
        return 0
    fi

    pushd "$target_dir" > /dev/null

    info "Fetching $gerrit_ref from $remote_url ..."
    if ! git fetch "$remote_url" "$gerrit_ref"; then
        error "git fetch failed — check network or if the ref still exists"
        popd > /dev/null
        return 1
    fi

    local subject
    subject="$(git log -1 --format='%s' FETCH_HEAD)"

    if git log --oneline | grep -qF "$subject"; then
        info "Already applied: \"$subject\" — skipping"
    else
        info "Cherry-picking: \"$subject\" → $repo_path"
        if git cherry-pick FETCH_HEAD; then
            info "✓ $subject"
        else
            error "Cherry-pick failed"
            git cherry-pick --abort
            error "Fix the conflict manually in $repo_path then re-run."
            popd > /dev/null
            return 1
        fi
    fi

    popd > /dev/null
}

# =============================================================================
# Patches — applied in order
# =============================================================================
echo ""
info "========================================="
info " Applying required patches for rubyx"
info "========================================="
echo ""

# 1. hardware/lineage/compat
apply_gerrit_commit \
    "hardware/lineage/compat" \
    "https://github.com/LineageOS/android_hardware_lineage_compat" \
    "refs/changes/04/447604/1"

# 2. external/wpa_supplicant_8
apply_patch_file \
    "external/wpa_supplicant_8" \
    "$PATCHES_DIR/external/wpa_supplicant_8/0001-nl80211-Do-not-set-NL80211_WPA_VERSION_3.patch"

# 3. frameworks/av
apply_patch_file \
    "frameworks/av" \
    "$PATCHES_DIR/frameworks/av/0001-Revert-stagefright-distinguish-HAL-name-from-name-in-MediaCodecInfo.patch"

# 4. frameworks/base
apply_patch_file \
    "frameworks/base" \
    "$PATCHES_DIR/frameworks/base/0001-SystemUI-Add-interaction-boost-for-QS-shade-animations.patch"

echo ""
info "========================================="
info " All patches applied successfully"
info "========================================="
echo ""
