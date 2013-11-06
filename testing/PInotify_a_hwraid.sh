#!/bin/bash
# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# PI notify using Bash only
vers="PInotify_a_hwraid-0.6.0"
# 0.5.1 Now prints the version in the logs.
# 0.5.2 trdaily enabled by default now.
# 0.5.3 changed vers variable to have _ only in name before the number.
# 0.6.0 changed "to" variable to pull from address.plist and updated logging

# Set log files for stdout & stderror
log="/Library/Logs/com.trmacs/pi/log.log"
err_log="/Library/Logs/com.trmacs/pi/error.log"

# exec 1 captures stdtout and exec 2 captures stderr and we are appending to log files.
exec 1>> "${log}" 
exec 2>> "${err_log}"

# Set the host name for easy identification.
host_raw="$(scutil --get HostName)"

if [ -z "$host_raw" ]; then
	host_name="$(scutil --get ComputerName)"
else	
	host_name="$host_raw"
fi

when=$(date +%Y-%m-%d)
attachment="/Library/Logs/com.trmacs/pi/transfer/"$host_name"."$when".tar.bz2"
source_dir="/Library/Logs/com.trmacs/pi/current/"
attach_name=""$host_name"."$when".tar.bz2"
subject="PI Logs for "$host_name""
archive="/Library/Logs/com.trmacs/pi/archive/"
to=`/usr/libexec/PlistBuddy -c  "Print :PI" /Library/Scripts/trmacs/address.plist`


echo "-------------------------------------------"
date
echo ""$vers""
echo "Creating log files"
# Call external script to create log files.
echo "Building drive checking log"
/Library/Scripts/trmacs/a_hwraid_drivecheck.sh || exit 1
echo "done"
echo "Building system log check"
/Library/Scripts/trmacs/trsyscheck.sh || exit 2
echo "done"
echo "Collating daily logs."
/Library/Scripts/trmacs/trdaily.sh || exit 3
echo "done"

# Tar and compress the log files.
echo "Compressing source files"
tar -cjf "$attachment" "$source_dir"

echo "uuencoding source files and mailing to '$to'"
# uuencode the resulting tar'd file and pipe through to mail to send.

uuencode "$attachment" "$attach_name" | mail -s "$subject" "$to"
 
echo "Removing raw log files and moving the compressed version to the archive"

#Cleanup - delete the individual log files and move the tar'd attachment to the archive.
rm -rf /Library/Logs/com.trmacs/pi/current/*
mv -f "$attachment" "$archive"

echo "Closing"
date
echo " "
exit 0