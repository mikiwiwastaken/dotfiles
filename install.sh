#!/usr/bin/env bash
#
# Automatic installer for the Catppuccin Mocha Hyprland dotfiles (Arch Linux).
#
# What it does:
#   1. Installs the official packages with pacman
#   2. Installs the AUR packages (bootstraps yay if no AUR helper is found)
#   3. Applies the GTK theme with gsettings
#   4. Clones the dotfiles into ~/.config (existing config is backed up first)
#   5. Creates the symlinks that live outside ~/.config
#   6. Enables and starts the mpd user service
#
# Usage:
#   ./install.sh                  # interactive, pacman asks for confirmation
#   ./install.sh --yes            # pass --noconfirm to pacman, yay and makepkg

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/mikiwiwastaken/dotfiles.git}"
BRANCH="main"
CONFIG_DIR="$HOME/.config"

PACMAN_PACKAGES=(
  git hyprland xdg-desktop-portal-hyprland hyprpolkitagent
  wofi swaync swayosd hyprpaper archlinux-wallpaper hyprlock hypridle
  grim slurp wf-recorder wl-clipboard cliphist
  pavucontrol hyprpicker hyprsunset gvfs libqalculate
  qt5-wayland qt6-wayland qt5ct qt6ct kvantum-qt5 kvantum papirus-icon-theme
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk
  kitty zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions
  starship eza bat ripgrep fd fzf zoxide ncdu
  btop fastfetch cava mpd ncmpcpp
  yazi ffmpeg 7zip jq poppler resvg
  imv zathura zathura-pdf-mupdf tesseract-data-eng mpv
)

AUR_PACKAGES=(
  catppuccin-gtk-theme-mocha
  catppuccin-cursors-mocha
  waybar-git
)

NOCONFIRM=()
AUR_HELPER=""

# ---------------------------------------------------------------- helpers

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

parse_args() {
  for arg in "$@"; do
    case "$arg" in
      -y|--yes) NOCONFIRM=(--noconfirm) ;;
      -h|--help)
        # Print the leading comment block (everything after the shebang).
        awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
        exit 0
        ;;
      *) die "Unknown option: $arg" ;;
    esac
  done
}

preflight() {
  [[ $EUID -ne 0 ]] || die "Do not run this script as root. It will call sudo when needed."
  command -v pacman >/dev/null || die "pacman not found. This script only supports Arch Linux."
  command -v sudo   >/dev/null || die "sudo not found. Install it and add your user to the wheel group."
}

# Append LINE to FILE unless a line containing KEY is already there.
append_once() {
  local file="$1" key="$2" line="$3"

  touch "$file"
  if grep -qF "$key" "$file"; then
    log "$key is already set in $file, leaving it alone"
    return
  fi

  # Make sure the previous last line is newline-terminated.
  if [[ -s "$file" && -n "$(tail -c1 "$file")" ]]; then
    printf '\n' >> "$file"
  fi
  printf '%s\n' "$line" >> "$file"
}

# ------------------------------------------------------------------ steps

install_pacman_packages() {
  log "Installing official packages"
  sudo pacman -Syu --needed "${NOCONFIRM[@]}" "${PACMAN_PACKAGES[@]}"
}

ensure_aur_helper() {
  for helper in yay paru; do
    if command -v "$helper" >/dev/null; then
      AUR_HELPER="$helper"
      return
    fi
  done

  log "No AUR helper found, building yay-bin from the AUR"
  sudo pacman -S --needed "${NOCONFIRM[@]}" base-devel git

  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si "${NOCONFIRM[@]}")
  rm -rf "$tmp"
  AUR_HELPER="yay"
}

install_aur_packages() {
  ensure_aur_helper
  log "Installing AUR packages with $AUR_HELPER"
  "$AUR_HELPER" -S --needed "${NOCONFIRM[@]}" "${AUR_PACKAGES[@]}"
}

set_gtk_theme() {
  log "Applying GTK theme"

  if ! command -v gsettings >/dev/null; then
    warn "gsettings not found, skipping the GTK theme."
    return
  fi

  # Without a D-Bus session (e.g. when run from a TTY) the settings would not persist.
  local runner=()
  if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && command -v dbus-run-session >/dev/null; then
    runner=(dbus-run-session --)
  fi

  if ! {
    "${runner[@]}" gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' &&
    "${runner[@]}" gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default' &&
    "${runner[@]}" gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-mocha-dark-cursors'
  }; then
    warn "Could not apply the GTK theme. Run the gsettings commands from the README inside your Hyprland session."
  fi
}

install_dotfiles() {
  mkdir -p "$CONFIG_DIR"

  if [[ -d "$CONFIG_DIR/.git" ]]; then
    log "Dotfiles repo already exists in $CONFIG_DIR, updating"
    git -C "$CONFIG_DIR" pull --ff-only origin "$BRANCH"
    return
  fi

  local backup
  backup="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
  log "Backing up the existing config to $backup"
  cp -a "$CONFIG_DIR" "$backup"

  log "Cloning dotfiles into $CONFIG_DIR"
  cd "$CONFIG_DIR"
  git init -b "$BRANCH"
  git remote add origin "$REPO_URL"
  git fetch origin
  git checkout -f -B "$BRANCH" "origin/$BRANCH"
  git branch --set-upstream-to="origin/$BRANCH" "$BRANCH"
}

create_symlinks() {
  log "Creating symlinks outside ~/.config"
  mkdir -p "$HOME/.local/bin"
  chmod +x "$CONFIG_DIR"/scripts/*
  ln -sf "$CONFIG_DIR/scripts/screenshot"    "$HOME/.local/bin/screenshot"
  ln -sf "$CONFIG_DIR/scripts/record"        "$HOME/.local/bin/record"
  ln -sf "$CONFIG_DIR/scripts/music"         "$HOME/.local/bin/music"
  ln -sf "$CONFIG_DIR/scripts/music-watch"   "$HOME/.local/bin/music-watch"
  ln -sf "$CONFIG_DIR/scripts/ncmpcpp-mocha" "$HOME/.local/bin/ncmpcpp-mocha"
  ln -sf "$CONFIG_DIR/zsh/.zshrc"            "$HOME/.zshrc"
}

enable_mpd() {
  log "Enabling the mpd user service"

  if ! command -v systemctl >/dev/null; then
    warn "systemctl not found, skipping mpd."
    return
  fi

  # Needs a user systemd session (e.g. not available over a bare su/sudo shell).
  if ! systemctl --user enable --now mpd.service; then
    warn "Could not start mpd. Run this from inside your Hyprland session:"
    printf '  systemctl --user enable --now mpd.service\n' >&2
  fi
}

print_next_steps() {
  printf '\nDone. Next steps:\n'
  printf '  - Log out and start Hyprland from your display manager or TTY.\n'
}

# ------------------------------------------------------------------- main

main() {
  parse_args "$@"
  preflight
  install_pacman_packages
  install_aur_packages
  set_gtk_theme
  install_dotfiles
  create_symlinks
  enable_mpd
  print_next_steps
}

main "$@"
