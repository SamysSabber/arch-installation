#!/bin/bash
set -e

#Festplatte wählen
while true; do
  echo "Verfügbare Festplatten:"
  lsblk -d -o NAME,SIZE,TYPE | grep disk
  echo ""
  printf "Festplattenname eingeben (z.b. sda, vda, nvme0n1): " > /dev/tty
  read -r DISKNAME < /dev/tty

  # Whitespace entfernen und führendes /dev/ abschneiden falls angegeben
  DISKNAME="${DISKNAME//[[:space:]]/}"
  DISKNAME="${DISKNAME#/dev/}"

  if [ -z "$DISKNAME" ]; then
    echo "Fehler: Kein Festplattenname eingegeben. Bitte erneut versuchen."
    continue
  fi

  DISK="/dev/$DISKNAME"

  if [ ! -b "$DISK" ]; then
    echo "Fehler: $DISK existiert nicht. Bitte erneut versuchen."
    continue
  fi

  break
done

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
printf "Korrekt? (j/n) " > /dev/tty
read -r CONFIRM < /dev/tty
if [ "$CONFIRM" != "j" ]; then
  echo "Abgebrochen."
  exit 1
fi

printf "Hostname für das Gerät setzen: " > /dev/tty
read -r HOSTNAME < /dev/tty
printf "Benutzername: " > /dev/tty
read -r USERNAME < /dev/tty
printf "Root Passwort: " > /dev/tty
read -rs ROOTPASS < /dev/tty
echo
printf "Benutzer Passwort: " > /dev/tty
read -rs USERPASS < /dev/tty
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
pacstrap -K /mnt base linux linux-firmware vim sudo btrfs-progs

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
echo "127.0.0.1 localhost" > /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

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

#Dependencies und Apps
pacman -S hyprland xdg-desktop-portal-hyprland dolphin kitty --noconfirm

#GDM Greeter
pacman -S gdm --noconfirm
systemctl enable gdm

EOF

#Unmounten und Reboot
umount -R /mnt
reboot
