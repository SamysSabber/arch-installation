sudo pacman -Syu --needed base-devel git --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ~

#Apps
sudo pacman -S alacritty neovim obsidian bitwarden steam btop \
    spotify-launcher hyprshot hyprpolkitagent --noconfirm

yay -S visual-studio-code-bin vesktop zen-browser-bin peaclock protonup-qt brave-bin --noconfirm

#Fonts und Icons
sudo pacman -S ttf-jetbrains-mono-nerd noto-fonts-emoji --noconfirm

#Sound Utils
sudo pacman -S pipewire pavucontrol easyeffects wireplumber pipewire-pulse --noconfirm
sudo systemctl --user enable --now pipewire pipewire-pulse wireplumber

#VM QEMU/KVM
sudo pacman -S qemu-full libvirt virt-manager --noconfirm
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER

