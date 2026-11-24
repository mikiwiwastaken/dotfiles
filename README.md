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
2. Builds and installs the AUR packages with `makepkg`.
3. Applies the GTK theme with `gsettings`.
4. Clones this repo as a bare repository into `~/.dotfiles` and checks its files out directly into your home directory. Existing `~/.config`, `~/.local/bin` and `~/.zshrc` are backed up to `~/.dotfiles-backup-<timestamp>` first. If the bare repository is already there, it updates it with `git pull --ff-only`.
5. Enables the `mpd` user service and the services used by the network, audio, battery and power profile controls.
6. Asks whether to set up the optional [greetd login manager](#greetd-login-manager), the [Catppuccin TTY theme](#catppuccin-tty-theme) and, when it detects both an Intel and an NVIDIA GPU, [hybrid graphics](#hybrid-intel--nvidia-graphics).

It is safe to run again: packages are installed with `--needed`; dotfiles updates use a fast-forward-only pull and preserve local changes.

> [!NOTE]
> If the GTK theme step fails (for example when running from a plain TTY with no D-Bus session), the script prints the `gsettings` commands. Run them again from inside your Hyprland session.

When it finishes, reboot to apply the changes. Then start Hyprland using `start-hyprland` or by selecting it from your preferred display manager.

### Manual

#### 1. Packages

```bash
sudo pacman -Syu --needed \
  base-devel git hyprland xdg-desktop-portal-hyprland hyprpolkitagent \
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
> The network, audio, battery, power profile and brightness controls depend on extra packages and services. Install and enable only the ones for the controls you want to use: `networkmanager` for network controls (you probably have this), `pipewire` and `wireplumber` for audio, `upower` and `power-profiles-daemon` for battery and power profile controls, and `brightnessctl` for brightness controls.

AUR packages:

```bash
for pkg in catppuccin-gtk-theme-mocha catppuccin-cursors-mocha; do
  git clone "https://aur.archlinux.org/${pkg}.git" "/tmp/${pkg}"
  (cd "/tmp/${pkg}" && makepkg -si)
done
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

### Optional

#### greetd login manager

[greetd](https://sr.ht/~kennylevinsen/greetd/) with the `tuigreet` greeter is a minimal TUI login screen. Skip this section if you prefer to launch Hyprland from a TTY or use another display manager.

> [!TIP]
> `tuigreet` draws with the 16 colors of the Linux console, so it only matches the rest of the setup after you apply the [Catppuccin TTY theme](#catppuccin-tty-theme). Applying it is strongly recommended.

Install the packages:

```bash
sudo pacman -S --needed greetd greetd-tuigreet
```

Write `/etc/greetd/config.toml`:

```bash
sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
[terminal]
vt = 1

[default_session]
user = "greeter"
command = "tuigreet --time --time-format '%a %d/%m - %H:%M' --greeting 'welcome back' --asterisks --remember --remember-user-session --window-padding 2 --container-padding 2 --prompt-padding 1 --theme 'border=blue;text=white;prompt=green;time=cyan;action=darkgray;button=white;container=black;input=white;title=magenta;greet=magenta' --cmd start-hyprland"
EOF
```

Disable any other display manager, then enable greetd:

```bash
sudo systemctl disable sddm.service   # or gdm, lightdm, ly...
sudo systemctl enable greetd.service
```

Reboot to see the new login screen.

#### Catppuccin TTY theme

This replaces the 16-color palette of the Linux console with Catppuccin Mocha. It is set through kernel parameters.

With GRUB, edit `/etc/default/grub` and add the following parameters to the existing `GRUB_CMDLINE_LINUX_DEFAULT` value:

```bash
vt.default_red=30,243,166,249,137,245,148,186,88,243,166,249,137,245,148,166 vt.default_grn=30,139,227,226,180,194,226,194,91,139,227,226,180,194,226,173 vt.default_blu=46,168,161,175,250,231,213,222,112,168,161,175,250,231,213,200
```

Regenerate the GRUB configuration and reboot:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
reboot
```

> [!NOTE]
> Other bootloaders work too: add the same three `vt.default_*` parameters to the kernel command line. See [Kernel parameters](https://wiki.archlinux.org/title/Kernel_parameters).

#### Hybrid Intel + NVIDIA graphics

For laptops with an Intel iGPU and an NVIDIA dGPU. This installs the open NVIDIA kernel modules, enables DRM modesetting, creates stable device names for both GPUs, and applies the matching Hyprland and mpv settings.

The installer offers this step automatically when it detects both GPUs. To set it up by hand instead:

Install the NVIDIA open kernel modules. Use `nvidia-open` with the stock `linux` kernel, or `nvidia-open-dkms` plus the matching headers for every other kernel:

```bash
sudo pacman -S --needed nvidia-open
# other kernels, for example linux-lts:
sudo pacman -S --needed nvidia-open-dkms linux-lts-headers
```

Enable DRM modesetting:

```bash
echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf
sudo mkinitcpio -P
```

Find the PCI addresses of both GPUs:

```bash
sudo pacman -S --needed pciutils
lspci -d ::03xx
```

Create stable device names, replacing the two addresses with yours (prefix them with `0000:`):

```bash
sudo tee /etc/udev/rules.d/gpu-dev-path.rules << 'EOF'
KERNEL=="card*", KERNELS=="0000:00:02.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/intel-igpu"

KERNEL=="card*", KERNELS=="0000:01:00.0", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/nvidia-dgpu"
EOF

sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=drm --action=add
ls -l /dev/dri/
```

Add the Hyprland settings to `~/.config/hypr/configs/env.lua`:

```lua
hl.env("AQ_DRM_DEVICES", "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu")
hl.env("GSK_RENDERER", "gl")
```

Switch mpv to the OpenGL API in `~/.config/mpv/mpv.conf`:

```bash
gpu-api=opengl
```

Reboot, then confirm modesetting is enabled:

```bash
cat /sys/module/nvidia_drm/parameters/modeset
```
