#!/usr/bin/env bash
set -euo pipefail

sudo pacman -Sy base-devel xmlto kmod inetutils bc libelf git cpio \
  wget gnupg perl tar xz awk ca-certificates --noconfirm

scriptDir() {
	P=`pwd`
	D="$(dirname $0)"
	if [[ $D == /* ]]; then
		echo $D
	elif [[ $D == \.* ]]; then
		J=`echo "$D" | sed 's/.//'`
		echo "${P}$J"
	else
		echo "${P}/$D"
	fi
}
SD=`scriptDir`

VER="${1:-}"
[ -z "$VER" ] && VER="5.16.11"
VP="v$(echo "$VER" | cut -d'.' -f1).x"

CUR=`pwd`
P="$HOME/.kernbuild"

[ -d "$P" ] && sudo rm -rf "$P"
mkdir -p "$P" && cd "$P"

wget --no-dns-cache --no-check-certificate --debug "https://cdn.kernel.org/pub/linux/kernel/${VP}/linux-${VER}.tar.xz"
wget --no-dns-cache --no-check-certificate --debug "https://cdn.kernel.org/pub/linux/kernel/${VP}/linux-${VER}.tar.sign"

FP=`gpg --list-packets linux-${VER}.tar.sign | grep keyid | awk '{print $6}'`
gpg --recv-keys $FP

unxz "linux-${VER}.tar.xz"
GS=`gpg --verify "linux-${VER}.tar.sign" "linux-${VER}.tar" 2>&1 | grep "Good signature"`
[ -z $GS ] && exit 1

echo "Signature verified"
tar -xvf "linux-${VER}.tar"
chown -R $(whoami):$(whoami) "linux-${VER}"

cd "linux-${VER}"
make mrproper

zcat /proc/config.gz > .config
if [ ! -z "$(egrep -e 'CONFIG_DRM_VMWGFX=m' .config)" ]; then
	echo "VMWGFX Module already exists"
else
	sed -i \
	's/# CONFIG_DRM_VMWGFX is not set//' .config
	sed -i \
	's/CONFIG_DRM_UDL=m.*/CONFIG_DRM_VMWGFX=m\
CONFIG_DRM_VMWGFX_FBCON=y\
CONFIG_DRM_UDL=m/' ./.config
fi

sed -i \
	's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-ARCH-VMWGFX"/'\
	.config

make olddefconfig
make -j`grep -c ^processor /proc/cpuinfo`
make modules
sudo make modules_install
sudo cp arch/arm64/boot/Image "/boot/Image-linux-${VER}-vmwgfx"

sudo mkinitcpio -k "${VER}-ARCH-VMWGFX" -g "/boot/initramfs-linux-${VER}-vmwgfx.img"

CF="/boot/loader/entries/arch-vmwgfx.conf"
CFF="/boot/loader/entries/arch-vmwgfx-fallback.conf"
if [ -f "$CF" ]; then
	T=`cat $CF | egrep -e "^title " | \
		awk '{print $2}'`
	sudo sed -i \
		"s/^title .*/title ${T} (Fallback)/" \
		$CF
	sudo cp $CF $CFF
else
	echo -e "default arch-vmwgfx.conf\n\
timeout 4\n\
console-mode max" | \
	sudo tee /boot/loader/loader.conf
fi


echo -e "title ArchLinux-${VER}\n\
linux /Image-linux-${VER}-vmwgfx\n\
initrd /initramfs-linux-${VER}-vmwgfx.img\n\
options root="LABEL=arch" rw splash quiet loglevel=3" | \
sudo tee $CF

cd "$CUR"
rm -rf $P
