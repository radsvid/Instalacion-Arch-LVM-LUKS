#!/bin/bash
echo '' > /tmp/config-arch-errors.txt
DEBUG = 1
function debug() {
  if  []$DEBUG != 0 ] then
    echo -e "\e[32m$(date | cut -d ' ' -f 5)\e[39m\e[42m[ERROR]\e[49m Error in the execution of $*" >> /tmp/config-arch-errors.txt
    exit code 1
  else
    echo -e "\e[31m$(date | cut -d ' ' -f 5)\e[39m\e[41m[SUCCESS]\e[49m Successful execution of $*"
  fi
}

read -p "Dispositivo fisico: " Device
read -p "Nombre para hostname: " Host
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/%en_US.UTF-8 UTF-8/' /etc/sudoers
sed -i 's/#es_ES.UTF-8 UTF-8/%es_ES.UTF-8 UTF-8/' /etc/sudoers
locale-gen
echo "LANG=es_ES.UTF-8" > /etc/locale.conf
echo "KEYMAP=es" > /etc/vconsole.conf

echo $Host > /etc/hostname
echo "127.0.0.1	  localhost
  ::1		      localhost
  127.0.1.1	  radsvid.localdomain	$Host" > /etc/hosts

DeviceUUID = $(blkid -s UUID -o value "$Device"2)

hook=$(grep "HOOKS=" /etc/mkinitcpio.conf)
sed -i 's/$hook/%HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
bootctl install
echo "  title     Arch Linux
linux     /vmlinuz-linux
initrd    /initramfs-linux.img
options   rd.luks.name="$DeviceUUID"=lvm root=/dev/grupo/root rw" > /boot/loader/entries/arch.conf
echo "Escriba Contraseña root: "
passwd
pacman -S dhcpcd


cd /tmp
# Create user and set password
read -p "Set user name: " userName
useradd -m -G wheel,storage,audio,video -s /bin/bash $userName
echo "Set user password:"
passwd $userName

# Instalar LTS kernel
pacman -S --noconfirm linux-lts
pacman -S --noconfirm sudo
pacman -S --noconfirm linux-headers linux-lts-headers

# Installar aplicaciones de red
pacman -S --noconfirm dhclient networkmanager network-manager-applet  

# Instalar yaourt 
pacman -S --noconfirm base-devel git wget yajl
cd /tmp
git clone https://aur.archlinux.org/package-query.git
cd package-query/
makepkg -si && cd /tmp/
git clone https://aur.archlinux.org/yaourt.git
cd yaourt/
makepkg -si
cd /tmp 


# Instalar windows manager i3
pacman -S --noconfirm xf86-video-ati mesa xf86-input-synaptics xf86-video-ati xf86-video-vesa
pacman -S --noconfirm xorg xorg-server xorg-app xorg-xinit xorg-twd xterm
pacman -S --noconfirm i3-wm i3lock i3blocks i3status gnu-free-fonts
pacman -S --noconfirm numlockx dmenu
pacman -S --noconfirm xf86s compton
pacman -S --noconfirm gnome-icon-theme
# screen saver i3lock-fancy-git 
pacman -S --noconfirm i3lock-color-git imagemagick bash awk util-linux
git clone https://github.com/meskarune/i3lock-fancy.git
cd i3lock-fancy
make install
cd ../

# Configurar auto startx 
cp /etc/skel/.bash_profile /home/$username
chown $username /home/$username/.bash_profile
chgrp $username /home/$username/.bash_profile
echo "[[ $XDG_VTNR -le 1 ]] && startx" >> /home/$username/.bash_profile

# Instalar fuentes
pacman -S --noconfirm ttf-droid ttf-ionicons ttf-dejavu

# Cambiar distribucion de teclado de X11 a español
echo "Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout"  "es,us"
        Option "XkbModel"   "pc104"
        Option "XkbVariant" "deadtilde,dvorak"
        Option "XkbOptions" "grp:alt_shift_toggle"
EndSection" > /etc/X11/xorg.conf.d/10-keyboard.conf


# Instalacion de soporte de audio
pacman -S --noconfirm alsa-utils alsa-plugins
pacman -S --noconfirm pulseaudio paprefs pavucontrol

# Instalar cli utils
pacman -S --noconfirm acpid ntp cronie avahi nss-mdns dbus cups ufw tlp 
pacman -S --noconfirm bash-completion
pacman -S --noconfirm  curl axel
pacman -S --noconfirm lshw #ls hardware
pacman -S --noconfirm openssh
pacman -S --noconfirm openvpn easy-rsa
pacman -Sy --noconfirm net-tools 
# Isntall gestor de archivos grafico
pacman -Sy --noconfirm nautilus 

# Instalar  terminal
pacman -Sy --noconfirm terminator

# Herramientas de desarrollo
pacman -Sy --noconfirm dialog autoconf automake cmake gcc gdb 
pacman -Sy --noconfirm php 
