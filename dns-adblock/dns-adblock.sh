#!/bin/bash

################################################################################
#                                                                              #
# Author: Patrick Ditzel                                                       #
# Lizenz:  GNU GENERAL PUBLIC LICENSE v3                                       #
#                                                                              #
################################################################################

################################################################################
#									       #
# Konfiguration über Variablen						       #
#									       #
################################################################################
#
# Wie soll die AdServer-Liste heißen und wo abgespiechert werden
TARGETFILE=/etc/bind/blacklist

# Absendeadresse für E-Mails
SENDER=netzmeister@central-computer.de

# Empfaengeradresse für E-Mails
RCPT=patrick@central-computer.de

################################################################################
#									       #
# Ab hier nichts mehr ändern ;-)					       #
#									       #
################################################################################

TMPFILE1=/tmp/tmp1.adserver.lst

TMPFILE2=/tmp/tmp2.adserver.lst

OLDTARGETFILE="${TARGETFILE}.1"

CHECKMSG=""

DIFFS=""
################################################################################
#									       #
# Funktionen des Programmes						       #
#									       #
################################################################################

function get_list () {
	# AdServer-Liste herunterladen
	curl -o $TMPFILE1 "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=bindconfig&showintro=0&startdate%5Bday%5D=01&startdate%5Bmonth%5D=01&startdate%5Byear%5D=2000&mimetype=plaintext"
}

function prepare_list () {
	# Test ob AdServerList bereits vorhanden ist
	if [ -s $TMPFILE1 ]; then
		# AdServerliste bearbeiten:
		## null.zone.file gegen /etc/bin/null.zone.file tauschen, da sonst die Liste nicht in bind geladen werden kann
		## Alle einträge die das Wort zone beinhalten rausfiltern und in eine eigene Daten schreiben
		sed 's!null.zone.file!/etc\/bind\/null.zone.file!' $TMPFILE1 | grep zone > $TMPFILE2
	else
		echo "Datei $TMPFILE1 ist nicht vorhanden" | mailx \-r "$SENDER" \-s "Datei nicht gefunden" "$RCPT"
		exit 1
	fi
}

function check_list () {
	if [ -s $TMPFILE2 ]; then
		while read LINE; do
			# Zeilenweise nach Einträgen suchen, die nicht den Namen der Zonendatei enthalten
			echo $LINE | grep -v "null.zone.file"
			# Wird ein solcher Eintrag gefunden, wird dieser in die Variable $CHEKCMSG geschrieben
			if [ "$?" -eq 0 ]; then
				CHECKMSG="$CHECKMSG Entry found not targeting to null.zone.file:\n $LINE \n --- --- ---\n" 
			fi
		done < $TMPFILE2	
		# Wenn die Variable $CHECKMSG nicht leer ist, ... 
		if [ -n "$CHECKMEG" ]; then
			# ... via E-Mail über das Ergebnis informiert.
			echo $CHECKMSG | mailx \-r "$SENDER" \-s "Nicht konforme Einträge in der AdBlock DNS-Liste gefunden" "$RCPT"
			exit 1
		fi
	else
		echo "Die Datei $TMPLIST2 ist nicht vorhanden" | mailx \-r "$SENDER" \-s "Datei nicht gedunden" "$RCPT"		
		exit 1
	fi
}

function compare_lists () {
	if [ -s $TMPFILE2 ] && [ -s $TARGETFILE ]; then
		# Unterschieden sich die neue Datei und die bestehende Datei
		diff $TMPFILE2 $TARGETFILE
		# Wenn ja, dann ...
		if [ "$?" -ne 0 ]; then
			# Änderungen in eine Variable schreiben und ...
			DIFFS="diff newBlacklsit existingBlacklist: "
			DIFFS="$DIFFS `diff $TMPFILE2 $TARGETFILE`"
			DIFFS="$DIFFS --- --- --- "
			# ... per E-Mail versenden
			echo $DIFFS | mailx \-r "$SENDER" \-s "Aenderungen an der DNS Blackliste" "$RCPT"	
		fi
	else
		if [ ! -s $TMPFILE1 ]; then
			echo "Datei $TMPFILE1 ist nicht vorhanden." | mailx \-r "$SENDER" \-s "Datei nicht gefunden" "$RCPT"
		fi
		if [ ! -s $TMPFILE2 ]; then
			echo "Die Datei $TMPLIST2 ist nicht vorhanden." | mailx \-r "$SENDER" \-s "Datei nicht gefunden" "$RCPT"
		fi
		exit 1
	fi
}

function renew_list () {
	# Bestehende Datei wegsichern, wenn vorhanden
	if [ -e $TARGETFILE ]; then
		cp $TARGETFILE $OLDTARGETFILE
	fi
	# Datei aktualisieren
	if [ -s $TMPFILE2 ]; then  
        	mv $TMPFILE2 $TARGETFILE
	else
		echo "Die Datei mit den Quelldaten ( $TEMPFILE2 ) ist entweder nicht vorhanden oder leer." | mailx \-r "$SENDER" \-s "Datei nicht gefunden" "$RCPT"
		exit 1
	fi
	# neue Liste in bind laden
	rndc reload
	# Aufräumen
	rm -f $TMPFILE1 $TMPFILE2
}

function check_root () {
	if [ "$USER" != "root" ]; then
		echo "Sie haben nicht ausreichende Berechtigungen um das Programm erfolgreich auszuführen. Bitte lassen Sie das Programm als Benutzer root laufen." | mailx \-r "$SENDER" \-s "Fehlende Berechtigungen" "$RCPT"
		exit 1
	fi
}

################################################################################
#									       #
# Das Hauptprogramm							       #
#									       #
################################################################################

get_list
prepare_list
check_list
compare_lists
check_root
renew_list

