# Updates
1. [VMWare Fusion Tech Preview 2023](https://blogs.vmware.com/teamfusion/2023/07/vmware-fusion-2023-tech-preview.html) is out.
2. Will henceforth be adding the latest ISO I can find on the Internet that works with these scripts in a
[Release](https://github.com/daimaou92/install-arch-vmwarefusion-techpreview/releases).
Please keep an eye out for that.

# What it is

A semi-automated way of setting up ArchLinux in [VMware Fusion for Apple Silicon](https://www.vmware.com/in/products/fusion.html)

# Steps

1. Acquire an ArchLinux ISO for aarch64. This can be done in a variety of ways. I download it from the [registry](https://pkgbuild.com/~tpowa/archboot/iso/aarch64/latest/) of the awesome [Archboot](https://gitlab.archlinux.org/tpowa/archboot) project since it has started creating `aarch64` ISOs recently. All tests have been done with the ~350MiB file - take that as you will. 

2. Setup a new "Custom Virtual Machine" in VMware.

   1. Choose "Other Linux 6.x kernel 64-bit Arm"
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

4. Set a root password in the VM:

```shell
   echo -e "root\nroot" | passwd
```

This will, of course, set the password to `root`.

5. Get the ip address of the VM:

```shell
ip addr
```

6. Now open a terminal window in your `Mac host` and clone this repo
7. `cd` into the repo directory
8. Run:

```shell
ADDR="<ip address from step 5>" \
ARCHUSER="preferred username (default:daimaou92)" \
ARCHHOSTNAME="preferred machine name (default:archmachine)" \
make vm/install
```

All configurable options are right on top of the `Makefile`. Configure as needed.

**If you are using SATA as the Bus type for `Hard Disk` make sure to add**

```shell
ABLOCKDEVICE="sda" PARTITIONPREFIX=""
```

to the above command.

9. This will install Archlinux and create provided user with password = `root`.
   The VM will be restarted and you should be able to login with your user.
   The default shell for the user will be set to `zsh`.
   I typically take a **VM Snapshot** at this stage.

10. [ArchLinuxARM packages](https://archlinuxarm.org/packages)
doesn't have open-vm-tools yet so we'll have to build it ourselves.

11. From the newly started VM fetch your current ip `ip addr`

12. From the terminal in you **Mac Host** - and inside this repo directory run:

```shell
ADDR="<ip address from step 11>" \
ARCHUSER="preferred username (default:daimaou92)" \
make vm/openvmtools
```
This step downloads the latest commit from the default branch of [open-vm-tools](https://github.com/vmware/open-vm-tools),
builds for aarch64 and installs it.
So shared clipboard directories should start working as soon as
you install your DE or setup your WM. Your system will be restarted at the end of this.

13. After logging in verify the service status of the following:

```shell
sudo systemctl status vmtoolsd.service
sudo systemctl status vmware-vmblock-fuse.service
```

Check `/mnt/hgfs` to see if the directory you've shared exists.
```shell
ls -la /mnt/hgfs
```

There should be no errors.

Check if the file `/etc/xdg/autostart/vmware-user.desktop` exists:

```shell
ls /etc/xdg/autostart/vmware-user.desktop
```

This needs to be autostarted at login and is required for clipboard sharing.

14. Change the user password:

```shell
passwd
```

and the root password:

```shell
sudo passwd
```

15. If everything has gone as per documentation so far - you can stop reading
    further and set up your home environment the way you prefer.

### Quick setup with i3, alacritty and xorg (optional):

```shell
sudo pacman -Sy xorg xorg-xinit i3-gaps i3status i3lock dmenu alacritty dex xss-lock
```

You'll need to start the `x server` at login followed by `i3` and handle DPI.
We'll do it with `~/.Xresources`, `~/.xinitrc` and `~/.zprofile`.

```shell
echo 'Xft.dpi: 220' | tee -a ~/.Xresources > /dev/null
echo 'xrdb -merge ~/.Xresources' | tee -a ~/.xinitrc > /dev/null
echo 'exec i3' | tee -a ~/.xinitrc > /dev/null
echo 'startx' | tee -a ~/.zprofile > /dev/null
```

Now kill the shell with `Ctrl+d` and relogin.

On logging in for the first time after installing i3 you'll be asked if the
`~/.config/i3/config` file should be created. Press `Enter` for `Yes`.
Another screen pops up asking your choice of modifier key
(called `$mod` henceforth). Choose `Cmd` or `Alt` per preference using
arrow keys and hit `Enter`.

Hit `$mod+Enter`. This should open up `Alacritty`.

## Done. Enjoy
