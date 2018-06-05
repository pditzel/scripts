#!/bin/bash

#################################################################################
#										#
#	Author: Patrick Ditzel (patrick@central-computer.de)			#
#										#
#	License: GPLv3								#
#										#
#										#
# This is just an idea - it is not testet yet - 2018-06-06			#	
#										#
# I realy don't know if this script works. So if you want to test please write	#
# me an email.									# 	
#										#
#################################################################################


# The partition of your backupdrive should be labled with an unique name
DISKLABEL=yourbackupdrivedisklabelhere

# The destinationdirectory where you whish to mount your backupdrive
MOUNTDIR=/mnt

# The list of directorys to be backuped by this script. For readability each directory is written in a seperate line. After each directory there has to be a whitspace followed by aa backslash - bash and array, you know...
PATHLIST=(\
	/etc \
	/home \
	/var/log \
	)

#################################################################################
# Do not change anything after this line
#################################################################################

function checkForBackupDrive () {
	if [ "$DISPLAY" ]; then 
		notify-send -i /usr/share/icons/gnome/48x48/status/dialog-warning.png "Borg Backup Action" "Mounting backupstorage - do not remove your backupdrive!"
	else 
		echo "mounting backupstorage"
		echo "..."
	fi
	
	if [ -L /dev/disk/by-label/$DISKLABEL ]; then 
		/bin/mount $MOUNTDIR
	else
		echo "backupdrive not found - aborting backup"
		notify-send -i /usr/share/icons/gnome/48x48/status/dialog-error.png "Borg Backup Action" "no backupdrive found - aborting"
		exit 1
	fi
	
	if [ "$DISPLAY" ]; then
		notify-send -i /usr/share/icons/gnome/48x48/status/dialog-warning.png "Borg Backup Action" "... starting backup ..."
	else
		echo "..."
		echo "done"
		echo "backup data"
		echo "..."
	fi
}

function loadEncryptionInfo () {
	# This file - $HOME/.local/share/borg/borg.rc.local - you should realy have
	# This file contains only one line:
	# export BORG_PASSPHRASE="YourPassword"
	# This is your encryption passphrase
	if [ -s $HOME/.local/share/borg/borg.rc.local ]; then
		. $HOME/.local/share/borg/borg.rc.local
	else
		echo "Your borg.rc.local is not found, can't do backup"
		exit 1
	fi
}

function backingUp () {
	typeset -i i=0 max=${#PATHLIST[*]}
	while (( i < max )); do
		if [ -d ${PATHLIST[$i]} ]; then
			if [ "$DISPLAY" ]; then
				notify-send -i /usr/share/icons/gnome/48x48/status/dialog-error.png "Borg Backup Action" "Backing up ${PATHLIST[$i]}"
			else
				echo "Backup ${PATHLIST[$i]}"
			fi
			/usr/bin/borg create --compression lz4 --exclude-caches --one-file-system -v --stats --progress $MOUNTDIR/$(hostname)::'{hostname}-{now:%Y-%m-%d-%H%M%S}' ${PATHLIST[$i]}
		else
			echo The path ${PATHLIST[$i]} does not exist. Skipping this on.
		fi
	done
}

function removeOldBackups () {
	/usr/bin/borg prune -v --list borg $MOUNTDIR/$(hostname) --prefix '{hostname}-' --keep-within=1d --keep-daily=7 --keep-weekly=4 --keep-monthly=12 
}

function unmountBackupDrive () {
	if [ "$DISPLAY" ]; then
		notify-send -i /usr/share/icons/gnome/48x48/status/dialog-warning.png "Borg Backup Action" "... finished backup and removing backupstorage"
	else
		echo "..."
		echo "finished backing up data"
		echo "unmount backupstorage"
		echo "..."
	fi
	
	/bin/umount $MOUNTDIR
	
	if [ "$DISPLAY" ]; then
		notify-send -i /usr/share/icons/gnome/48x48/status/dialog-warning.png "Borg Backup Action" "Successfully removed backupstorage - it is save to remove yout backupdevice now."
	else
		echo "..."
		echo "backupstorage is removed"
	fi
}

function main () {
	checkForBackupDrive
	loadEncryptionInfo
	backingUp
	removeOldBackups
	unmountBackupDrive
}

main
