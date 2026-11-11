# Dotfiles

A Catppuccin Mocha Hyprland setup for Arch Linux.

## Overview

| Role                 | Tool                    |
| -------------------- | ----------------------- |
| Compositor           | Hyprland                |
| Bar                  | Waybar                  |
| Launcher             | Wofi                    |
| Notifications        | SwayNC                  |
| OSD                  | SwayOSD                 |
| Wallpaper            | hyprpaper               |
| Lock screen / idle   | hyprlock + hypridle     |
| Terminal             | kitty                   |
| Shell / prompt       | zsh + Starship          |
| File manager         | yazi                    |
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

Pick one of the two methods below. Both give the same result.

### Automatic (recommended)

The `install.sh` script runs every step of the manual installation for you. It needs a working Arch Linux install with `sudo` and an internet connection. Do not run it as root.

Download it, read it, then run it:

```bash
curl -fsSLO https://raw.githubusercontent.com/mikiwiwastaken/dotfiles/main/install.sh
less install.sh
bash install.sh
```

Options:

| Flag     | Effect                                         |
| -------- | ---------------------------------------------- |
| `--yes`  | Pass `--noconfirm` to pacman, yay and makepkg. |
| `--help` | Show the usage text.                           |

The script:

1. Installs the official packages with `pacman`.
2. Installs the AUR packages. If no AUR helper (`yay` or `paru`) is found, it builds `yay-bin` first.
3. Applies the GTK theme with `gsettings`.
4. Clones this repo into `~/.config`. An existing `~/.config` is copied to `~/.config-backup-<timestamp>` first. If the repo is already there, it runs `git pull --ff-only` instead.
5. Creates the symlinks that live outside `~/.config`.
6. Enables and starts the `mpd` user service.

It is safe to run again: packages are installed with `--needed` and the symlinks are overwritten.

> [!NOTE]
> If the GTK theme step fails (for example when running from a plain TTY with no D-Bus session), the script prints the `gsettings` commands. Run them again from inside your Hyprland session.

When it finishes, log out and start Hyprland using `start-hyprland` or by selecting it from your preferred display manager.

### Manual

#### 1. Packages

```bash
sudo pacman -Syu --needed \
  git hyprland xdg-desktop-portal-hyprland hyprpolkitagent \
  wofi swaync swayosd hyprpaper archlinux-wallpaper hyprlock hypridle \
  grim slurp wf-recorder wl-clipboard cliphist \
  pavucontrol hyprpicker hyprsunset gvfs libqalculate \
  qt5-wayland qt6-wayland qt5ct qt6ct kvantum-qt5 kvantum papirus-icon-theme \
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji noto-fonts-cjk \
  kitty zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions \
  starship eza bat ripgrep fd fzf zoxide ncdu \
  btop fastfetch cava mpd ncmpcpp \
  yazi ffmpeg 7zip jq poppler resvg \
  imv zathura zathura-pdf-mupdf tesseract-data-eng mpv
```

AUR packages (requires an AUR helper such as `yay`):

```bash
yay -S --needed catppuccin-gtk-theme-mocha catppuccin-cursors-mocha waybar-git
```

#### 2. GTK theme

```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default'
gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-mocha-dark-cursors'
```

#### 3. Dotfiles

Back up any existing config first, then clone the repo into `~/.config`:

```bash
cd ~/.config
git init -b main
git remote add origin https://github.com/mikiwiwastaken/dotfiles.git
git fetch origin
git checkout -f -B main origin/main
git branch --set-upstream-to=origin/main main
```

Create the symlinks that live outside `~/.config`:

```bash
mkdir -p ~/.local/bin
chmod +x ~/.config/scripts/*
ln -sf ~/.config/scripts/screenshot ~/.local/bin/screenshot
ln -sf ~/.config/scripts/record ~/.local/bin/record
ln -sf ~/.config/scripts/music ~/.local/bin/music
ln -sf ~/.config/scripts/music-watch ~/.local/bin/music-watch
ln -sf ~/.config/scripts/ncmpcpp-mocha ~/.local/bin/ncmpcpp-mocha
ln -sf ~/.config/zsh/.zshrc ~/.zshrc
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
