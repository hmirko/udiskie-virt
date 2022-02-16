#!/bin/bash
BIN_DIR=~/.local/bin/
AUTO_DIR=~/.config/autostart
SCRIPT=$0
SCRIPT_DIR=$(dirname $SCRIPT)

case $1 in

    install)
	if [ -d $BIN_DIR ]; then
	    cp "$SCRIPT_DIR"/udiskie-virt "$BIN_DIR"
	fi
	if [ -d $AUTO_DIR ]; then
	    cp "$SCRIPT_DIR"/udiskie-virt.desktop "$AUTO_DIR"
	fi
	;;

    uninstall)
	if [ -f $BIN_DIR/udiskie-virt ]; then
	    rm "$BIN_DIR"/udiskie-virt
	fi
	if [ -d $AUTO_DIR ]; then
	    rm "$AUTO_DIR"/udiskie-virt.desktop
	fi
	;;
esac
