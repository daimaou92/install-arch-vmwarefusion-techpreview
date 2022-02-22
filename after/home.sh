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
cd $SD

mkdir -p $HOME/code/personal
mkdir -p $HOME/.cache
mkdir -p $HOME/.config
mkdir -p $HOME/.config/zsh


cd $HOME/code/personal
git clone https://github.com/daimaou92/dotfiles
cd dotfiles
./zshconf.sh
./tmuxconf.sh
./xconf.sh
cd $CUR

sudo reboot
