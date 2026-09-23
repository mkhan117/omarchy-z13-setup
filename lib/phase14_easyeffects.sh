#!/bin/bash
# Phase 14: EasyEffects (speaker + mic presets)
#
# Phase 4 deploys the IRZ13 Flow / Perfect EQ / FlowMic presets, but nothing
# installed or ran EasyEffects, so they never loaded. This installs it plus
# lsp-plugins-lv2 (the compressor, multiband, equalizer, gate and limiter the
# presets use are LSP plugins, which the easyeffects package doesn't pull in),
# runs it as a systemd user service tied to the graphical session, and loads
# the presets once. EasyEffects remembers the loaded presets from then on.
#
# The ALC294's speakers and headphones are two ports on the same PipeWire
# sink, so a loaded output preset applies to both. To give headphones their own
# preset (or none), set per-route autoload in the EasyEffects UI.

EASYEFFECTS_SERVICE="easyeffects.service"
EASYEFFECTS_SERVICE_PATH="$HOME/.config/systemd/user/$EASYEFFECTS_SERVICE"
EASYEFFECTS_DATA="$HOME/.local/share/easyeffects"
EASYEFFECTS_OUTPUT_PRESET="IRZ13 Flow"
EASYEFFECTS_INPUT_PRESET="FlowMic"

phase14_check() {
    is_pkg_installed easyeffects \
        && is_pkg_installed lsp-plugins-lv2 \
        && [[ -f "$EASYEFFECTS_SERVICE_PATH" ]] \
        && systemctl --user is-enabled "$EASYEFFECTS_SERVICE" &>/dev/null \
        && [[ -f "$EASYEFFECTS_DATA/output/$EASYEFFECTS_OUTPUT_PRESET.json" ]] \
        && [[ -f "$EASYEFFECTS_DATA/input/$EASYEFFECTS_INPUT_PRESET.json" ]]
}

phase14_run() {
    local missing=()
    is_pkg_installed easyeffects     || missing+=(easyeffects)
    is_pkg_installed lsp-plugins-lv2 || missing+=(lsp-plugins-lv2)

    if [[ ${#missing[@]} -gt 0 ]]; then
        info "Installing ${missing[*]}..."
        run_sudo pacman -S --needed --noconfirm "${missing[@]}"
        success "EasyEffects installed."
    else
        success "EasyEffects already installed."
    fi

    # Presets normally come from phase 4; copy any that are missing (never
    # overwrite, so edits made in the EasyEffects UI survive a re-run)
    info "Ensuring EasyEffects presets are in place..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would copy missing presets from dotfiles/easyeffects to $EASYEFFECTS_DATA"
    else
        mkdir -p "$EASYEFFECTS_DATA"/{input,output,irs}
        cp -n "$SCRIPT_DIR/dotfiles/easyeffects/output/"*.json "$EASYEFFECTS_DATA/output/"
        cp -n "$SCRIPT_DIR/dotfiles/easyeffects/input/"*.json "$EASYEFFECTS_DATA/input/"
        cp -n "$SCRIPT_DIR/dotfiles/easyeffects/irs/"*.irs "$EASYEFFECTS_DATA/irs/"
    fi
    success "Presets in place."

    info "Installing EasyEffects systemd user service..."
    run_cmd mkdir -p "$(dirname "$EASYEFFECTS_SERVICE_PATH")"
    run_cmd cp "$SCRIPT_DIR/templates/easyeffects.service" "$EASYEFFECTS_SERVICE_PATH"
    run_cmd systemctl --user daemon-reload
    run_cmd systemctl --user enable --now "$EASYEFFECTS_SERVICE"
    success "EasyEffects service enabled."

    info "Loading presets ($EASYEFFECTS_OUTPUT_PRESET, $EASYEFFECTS_INPUT_PRESET)..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would run: easyeffects -l \"$EASYEFFECTS_OUTPUT_PRESET\""
        info "[DRY-RUN] would run: easyeffects -l \"$EASYEFFECTS_INPUT_PRESET\""
    else
        local i
        for i in {1..10}; do
            pgrep -x easyeffects >/dev/null && break
            sleep 1
        done
        sleep 2
        if easyeffects -l "$EASYEFFECTS_OUTPUT_PRESET" && easyeffects -l "$EASYEFFECTS_INPUT_PRESET"; then
            success "Presets loaded."
        else
            warn "Couldn't load presets automatically — load them from the EasyEffects UI."
        fi
    fi

    info "Speakers and headphones share one sink on the Z13, so '$EASYEFFECTS_OUTPUT_PRESET'"
    info "also applies to headphones. To change that, set per-device autoload in"
    info "EasyEffects (e.g. 'Perfect EQ' or nothing for the Headphones route)."
}
