# Updates
1. There's a new public Tech preview -
[22H2](https://customerconnect.vmware.com/downloads/get-download?downloadGroup=FUS-PUBTP-22H2)
with 3D Graphics 🚀🚀🚀
2. The scripts - henceforth - will be tested with the official archboot releases for
aarch64 only. As of the time of editing this file the version tested is:
[archboot-archlinuxarm-2022.09.12-11.41-aarch64.iso](archboot-archlinuxarm-2022.09.12-11.41-aarch64.iso).
All my testing is done with the ~350MiB file since it's a nice balance. It boots much
faster into a live env compared to the ~130MiB file and is much smaller over the wire
compared to the ~1.2GiB one.

# What it is

A semi-automated way of setting up ArchLinux in [VMware Fusion Public Tech Preview 21H1](https://customerconnect.vmware.com/downloads/get-download?downloadGroup=FUS-PUBTP-2021H1)

# Steps

1. Acquire an ArchLinux ISO for aarch64. This can be done in a variety of ways. I download it from the [registry](https://pkgbuild.com/~tpowa/archboot/iso/aarch64/latest/) of the awesome [Archboot](https://gitlab.archlinux.org/tpowa/archboot) project since it has started creating `aarch64` ISOs recently. All tests have been done with the ~350MiB file - take that as you will. 

2. Setup a new "Custom Virtual Machine" in VMware.

   1. Choose "Other Linux 5.x kernel 64-bit Arm"
   2. Create a disk with at least 16 GiB of space because my script defaults of 8GiB of swap and 512 MiB for ESP. Both of these are configurable if you so choose.
   3. Setup the processor count and RAM size - I personally set it to 4cores and 8GiB respectively.
   4. Make sure to check `Use full resolution for Retina display` in `Display`
   5. Also select `Accelerate 3D Graphcis` and select the recommended amount in
   `Shared Graphics Memory`
   6. The default Hard Disk Bus type is assumed to be NVME.
   7. In `CD/DVD (SATA)` make sure to check `Connect CD/DVD Drive` and from the drop
   down menu below select the ISO Image you acquired in Step 1.
   8. I personally remove all `Sound Card` and `Camera` devices - but this is optional.
   9. Donot remove the `USB & Bluetooth` device. Peripherals are attached via USB
   inside the VM - so your keyboard for one will stop functioning.

3. Start the VM

4. Since we're using an ISO built by the `archboot` project - at boot it'll try to
guide you through the install process. This is a very very intuitive and easy process
and if you happen to prefer that please go ahead and use it. For those that would
rather follow the steps below - just `Cancel` out of it.

5. Set a root password in the VM:

```Bash
   echo -e "root\nroot" | passwd
```

This will, of course, set the password to `root`.

6. Get the ip address of the VM:

```Bash
ip addr
```

My VM ip is typically: `172.16.210.140`

7. Now open a terminal window in you `Mac host` and clone this repo
8. `cd` into the repo directory
9. Run:

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

10. This will install Archlinux and create provided user with password = `root`.
   The VM will be restarted and you should be able to login with your user.
   The default shell for the user will be set to `zsh`.
   I typically take a **VM Snapshot** at this stage.

11. The linux kernel included, as of now, is not built with support for
    the vmware graphics driver. Consequently you'll be stuck to a basic resolution
    of 1024x768. We'll need to build our own kernel with support for said driver.

12. From the newly started VM fetch your current ip `ip addr`

13. From the terminal in you **Mac Host** - and inside this repo directory run:

```Bash
ADDR="<ip address from step 11>" \
ARCHUSER="preferred username (default:daimaou92)" \
make vm/after
```

This will take quite a bit of time - compiling the linux kernel.
Takes about 20 minutes with 4 cores given to the VM in my M1 Pro 14". It
installs the latest kernel version (5.19.9 at the time of this update) by default.
You could change this and pin it to a fixed kernel inside `after/kernelvmwgfx/build.sh`.

14. This step also downloads the latest commit from open-vm-tools, builds for aarch64
and installs it. So shared clipboard directories should start working as soon as
you install your DE or setup your WM. Your system gets restarted at the end of this.

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

### Quick setup with i3, alacritty and xorg (optional):

```Bash
sudo pacman -Sy xorg xorg-xinit i3-gaps i3status i3lock dmenu dex \
	alacritty dex
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

Hit `$mod+Enter`. This should open up `alacritty`.

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

Pick a resolution of choice and set it using xrandr.

```Bash
xrandr -s 3840x2400
```

Set this in i3 to have correct resolution post log in:

```Bash
echo "exec --no-startup-id xrandr -s 3840x2400" >> ~/.config/i3/config
```

There's also DPI - specially if you're on a smaller screen. I set mine
using `~/.Xresources`

```Bash
echo "Xft.dpi: 170" >> ~/.Xresources
sed -i \
	's@exec i3.*@xrdb -merge ~/.Xresources\
exec i3@' ~/.xinitrc
```

## Done. Enjoy