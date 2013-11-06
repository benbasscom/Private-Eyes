#!/bin/bash
# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# PI notify using Bash only
vers="PInotify-0.6"
# 0.5.1 Now prints the version in the logs.
# 0.5.2 trdaily enabled by default now.
# 0.6 pulling e-addresses from /Library/Scripts/trmacs/address.plist

# Set log files for stdout & stderror
log="/Library/Logs/com.trmacs/pi/log.log"
err_log="/Library/Logs/com.trmacs/pi/error.log"

# exec 1 captures stdtout and exec 2 captures stderr and we are appending to log files.
exec 1>> "${log}" 
exec 2>> "${err_log}"

# Set the host name.
host_raw="$(scutil --get HostName)"

if [ -z "$host_raw" ]; then
	host_name="$(scutil --get ComputerName)"
else	
	host_name="$host_raw"
fi

when=$(date +%Y-%m-%d)
# host_name="$(system_profiler SPSoftwareDataType | grep "Computer Name:" | awk '{print $3" "$4}')"
attachment="/Library/Logs/com.trmacs/pi/transfer/"$host_name"."$when".tar.bz2"
source_dir="/Library/Logs/com.trmacs/pi/current/"
attach_name=""$host_name"."$when".tar.bz2"
subject="PI Logs for "$host_name""
to=`/usr/libexec/PlistBuddy -c  "Print :alerts" /Library/Scripts/trmacs/address.plist`
archive="/Library/Logs/com.trmacs/pi/archive/"

#startTime=`/usr/libexec/PlistBuddy -c "Print ${last_entry}:startTime" /Library/Logs/CCC.stats`


echo "-------------------------------------------"
date
echo ""$vers""
echo "Creating log files"
# Call external script to create log files.
#echo "Building drive checking log"
#/Library/Scripts/trmacs/drivecheck.sh || exit 1
#echo "done"
#echo "Building system log check"
#/Library/Scripts/trmacs/trsyscheck.sh || exit 2
echo "done"
echo "Collating daily logs."
/Library/Scripts/trmacs/trdaily.sh || exit 3
echo "done"


# Tar and compress the log files.
echo "Compressing source files"
tar -cjf "$attachment" "$source_dir"

echo "uuencoding source files and mailing"
# uuencode the resulting tar'd file and pipe through to mail to send.

uuencode "$attachment" "$attach_name" | mail -s "$subject" "$to"
 
echo "Removing raw log files and moving the compressed version to the archive"

#Cleanup
rm -rf /Library/Logs/com.trmacs/pi/current/*
mv -f "$attachment" "$archive"

echo "Closing"
date
echo " "
exit 0