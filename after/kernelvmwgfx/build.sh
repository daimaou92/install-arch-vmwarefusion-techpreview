#!/usr/bin/env bash
set -euo pipefail

sudo pacman -Sy base-devel xmlto kmod inetutils bc libelf git cpio \
	wget gnupg perl tar xz --noconfirm

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

CUR=`pwd`
P="$HOME/.kernbuild"
[ -d "$P" ] && sudo rm -rf "$P"
mkdir -p "$P" && cd "$P"

wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.16.10.tar.xz
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.16.10.tar.sign

FP=`gpg --list-packets linux-5.16.10.tar.sign | grep keyid | awk '{print $6}'`
gpg --recv-keys $FP

unxz linux-5.16.10.tar.xz
GS=`gpg --verify linux-5.16.10.tar.sign linux-5.16.10.tar 2>&1 | grep "Good signature"`
[ -z $GS ] && exit 1

echo "Signature verified"
tar -xvf linux-5.16.10.tar
chown -R $(whoami):$(whoami) linux-5.16.10

cd linux-5.16.10
make mrproper

zcat /proc/config.gz > .config
if [ ! -z "$(egrep -e 'CONFIG_DRM_VMWGFX=m' .config)" ]; then
	echo "VMWGFX Module already exists"
	cd "$CUR"
	rm -rf "$P"
	exit 0
fi

sudo cp $SD/systemdloaders/arch-vmwgfx.conf /boot/loader/entries/
sudo cp $SD/systemdloaders/loader.conf /boot/loader/

sed -i \
	's/# CONFIG_DRM_VMWGFX is not set//' .config
sed -i \
	's/CONFIG_DRM_UDL=m.*/CONFIG_DRM_VMWGFX=m\
CONFIG_DRM_VMWGFX_FBCON=y\
CONFIG_DRM_UDL=m/' ./.config
sed -i \
	's/CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION="-ARCH-VMWGFX"/'\
	.config

make olddefconfig
make -j`grep -c ^processor /proc/cpuinfo`
make modules
sudo make modules_install
sudo cp arch/arm64/boot/Image /boot/Image-linux51610-vmwgfx

sudo mkinitcpio -k "5.16.10-ARCH-VMWGFX" -g /boot/initramfs-linux51610-vmwgfx.img

cd "$CUR"
rm -rf $P
