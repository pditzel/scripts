#!/bin/bash

################################################################################
#									       #
#	Author: Patrick Ditzel (patrick@central-computer.de)		       #
#									       #
#	License: GPLv3  						       #
#									       #
################################################################################

ENABLE_DEBUG=TRUE

function get_info () {
	
	clear
	echo "Which harddrive do you want to wipe? (Type full path e.g. /dev/sdX)"
	echo ""
	read DEVICE
	echo ""
	echo "How much cache does the harddrive has (in MB)?"
	echo ""
	read CACHEM
	CACHE="$(($CACHEM * 1024))"
	echo ""
	echo "Dryrun (y/n)?"
	echo ""
	read DRYRUN
	echo ""	
	if [ "$ENABLE_DEBUG" = "TRUE" ]; then
		echo "Devicename: $DEVICE"
		echo "Cachesize: $CACHE byte"
		echo ""
	fi

}

function wipe_hd () {

	if [ "$DRYRUN" = "y" ]; then
		echo "This script would perfom the following command:"
		echo "dd if=/dev/urandom conv=noerror,notrunc,sync bs=$CACHE | pv -S > $DEVICE"
		echo ""
	elif [ "$DRYRUN" = "n" ]; then
		dd if=/dev/urandom conv=noerror,notrunc,sync bs=$CACHE | pv -S > $DEVICE
	else
		echo "Please typ [y] or [n]"
		exit 1
	fi

}

function main () {

	get_info
	wipe_hd

}

main

