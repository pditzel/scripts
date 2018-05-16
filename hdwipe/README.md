# hdwipe.sh

For wiping harddisks I use dd. In older Versions of dd there is no view of the progress. The small tool pv create such a progressbar. I've combined both tools into a script.

> Warning: Using this program will delete all your data from the named harddrives.
> Use it with care.

## Usage

The script asks you for the device to wipe and the cache size of the harddisk. Giving the complete path to the harddisk device and the correct cachesize will complete the command for wiping. The last question before the script starts to wipe is if you want to make a dryrun which just print out the command that will be used. If you really wnat to wipe th disk answer here with [n].

