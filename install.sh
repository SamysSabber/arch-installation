#!/bin/bash

#Festplatte wählen
echo "Verfügbare Festplatten:"
lsblk -d -o NAME,SIZE,TYPE | grep disk
echo ""
read -p "Festplattenname eingeben (z.b. sda, vda, nvme0n1): " DISKNAME
DISK="/dev/$DISKNAME"

#Prüfen ob Disk existiert
if [ ! -b "$DISK" ]; then
  echo "Fehler: $DISK existiert nicht!"
  exit 1
fi

#NVMe Partitionsbezeichnung anpassen (nvme0n1 → nvme0n1p1, sda → sda1)
if [[ $DISKNAME == nvme* ]]; then
  PART1="${DISK}p1"
  PART2="${DISK}p2"
else
  PART1="${DISK}1"
  PART2="${DISK}2"
fi

echo "Disk: $DISK"
echo "Boot Partition: $PART1"
echo "Root Partition: $PART2"
read -p "Korrekt? (j/n) " CONFIRM
if [ "$CONFIRM" != "j" ]; then
  echo "Abgebrochen."
  exit 1
fi

read -p "Hostname für das Gerät setzen: " HOSTNAME
read -p "Benutzername: " USERNAME
read -sp "Root Passwort: " ROOTPASS
echo
read -sp "Benutzer Passwort: " USERPASS
echo

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
mkfs.fat -F32 $PART1
mkfs.btrfs -f $PART2

#Subvolumes auf Root erstellen
mount $PART2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt

#Subvolumes und EFI mounten
mount -t btrfs -o subvol=@,compress=zstd $PART2 /mnt
mkdir -p /mnt/{boot,home,.snapshots}
mount $PART1 /mnt/boot
mount -t btrfs -o subvol=@home,compress=zstd $PART2 /mnt/home
mount -t btrfs -o subvol=@snapshots,compress=zstd $PART2 /mnt/.snapshots

#Basissystem installieren
pacstrap -K /mnt base linux linux-firmware vim sudo

#Mirrorlist ins Livesystem kopieren
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

#fstab generieren
genfstab -U /mnt >>/mnt/etc/fstab

#Chroot ins Live-system
arch-chroot /mnt /bin/bash <<EOF

#Zeitzone im Livesystem anpassen
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

#Sprache im Livesystem setzen
echo "de_DE.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" > /etc/vconsole.conf

#Hostname setzen
echo "$HOSTNAME" > /etc/hostname

#Root Passwort setzen
echo "root:$ROOTPASS" | chpasswd

#Benutzer erstellen
useradd -mG wheel $USERNAME
echo "$USERNAME:$USERPASS" | chpasswd
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers #Erlaubt sudo Befehle für Gruppe wheel

#Netzwerk
pacman -S networkmanager --noconfirm
systemctl enable NetworkManager

#Grub
pacman -S grub efibootmgr --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

#Hyprland Standart
pacman -S hyprland xdg-desktop-portal-hyprland waybar wofi kitty pipewire wireplumber polkit-kde-agent gdm --noconfirm
systemctl enable gdm

EOF

#Unmounten und Reboot
umount -R /mnt
reboot
