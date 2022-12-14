#!/bin/bash

# Redirect all commands to file
exec > >(tee "install.log") >&1

# Wipe drive and perform clean base install?
read -n 1 -r -p "Wipe drive and perform clean base install [y/N]? "
echo # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

	# Print commands as they are executed
	set -x

	# Base install
	umount -R /mnt 2> /dev/null
	wipefs -a /dev/sda
	echo 'type=83' | sfdisk /dev/sda
	yes | mkfs.ext4 /dev/sda1
	mount /dev/sda1 /mnt
	pacstrap -K /mnt base linux grub dhcpcd sudo fish neovim
	genfstab -U /mnt >> /mnt/etc/fstab
	arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/Europe/Ljubljana /etc/localtime"
	arch-chroot /mnt /bin/bash -c "hwclock --systohc"
	arch-chroot /mnt /bin/bash -c "sed -i 's/#en_US.UTF/en_US.UTF/' /etc/locale.gen"
	arch-chroot /mnt /bin/bash -c "locale-gen"
	arch-chroot /mnt /bin/bash -c "echo 'LANG=en_US.UTF-8' > /etc/locale.conf"
	# Add hostname...
	read -p "Hostname: " hostname
	arch-chroot /mnt /bin/bash -c "echo $hostname > /etc/hostname"
	# Root password
	echo "Enter password for root: "
	arch-chroot /mnt /bin/bash -c "passwd"
	# Add new user...
	read -p "Add user: " user
	echo "Enter password for $user: "
	arch-chroot /mnt /bin/bash -c "useradd -m -s /bin/fish $user"
	arch-chroot /mnt /bin/bash -c "passwd $user"
	arch-chroot /mnt /bin/bash -c "sed -i 's/root ALL=(ALL:ALL) ALL/root ALL=(ALL:ALL) ALL\n$user ALL=(ALL:ALL) ALL/' /etc/sudoers"
	# Enable dhcpcd
	arch-chroot /mnt /bin/bash -c "systemctl enable dhcpcd"
	# Setup grub
	arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc /dev/sda"
	arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
	# Base install finished...
	echo "Minimal install finished."
	echo

	# Disable printing of commands, since these next ones are too verbose
	set +x

fi

# Install additional packages?
read -n 1 -r -p "Install additional packages [y/N]? "
echo # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

	# Mount, in case we skipped the base install
	mount /dev/sda1 /mnt 2> /dev/null

	read -n 1 -r -p "exa htop mlocate openssh broot ranger nnn strace ltrace lsof [y/N]? " exa
	echo # move to a new line
	read -n 1 -r -p "gcc cmake git [y/N]? " gcc
	echo # move to a new line
	read -n 1 -r -p "python python-pip python-setuptools [y/N]? " python
	echo # move to a new line
	read -n 1 -r -p "xorg-server xorg-xinit xorg-xset ttf-dejavu alacritty [y/N]? " xorg
	echo # move to a new line
	read -n 1 -r -p "i3 [y/N]? " i3
	echo # move to a new line
	read -n 1 -r -p "xfce4 [y/N]? " xfce4
	echo # move to a new line
	read -n 1 -r -p "chromium [y/N]? " chromium
	echo # move to a new line
	
	if [[ $exa =~ ^[Yy]$ ]]
	then
		pacstrap /mnt --needed exa htop mlocate openssh broot ranger nnn strace ltrace lsof
	fi
	if [[ $gcc =~ ^[Yy]$ ]]
	then
		pacstrap /mnt --needed gcc cmake git
	fi
	if [[ $python =~ ^[Yy]$ ]]
	then
		pacstrap /mnt --needed python python-pip python-setuptools
	fi
	if [[ $xorg =~ ^[Yy]$ ]]
	then
		pacstrap /mnt --needed xorg-server xorg-xinit xorg-xset ttf-dejavu alacritty
	fi
	if [[ $i3 =~ ^[Yy]$ ]]
	then
		pacstrap /mnt --needed i3
	fi
	if [[ $xfce4 =~ ^[Yy]$ ]]
	then
		pacstrap /mnt --needed xfce4
	fi
	if [[ $chromium =~ ^[Yy]$ ]]
	then
		pacstrap /mnt --needed chromium
	fi
	
fi

umount -R /mnt 2> /dev/null

# Finished
echo "Done."