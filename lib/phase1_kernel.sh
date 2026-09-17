#!/bin/bash
# Phase 1: Kernel & Drivers (G14 repo, linux-g14 kernel, ASUS tools)
#
# Uses linux-g14 (asus-linux.org) rather than the CachyOS kernel. This repo's
# Performance Plus power system (phase5) was tuned and validated against
# linux-g14's ASUS-specific patches (fan curves, platform-profile integration),
# so we standardize on it instead of layering a second kernel source on top.

phase1_check() {
    file_contains /etc/pacman.conf "[g14]" \
        && is_pkg_installed linux-g14 \
        && is_pkg_installed asusctl
}

phase1_run() {
    local made_changes=false

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

    # 3. Install ASUS tools if not present
    if ! is_pkg_installed asusctl; then
        info "Installing asusctl and rog-control-center..."
        run_sudo pacman -S --noconfirm asusctl rog-control-center
        made_changes=true
        success "ASUS tools installed."
    else
        success "ASUS tools already installed."
    fi

    if $made_changes; then
        NEEDS_REBOOT=1
    fi
}
