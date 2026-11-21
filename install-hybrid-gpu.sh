#!/usr/bin/env bash

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
NOCONFIRM=()

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

case $# in
  0) ;;
  1)
    [[ $1 == "--yes" ]] || die "Usage: $0 [--yes]"
    NOCONFIRM=(--noconfirm)
    ;;
  *) die "Usage: $0 [--yes]" ;;
esac

[[ $EUID -ne 0 ]] || die "Do not run this script as root."
command -v pacman >/dev/null || die "pacman not found. This script only supports Arch Linux."
command -v sudo >/dev/null || die "sudo not found."

log "Installing pciutils"
sudo pacman -S --needed "${NOCONFIRM[@]}" pciutils
command -v lspci >/dev/null || die "lspci not found after installing pciutils."

find_gpu_id() {
  lspci -d ::03xx | grep -i "$1" | head -n1 | cut -f1 -d' ' || true
}

intel_id="$(find_gpu_id Intel)"
nvidia_id="$(find_gpu_id NVIDIA)"
[[ -n "$intel_id" && -n "$nvidia_id" ]] || die "Could not find both an Intel and an NVIDIA GPU."

log "Installing the NVIDIA open kernel modules"
kernels=()
pkgs=()
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

sudo pacman -S --needed "${NOCONFIRM[@]}" "${pkgs[@]}"

log "Enabling NVIDIA DRM modesetting"
echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null
sudo mkinitcpio -P

rule_path="/etc/udev/rules.d/gpu-dev-path.rules"
log "Creating stable GPU device names in $rule_path"
sudo tee "$rule_path" >/dev/null <<EOF
KERNEL=="card*", KERNELS=="0000:$intel_id", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/intel-igpu"

KERNEL=="card*", KERNELS=="0000:$nvidia_id", SUBSYSTEM=="drm", SUBSYSTEMS=="pci", SYMLINK+="dri/nvidia-dgpu"
EOF

sudo udevadm control --reload
sudo udevadm trigger --subsystem-match=drm --action=add
ls -l /dev/dri/
[[ -e /dev/dri/intel-igpu ]] || warn "/dev/dri/intel-igpu does not exist; check the udev rule."
[[ -e /dev/dri/nvidia-dgpu ]] || warn "/dev/dri/nvidia-dgpu does not exist yet; it should appear after a reboot."

append_once() {
  local file="$1" key="$2" line="$3"
  touch "$file"
  if grep -qF "$key" "$file"; then
    log "$key is already set in $file, leaving it alone"
    return
  fi
  if [[ -s "$file" && -n "$(tail -c1 "$file")" ]]; then
    printf '\n' >> "$file"
  fi
  printf '%s\n' "$line" >> "$file"
}

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

printf '\nDone. Reboot so the NVIDIA modules and udev device names are loaded.\n'
