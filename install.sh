#!/usr/bin/env bash
#
# Automatic installer for the Catppuccin Mocha Hyprland dotfiles (Arch Linux).
#
# What it does:
#   1. Installs the official packages with pacman
#   2. Installs the AUR packages
#   3. Applies the GTK theme with gsettings
#   4. Checks out the dotfiles into $HOME from a bare repo in ~/.dotfiles
#   5. Enables the mpd user service and the services the Quickshell controls use
#   6. Optionally sets up the greetd login manager (tuigreet)
#   7. Optionally applies the Catppuccin Mocha palette to the TTY
#   8. Optionally sets up hybrid Intel + NVIDIA graphics (only offered when
#      both GPUs are detected)
#
# Usage:
#   ./install.sh                  # interactive, pacman asks for confirmation
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/mikiwiwastaken/dotfiles/main/install.sh)"

set -euo pipefail

REPO_URL="${DOTFILES_REPO:-https://github.com/mikiwiwastaken/dotfiles.git}"
BRANCH="main"
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

PACMAN_PACKAGES=(
  base-devel git hyprland xdg-desktop-portal-hyprland hyprpolkitagent
  quickshell hyprpaper archlinux-wallpaper hyprlock hypridle hyprpicker
  grim slurp wf-recorder wl-clipboard cliphist libnotify
  qt5-wayland qt6-wayland qt5ct qt6ct kvantum-qt5 kvantum papirus-icon-theme
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk
  kitty zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions
  neovim unzip tree-sitter-cli
  starship eza bat ripgrep fd fzf zoxide ncdu
  btop fastfetch cava mpd ncmpcpp
  yazi ffmpeg 7zip jq poppler resvg
  imv zathura zathura-pdf-mupdf tesseract-data-eng mpv
  networkmanager pipewire wireplumber
)

BATTERY_PACKAGES=(
  upower power-profiles-daemon
)

AUR_PACKAGES=(
  catppuccin-gtk-theme-mocha
  catppuccin-cursors-mocha
)

TTY_PALETTE="vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166 vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173 vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200"

AUR_TMP=""

# ---------------------------------------------------------------- helpers

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2
  exit 1
}

preflight() {
  [[ $EUID -ne 0 ]] || die "Do not run this script as root. It will call sudo when needed."
  command -v pacman >/dev/null || die "pacman not found. This script only supports Arch Linux."
  command -v sudo >/dev/null || die "sudo not found. Install it and add your user to the wheel group."
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
    printf '\n' >>"$file"
  fi
  printf '%s\n' "$line" >>"$file"
}

# Ask a yes/no question. The second argument is the default answer.
ask() {
  local prompt="$1" default="${2:-n}" hint reply=""

  { true </dev/tty; } 2>/dev/null || return 1

  if [[ "$default" == y ]]; then hint="Y/n"; else hint="y/N"; fi
  read -r -p "$prompt [$hint] " reply </dev/tty || true
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy] ]]
}

has_battery() {
  compgen -G '/sys/class/power_supply/BAT*' >/dev/null
}

