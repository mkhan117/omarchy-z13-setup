#!/bin/bash
# Phase 5: Performance Plus — Power Management
#
# Installs the Ultra-mode power system: a global ryzenadj rate-limiting
# wrapper, a Waybar Q/B/P/U toggle (deployed by phase4 as part of the
# waybar dotfiles), and resume/AC hooks that reassert ryzenadj limits since
# they don't survive suspend or a power-source change.
#
# This is the ONLY power-limit-setting mechanism this repo installs. Do not
# run this alongside another tool that also writes PPT/TDP limits directly
# (e.g. a raw asus-nb-wmi sysfs writer, or a Decky TDP plugin) — concurrent
# writers to the same hardware registers is exactly what caused the crashes
# documented in docs/z13flow/performance-plus.md.

RYZENADJ_WRAPPER="$HOME/.local/bin/ryzenadj"
SLEEP_HOOK="/lib/systemd/system-sleep/performance-plus"
AC_HOOK="/usr/lib/performance-plus/ac-hook"
UDEV_RULE="/etc/udev/rules.d/99-performance-plus-ac.rules"
TMPFILES_CONF="/etc/tmpfiles.d/ryzenadj.conf"
SUDOERS_FILE="/etc/sudoers.d/performance-plus"

phase5_check() {
    [[ -x "$RYZENADJ_WRAPPER" ]] \
        && [[ -x "$SLEEP_HOOK" ]] \
        && [[ -x "$AC_HOOK" ]] \
        && [[ -f "$UDEV_RULE" ]] \
        && [[ -f "$TMPFILES_CONF" ]] \
        && [[ -f "$SUDOERS_FILE" ]] \
        && is_pkg_installed ryzenadj
}

phase5_run() {
    # 1. Install ryzenadj (real binary) from AUR if missing
    if ! is_pkg_installed ryzenadj; then
        info "Installing ryzenadj from AUR..."
        if ! has_command yay; then
            warn "yay not found — installing yay-bin from AUR..."
            local tmpdir
            tmpdir=$(mktemp -d)
            run_cmd git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
            if [[ $DRY_RUN -eq 1 ]]; then
                info "[DRY-RUN] would run: makepkg -si --noconfirm (in $tmpdir/yay-bin)"
            else
                (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
            fi
            rm -rf "$tmpdir"
        fi
        run_cmd yay -S --noconfirm ryzenadj
        success "ryzenadj installed."
    else
        success "ryzenadj already installed."
    fi

    # 2. Install the rate-limiting wrapper (shadows /usr/bin/ryzenadj via PATH)
    info "Installing ryzenadj throttling wrapper to $RYZENADJ_WRAPPER..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would install performance-plus/ryzenadj-wrapper to $RYZENADJ_WRAPPER"
    else
        mkdir -p "$HOME/.local/bin"
        cp "$SCRIPT_DIR/performance-plus/ryzenadj-wrapper" "$RYZENADJ_WRAPPER"
        chmod +x "$RYZENADJ_WRAPPER"
    fi
    success "ryzenadj wrapper installed."

    # 3. /run/ryzenadj tmpfiles provisioning
    info "Installing tmpfiles.d rule for /run/ryzenadj..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would install $TMPFILES_CONF"
    else
        run_sudo cp "$SCRIPT_DIR/performance-plus/ryzenadj.tmpfiles.conf" "$TMPFILES_CONF"
        run_sudo systemd-tmpfiles --create "$TMPFILES_CONF"
    fi
    success "tmpfiles rule installed."

    # 4. sudoers — passwordless ryzenadj + Ultra state-file management
    info "Installing sudoers rule for $USER..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would install $SUDOERS_FILE for user $USER"
    else
        local tmpfile
        tmpfile=$(mktemp)
        sed "s|__USER__|$USER|g" "$SCRIPT_DIR/performance-plus/sudoers.performance-plus.template" > "$tmpfile"
        if ! visudo -cf "$tmpfile" >/dev/null 2>&1; then
            error "Generated sudoers file failed validation — not installing."
            rm -f "$tmpfile"
            return 1
        fi
        run_sudo install -m 0440 "$tmpfile" "$SUDOERS_FILE"
        rm -f "$tmpfile"
    fi
    success "sudoers rule installed."

    # 5. Resume hook — reasserts ryzenadj limits after suspend (CO offset
    # does not survive a sleep cycle)
    info "Installing suspend/resume hook..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would install $SLEEP_HOOK"
    else
        local tmpfile
        tmpfile=$(mktemp)
        sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/performance-plus/performance-plus-sleep-hook" > "$tmpfile"
        run_sudo install -m 0755 "$tmpfile" "$SLEEP_HOOK"
        rm -f "$tmpfile"
    fi
    success "Resume hook installed."

    # 6. AC hook — reasserts Ultra limits when power-profiles-daemon
    # re-applies its own stock limits on an AC power-source change
    info "Installing AC power hook..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would install $AC_HOOK and $UDEV_RULE"
    else
        run_sudo mkdir -p "$(dirname "$AC_HOOK")"
        local tmpfile
        tmpfile=$(mktemp)
        sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/performance-plus/performance-plus-ac-hook" > "$tmpfile"
        run_sudo install -m 0755 "$tmpfile" "$AC_HOOK"
        rm -f "$tmpfile"
        run_sudo cp "$SCRIPT_DIR/performance-plus/99-performance-plus-ac.rules" "$UDEV_RULE"
        run_sudo udevadm control --reload-rules
    fi
    success "AC hook installed."

    info "Performance Plus installed. The Waybar power-profile module (from phase 4)"
    info "cycles Quiet -> Balanced -> Performance -> Ultra on click. See"
    info "docs/z13flow/performance-plus.md for the full design and tuning rationale."
}
