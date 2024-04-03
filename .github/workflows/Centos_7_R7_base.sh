#!/bin/bash

# Configuración del usuario root
echo "HC37nn1." | passwd --stdin root

# Desactivar SELinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

# Desactivar IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

# Desactivar firewall
systemctl stop firewalld
systemctl disable firewalld

# Configuración de la zona horaria
timedatectl set-timezone America/Mexico_City

# Configuración del idioma y teclado
localectl set-locale LANG=en_US.UTF-8
localectl set-keymap la-latin1

# Particionamiento
echo -e "n\np\n1\n\n+500M\nt\n1\n82\nn\np\n2\n\n+8192M\nt\n2\n82\nn\np\n3\n\n\n\nt\n3\n8e\nw\n" | fdisk /dev/sda
partprobe /dev/sda
pvcreate /dev/sda3
vgcreate VG_SO /dev/sda3
lvcreate -L 8G -n LV_root VG_SO
lvcreate -L 1G -n LV_home VG_SO
lvcreate -L 4G -n LV_tmp VG_SO
lvcreate -L 1G -n LV_var VG_SO
lvcreate -L 1G -n LV_var_log VG_SO
lvcreate -L 100G -n LV_app_IVM VG_SO
mkfs.xfs /dev/VG_SO/LV_root
mkfs.xfs /dev/VG_SO/LV_home
mkfs.xfs /dev/VG_SO/LV_tmp
mkfs.xfs /dev/VG_SO/LV_var
mkfs.xfs /dev/VG_SO/LV_var_log
mkfs.xfs /dev/VG_SO/LV_app_IVM
mkswap /dev/VG_SO/LV_home

# Montaje de particiones
mount /dev/VG_SO/LV_root /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/VG_SO/LV_home /mnt/home
mkdir /mnt/tmp
mount /dev/VG_SO/LV_tmp /mnt/tmp
mkdir /mnt/var
mount /dev/VG_SO/LV_var /mnt/var
mkdir /mnt/var/log
mount /dev/VG_SO/LV_var_log /mnt/var/log
mkdir /mnt/opt
mount /dev/VG_SO/LV_app_IVM /mnt/opt

# Crear archivo de configuración de repositorio
cat <<EOF > /etc/yum.repos.d/custom.repo
[custom]
name=Custom Repository
baseurl=http://mirror.centos.org/centos/7/os/x86_64/
enabled=1
gpgcheck=0
EOF

# Instalación de paquetes
yum groupinstall -y "GNOME Desktop" "Graphical Administration Tools"
yum install -y perl tuned man vim openssh-clients bind bind-utils

# Configuración para iniciar en modo gráfico
ln -sf /lib/systemd/system/runlevel5.target /etc/systemd/system/default.target

echo "Configuración finalizada."
