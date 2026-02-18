#Festplatte wählen
lsblk
read -p "Festplatte wählen: (nicht nvme0nXp oder sdX) " DISK
read -p "Hostname für das Gerät setzen " HOSTNAME

#Deutsche Tastatur laden im Archiso environment
loadkeys de-latin1

#Zeitzone auf Berlin stellen (Lokal)
timedatectl set-timezone Europe/Berlin

#Mirrorlist setzen
reflector --country Germany --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

#Partitionierung
sgdisk --zap-all $DISK
sgdisk -n 1:0:+1G -t 1:ef00 $DISK
sgdisk -n 2:0:0 -t 2:8300 $DISK

#Partitionen formatieren
mkfs.fat -F32 ${DISK}1
mkfs.btrfs -f ${DISK}2

#Subvolumes auf Root erstellen
mount /dev/${DISK}2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt

#Subvolumes und EFI mounten
mount -t btrfs -o subvol=@,compress=zstd /dev/${DISK}2 /mnt
mkdir -p /mnt/{boot,home,.snapshots}
mount /dev/vda1 /mnt/boot
mount -t btrfs -o subvol=@home,compress=zstd /dev/${DISK}2 /mnt/home
mount -t btrfs -o subvol=@snapshots,compress=zstd /dev/${DISK}2 /mnt/.snapshots

#Basissystem installieren
pacstrap -K /mnt base linux linux-firmware vim sudo

#Mirrorlist ins Livesystem kopieren
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

#fstab generieren
genfstab -U /mnt >>/mnt/etc/fstab

#Chroot ins Live-system
arch-chroot /mnt

#Zeitzone im Livesystem anpassen
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

#Sprache im Livesystem setzen
echo "de_DE.UTF-8" >/etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" >/etc/locale.conf
echo "KEYMAP=de-latin1" >/etc/vconsole.conf

#Hostname setzen
echo $HOSTNAME >/etc/hostname

#Root Passwort setzten
echo "Root passwort setzen: "
passwd

#Benutzer erstellen
useradd -mG wheel hamster
echo "Benutzter Passwort setzen: "
passwd hamster
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers #Erlaubt sudo befehle für Gruppe wheel

#Netzwork
pacman -S networkmanager
systemctl enable NetworkManager

#Grub
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

#Hyprland Standart
pacman -S hyprland xdg-desktop-portal-hyprland waybar wofi kitty pipewire wireplumber polkit-kde-agent gdm
systemctl enable gdm

#Unmounten und Reboot
exit
umount -R /mnt
reboot
