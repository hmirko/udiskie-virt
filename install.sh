!/bin/bash

# Dependecies
sudo apt install\
     udisks2\
     libguestfs-dev\
     python3\
     python3-pip\
     python3-guestfs


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
sudo usermod -a -G $USER virtmount

echo "Creating location for virtual mounts."
mkdir -pv /media/virtmount
sudo chown -v virtmount:virtmount /media/virtmount

# Ubuntu specific problem. Normal permissions not sufficient to read
# kernel images
echo "Giving users permissions to use the kernel image."
sudo chmod 755 /boot/vmlinuz*

# Checking
echo "Checking correct install of libguestfs."
libguestfs-test-tool
