# What it is

An automated way of setting up ArchLinux in [VMware Fusion Public Tech Preview 21H1](https://customerconnect.vmware.com/downloads/get-download?downloadGroup=FUS-PUBTP-2021H1)

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

14. Install xrandr and run it to check if you have all the resolutions
    at this point.

15. You'll also need open-vm-tools for copy-paste and sharing to work across
    VM and host. In your **Mac Host** terminal run:

```Bash
ADDR="<ip address from step 11>" \
ARCHUSER="preferred username (default:daimaou92)" \
make vm/openvmtools
```

This will pull the latest sources, compile and set it up. It'll reboot
one last time and you're done.

16. Enjoy
