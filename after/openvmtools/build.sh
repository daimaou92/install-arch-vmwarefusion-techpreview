#!/usr/bin/env bash
set -euo pipefail

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
P="$HOME"
cd $P

sudo pacman -Sy fuse2 icu iproute2 libdnet libmspack libsigc++ \
         libxcrypt libcrypt.so libxss lsb-release procps-ng \
         uriparser gdk-pixbuf-xlib chrpath doxygen gtkmm3 libxtst \
		 python rpcsvc-proto netctl networkmanager cunit \
		 --noconfirm

git clone https://github.com/vmware/open-vm-tools.git
cd open-vm-tools/open-vm-tools
autoreconf -i
./configure \
    --prefix=/usr \
    --sbindir=/usr/bin \
    --sysconfdir=/etc \
    --with-udev-rules-dir=/usr/lib/udev/rules.d \
    --without-xmlsecurity \
    --without-kernel-modules
make
make check
sudo make install
sudo ldconfig

cd $SD
sudo cp ./vmtoolsd.service /usr/lib/systemd/system/vmtoolsd.service

sudo cp ./vmware-vmblock-fuse.service \
	/usr/lib/systemd/system/vmware-vmblock-fuse.service

# sudo cp ./vmware-user.desktop /etc/xdg/autostart/vmware-user.desktop

sudo systemctl enable vmtoolsd.service
sudo systemctl enable vmware-vmblock-fuse.service

sudo pacman -R chrpath doxygen rpcsvc-proto cunit --noconfirm

cd $CUR
rm -rf $P/open-vm-tools
