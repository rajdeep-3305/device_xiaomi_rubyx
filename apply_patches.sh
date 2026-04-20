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
            error "Fix conflict manually in $repo_path then re-run."
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
info "   Applying required patches for rubyx"
info "========================================="
echo ""

# ── Original rubyx patches ────────────────────────────────────────────────────

# 1. hardware/lineage/compat
apply_gerrit_commit \
    "hardware/lineage/compat" \
    "https://github.com/LineageOS/android_hardware_lineage_compat" \
    "refs/changes/04/447604/1"

# 2. external/wpa_supplicant_8
apply_patch_dir "external/wpa_supplicant_8"

# 3. frameworks/av
apply_patch_dir "frameworks/av"

# 4. frameworks/base
apply_patch_dir "frameworks/base"

# 5. system/core [miuicamera]
apply_patch_dir "system/core"

# ── bpf: Android 16 QPR2 BPF patches for 4.19 kernel ──────────────────────────

# 6. packages/modules/DnsResolver
apply_patch_dir "packages/modules/DnsResolver"

# 7. system/apex
apply_patch_dir "system/apex"

echo ""
info "========================================="
info "    All patches applied successfully"
info "========================================="
echo ""
