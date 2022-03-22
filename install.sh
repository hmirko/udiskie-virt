#!/bin/bash

# Dependecies
sudo apt install\
     udisks2\
     libguestfs-dev\
     libguestfs-tools\
     python3\
     python3-pip\
     python3-guestfs\
     tint2


#  Udiskie

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


echo "Installing udiskie-virt."
pip3 install -e $REPO_DIR

# Group / Permission
echo "Creating group virtmount."
sudo groupadd virtmount
echo "Addint $USER to virtmount. You will have to start a new session for this to take effect."
sudo usermod -a -G virtmount $USER

echo "Creating location for virtual mounts."
sudo mkdir -pv /media/virtmount
sudo chgrp -v virtmount /media/virtmount
sudo chmod g+w /media/virtmount

# Ubuntu specific problem. Normal permissions not sufficient to read
# kernel images
echo "Giving users permissions to use the kernel image."
sudo chmod 755 /boot/vmlinuz*


echo "Installing udev rule."
# https://unix.stackexchange.com/questions/333697/etc-udev-rules-d-vs-lib-udev-rules-d-which-to-use-and-why
sudo cp "${REPO_DIR}/script/99-external-media.rules" /udev/rules.d
sudo udevadm control --reload-rules
sudo udevadm trigger


# Checking
echo "Checking correct install of libguestfs."
libguestfs-test-tool
