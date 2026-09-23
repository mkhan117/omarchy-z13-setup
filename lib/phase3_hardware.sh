#!/bin/bash
# Phase 3: Hardware Support (Tablet utils, Wi-Fi fix, audio)
#
# Firmware is no longer handled here: Omarchy installs the linux-firmware
# meta package explicitly, and it depends on every split firmware package
# (amdgpu, mediatek, cirrus, ...), so none of them can become orphans.

# Internal mic volume ceiling. PipeWire folds the ALC294's "Internal Mic
# Boost" (0/+10/+20/+30 dB) and "Capture" (up to +30 dB) into the one source
# volume, so at 100% the mic runs +60 dB of hardware gain and clips before
# anything downstream (EasyEffects FlowMic) sees it. At 30% the boost stage is
# 0 dB and Capture is +28.5 dB — the level docs/z13flow/easyeffects-mic-setup.md
# measured as clean. Setting it through PipeWire (not amixer + alsactl store,
# as Omarchy's ALC285 fix does) matters: without Omarchy's soft-mixer,
# WirePlumber re-applies the saved route volume to these controls on restore.
MIC_MAX_VOLUME=30

# Name of the PipeWire source for the ALC294's internal mic, if present
z13_mic_source() {
    local codec card
    codec=$(grep -l "ALC294" /proc/asound/card*/codec#* 2>/dev/null | head -1)
    [[ -n $codec ]] || return 1
    card=$(echo "$codec" | grep -oP 'card\K\d+')
    pactl -f json list sources 2>/dev/null \
        | jq -r --arg card "$card" '.[] | select(.properties["alsa.card"] == $card and (.name | startswith("alsa_input."))) | .name' \
        | head -1 | grep .
}

z13_mic_volume() {
    pactl get-source-volume "$1" 2>/dev/null | grep -oP '\d+(?=%)' | head -1
}

z13_mic_ok() {
    local source volume
    source=$(z13_mic_source) || return 0  # not a Z13, or no audio server yet
    volume=$(z13_mic_volume "$source")
    [[ -n $volume ]] && (( volume <= MIC_MAX_VOLUME ))
}

phase3_check() {
    is_pkg_installed iio-hyprland-git \
        && is_pkg_installed wvkbd-deskintl \
        && [[ -f /etc/modprobe.d/mt7925e.conf ]] \
        && is_pkg_installed alsa-utils \
        && [[ ! -f ~/.config/wireplumber/wireplumber.conf.d/alsa-soft-mixer.conf ]] \
        && [[ -f ~/.config/wireplumber/wireplumber.conf.d/hdmi-audio-autoactivate.conf ]] \
        && z13_mic_ok
}

phase3_run() {
    # Remove legacy linux-firmware-git if present (conflicts with split packages)
    if is_pkg_installed linux-firmware-git; then
        warn "linux-firmware-git is installed (obsolete — split packages are now used)."
        if ask_yn "Remove linux-firmware-git?"; then
            run_sudo pacman -Rdd --noconfirm linux-firmware-git
            success "Removed linux-firmware-git."
        else
            warn "Keeping linux-firmware-git. You may encounter file conflicts."
        fi
    fi

    # Ensure yay is available for AUR packages
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
        success "yay installed."
    fi

    # Install AUR packages
    local aur_pkgs=()
    is_pkg_installed iio-hyprland-git || aur_pkgs+=(iio-hyprland-git)
    is_pkg_installed wvkbd-deskintl   || aur_pkgs+=(wvkbd-deskintl)

    if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
        info "Installing AUR packages: ${aur_pkgs[*]}..."
        run_cmd yay -S --noconfirm "${aur_pkgs[@]}"
        success "Tablet utilities installed."
    else
        success "Tablet utilities already installed."
    fi

    # Wi-Fi stability fix
    if [[ ! -f /etc/modprobe.d/mt7925e.conf ]]; then
        info "Creating Wi-Fi stability fix..."
        run_sudo_tee /etc/modprobe.d/mt7925e.conf "options mt7925e disable_aspm=1"
        success "Wi-Fi fix applied."
    else
        success "Wi-Fi fix already in place."
    fi

    # Audio fix: Remove Omarchy's soft-mixer config
    # With soft-mixer enabled, PipeWire doesn't manage ALSA hardware switches,
    # causing speaker/headphone switching to break on jack plug/unplug.
    # See: https://github.com/basecamp/omarchy/issues/4821
    if [[ -f ~/.config/wireplumber/wireplumber.conf.d/alsa-soft-mixer.conf ]]; then
        info "Removing soft-mixer config (breaks headphone/speaker switching)..."
        rm -f ~/.config/wireplumber/wireplumber.conf.d/alsa-soft-mixer.conf
        info "Restarting WirePlumber..."
        systemctl --user restart wireplumber pipewire pipewire-pulse 2>/dev/null || true
        success "Audio fix applied."
    fi

    # Speaker amp initialization (ALC294 + CS35L41)
    if ! is_pkg_installed alsa-utils; then
        info "Installing alsa-utils for mixer control..."
        run_sudo pacman -S --noconfirm alsa-utils
    fi

    # Initial unmute for first boot (PipeWire manages persistence via WirePlumber)
    # Dynamically find the card with ALC294 codec (Z13's Realtek chip)
    local card
    card=$(aplay -l 2>/dev/null | grep -i "ALC294" | head -1 | sed 's/card \([0-9]*\).*/\1/')
    if [[ -n $card ]]; then
        info "Initializing speaker amplifier volume (card $card)..."
        run_cmd amixer -c "$card" set Master 80% unmute
        run_cmd amixer -c "$card" set Speaker unmute
        run_cmd amixer -c "$card" set Headphone unmute
        success "Speaker amp initialized."
    else
        warn "ALC294 codec not found — skipping mixer init"
    fi

    # Internal mic: drop the source volume so the ALC294's analog boost stage
    # sits at 0 dB instead of +30 dB (see MIC_MAX_VOLUME above). WirePlumber
    # saves this as the route volume, so it persists across reboots.
    local mic_source
    if mic_source=$(z13_mic_source); then
        if ! z13_mic_ok; then
            info "Lowering internal mic volume to ${MIC_MAX_VOLUME}% (stops ALC294 boost clipping)..."
            run_cmd pactl set-source-volume "$mic_source" "${MIC_MAX_VOLUME}%"
            success "Internal mic volume set to ${MIC_MAX_VOLUME}%."
        else
            success "Internal mic volume already at or below ${MIC_MAX_VOLUME}%."
        fi
    else
        warn "ALC294 mic source not found in PipeWire — skipping mic level fix"
    fi

    # Note: this repo does not override Omarchy's default power-profile udev
    # rule. Phase 5 (Performance Plus) replaces the whole reactive
    # auto-switch-on-AC-change model with a manually-selected profile, so
    # there's no more spurious-event/fan-curve-rewrite problem to debounce.

    # HDMI audio: Enable auto-profile for AMD HDMI controller
    # Without this, WirePlumber leaves the HDMI audio card profile set to "off"
    # and HDMI monitors never appear as audio output devices.
    local wp_conf_dir="$HOME/.config/wireplumber/wireplumber.conf.d"
    local hdmi_conf="$wp_conf_dir/hdmi-audio-autoactivate.conf"
    if [[ ! -f "$hdmi_conf" ]]; then
        info "Enabling HDMI audio auto-profile..."
        mkdir -p "$wp_conf_dir"
        cat > "$hdmi_conf" << 'EOF'
## Auto-activate HDMI audio output profiles.
## WirePlumber defaults api.acp.auto-profile to false, which leaves
## HDMI audio cards on the "off" profile — monitors never appear as
## audio outputs. This rule enables automatic profile selection for
## AMD/ATI HDMI audio controllers.

monitor.alsa.rules = [
  {
    matches = [
      {
        device.vendor.id = "0x1002"
      }
    ]
    actions = {
      update-props = {
        api.acp.auto-profile = true
        api.acp.auto-port = true
      }
    }
  }
]
EOF
        # Clear any stale "off" profile stored in WirePlumber state.
        # Without this, the state-profile hook restores "off" on every
        # restart, overriding the auto-profile config above.
        local wp_state="$HOME/.local/state/wireplumber/default-profile"
        if [[ -f "$wp_state" ]] && grep -q "alsa_card.pci-0000_c4_00.1=off" "$wp_state"; then
            info "Clearing stale HDMI 'off' profile from WirePlumber state..."
            sed -i '/alsa_card.pci-0000_c4_00.1=off/d' "$wp_state"
        fi

        systemctl --user restart wireplumber pipewire pipewire-pulse 2>/dev/null || true
        success "HDMI audio auto-profile enabled."
    else
        success "HDMI audio auto-profile already configured."
    fi

}
