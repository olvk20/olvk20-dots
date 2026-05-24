#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/config"
HOME_SRC="$DOTFILES_DIR/home"

GPU_PACKAGES=()
GPU_NAME="none"

# ── Helpers ────────────────────────────────────────────────────────────────
info()    { echo -e "\e[34m[info]\e[0m  $*"; }
success() { echo -e "\e[32m[ ok]\e[0m  $*"; }
warn()    { echo -e "\e[33m[warn]\e[0m  $*"; }
error()   { echo -e "\e[31m[ err]\e[0m  $*" >&2; }

symlink() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backing up existing $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sfn "$src" "$dst"
    success "linked $dst"
}

# ── 0. OS detection ────────────────────────────────────────────────────────
check_os() {
    if [[ ! -f /etc/arch-release ]]; then
        error "Unsupported OS — this script only runs on Arch Linux."
        exit 1
    fi
    success "Arch Linux detected"
}

# ── GPU driver selection ───────────────────────────────────────────────────
select_gpu() {
    echo ""
    echo -e "\e[1m  GPU Driver Selection\e[0m"
    echo "  ─────────────────────────────────────────────────────────────"
    echo "  1) AMD    — vulkan-radeon, xf86-video-amdgpu, libva-mesa-driver, mesa"
    echo "  2) NVIDIA — nvidia, nvidia-utils, lib32-nvidia-utils, egl-wayland"
    echo "              (also configures Wayland env vars and initramfs)"
    echo "  3) Intel  — vulkan-intel, intel-media-driver, libva-intel-driver, mesa"
    echo "  4) Skip   — no GPU drivers installed"
    echo "  ─────────────────────────────────────────────────────────────"
    echo ""
    read -rp "  Choice [1-4]: " gpu_choice

    case "$gpu_choice" in
        1)
            GPU_PACKAGES=(vulkan-radeon xf86-video-amdgpu libva-mesa-driver mesa)
            GPU_NAME="AMD"
            ;;
        2)
            GPU_PACKAGES=(nvidia nvidia-utils lib32-nvidia-utils egl-wayland)
            GPU_NAME="NVIDIA"
            ;;
        3)
            GPU_PACKAGES=(vulkan-intel intel-media-driver libva-intel-driver mesa)
            GPU_NAME="Intel"
            ;;
        *)
            GPU_PACKAGES=()
            GPU_NAME="none"
            warn "Skipping GPU drivers"
            ;;
    esac
    [[ "$GPU_NAME" != "none" ]] && success "Selected GPU driver: $GPU_NAME"
}

