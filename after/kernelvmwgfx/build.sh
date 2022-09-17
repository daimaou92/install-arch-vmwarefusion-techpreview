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
if [ -z "$VER" ]; then
	VER=`curl -sL "https://cdn.kernel.org/pub/linux/kernel/v5.x" | \
		grep -E "<a href=\"linux-.*\.tar\.xz" | \
		sed -e 's/<a href=".*">//g' -e 's/<\/a>//g' | \
		awk '{print $1}' | sed -e 's/linux-//g' -e 's/\.tar\.xz//g' | \
		sort --version-sort | tail -n1`
fi
MAV="$(echo $VER | cut -d'.' -f1)"
[ -z "$MAV" ] && exit 1
VP="v${MAV}.x"
MIV="$(echo $VER | cut -d'.' -f2)"
[ -z "$MIV" ] && exit 1
PAV="$(echo $VER | cut -d'.' -f3)"
[ -z $PAV ] && PAV="0"
UVER="$VER"
if [ "$PAV" == "0" ]; then
	UVER="${MAV}.${MIV}"
fi
VER="${MAV}.${MIV}.${PAV}"
echo "Version: ${VER}"

CUR=`pwd`
P="$HOME/.kernbuild"

[ -d "$P" ] && sudo rm -rf "$P"
mkdir -p "$P" && cd "$P"

wget --no-dns-cache --no-check-certificate --debug \
	"https://cdn.kernel.org/pub/linux/kernel/${VP}/linux-${UVER}.tar.xz"
wget --no-dns-cache --no-check-certificate --debug \
	"https://cdn.kernel.org/pub/linux/kernel/${VP}/linux-${UVER}.tar.sign"

FP=`gpg --list-packets linux-${UVER}.tar.sign | grep keyid | awk '{print $6}'`
gpg --recv-keys $FP

unxz "linux-${UVER}.tar.xz"
GS=`gpg --verify "linux-${UVER}.tar.sign" "linux-${UVER}.tar" 2>&1 | grep "Good signature"`
[ -z $GS ] && exit 1

echo "Signature verified"
tar -xvf "linux-${UVER}.tar"
chown -R $(whoami):$(whoami) "linux-${UVER}"

cd "linux-${UVER}"
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
