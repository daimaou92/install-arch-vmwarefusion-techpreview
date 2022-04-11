# PSA

There is an ongoing issue with kernel versions released since March 2022
not booting in Fusion for M1 Tech Preview. Here are some discussions:

1. [Linux 5.17 EFI-stub does not boot, hangs at loading kernel](https://communities.vmware.com/t5/Fusion-for-Apple-Silicon-Tech/Linux-5-17-EFI-stub-does-not-boot-hangs-at-loading-kernel/td-p/2900884)
2. [Failure to boot Linux Kernel 5.15.31, works with 5.15.26](https://communities.vmware.com/t5/Fusion-for-Apple-Silicon-Tech/Failure-to-boot-Linux-Kernel-5-15-31-works-with-5-15-26/td-p/2901884)
3. [Stuck trying to boot](https://github.com/mitchellh/nixos-config/issues/22)

The lastest kernel version I've been able to compile and boot successfully is
`5.16.13`. Please stick to that for now.

As a consequence, for the time being, people will not be able to do fresh
installs using this. Basically a particular version of `linux` is needed during
Arch's installation. I will work on it when I have the time. PRs are welcome

---

# What it is

A semi-automated way of setting up ArchLinux in [VMware Fusion Public Tech Preview 21H1](https://customerconnect.vmware.com/downloads/get-download?downloadGroup=FUS-PUBTP-2021H1)

# Steps

1. Acquire an ArchLinux ISO for aarch64. This can be done in a variety of ways. I prefer downloading it from the [release](https://github.com/JackMyers001/archiso-aarch64/releases) section of [https://github.com/JackMyers001/archiso-aarch64](https://github.com/JackMyers001/archiso-aarch64).

2. Setup a new "Custom Virtual Machine" in VMware.

   1. Choose "Other Linux 5.x kernel 64-bit Arm"
   2. Create a disk with at least 16 GiB of space because my script defaults of 8GiB of swap and 512 MiB for ESP. Both of these are configurable if you so choose.
   3. Setup the processor count and RAM size - I personally set it to 4cores and 8GiB respectively.
   4. Make sure to check `Use full resolution for Retina display` in `Display`
   5. The default Hard Disk Bus type is assumed to be NVME.
   6. In `CD/DVD (SATA)` make sure to check `Connect CD/DVD Drive` and from the drop down menu below select the ISO Image you acquired in Step 1.
   7. I personally remove all `Sound Card` and `Camera` devices - but this is optional.
   8. Donot remove the `USB & Bluetooth` device. If done so, I have noticed that the keyboard does not get detected on boot from ISO. I have done no research on this and it could very well be local to my system only.

3. Start the VM

4. Set a root password in the VM:

```Bash
   echo -e "root\nroot" | passwd
```

This will, of course, set the password to `root`.

5. Get the ip address of the VM:

```Bash
ip addr
```

My VM ip is typically: `172.16.210.140`

6. Now open a terminal window in you `Mac host` and clone this repo
7. `cd` into the repo directory
8. Run:

```Bash
ADDR="<ip address from step 5>" \
ARCHUSER="preferred username (default:daimaou92)" \
make vm/install
```

All configurable options are right on top of the `Makefile`. Configure as needed.
If you are using SATA as the Bus type for `Hard Disk` make sure to add

```Bash
ABLOCKDEVICE="sda" PARTITIONPREFIX=""
```

to the above command.

9. This will install Archlinux and create provided user with password = `root`.
   The VM will be restarted and you should be able to login with your user.
   The default shell for the user will be set to `zsh`.
   I typically take a **VM Snapshot** at this stage.

10. The linux kernel included, as of now, is not built with support for
    the vmware graphics driver. Consequently you'll be stuck to a basic resolution
    of 1024x768. We'll need to build our own kernel with support for said driver.

11. From the newly started VM fetch your current ip `ip addr`

12. From the terminal in you **Mac Host** - and inside this repo directory run:

```Bash
ADDR="<ip address from step 11>" \
ARCHUSER="preferred username (default:daimaou92)" \
make vm/vmwgfx
```

This will take quite a bit of time - compiling the linux kernel.
Takes about 20 minutes with 4 cores given to the VM in my M1 Pro 14". It
installs kernel version 5.16.11 by default. You could change this inside
`after/kernelvmwgfx/build.sh`. **CAUTION: In case you choose to do this, there
is no guarantee if this script will be able to build the kernel.**

13. Your system should again be restarted and you should see systemd
    boot default to the new kernel image.

14. You'll also need open-vm-tools for clipboard (copy-paste) functionality
    and sharing to work across VM and host.
    At the time of writing this `open-vm-tools` exists for target
    x86_64 only in Arch packages. In your **Mac Host** terminal run:

```Bash
ADDR="<ip address from step 11>" \
ARCHUSER="preferred username (default:daimaou92)" \
make vm/openvmtools
```

This will pull the latest sources from
[https://github.com/vmware/open-vm-tools](https://github.com/vmware/open-vm-tools),
compile and set it up. It'll reboot
one more time.

15. After logging in verify the service status of the following:

```Bash
sudo systemctl status vmtoolsd.service
sudo systemctl status vmware-vmblock-fuse.service
```

There should be no errors.

Check if the file `/etc/xdg/autostart/vmware-user.desktop` exists:

```Bash
ls /etc/xdg/autostart/vmware-user.desktop
```

This needs to be autostarted and is required for clipboard functionality.

16. Change the user password:

```Bash
passwd
```

and the root password:

```Bash
sudo passwd
```

17. If everything has gone as per documentation so far - you can stop reading
    further and set up your home environment the way you prefer.

### Quick setup with i3, kitty and xorg (optional):

```Bash
sudo pacman -Sy xorg xorg-xinit i3-gaps i3status i3lock dmenu dex \
	kitty dex
```

You'll need to mount the shared directories at this point. I typically
create `$HOME/shares` and set the mounting command in my `.zprofile`
(since i use zsh):

```Bash
mkdir -p $HOME/shares
echo 'vmhgfs-fuse .host:/ "$HOME/shares" -o subtype=vmhgfs-fuse,allow_other' | \
tee -a ~/.zprofile > /dev/null
```

Use `~/.profile` instead of `~/.zprofile` for bash.

You'll need to start the x server at login followed by i3.
We'll do it with a `~/.xinitrc` and `~/.zprofile`. Again replace with
`~/.profile` for bash

```Bash
echo 'exec i3' | tee ~/.xinitrc > /dev/null
echo 'startx' | tee -a ~/.zprofile > /dev/null
```

And reboot

```Bash
sudo reboot
```

On logging in for the first time after installing i3 you'll be asked if the
`~/.config/i3/config` file should be created. Press `Enter` for `Yes`.
Another screen pops up asking your choice of modifier key
(called `$mod` henceforth). Choose `cmd` or `alt` per preference using
arrow keys and hit `Enter`.

Hit `$mod+Enter`. This should open up `kitty`.

```Bash
xrandr
```

You should see some text like this:

```Bash
   1024x768      60.00*+  60.00
   3840x2400     59.97
   3840x2160     59.97
   2880x1800     59.95
   2560x1600     59.99
   2560x1440     59.95
   1920x1440     60.00
   1856x1392     60.00
   1792x1344     60.00
   1920x1200     59.88
   1920x1080     59.96
   1600x1200     60.00
   1680x1050     59.95
   1400x1050     59.98
   1280x1024     60.02
   1440x900      59.89
   1280x960      60.00
   1360x768      60.02
   1280x800      59.81
   1152x864      75.00
   1280x768      59.87
   1280x720      59.86
   800x600       60.32
   640x480       59.94
```

Pick a resolution of choice and set it using xrandr. I'd advice against using
more than 2560x1600 since 3D acceleration is missing in
VMware Tech preview so far:

```Bash
xrandr -s 2560x1600
```

Set this in i3 to have correct resolution post log in:

```Bash
echo "exec --no-startup-id xrandr -s 2560x1600" >> ~/.config/i3/config
```

There's also DPI - specially if you're on a smaller screen. I set mine
using `~/.Xresources`

```Bash
echo "Xft.dpi: 170" >> ~/.Xresources
sed -i \
	's@exec i3.*@xrdb -merge ~/.Xresources\
exec i3@' ~/.xinitrc
```

Done. Enjoy

### NB:

If you inspect the `Makefile` there is an option `vm/home`. I use it personally
to compile the kernel, build open-vm-tools, pull my dotfiles repo and setup
a home environment all in a single step. I would strongly advice to have a look
at my dotfiles repo (linked below) before running this - if you choose to do
so that is.

My minimal dotfiles are available [here](https://github.com/daimaou92/dotfiles).
