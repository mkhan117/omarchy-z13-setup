#!/bin/bash
# Phase 1: Kernel & Drivers (G14 repo, linux-g14 kernel, ROG Control Center)
#
# asusctl itself isn't installed here: Omarchy installs it on every ROG
# machine (install/hardware/asus-rog.sh). rog-control-center, the GUI, is
# still ours to add.
#
# Uses linux-g14 (asus-linux.org) rather than the CachyOS kernel. This repo's
# Performance Plus power system (phase5) was tuned and validated against
# linux-g14's ASUS-specific patches (fan curves, platform-profile integration),
# so we standardize on it instead of layering a second kernel source on top.

phase1_check() {
    file_contains /etc/pacman.conf "[g14]" \
        && is_pkg_installed linux-g14 \
        && is_pkg_installed rog-control-center
}

phase1_run() {
    local made_changes=false

    # If a previous install of the pre-merge script put linux-cachyos on this
    # machine, it's left in place (removing the currently-booted kernel here
    # would be destructive) — but it's installed *alongside* linux-g14 below,
    # not switched. You'll need to boot into linux-g14 explicitly for the
    # kernel Performance Plus was validated against.
    if is_pkg_installed linux-cachyos; then
        warn "linux-cachyos is installed (from a previous install of the pre-merge script)."
        warn "This repo installs linux-g14 alongside it rather than removing it — pick"
        warn "linux-g14 from your bootloader menu after rebooting. Performance Plus (phase 5)"
        warn "was tuned and tested against linux-g14, not linux-cachyos."
        if [[ "$(uname -r)" == *cachyos* ]]; then
            warn "You are currently BOOTED into linux-cachyos ($(uname -r))."
        fi
    fi

    # 1. Add G14 repo if not present
    if ! file_contains /etc/pacman.conf "[g14]"; then
        info "Adding G14 repository..."
        run_sudo_tee /etc/pacman.conf "\n[g14]\nServer = https://arch.asus-linux.org"
        run_sudo pacman-key --recv-keys 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
        run_sudo pacman-key --lsign-key 8F654886F17D497FEFE3DB448B15A6B0E9A3FA35
        run_sudo pacman -Sy
        success "G14 repo added and keys imported."
    else
        success "G14 repo already present."
    fi

    # 2. Install linux-g14 kernel if not installed
    if ! is_pkg_installed linux-g14; then
        info "Installing linux-g14 kernel and headers..."
        run_sudo pacman -S --noconfirm linux-g14 linux-g14-headers
        made_changes=true
        success "linux-g14 kernel installed."
    else
        success "linux-g14 kernel already installed."
    fi

    # 3. Install ROG Control Center if not present
    if ! is_pkg_installed rog-control-center; then
        info "Installing rog-control-center..."
        run_sudo pacman -S --noconfirm rog-control-center
        made_changes=true
        success "rog-control-center installed."
    else
        success "rog-control-center already installed."
    fi

    if $made_changes; then
        NEEDS_REBOOT=1
    fi
}
