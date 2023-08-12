ADDR ?= unset
APORT ?= 22
ARCHUSER ?= daimaou92
ARCHUSERPASS ?= root
ARCHHOSTNAME ?= archmachine
ARCHREGION ?= Asia
ARCHCITY ?= Kolkata

SWAPSZG ?= 2
ESPSZM ?= 512

# typically sda for SATA
ABLOCKDEVICE ?= nvme0n1

# make sure this is empty if using SATA
PARTITIONPREFIX ?= p

MIRRORLIST ?= mirrorlist

MAKEFILEDIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

SSHOPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

vm/install:
	scp $(SSHOPTIONS) -p$(APORT) -r $(MAKEFILEDIR)/before \
		root@$(ADDR):/tmp/
	ssh $(SSHOPTIONS) -p$(APORT) -t root@$(ADDR) " \
		cd; \
		pacman-key --init; \
		pacman-key --populate archlinuxarm; \
		timedatectl set-ntp true; \
		parted /dev/$(ABLOCKDEVICE) -- mklabel gpt; \
		parted /dev/$(ABLOCKDEVICE) -- mkpart primary $(ESPSZM)MiB -$(SWAPSZG)GiB; \
		parted /dev/$(ABLOCKDEVICE) -- mkpart primary linux-swap -$(SWAPSZG)GiB 100%; \
		parted /dev/$(ABLOCKDEVICE) -- mkpart ESP fat32 1MiB $(ESPSZM)MiB; \
		parted /dev/$(ABLOCKDEVICE) -- set 3 ESP on; \
		mkfs.ext4 -L arch /dev/$(ABLOCKDEVICE)$(PARTITIONPREFIX)1; \
		mkswap -L swap /dev/$(ABLOCKDEVICE)$(PARTITIONPREFIX)2; \
		mkfs.fat -F 32 -n BOOT /dev/$(ABLOCKDEVICE)$(PARTITIONPREFIX)3; \
		mount /dev/$(ABLOCKDEVICE)$(PARTITIONPREFIX)1 /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/$(ABLOCKDEVICE)$(PARTITIONPREFIX)3 /mnt/boot; \
		swapon /dev/$(ABLOCKDEVICE)$(PARTITIONPREFIX)2; \
		pacstrap /mnt base base-devel linux linux-firmware efibootmgr; \
		pacstrap /mnt neovim zsh git wget curl sudo openssh; \
		genfstab -U /mnt >> /mnt/etc/fstab; \
		cp /tmp/before/fuse.conf /mnt/etc/fuse.conf; \
		cp /tmp/before/netmake.sh /mnt/netmake.sh; \
		arch-chroot /mnt sh -c 'ln -sf /usr/share/zoneinfo/$(ARCHREGION)/$(ARCHCITY) /etc/localtime'; \
		arch-chroot /mnt sh -c 'hwclock --systohc'; \
		arch-chroot /mnt sh -c 'sed -e \"/en_US.UTF-8/s/^#*//g\" -i /etc/locale.gen'; \
		arch-chroot /mnt sh -c 'locale-gen'; \
		arch-chroot /mnt sh -c 'echo \"LANG=en_US.UTF-8\" > /etc/locale.conf'; \
		arch-chroot /mnt sh -c 'echo \"$(ARCHHOSTNAME)\" > /etc/hostname'; \
		arch-chroot /mnt sh -c 'bash /netmake.sh && rm /netmake.sh'; \
		arch-chroot /mnt sh -c 'useradd -m -G wheel -s /bin/zsh $(ARCHUSER)'; \
		arch-chroot /mnt sh -c 'echo -e \"$(ARCHUSERPASS)\n$(ARCHUSERPASS)\" | passwd $(ARCHUSER)'; \
		arch-chroot /mnt sh -c 'echo -e \"$(ARCHUSER) ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/100-$(ARCHUSER)'; \
		arch-chroot /mnt sh -c 'mkinitcpio -P'; \
		arch-chroot /mnt sh -c 'echo -e \"root\nroot\" | passwd'; \
		arch-chroot /mnt sh -c 'bootctl install'; \
		mkdir -p /mnt/boot/loader; \
		cp -r /tmp/before/systemdbootloaders/* /mnt/boot/loader/; \
		systemctl enable systemd-networkd.service --root=/mnt; \
		systemctl enable systemd-resolved.service --root=/mnt; \
		systemctl enable sshd.service --root=/mnt; \
		umount -R /mnt; \
		reboot; \
	"

vm/openvmtools:
	scp $(SSHOPTIONS) -p$(APORT) \
		-r $(MAKEFILEDIR)/after/openvmtools \
		$(ARCHUSER)@$(ADDR):/tmp/
	ssh $(SSHOPTIONS) -p$(APORT) -t $(ARCHUSER)@$(ADDR) " \
		/bin/bash /tmp/openvmtools/build.sh; \
		sudo reboot; \
	"
