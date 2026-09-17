#!/bin/bash
# Phase 6: Gaming Mode + Tools (optional)
#
# Gaming Mode itself (Super+Shift+F5 session handoff to Gamescope/Steam Big
# Picture, and back) is installed by scripts/gaming-mode-install.sh — a
# self-contained installer that also handles capability grants, polkit
# rules, and pacman hooks. It's already wired into the keybind deployed by
# phase 4 (dotfiles/hypr/bindings.conf).
#
# Note: SimpleDeckyTDP is intentionally NOT offered here. It's a Decky
# Loader plugin that sets TDP/PPT limits directly, which would fight with
# Performance Plus's ryzenadj-based limits (phase 5) over the same hardware
# registers — the exact kind of concurrent-writer conflict that caused
# crashes on this hardware. Don't install it alongside this repo's setup.

phase6_check() {
    [[ -f /usr/local/bin/switch-to-gaming ]] \
        && [[ -d "$HOME/homebrew/services" ]] \
        && is_pkg_installed heroic-games-launcher-bin \
        && [[ -f "$HOME/Applications/EmuDeck.AppImage" ]] \
        && [[ -f "$HOME/Applications/.emudeck-version" ]]
}

phase6_run() {
    # --- Gaming Mode (Gamescope session handoff) ---
    if [[ -f /usr/local/bin/switch-to-gaming ]]; then
        success "Gaming Mode already installed."
    elif [[ $DRY_RUN -eq 1 ]]; then
        info "Would prompt to install Gaming Mode (Gamescope session handoff, Super+Shift+F5)"
    else
        if ask_yn "Install Gaming Mode (Gamescope session handoff, Super+Shift+F5)?"; then
            info "Running Gaming Mode installer (scripts/gaming-mode-install.sh)..."
            bash "$SCRIPT_DIR/scripts/gaming-mode-install.sh"
            success "Gaming Mode installed."
        fi
    fi

    # --- Decky Loader ---
    if [[ -d "$HOME/homebrew/services" ]]; then
        success "Decky Loader already installed."
    elif [[ $DRY_RUN -eq 1 ]]; then
        info "Would prompt to install Decky Loader (plugin framework for Gaming Mode)"
    else
        if ask_yn "Install Decky Loader (plugin framework for Gaming Mode)?"; then
            info "Installing Decky Loader..."
            curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh
            success "Decky Loader installed."
        fi
    fi

    # --- Heroic Games Launcher ---
    if is_pkg_installed heroic-games-launcher-bin; then
        success "Heroic Games Launcher already installed."
    elif [[ $DRY_RUN -eq 1 ]]; then
        info "Would prompt to install Heroic Games Launcher (Epic/GOG/Amazon)"
    else
        if ask_yn "Install Heroic Games Launcher (Epic/GOG/Amazon)?"; then
            yay -S --needed --noconfirm heroic-games-launcher-bin
            success "Heroic Games Launcher installed."
        fi
    fi

    # --- Patch Heroic for Gamescope ---
    if [[ -f /opt/Heroic/resources/app.asar ]]; then
        if heroic_needs_patch; then
            if [[ $DRY_RUN -eq 1 ]]; then
                info "Would prompt to patch Heroic for Gamescope (--ozone-platform=x11)"
            else
                echo ""
                info "Heroic needs patching to work in Gamescope/Gaming Mode."
                info "This adds --ozone-platform=x11 to Steam shortcuts so Electron can render in XWayland."
                if ask_yn "Apply Heroic Gamescope patch?"; then
                    info "Patching Heroic for Gamescope compatibility..."
                    if bash "$SCRIPT_DIR/templates/patch-heroic-gamescope.sh"; then
                        sudo cp "$SCRIPT_DIR/templates/patch-heroic-gamescope.sh" /usr/local/bin/patch-heroic-gamescope
                        sudo chmod +x /usr/local/bin/patch-heroic-gamescope
                        success "Heroic patched and patch script installed to /usr/local/bin/"
                    else
                        warn "Heroic patch returned non-zero (may already be patched)"
                    fi
                fi
            fi
        else
            success "Heroic already patched for Gamescope."
        fi
    fi

    # --- EmuDeck ---
    local EMUDECK_APPIMAGE="$HOME/Applications/EmuDeck.AppImage"
    local EMUDECK_VERSION_FILE="$HOME/Applications/.emudeck-version"
    local EMUDECK_API="https://api.github.com/repos/EmuDeck/emudeck-electron/releases/latest"

    if [[ -f "$EMUDECK_APPIMAGE" ]]; then
        local installed_version latest_version latest_url
        installed_version=$(cat "$EMUDECK_VERSION_FILE" 2>/dev/null || echo "unknown")
        latest_version=$(curl -s "$EMUDECK_API" | jq -r '.tag_name' 2>/dev/null || echo "")

        if [[ -z "$latest_version" ]]; then
            success "EmuDeck already installed ($installed_version)."
        elif [[ "$installed_version" == "$latest_version" ]]; then
            success "EmuDeck already installed ($installed_version)."
        elif [[ $DRY_RUN -eq 1 ]]; then
            info "Would prompt to update EmuDeck ($installed_version → $latest_version)"
        else
            if ask_yn "Update EmuDeck ($installed_version → $latest_version)?"; then
                latest_url=$(curl -s "$EMUDECK_API" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .browser_download_url')
                info "Downloading EmuDeck $latest_version..."
                curl -L "$latest_url" -o "$EMUDECK_APPIMAGE"
                chmod +x "$EMUDECK_APPIMAGE"
                echo "$latest_version" > "$EMUDECK_VERSION_FILE"
                success "EmuDeck updated to $latest_version."
            fi
        fi
    elif [[ $DRY_RUN -eq 1 ]]; then
        info "Would prompt to install EmuDeck (emulator setup & ROM management)"
    else
        if ask_yn "Install EmuDeck (emulator setup & ROM management)?"; then
            sudo pacman -S --needed --noconfirm bash flatpak fuse2 git jq rsync python steam unzip zenity
            mkdir -p "$HOME/Applications"
            local latest_version latest_url
            latest_version=$(curl -s "$EMUDECK_API" | jq -r '.tag_name')
            latest_url=$(curl -s "$EMUDECK_API" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .browser_download_url')
            info "Downloading EmuDeck $latest_version..."
            curl -L "$latest_url" -o "$EMUDECK_APPIMAGE"
            chmod +x "$EMUDECK_APPIMAGE"
            echo "$latest_version" > "$EMUDECK_VERSION_FILE"
            success "EmuDeck installed ($latest_version)."
        fi
    fi
}
