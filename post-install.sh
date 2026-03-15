#!/bin/bash
set -e

# Einmalig sudo-Passwort abfragen und im Hintergrund frisch halten
sudo -v
while true; do sudo -n true; sleep 60; done &
SUDO_PID=$!
trap "kill $SUDO_PID 2>/dev/null" EXIT

# Multilib-Repo aktivieren (für steam)
sudo sed -i '/^#\[multilib\]/,/^#Include/{s/^#//}' /etc/pacman.conf

# Basis-Tools + yay bauen
sudo pacman -Syu --needed base-devel git --noconfirm
if ! command -v yay &>/dev/null; then
  rm -rf ~/yay
  git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay
  makepkg -si --noconfirm
  cd ~
fi

# Alle pacman-Pakete in einem Aufruf
sudo pacman -S --noconfirm \
    alacritty neovim obsidian bitwarden steam btop \
    spotify-launcher hyprshot hyprpolkitagent \
    ttf-jetbrains-mono-nerd noto-fonts-emoji \
    pipewire pavucontrol easyeffects wireplumber pipewire-pulse \
    qemu-full libvirt virt-manager

# AUR-Pakete
yay -S --noconfirm visual-studio-code-bin vesktop zen-browser-bin peaclock protonup-qt brave-bin

# Dienste aktivieren
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$USER"

# Dotfiles deployen
rm -rf ~/arch-installation
git clone https://github.com/SamysSabber/arch-installation.git ~/arch-installation
mkdir -p ~/.config
cp -r ~/arch-installation/* ~/.config/
rm -rf ~/arch-installation
