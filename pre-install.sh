#!/bin/bash
echo '' > /tmp/install-arch-errors.txt
DEBUG = 1
function debug() {
  if  []$DEBUG != 0 ] then
    echo -e "\e[32m$(date | cut -d ' ' -f 5)\e[39m\e[42m[ERROR]\e[49m Error in the execution of $*" >> /tmp/install-arch-errors.txt
    exit code 1
  else
    echo -e "\e[31m$(date | cut -d ' ' -f 5)\e[39m\e[41m[SUCCESS]\e[49m Successful execution of $*"
  fi
}

loadkeys es
fdisk -l |grep /dev
read -p "Dispositivo fisico: " Device
read -p "Nombre del volumen fisico: " PVolumen
read -p "Nombre del grupo virtual: " VGroup
# creamos tabla de particiones y particiones
(echo g; echo w)| fdisk $Device
debug crear tabla de particiones
(
echo n # Add a new partition
echo 1 # Partition number
echo   # First sector (Accept default)
echo +512M # Last sector
echo n # Add a new partition
echo 2 # Partition number
echo   # First sector (Accept default)
echo   # Last sector (Accept default)
echo w # Write changes
) |  fdisk $Device
debug crear particiones
(
echo t # Add a new partition
echo 1 # Partition number
echo 1 # Partition type
echo t # Add a new partition
echo 2 # Partition number
echo 20 # Partition type
echo w # Write changes
) |  fdisk $Device
debug disk partitioning


read -s -p "Contraseña para volumen cifrado: " CryptPass ;echo ""
read -s -p "Repite contraseña para volumen cifrado: " ReCryptPass ;echo ""
while [ $CryptPass != $ReCryptPass ]
do
  echo "Las contraseñas no coinciden"
  read -s -p "Contraseña para volumen cifrado: " CryptPass ;echo ""
  read -s -p "Repite contraseña para volumen cifrado: " ReCryptPass ;echo ""
done


(echo $CryptPass
echo $CryptPass) | cryptsetup luksFormat "$Device"2
(echo $CryptPass ) | cryptsetup open --type luks "$Device"2 $PVolumen
debug disk encryption

echo "\nTamaño de la particion cifrada: $(fdisk -l | grep "$Device"2 | cut -d ' ' -f 7)"
read -p "Tamaño root, solo el numero en GB (al menos 3 GB): " Sizeroot
read -p "Tamaño Swap, solo el numero en MB: " Sizeswap

pvcreate /dev/mapper/$PVolumen
vgcreate $VGroup /dev/mapper/$PVolumen
lvcreate -L "$Sizeroot"G $VGroup -n swap
lvcreate -L "$Sizeswap"M $VGroup -n root
lvcreate -l 100%FREE $VGroup -n home

debug crear volumenes logicos

mkfs.fat -F32 "$Device"1
mkfs.ext4 /dev/$VGroup/root
mkfs.ext4 /dev/$VGroup/home
mkswap /dev/$VGroup/swap

mount /dev/$VGroup/root /mnt
mkdir /mnt/home
mount /dev/$VGroup/home /mnt/home
swapon /dev/$VGroup/swap
mkdir /mnt/boot
mount "$Device"1 /mnt/boot

debug volume creation and mounting

pacstrap /mnt base base-devel linux linux-firmware vim

debug pacstrap

genfstab -U /mnt >> /mnt/etc/fstab

debug generating fstab
