#!/bin/bash

DEBUG=TRUE
DEPENDENCYLIST="htpasswd pwgen"

function checkDependencies () {
	# Check for the software dependencies we need
	# - htpasswd
	# - pwgen
	# - all other commands should be built in in bash or installed on your system per default.
	for DEP in $DEPENDENCYLIST; do
		if ! type "$DEP" > /dev/null; then
			echo "The command $DEP is needed but not found. Pleas install it."
			exit 1
		else
			if [ "${DEBUG}" == TRUE ]; then
				echo "Found $DEP, continue..."
			fi
		fi
	done 
}

function getInfo () {
	# Set password length
	read -p "Which length shoult the passwords have: " PWDLENGTH
	# Set the inputfile
	read -p "The name and path of the userlistfile: " USERLIST
	if [ "${DEBUG}" == true ]; then
		echo -e "The passwordlength is: $PWDLENGTH"
		echo -e "The inputfile is: $INPUTFILE"
	fi
}

function createPasswordList () {
	# Read the userlistfile and create for each user an unique password. 
	# Both, the username and the password will be written into a new file separated by a ",".
	while read LINE; do
		echo "$LINE,$(pwgen -1 ${PWDLENGTH})" >> $USERLIST.pwd.csv
		if [ "${DEBUG}" == TRUE ]; then
			echo "Username: $LINE, Password: $(tail -n1 $USERLIST.pwd.csv | cut -d "," -f2)"
		fi
	done < $USERLIST
}

function checkAndCreateHtpasswd () {
	# Check if the htpasswd-file already exists
	if [ -f $USERLIST.htpasswd ]; then
		# Check if the htpasswd-file ist writeable
		if [ -w $USERLIST.htpasswd ]; then
			if [ "${DEBUG}" == TRUE ]; then
				echo "$USERLIST.htpasswd exists and is writeable."
			fi
		else
			# If not you have to check the filepermissions
			echo "$USERLIST.htpasswd exists but is not writeable. Please corrct filepermissions"
			exit 1
		fi
	else
		# If the file does not exists it will be created.
		echo "$USERLIST.htpasswd does not exist. Create this file now."
		htpasswd -cb $USERLIST.htpasswd user password
		htpasswd -D $USERLIST.htpasswd user
		# I am not shure if the following command is the better one...
		# touch $USERLIST.htpasswd
	fi
}

function writeHtpasswd () {
	# The Passwords for each user are created so we can add the users into the htpasswd-file
	while read LINE; do 
		htpasswd -b $USERLIST.htpasswd $(echo $LINE | cut -d "," -f1) $(echo $LINE | cut -d "," -f2)
	done < $USERLIST	
}

function main () {
	checkDependencies
	getInfo
	createPasswordList
	checkAndCreateHtpasswd
	writeHtpasswd
}

main
