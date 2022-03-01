ADDR ?= unset
APORT ?= 22
ARCHUSER ?= daimaou92
ARCHHOSTNAME ?= archmachine
ARCHREGION ?= Asia
ARCHCITY ?= Kolkata

SWAPSZG ?= 8
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
		timedatectl set-ntp true; \
		parted /dev/$(ABLOCKDEVICE) -- mklabel gpt; \
		parted /dev/$(ABLOCKDEVICE) -- mkpart primary $(ESPSZM)MiB -$(SWAPSZG)GiB; \
		parted /dev/$(ABLOCKDEVICE) -- mkpart primary linux-swap -$(SWAPSZG)GiB 100\%; \
		parted /dev/$(ABLOCKDEVICE) -- mkpart ESP fat32 1MiB $(ESPSZM)MiB; \
		parted /dev/$(ABLOCKDEVICE) -- set 3 esp on; \
		mkfs.ext4 -L arch /dev/$(ABLOCKDEVICE)$(PARTITIONPREFIX)1; \
		mkswap -L swap /dev/$(ABLOCKDEVICE)$(PARTITIONPREFIX)2; \
		mkfs.fat -F 32 -n boot /dev/$(ABLOCKDEVICE)$(PARTITIONPREFIX)3; \
		mount /dev/disk/by-label/arch /mnt; \
		mkdir -p /mnt/boot; \
		mount /dev/disk/by-label/boot /mnt/boot; \
		swapon /dev/disk/by-label/swap; \
		cp /tmp/before/mirrors/$(MIRRORLIST) /etc/pacman.d/mirrorlist; \
		pacstrap /mnt base base-devel linux linux-firmware; \
		pacstrap /mnt neovim zsh git wget curl sudo openssh; \
		pacstrap /mnt networkmanager; \
		genfstab -U /mnt >> /mnt/etc/fstab; \
		cp /tmp/before/fuse.conf /mnt/etc/fuse.conf; \
		cp /tmp/before/mirrors/$(MIRRORLIST) /mnt/etc/pacman.d/mirrorlist; \
		arch-chroot /mnt sh -c 'ln -sf /usr/share/zoneinfo/$(ARCHREGION)/$(ARCHCITY) /etc/localtime'; \
		arch-chroot /mnt sh -c 'hwclock --systohc'; \
		arch-chroot /mnt sh -c 'sed -e \"/en_US.UTF-8/s/^#*//g\" -i /etc/locale.gen'; \
		arch-chroot /mnt sh -c 'locale-gen'; \
		arch-chroot /mnt sh -c 'echo \"LANG=en_US.UTF-8\" > /etc/locale.conf'; \
		arch-chroot /mnt sh -c 'echo \"$(ARCHHOSTNAME)\" > /etc/hostname'; \
		arch-chroot /mnt sh -c 'systemctl enable NetworkManager.service'; \
		arch-chroot /mnt sh -c 'systemctl enable sshd.service'; \
		arch-chroot /mnt sh -c 'useradd -m -G wheel -s /bin/zsh $(ARCHUSER)'; \
		arch-chroot /mnt sh -c 'echo -e \"root\nroot\" | passwd $(ARCHUSER)'; \
		arch-chroot /mnt sh -c 'echo -e \"$(ARCHUSER) ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/100-$(ARCHUSER)'; \
		arch-chroot /mnt sh -c 'mkinitcpio -P'; \
		arch-chroot /mnt sh -c 'echo -e \"root\nroot\" | passwd'; \
		arch-chroot /mnt sh -c 'bootctl install'; \
		mkdir -p /mnt/boot/loader; \
		cp -r /tmp/before/systemdbootloaders/* /mnt/boot/loader/; \
		umount -R /mnt; \
		reboot; \
	"

vm/vmwgfx:
	scp $(SSHOPTIONS) -p$(APORT) \
		-r $(MAKEFILEDIR)/after/kernelvmwgfx \
		$(ARCHUSER)@$(ADDR):/tmp/
	ssh $(SSHOPTIONS) -p$(APORT) -t $(ARCHUSER)@$(ADDR) " \
		/bin/bash /tmp/kernelvmwgfx/build.sh; \
		reboot; \
	"

vm/openvmtools:
	scp $(SSHOPTIONS) -p$(APORT) \
		-r $(MAKEFILEDIR)/after/openvmtools \
		$(ARCHUSER)@$(ADDR):/tmp/
	ssh $(SSHOPTIONS) -p$(APORT) -t $(ARCHUSER)@$(ADDR) " \
		/bin/bash /tmp/openvmtools/build.sh; \
		reboot; \
	"

# This will
# Build and install kernel 5.16.10 with vmwgfx
# Build and install open-vm-tools
# Configure my personal home setup
# DONOT use this directly unless you do want the things they install
vm/home:
	scp $(SSHOPTIONS) -p$(APORT) -r $(MAKEFILEDIR)/after \
		$(ARCHUSER)@$(ADDR):/tmp/
	ssh $(SSHOPTIONS) -p$(APORT) -t $(ARCHUSER)@$(ADDR) " \
		/bin/bash /tmp/after/home.sh; \
	"