# ── Package preview ────────────────────────────────────────────────────────
preview_packages() {
    # Strip AMD-specific packages from the base list — handled by GPU selection
    local base_pkgs
    base_pkgs=$(grep -v '^\s*#' "$DOTFILES_DIR/packages/pacman.txt" | grep -v '^\s*$' | \
        grep -v -E '^(vulkan-radeon|xf86-video-amdgpu|libva-mesa-driver)$')

    echo ""
    echo -e "\e[1m  Packages to be installed\e[0m"
    echo "  ════════════════════════════════════════════════════════════"
    echo ""
    echo -e "  \e[33m── Base packages (pacman)\e[0m"
    echo "$base_pkgs" | column | sed 's/^/  /'
    echo ""
    echo -e "  \e[33m── AUR packages\e[0m"
    grep -v '^\s*#' "$DOTFILES_DIR/packages/aur.txt" | grep -v '^\s*$' | column | sed 's/^/  /'
    if [[ ${#GPU_PACKAGES[@]} -gt 0 ]]; then
        echo ""
        echo -e "  \e[33m── $GPU_NAME GPU drivers\e[0m"
        printf '  %s\n' "${GPU_PACKAGES[@]}"
    fi
    echo ""
    echo "  ════════════════════════════════════════════════════════════"
    echo ""
    read -rp "  Proceed with installation? [Y/n]: " confirm
    [[ "${confirm,,}" == "n" ]] && { info "Aborted."; exit 0; }
    echo ""
}

# ── 1. Install yay ─────────────────────────────────────────────────────────
install_yay() {
    if command -v yay &>/dev/null; then
        return
    fi
    info "Installing yay..."
    local tmp
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    success "yay installed"
}

# ── 2. Install packages ────────────────────────────────────────────────────
install_packages() {
    # Exclude AMD-specific packages from the base list to avoid conflicts with
    # non-AMD GPU selections; GPU selection installs the right packages instead
    local base_pkgs
    base_pkgs=$(grep -v '^\s*#' "$DOTFILES_DIR/packages/pacman.txt" | grep -v '^\s*$' | \
        grep -v -E '^(vulkan-radeon|xf86-video-amdgpu|libva-mesa-driver)$')

    info "Installing base pacman packages..."
    echo "$base_pkgs" | sudo pacman -S --needed --noconfirm -

    if [[ ${#GPU_PACKAGES[@]} -gt 0 ]]; then
        info "Installing $GPU_NAME drivers: ${GPU_PACKAGES[*]}"
        sudo pacman -S --needed --noconfirm "${GPU_PACKAGES[@]}"
    fi

    install_yay

    info "Installing AUR packages..."
    grep -v '^\s*#' "$DOTFILES_DIR/packages/aur.txt" | grep -v '^\s*$' | \
        yay -S --needed --noconfirm -
}

# ── 3. Symlink ~/.config entries ───────────────────────────────────────────
link_configs() {
    info "Linking config directories..."
    mkdir -p "$HOME/.config"
    for item in "$CONFIG_SRC"/*/; do
        name="$(basename "$item")"
        symlink "$item" "$HOME/.config/$name"
    done
    for item in "$CONFIG_SRC"/*; do
        [ -d "$item" ] && continue
        name="$(basename "$item")"
        symlink "$item" "$HOME/.config/$name"
    done
}

# ── 4. Symlink home dotfiles ───────────────────────────────────────────────
link_home() {
    info "Linking home dotfiles..."
    for f in "$HOME_SRC"/.*; do
        [ "$(basename "$f")" = "." ] && continue
        [ "$(basename "$f")" = ".." ] && continue
        symlink "$f" "$HOME/$(basename "$f")"
    done
}

# ── 5. Copy wallpapers + set initial state ─────────────────────────────────
copy_wallpapers() {
    info "Copying wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    cp -n "$DOTFILES_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true

    # Write initial wallpaper path to cache so awww/init.sh works on first boot
    local cache_file="$HOME/.cache/current_wallpaper"
    if [[ ! -f "$cache_file" ]]; then
        local first_wall
        first_wall=$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \
            \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
            | sort | head -1)
        if [[ -n "$first_wall" ]]; then
            mkdir -p "$HOME/.cache"
            echo "$first_wall" > "$cache_file"
            success "Initial wallpaper set: $(basename "$first_wall")"
        else
            warn "No wallpapers found in dotfiles/wallpapers/ — wallpaper cache not written"
        fi
    fi

    success "Wallpapers ready in ~/Pictures/Wallpapers"
}

# ── 6. Oh My Zsh + default shell ──────────────────────────────────────────
setup_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    local zsh_path
    zsh_path="$(which zsh)"
    if [ "$SHELL" != "$zsh_path" ]; then
        info "Setting zsh as default shell..."
        chsh -s "$zsh_path"
        success "Default shell set to zsh — takes effect on next login"
    fi
}

# ── 7. NVIDIA Wayland configuration ───────────────────────────────────────
setup_nvidia() {
    [[ "$GPU_NAME" != "NVIDIA" ]] && return

    info "Configuring NVIDIA for Wayland/Hyprland..."

    # Add NVIDIA kernel modules to initramfs
    if ! grep -q "nvidia_drm" /etc/mkinitcpio.conf; then
        sudo sed -i \
            's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' \
            /etc/mkinitcpio.conf
        # Clean up accidental leading space: MODULES=( foo) → MODULES=(foo)
        sudo sed -i 's/MODULES=( /MODULES=(/' /etc/mkinitcpio.conf
        sudo mkinitcpio -P
        success "NVIDIA modules added to initramfs"
    fi

    # Add DRM modeset kernel parameter to GRUB
    if [[ -f /etc/default/grub ]]; then
        if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
            sudo sed -i \
                's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1 nvidia.NVreg_UsePageAttributeTable=1"/' \
                /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            success "NVIDIA DRM modeset kernel parameter added to GRUB"
        fi
    else
        warn "GRUB config not found — manually add 'nvidia-drm.modeset=1' to your bootloader kernel parameters"
    fi

    # Inject NVIDIA Wayland env vars into hyprland env.conf
    # The config is symlinked so this writes through to the dotfiles source
    local env_conf="$HOME/.config/hypr/config/env.conf"
    if [[ -f "$env_conf" ]] && ! grep -q "GBM_BACKEND" "$env_conf"; then
        cat >> "$env_conf" <<'EOF'

# NVIDIA Wayland (added by install.sh)
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = ELECTRON_OZONE_PLATFORM_HINT,auto
EOF
        success "NVIDIA Wayland env vars written to hyprland env.conf"
    fi

    success "NVIDIA Wayland setup complete"
    warn "If using systemd-boot instead of GRUB, add 'nvidia-drm.modeset=1' to your boot entry manually"
}

# ── 8. Enable system + user services ──────────────────────────────────────
enable_services() {
    info "Enabling system services..."

    local system_services=(
        NetworkManager
        bluetooth
        cups
        tuned
        ufw
        fstrim.timer      # SSD periodic TRIM
    )
    for svc in "${system_services[@]}"; do
        if sudo systemctl enable --now "$svc" 2>/dev/null; then
            success "enabled $svc"
        else
            warn "Could not enable $svc (may not be installed or already running)"
        fi
    done

    # SDDM: enable without --now since we are not yet in a graphical session
    if sudo systemctl enable sddm 2>/dev/null; then
        success "enabled sddm (starts on next boot)"
    else
        warn "Could not enable sddm"
    fi

    # Pipewire audio stack as user services
    info "Enabling user services (pipewire)..."
    local user_services=(
        pipewire
        pipewire-pulse
        wireplumber
    )
    for svc in "${user_services[@]}"; do
        if systemctl --user enable "$svc" 2>/dev/null; then
            success "enabled user: $svc"
        else
            warn "Could not enable user service $svc (will be started by Hyprland autostart)"
        fi
    done

    success "All services configured"
}

# ── Main ───────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "\e[1m  Hyprland Dotfiles Installer\e[0m"
    echo "  ═════════════════════════════════════════════════════════════"
    echo ""

    check_os
    select_gpu
    preview_packages

    info "Starting installation..."
    install_packages
    link_configs
    link_home
    copy_wallpapers
    setup_zsh
    setup_nvidia
    enable_services

    echo ""
    echo "  ═════════════════════════════════════════════════════════════"
    success "All done! Reboot to start into Hyprland."
    [[ "$GPU_NAME" == "NVIDIA" ]] && \
        info "NVIDIA: verify 'nvidia-drm.modeset=1' is in your bootloader kernel params before rebooting."
    echo ""
}

main "$@"
