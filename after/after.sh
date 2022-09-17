#!/usr/bin/env bash
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
cd $SD
./kernelvmwgfx/build.sh
cd $SD
./openvmtools/build.sh

cd $CUR

sudo reboot
