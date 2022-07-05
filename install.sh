#!/bin/bash
##!/bin/bash -ex

# Dependecies
echo "Installing dependencies."
sudo apt update
sudo apt install\
     udisks2\
     libguestfs-dev\
     libguestfs-tools\
     python3\
     python3-pip\
     python3-guestfs\
     qemu-kvm

echo ""
echo ""

#  Udiskie
echo "Installing udiskie-virt."

AUTO_DIR=~/.config/autostart
SCRIPT=$0
REPO_DIR="$(dirname $SCRIPT)"
SCRIPT_DIR="${REPO_DIR}/script"

read -p "Specify folder for launch script: " -i "$HOME/.local/bin/" -e BIN_DIR

# check against all directories in path
# ${var%/} removes trailing slash
if [[ ":$PATH:" != *":${BIN_DIR%/}:"* ]]; then
  echo "PATH does not contain \"$BIN_DIR\". Udiskie-virt might not work properly."
fi

echo "Installing launch script"
if [ -d $BIN_DIR ]; then
    cp "$SCRIPT_DIR"/udiskie-virt "$BIN_DIR"
fi
echo "Installing desktop entry"
if [ -d $AUTO_DIR ]; then
    cp "$SCRIPT_DIR"/udiskie-virt.desktop "$AUTO_DIR"
fi

pip3 install -e $REPO_DIR

echo ""
echo ""

# Group / Permission
echo "Creating group virtmount."
sudo groupadd virtmount
echo "Add $USER to virtmount group. You will have to start a new session for this to take effect."
sudo usermod -a -G virtmount $USER
echo "Add $USER to kvm group. You will have to start a new session for this to take effect."
sudo usermod -a -G kvm $USER

echo "Creating location for virtual mounts."
sudo mkdir -pv /media/virtmount
sudo chgrp -v virtmount /media/virtmount
sudo chmod g+w /media/virtmount

# Ubuntu specific problem. Normal permissions not sufficient to read
# kernel images
# https://libguestfs.org/guestfs-faq.1.html
echo "Giving users permissions to use the kernel image."
sudo chmod 0644 /boot/vmlinuz*

echo "Installing udev rule."
# https://unix.stackexchange.com/questions/333697/etc-udev-rules-d-vs-lib-udev-rules-d-which-to-use-and-why
sudo cp "${REPO_DIR}/script/99-external-media.rules" /etc/udev/rules.d
sudo udevadm control --reload-rules
sudo udevadm trigger

echo ""
echo ""

# Disable automounting of known desktop environments
echo "Disable automounting of known desktop environments."

if [ $DESKTOP_SESSION != "" ]
then
    desktop_environment="$DESKTOP_SESSION"
elif [ $XDG_CURRENT_DESKTOP != "" ]
then
    desktop_environment="$XDG_CURRENT_DESKTOP"
elif [ $GDMSESSION != "" ]
then
    desktop_environment="$GDMSESSION"
    echo ""
fi

if [ $desktop_environment != "" ]
then
    desktop_environment=$(echo $desktop_environment | tr [:upper:] [:lower:])
    echo "Detected ${desktop_environment}."
fi

case $desktop_environment in
    "ubuntu" | "ubuntu:gnome" | "ubuntu:GNOME")
	gsettings set org.gnome.desktop.media-handling automount false
	gsettings set org.gnome.desktop.media-handling automount-open false


	;;
    "MATE" | "mate")
	gsettings set org.mate.media-handling automount false
	gsettings set org.mate.media-handling automount-open false
	gsettings set org.gnome.desktop.media-handling automount false
	gsettings set org.gnome.desktop.media-handling automount-open false
    ;;

    "plasma" | "kde")
	# manipulate INI-format files
	sudo apt install crudini
	crudini --set"$HOME/.config/kded5rc" "Module-device_automounter" "autoload" "false"
	;;
    "lubuntu" | "lxqt")
	# manipulate INI-format files
	sudo apt install crudini
	crudini --set "$HOME/.config/pcmanfm-qt/lxqt/settings.conf" "Volume" "autorun" "false"
	crudini --set "$HOME/.config/pcmanfm-qt/lxqt/settings.conf" "Volume" "mount_on_startup" "false"
	crudini --set "$HOME/.config/pcmanfm-qt/lxqt/settings.conf" "Volume" "mount_removable" "false"
	;;
    "xubuntu" | "xfce")
	xfconf-query -c thunar-volman -np "/automount-media/enabled" -t "bool" -s "false"
	xfconf-query -c thunar-volman -np "/autoburn/enabled" -t "bool" -s "false"
	xfconf-query -c thunar-volman -np "/autobrowse/enabled" -t "bool" -s "false"
	xfconf-query -c thunar-volman -np "/autoipod/enabled" -t "bool" -s "false"
	xfconf-query -c thunar-volman -np "/automount-drives/enabled" -t "bool" -s "false"
	xfconf-query -c thunar-volman -np "/autoopen/enabled" -t "bool" -s "false"
	xfconf-query -c thunar-volman -np "/autophoto/enabled" -t "bool" -s "false"
	xfconf-query -c thunar-volman -np "/autoplay-audio-cds/enabled" -t "bool" -s "false"
	xfconf-query -c thunar-volman -np "/autoplay-video-cds/enabled" -t "bool" -s "false"
	xfconf-query -c thunar-volman -np "/autorun/enabled" -t "bool" -s "false"
	;;
    "budgie:gnome" | "Budgie:GNOME" | "budgie-desktop")
	gsettings set org.gnome.desktop.media-handling automount false
	gsettings set org.gnome.desktop.media-handling automount-open false
	gsettings set org.cinnamon.desktop.media-handling automount false
	gsettings set org.cinnamon.desktop.media-handling automount-open false
	;;

  *)
	echo "No solution for $desktop_environment found. Please deactivate automounting manually"
    ;;
esac
