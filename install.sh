#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/config"
HOME_SRC="$DOTFILES_DIR/home"

# ── Helpers ────────────────────────────────────────────────────────────────
info()    { echo -e "\e[34m[info]\e[0m $*"; }
success() { echo -e "\e[32m[ok]\e[0m   $*"; }
warn()    { echo -e "\e[33m[warn]\e[0m $*"; }

symlink() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backing up existing $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sfn "$src" "$dst"
    success "linked $dst"
}

# ── 1. Install yay first (needed to install AUR packages) ─────────────────
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
    info "Installing pacman packages..."
    sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/packages/pacman.txt"

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
    # single files
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

# ── 5. Copy wallpapers ─────────────────────────────────────────────────────
copy_wallpapers() {
    info "Copying wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    cp -n "$DOTFILES_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/"
    success "Wallpapers copied to ~/Pictures/Wallpapers"
}

# ── 6. Oh My Zsh + set default shell ──────────────────────────────────────
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

# ── 7. Enable system services ──────────────────────────────────────────────
enable_services() {
    info "Enabling system services..."
    sudo systemctl enable --now NetworkManager
    sudo systemctl enable --now bluetooth
    sudo systemctl enable --now cups
    sudo systemctl enable --now tuned
    sudo systemctl enable --now ufw
    sudo systemctl enable sddm
    success "Services enabled"
}

# ── Main ───────────────────────────────────────────────────────────────────
main() {
    info "Starting dotfiles install..."
    install_packages
    link_configs
    link_home
    copy_wallpapers
    setup_zsh
    enable_services
    success "All done! Reboot to start into Hyprland."
}

main "$@"
