# Databasebackup (dbbackup)

This is a bash-script to backup your databases with tho most common standard tools.

## Requirenments

Important: This Script is developed with debian GNU/Linux so it should work on debian and the most derived distributions.

For the backup of your databases you need a propper client to connect to your databaseserver.
This script aims to backup many different databasetype eg. postgres, mysql or mongodb in one single program. So if you have to backup postgres you have to install the psql-client package. If you want to backup MySQL databases install the mysql-client package.

## Features

* Runs interactive and noninteractive
* Make Postgrsbackups (localy and remote)
* Make MySQL/MariaDB-Backups (coming soon)
* Make MongoDB-Backups (coming soon)
* Optinal keep a filehistory of backups
* Optinal logging to syslog
* Reads configuration for postgresbackups from ~/.pgpass

More Information here: [https://www.central-computer.de/datenbanken-backup/]

