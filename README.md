# Instalacion-Arch-LVM-LUKS
Guía y script de instalación

Utilizaremos LVM sobre LUKS para crear un esquema de particionado flexible sobre una unica unidad cifrada. LVM no es visible hasta que el dispositivo de bloque se desbloquea y la estructura del volumen subyacente se escanea y se monta durante el arranque.

## Preparacion del sistema:
Definir distribucioin del teclado a español.
```
 # loadkeys es 
```
Para listar las distribuciones de teclado disponibles usamos:

Comprobacion de conectividad a internet:
```
# ping -c 3 8.8.8.8
```

verificar el modo de arranque EFI o Legacy:
```
# ls /sys/firmware/efi/efivars
```

Esquema de particiones usado:

La herramienta para crear este particionado de disco es fdisk. Para sistemas con EFI es necesario usar una tabla de particiones de tipo GPT. Creamos 2 particiones, una contendra el sistema boot y otra sera la unidad a cifrar.
Es necesario que la particion de boot tenga tipo EFI para que no haya problemas.

Una vez creadas las particiones cifreamos una mediante LUKS:
```
# cryptsetup luksFormat /dev/sda2
```
Accedemos al contenido de la unidad cifreda y crear un identificador
```
# cryptsetup open --type luks /dev/sda2 cryptlvm
```
El contenedor descifrado estará ahora disponible como /dev/mapper/lvm. Creamos el volumen fisico:
```
# pvcreate /dev/mapper/cryptlvm
```
Creamos el grupo virtual:
```
# vgcreate grupo /dev/mapper/cryptlvm
```
Creamos los volumenes dentro del volumen que acabamos de crear. En este ejemplo utilizaremos una unidad /home separada de /, y el espacio de intercambio estara ubicado dentro de la unidad cifrada:
```
# lvcreate -L 8G grupo -n swap
# lvcreate -L 100G grupo -n root
# lvcreate -l 100%FREE grupo -n home
```
Damos formato a los volumenes creados:
```
# mkfs.fat -F32 /dev/sda1
# mkfs.ext4 /dev/grupo/root
# mkfs.ext4 /dev/grupo/home
# mkswap /dev/grupo/swap
```
Montamos los volumenes en orde:
```
# mount /dev/grupo/root /mnt
# mkdir /mnt/home
# mount /dev/grupo/home /mnt/home
# swapon /dev/grupo/swap
# mkdir /mnt/boot
# mount /dev/sda1 /mnt/boot
```
Para comprobar los dispositivos montados correctamente 
```
# mount | grep mnt
```

## Instalacion del sistema :
```
# pacstrap /mnt base base-devel linux linux-firmware vim 
```
generamos fstab. Fichero que contiene la lista de discos y particiones disponibles e indica como montarlos y que configuracion utilizan.
```
# genfstab -U /mnt >> /mnt/etc/fstab
```
Opcion -U para para especificar en dicho archivo las UUID (en vez de las etiquetas opcion -L).
Cambiamos la raiz al sistema recien instalado
```
# arch-chroot /mnt
```
Definimos la zona horaria
```
# ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
```
GEneramos el archivo /etc/adjtime. Contine informacion descriptiva del relog hardware y el factor de deriva. Solo si el reloj esta configurado en UTC
```
# hwclock --systohc
```

Configuramos el idioma y la distribucion de teclado del sistema. Descomentar en /etc/locale.gen  en_US.UTF-8 UTF-8 y es_ES.UTF-8 UTF-8
```
# locale-gen
```
```
# echo "LANG=es_ES.UTF-8" > /etc/locale.conf
```
```
# echo "KEYMAP=es" > /etc/vconsole.conf
```
Creamos el archivo hostname. Nombre unico para identifica el dispositivo en una red.
```
# echo "radsvid" > /etc/hostname
```
Insertar en /etc/hosts:
```
  127.0.0.1	  localhost
  ::1		      localhost
  127.0.1.1	  radsvid.localdomain	radsvid
```
Editar el fichero /etc/mkinitcpio.conf para añadir los hooks necesarios para que funcien el sistema con LVM y LUKS:
```
HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt sd-lvm2 filesystems fsck)
```
Generamos los ramdisks:
```
# mkinitcpio -P
```
Para buscar informacion de un hook en especifico:
```
# mkinitcpio -H udev
```
Instalamos el gestor de arranque. En este caso instalaremos systemd-boot:
```
# bootctl install
```
Añadimos la siguiente entrada para el menu de arranque (en /boot/loader/entries/arch.conf):
```
  title     Arch Linux
  linux     /vmlinuz-linux
  initrd    /initramfs-linux.img
  options   rd.luks.name="UUID-del-dispositivo"=lvm root=/dev/grupo/root rw
```
El UUID del dispositivo se puede obtener mediante blkid -s UUID -o value /dev/sda2 
el UUID se refiere a la partición física cifrada, no al dispositivo mapeado resultante.

Poneos constraseña a root
```
# passwd
```
Para terminar la instalacion salimos de chroot, desmosntamos las particiones y reiniciamos la maquina:

```
# exit
# umount -R /mnt
# reboot 

```
