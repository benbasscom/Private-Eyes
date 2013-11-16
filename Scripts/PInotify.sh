#!/bin/bash
# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# PI notify using Bash only
vers="PInotify-0.6.2"
# 0.5.1 Now prints the version in the logs.
# 0.5.2 trdaily enabled by default now.
# 0.6.0 changed "to" variable to pull from address.plist and updated logging
# 0.6.1 Added SendPILogs variable.  If true, send the e-mail.  
# 0.6.2 Changed sending logic depending on SendPILogs, EveryDay and IsWeekday.  

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
attachment="/Library/Logs/com.trmacs/pi/transfer/"$host_name"."$when".tar.bz2"
source_dir="/Library/Logs/com.trmacs/pi/current/"
attach_name=""$host_name"."$when".tar.bz2"
subject="PI Logs for "$host_name""
archive="/Library/Logs/com.trmacs/pi/archive/"
to=`/usr/libexec/PlistBuddy -c  "Print :PI" /Library/Scripts/trmacs/settings.plist`
SendPILogs=`/usr/libexec/PlistBuddy -c  "Print :SendPILogs" /Library/Scripts/trmacs/settings.plist`
EveryDay=`/usr/libexec/PlistBuddy -c  "Print :EveryDay" /Library/Scripts/trmacs/settings.plist`
IsWeekday=`/usr/libexec/PlistBuddy -c  "Print :IsWeekday" /Library/Scripts/trmacs/settings.plist`


echo "-------------------------------------------"
date
echo ""$vers""
echo "Creating log files"
# Call external script to create log files.
echo "Building drive checking log"
/Library/Scripts/trmacs/drivecheck.sh || exit 1
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

# Check if SendPILogs is disabled.  If disabled, do not send.
if [[ "$SendPILogs" = "false" ]]; then
	echo "Mailing of the log files has been disabled, no e-mail has been sent."
fi 

# PILogs enabled, weekend without Everyday.  Do not send.
if [[ "$SendPILogs" = "true" ]] && [[ "$EveryDay" = "false" ]] && [[ "$IsWeekday" = "false" ]]; then
	echo "Mailing of the log files has been disabled for the weekend, no e-mail has been sent."
fi 

# PILogs enabled, EveryDay enabled and a weekday. Send logs
if [[ "$SendPILogs" = "true" ]] && [[ "$EveryDay" = "true" ]] && [[ "$IsWeekday" = "true" ]]; then
	
	#uuencode the resulting tar'd file and pipe through to mail to send.
	echo "uuencoding source files and mailing to '$to'"
	uuencode "$attachment" "$attach_name" | mail -s "$subject" "$to"	
fi 

# PILogs enabled, EveryDay enabled and a weekend. Send logs
if [[ "$SendPILogs" = "true" ]] && [[ "$EveryDay" = "true" ]] && [[ "$IsWeekday" = "false" ]]; then

	# uuencode the resulting tar'd file and pipe through to mail to send.
	echo "uuencoding source files and mailing to '$to'"
	uuencode "$attachment" "$attach_name" | mail -s "$subject" "$to"
fi

# PILogs enabled, EveryDay disabled and a weekday. Send logs.
if [[ "$SendPILogs" = "true" ]] && [[ "$EveryDay" = "false" ]] && [[ "$IsWeekday" = "true" ]]; then

	# uuencode the resulting tar'd file and pipe through to mail to send.
	echo "uuencoding source files and mailing to '$to'"
	uuencode "$attachment" "$attach_name" | mail -s "$subject" "$to"
fi 


echo "Removing raw log files and moving the compressed version to the archive"

#Cleanup - delete the individual log files and move the tar'd attachment to the archive.
rm -rf /Library/Logs/com.trmacs/pi/current/*
mv -f "$attachment" "$archive"

echo "Closing"
date
echo " "
exit 0