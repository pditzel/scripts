#!/bin/bash

################################################################################
#									       #
#	Author: Patrick Ditzel (patrick@central-computer.de)		       #
#									       #
#	License: GPLv3  						       #
#									       #
################################################################################

################################################################################
# Vars for configuration	

FRITZBOXFQDN="fritz.box"

USER="Username"

PWD="SecretPassword"

DEBUG=true

################################################################################
# No changes after this line 

PIDFILE=/var/run/tcpreplay.pid

SIDFILE=/var/run/${USER}.txt

# Functions   

function initcapture () {
	                                                                              
	# Create dummy interface for captureoutput 
	
	DUMMYMOD=$(lsmod | grep dummy | cut -d " " -f1)
	
	if [ "${DUMMYMOD}" != "dummy" ]; then
		/sbin/modprobe dummy
		sleep 15
		if [ "${DEBUG}" == true ]; then
                        echo -e "\n Sleeping for 15 seconds to load the dummy kernelmodule correctly \n"
                fi
		/sbin/ifconfig dummy0 up
		/sbin/ifconfig dummy0 promisc
	else
		if [ "${DEBUG}" == true ]; then
	        	echo -e "\n Kernelmodule dummy is already active \n"
		fi
		/sbin/ifconfig dummy0 up
	        /sbin/ifconfig dummy0 promisc
	fi
	
	# Login to FRITZ!BOX (challenge/response) and create SID  	       
	
	# Get challenge
	CHALLENGE=$(curl -s "https://${FRITZBOXFQDN}/login_sid.lua?username=${USER}" | grep -Po '(?<=<Challenge>).*(?=</Challenge>)')
	if [ "${DEBUG}" == true ]; then
		echo -e "Challenge:\n $CHALLENGE \n"
	fi
	# Hash login
	MD5=$(echo -n ${CHALLENGE}"-"${PWD} | iconv -f ISO8859-1 -t UTF-16LE | md5sum -b | awk '{print substr($0,1,32)}')
	if [ "${DEBUG}" == true ]; then
	        echo -e "MD5:\n $MD5 \n"
	fi
	# Create response
	RESPONSE="${CHALLENGE}-${MD5}"
	if [ "${DEBUG}" == true ]; then
	        echo -e "REPONSE:\n $RESPONSE \n"
	fi
	# Send login and grep sid
	SID=$(curl -i -s -k -d "response=${RESPONSE}&username=${USER}" "${FRITZBOXFQDN}" | grep -Po -m 1 '(?<=sid=)[a-f\d]+')
	if [ "${DEBUG}" == true ]; then
	        echo -e "SID:\n $SID \n"
	fi
	
	# Capture PCAP-Stream for Internetdevice from the FRITZ!BOX	       #
	
	if [ "${SID}" != "0000000000000000" ]; then
		if [ "${DEBUG}" == true ]; then
                        echo -e "\n Start getting the stream from the FRITZ!BOX and redirect to dummy0 \n"
                fi
		# Networkinterface 1(Internet)=3-17 oder 2-1
		/usr/bin/wget -O - "https://$FRITZBOXFQDN/cgi-bin/capture_notimeout?ifaceorminor=2-1&snaplen=1600&capture=Start&sid=$SID" 2>/dev/null | /usr/bin/tcpreplay -q --topspeed -i dummy0 - &

		# Write tcpreplay-PID into pidfile for later use
		echo $! > $PIDFILE
		if [ "${DEBUG}" == true ]; then
                        echo -e "\n Writing PID and SID into files for later use \n"
                fi
	
		# Write sid into textfile for later use (logout, other script)
		echo $SID > $SIDFILE
	else
		echo "\n Can't establish SID-Connection \n"
	 	/sbin/ifdown dummy0
	fi

}

function stopcapture () {

	# Turn off tcpreplay an delete pidfile 
	
	if [ -e ${PIDFILE} ]; then
		if [ "${DEBUG}" == true ]; then
                        echo -e "\n Killing the capturingproces and remove PID-file \n"
                fi
	       	/bin/kill -9 `/bin/cat ${PIDFILE}`
	       	/bin/rm -f ${PIDFILE}
	else
	       	echo "\n $PIDFILE does not exist. \n"
	fi
	
	# Logoff from the FRITZ!BOX and remove the sidfile 

	# Create postdata and logoff from the FRITZ!BOX
	if [ "${DEBUG}" == true ]; then
                        echo -e "\n Logoff from FRITZ!BOX \n"
        fi
	if [ -e $SIDFILE ]; then
	       	SID=`/bin/cat ${SIDFILE}`
	       	POSTDATA="getpage=./home/home.lua/logout=1&sid=$SID"
	       	/usr/bin/wget -O /dev/null --post-data="${POSTDATA}" "${FRITZBOXFQDN}" 2>/dev/null
	       	/bin/rm -f $SIDFILE
	else
	       	echo "\n $SIDFILE does not exist, can't logoff because no session exists. \n"
	fi

	# Turn down interface dummy0 and remove kernelmodule
	INTERFACEISTHERE=$(grep "dummy0" /proc/net/dev)
	if [ -n "${INTERFACEISTHERE}" ]; then
		if [ "${DEBUG}" == true ]; then
                	echo -e "\n Turn down dummy0. \n"
        	fi
		/sbin/ifconfig dummy0 down
	else
		echo -e "\n Interface dummy0 not found, cant turn it down. \n"
	fi
	
	MODULEISTHERE=$(grep "dummy" /proc/modules)
	if [ -n "${MODULEISTHERE}" ]; then
	if [ "${DEBUG}" == true ]; then
                	echo -e "\n Remove kernelmodule dummy. \n"
        	fi
		/sbin/rmmod dummy
	else
		echo -e "\n Kernelmodule dummy is actualy not loaded into the kernel, can't remove it. \n"
	fi

}


case "$1" in
   	-[iI]|-init)
		initcapture
		;;
	-[sS]|-stop)
		stopcapture
		;;
	*)
		echo "Use -i or -I or --init to start and -s or -S or --stop to stop the capturing"
		;;
esac

################################################################################
#                                                                              #
#       The End	                                                               #
#                                                                              #
################################################################################