# Print the PCI address (for example 0000:00:02.0) of the first display
# controller with the given vendor ID. Prints nothing when there is no match.
find_gpu_address() {
  local vendor="$1" dev

  for dev in /sys/bus/pci/devices/*; do
    [[ -r "$dev/class" && -r "$dev/vendor" ]] || continue
    [[ "$(<"$dev/class")" == 0x03* ]] || continue
    [[ "$(<"$dev/vendor")" == "$vendor" ]] || continue
    basename "$dev"
    return
  done
}

# True when both an Intel and an NVIDIA GPU are present.
has_hybrid_gpu() {
  [[ -n "$(find_gpu_address 0x8086)" && -n "$(find_gpu_address 0x10de)" ]]
}

# ------------------------------------------------------------------ steps

install_pacman_packages() {
  local packages=("${PACMAN_PACKAGES[@]}")

  if has_battery; then
    packages+=("${BATTERY_PACKAGES[@]}")
  fi

  log "Installing official packages"
  sudo pacman -Syu --needed "${packages[@]}"
}

install_aur_packages() {
  local pkg

  AUR_TMP="$(mktemp -d)"
  trap 'rm -rf -- "${AUR_TMP:-}"' EXIT

  for pkg in "${AUR_PACKAGES[@]}"; do
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
      log "$pkg is already installed, skipping"
      continue
    fi

    log "Building $pkg from the AUR with makepkg"
    git clone --depth 1 "https://aur.archlinux.org/${pkg}.git" "$AUR_TMP/$pkg"
    (cd "$AUR_TMP/$pkg" && makepkg -si)
  done
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

backup_existing_dotfiles() {
  local backup path
  backup="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

  for path in .config .local/bin .zshrc; do
    if [[ -e "$HOME/$path" || -L "$HOME/$path" ]]; then
      log "Backing up $path to $backup"
      mkdir -p "$backup/$(dirname "$path")"
      cp -a "$HOME/$path" "$backup/$path"
    fi
  done
}

install_dotfiles() {
  if [[ -e "$DOTFILES_DIR" ]]; then
    [[ -d "$DOTFILES_DIR" ]] || die "$DOTFILES_DIR exists and is not a directory."
    [[ "$(git --git-dir="$DOTFILES_DIR" rev-parse --is-bare-repository 2>/dev/null)" == true ]] ||
      die "$DOTFILES_DIR exists but is not a bare Git repository."
    log "Dotfiles repo already exists in $DOTFILES_DIR, updating"
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" pull --ff-only origin "$BRANCH"
    return
  fi

  backup_existing_dotfiles
  log "Cloning dotfiles into $DOTFILES_DIR"
  git clone --bare "$REPO_URL" "$DOTFILES_DIR"
  git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" checkout -f -B "$BRANCH" "$BRANCH"
  git --git-dir="$DOTFILES_DIR" config --local status.showUntrackedFiles no
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

setup_quickshell_services() {
  log "Enabling the services used by the Quickshell controls"

  if ! command -v systemctl >/dev/null; then
    warn "systemctl not found, skipping the Quickshell services."
    return
  fi

  if systemctl is-enabled --quiet NetworkManager.service 2>/dev/null; then
    log "NetworkManager is already enabled"
  else
    local other conflict=""
    for other in systemd-networkd.service dhcpcd.service connman.service iwd.service; do
      if systemctl is-enabled --quiet "$other" 2>/dev/null; then
        conflict="$other"
        break
      fi
    done

    if [[ -n "$conflict" ]]; then
      warn "$conflict is enabled, so NetworkManager was left disabled. The Quickshell network controls need it."
    else
      sudo systemctl enable --now NetworkManager.service ||
        warn "Could not enable NetworkManager."
    fi
  fi

  if ! systemctl --user enable --now pipewire.socket wireplumber.service; then
    warn "Could not start the audio services. Run this from inside your Hyprland session:"
    printf '  systemctl --user enable --now pipewire.socket wireplumber.service\n' >&2
  fi

  if has_battery; then
    sudo systemctl enable --now upower.service power-profiles-daemon.service ||
      warn "Could not enable upower and power-profiles-daemon."
  fi
}

greetd_config() {
  cat <<'EOF'
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "tuigreet --time --time-format '%a %d/%m - %H:%M' --greeting 'welcome back' --asterisks --remember --remember-user-session --window-padding 2 --container-padding 2 --prompt-padding 1 --theme 'border=blue;text=white;prompt=green;time=cyan;action=darkgray;button=white;container=black;input=white;title=magenta;greet=magenta' --cmd start-hyprland"
EOF
}

setup_greetd() {
  local config=/etc/greetd/config.toml dm

  log "Installing greetd and tuigreet"
  sudo pacman -S --needed greetd greetd-tuigreet

  if ! command -v start-hyprland >/dev/null; then
    warn "start-hyprland not found. Update Hyprland, or change --cmd in $config."
  fi

  if greetd_config | sudo cmp -s - "$config" 2>/dev/null; then
    log "$config is already up to date"
  else
    if [[ -e "$config" ]]; then
      log "Backing up $config"
      sudo cp -a "$config" "$config.bak-$(date +%Y%m%d-%H%M%S)"
    fi
    log "Writing $config"
    greetd_config | sudo tee "$config" >/dev/null
  fi

  for dm in sddm gdm lightdm ly lxdm; do
    if systemctl is-enabled --quiet "$dm.service" 2>/dev/null; then
      log "Disabling $dm.service"
      sudo systemctl disable "$dm.service"
    fi
  done

  sudo systemctl enable --force greetd.service
}

setup_tty_theme() {
  local grub_default=/etc/default/grub

  log "Applying the Catppuccin Mocha TTY palette"

  if [[ ! -f "$grub_default" ]] || ! command -v grub-mkconfig >/dev/null; then
    warn "GRUB was not found. Add these parameters to your kernel command line manually:"
    printf '  %s\n' "$TTY_PALETTE" >&2
    return
  fi

  if grep -qF 'vt.default_red=' "$grub_default"; then
    log "A TTY palette is already set in $grub_default, leaving it alone"
    return
  fi

  if ! grep -q '^GRUB_CMDLINE_LINUX_DEFAULT="' "$grub_default"; then
    warn "Could not find GRUB_CMDLINE_LINUX_DEFAULT in $grub_default. Add these parameters to it manually:"
    printf '  %s\n' "$TTY_PALETTE" >&2
    return
  fi

  log "Backing up $grub_default"
  sudo cp -a "$grub_default" "$grub_default.bak-$(date +%Y%m%d-%H%M%S)"
  sudo sed -i -E "s|^(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*)\"|\1 ${TTY_PALETTE}\"|" "$grub_default"

  log "Regenerating the GRUB configuration"
  sudo grub-mkconfig -o /boot/grub/grub.cfg
}

setup_hybrid_gpu() {
  local intel_addr nvidia_addr kernel rule_path env_file
  local kernels=() pkgs=()

  intel_addr="$(find_gpu_address 0x8086)"
  nvidia_addr="$(find_gpu_address 0x10de)"
  if [[ -z "$intel_addr" || -z "$nvidia_addr" ]]; then
    warn "Could not find both an Intel and an NVIDIA GPU, skipping the hybrid graphics setup."
    return
  fi

  log "Installing the NVIDIA open kernel modules"
  for kernel in linux linux-lts linux-zen linux-hardened; do
    if pacman -Q "$kernel" >/dev/null 2>&1; then
      kernels+=("$kernel")
    fi
  done

  if [[ ${#kernels[@]} -eq 1 && "${kernels[0]}" == "linux" ]]; then
    pkgs=(nvidia-open)
  else
    pkgs=(nvidia-open-dkms)
    for kernel in "${kernels[@]}"; do
      pkgs+=("$kernel-headers")
    done
    if [[ ${#kernels[@]} -eq 0 ]]; then
      warn "Could not identify your kernel package. Install its matching headers manually for DKMS."
    fi
  fi

  sudo pacman -S --needed "${pkgs[@]}"

  log "Enabling NVIDIA DRM modesetting"
  echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
  sudo mkinitcpio -P

  rule_path="/etc/udev/rules.d/gpu-dev-path.rules"
  log "Creating stable GPU device names in $rule_path"
  sudo tee "$rule_path" >/dev/null <<EOF
KERNEL=="card*", KERNELS=="$intel_addr", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/intel-igpu"

KERNEL=="card*", KERNELS=="$nvidia_addr", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/nvidia-dgpu"
EOF

  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=drm --action=add
  ls -l /dev/dri/
  [[ -e /dev/dri/intel-igpu ]] || warn "/dev/dri/intel-igpu does not exist; check the udev rule."
  [[ -e /dev/dri/nvidia-dgpu ]] || warn "/dev/dri/nvidia-dgpu does not exist yet; it should appear after a reboot."

  env_file="$CONFIG_DIR/hypr/configs/env.lua"
  if [[ -f "$env_file" ]]; then
    append_once "$env_file" "AQ_DRM_DEVICES" \
      'hl.env("AQ_DRM_DEVICES", "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu")'
    append_once "$env_file" "GSK_RENDERER" 'hl.env("GSK_RENDERER", "gl")'
  else
    warn "$env_file not found. Add the AQ_DRM_DEVICES and GSK_RENDERER settings manually."
  fi

  log "Switching mpv to the OpenGL GPU API"
  mkdir -p "$CONFIG_DIR/mpv"
  append_once "$CONFIG_DIR/mpv/mpv.conf" "gpu-api" "gpu-api=opengl"

}

print_next_steps() {
  printf '\nDone. Next steps:\n'
  printf '  - Reboot to apply the changes.\n'
  printf '  - Start Hyprland using start-hyprland or by selecting it from your preferred display manager.\n'
}

# ------------------------------------------------------------------- main

main() {
  [[ $# -eq 0 ]] || die "This script does not accept arguments."
  preflight
  install_pacman_packages
  install_aur_packages
  set_gtk_theme
  install_dotfiles
  enable_mpd
  setup_quickshell_services

  local greetd_chosen=false
  if ask "Set up the greetd login manager (tuigreet)?" n; then
    setup_greetd
    greetd_chosen=true
  fi

  if [[ "$greetd_chosen" == true ]]; then
    if ask "Apply the Catppuccin TTY theme? (recommended with greetd)" y; then
      setup_tty_theme
    fi
  elif ask "Apply the Catppuccin TTY theme?" n; then
    setup_tty_theme
  fi

  if has_hybrid_gpu && ask "Intel and NVIDIA GPUs detected. Set up hybrid graphics?" n; then
    setup_hybrid_gpu
  fi

  print_next_steps
}

main "$@"
