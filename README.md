# Dotfiles

A Catppuccin Mocha Hyprland setup for Arch Linux.

## Overview

| Role                 | Tool                    |
| -------------------- | ----------------------- |
| Compositor           | Hyprland                |
| Shell                | Quickshell              |
| Wallpaper            | hyprpaper               |
| Lock screen / idle   | hyprlock + hypridle     |
| Terminal             | kitty                   |
| Shell / prompt       | zsh + Starship          |
| Code editor          | neovim                  |
| File manager         | yazi                    |
| Music player         | ncmpcpp                 |
| Image viewer         | imv                     |
| Document viewer      | zathura                 |
| Video / audio player | mpv                     |
| Screenshots          | grim + slurp            |
| Recordings           | wf-recorder             |
| Clipboard history    | cliphist + wl-clipboard |
| Polkit agent         | hyprpolkitagent         |
| Theme                | Catppuccin Mocha        |
| Icon Theme           | Papirus                 |
| Font                 | JetBrainsMono Nerd Font |

## Installation

### Automatic (recommended)

The `install.sh` script runs every step of the manual installation for you. It needs a working Arch Linux install with `sudo` and an internet connection. Do not run it as root.

Run the installer:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/mikiwiwastaken/dotfiles/main/install.sh)"
```

The script:

1. Installs the official packages with `pacman`.
2. Installs the AUR packages. If no AUR helper (`yay` or `paru`) is found, it builds `yay-bin` first.
3. Applies the GTK theme with `gsettings`.
4. Clones this repo as a bare repository into `~/.dotfiles` and checks its files out directly into your home directory. Existing `~/.config`, `~/.local/bin` and `~/.zshrc` are backed up to `~/.dotfiles-backup-<timestamp>` first. If the bare repository is already there, it updates it with `git pull --ff-only`.
5. Enables and starts the `mpd` user service.

It is safe to run again: packages are installed with `--needed`; dotfiles updates use a fast-forward-only pull and preserve local changes.

> [!NOTE]
> If the GTK theme step fails (for example when running from a plain TTY with no D-Bus session), the script prints the `gsettings` commands. Run them again from inside your Hyprland session.

When it finishes, log out and start Hyprland using `start-hyprland` or by selecting it from your preferred display manager.

### Manual

#### 1. Packages

```bash
sudo pacman -Syu --needed \
  git hyprland xdg-desktop-portal-hyprland hyprpolkitagent \
  quickshell hyprpaper archlinux-wallpaper hyprlock hypridle hyprpicker \
  grim slurp wf-recorder wl-clipboard cliphist libnotify \
  qt5-wayland qt6-wayland qt5ct qt6ct kvantum-qt5 kvantum papirus-icon-theme \
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk \
  kitty zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions \
  starship eza bat ripgrep fd fzf zoxide ncdu \
  neovim unzip tree-sitter-cli \
  btop fastfetch cava mpd ncmpcpp \
  yazi ffmpeg 7zip jq poppler resvg \
  imv zathura zathura-pdf-mupdf tesseract-data-eng mpv
```

> [!NOTE]
> For Quickshell's network, audio, battery, and power profile controls to work reliably, install the optional service packages if they are not already present: `networkmanager`, `pipewire`, `wireplumber`, `upower`, and `power-profiles-daemon`. Keep the corresponding services running in your system or user session. Without them, Quickshell can still start, but those controls may be unavailable.

AUR packages (requires an AUR helper such as `yay`):

```bash
yay -S --needed catppuccin-gtk-theme-mocha catppuccin-cursors-mocha
```

#### 2. GTK theme

```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default'
gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-mocha-dark-cursors'
```

#### 3. Dotfiles

Back up any existing `~/.config`, `~/.local/bin` and `~/.zshrc` files first. Clone the repo as a bare repository outside the config directory, then check its files out into your home directory:

```bash
git clone --bare https://github.com/mikiwiwastaken/dotfiles.git ~/.dotfiles
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout -f -B main main
git --git-dir="$HOME/.dotfiles" config --local status.showUntrackedFiles no
```

To update the dotfiles later:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" pull --ff-only origin main
```

#### 4. Start the mpd service

`mpd` runs as a systemd user service (do not use the system-wide one). Enable it so it starts on login and start it now:

```bash
systemctl --user enable --now mpd.service
```

Check that it is running:

```bash
systemctl --user status mpd.service
mpc status   # or open ncmpcpp
```

### Hybrid Intel + NVIDIA graphics

On an Intel/NVIDIA laptop, `install-hybrid-gpu.sh` installs and configures the
open NVIDIA kernel modules, DRM modesetting, stable DRM device names, and the
Hyprland and mpv settings. Run it from the dotfiles checkout:

```bash
bash ./install-hybrid-gpu.sh
```

The script uses `nvidia-open` for the stock Arch kernel and
`nvidia-open-dkms` with matching headers for other detected kernels. Reboot
after it completes. Confirm modesetting is enabled with:

```bash
cat /sys/module/nvidia_drm/parameters/modeset
```
