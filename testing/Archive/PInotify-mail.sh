#!/bin/bash
# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# PI notify Using AppleScript and Apple Mail
vers="PInotify_mail-0.5.3"
# 0.5.1 Now prints the version in the logs.
# 0.5.2 trdaily enabled by default now.
# 0.5.3 changed vers variable to have _ only in name before the number.

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
# host_name="$(system_profiler SPSoftwareDataType | grep "Computer Name:" | awk '{print $3" "$4}')"
attachment="/Library/Logs/com.trmacs/pi/transfer/"$host_name"."$when".tar.bz2"
source_dir="/Library/Logs/com.trmacs/pi/current/"
attach_name=""$host_name".tar.bz2"
subject="PI Logs for "$host_name""
to="ben@trmacs.com"
archive="/Library/Logs/com.trmacs/pi/archive/"

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
echo "taring source files"
tar -cjf "$attachment" "$source_dir"

# Embedding Apple Script to use Apple Mail to send the logs as an attachment.
# Remember to change the absolute directories of the attachments as needed.

echo "Calling Apple Script to send the log file via Apple Mail"

/usr/bin/osascript > /dev/null <<EOT
tell application "Finder"
	set folderPath to (get name of startup disk) & ":Library:Logs:com.trmacs:pi:transfer:" as alias
	set theFile to first file in folderPath as alias
	set fileName to name of theFile
end tell

set compName to the computer name of the (system info)
set theSubject to "PI Logs for " & compName
set theBody to "Here are the logs for " & compName
set theAddress to "ben@trmacs.com"
set theAttachment to theFile
set theSender to "alerts@technologyrevealed.com"

tell application "Mail"
	set theNewMessage to make new outgoing message with properties {subject:theSubject, content:theBody & return & return, visible:true}
	tell theNewMessage
		set visibile to true
		set sender to theSender
		make new to recipient at end of to recipients with properties {address:theAddress}
		try
			make new attachment with properties {file name:theAttachment} at after the last word of the last paragraph
			set message_attachment to 0
		on error errmess -- oops
			log errmess -- log the error
			set message_attachment to 1
		end try
		log "message_attachment = " & message_attachment
		send
	end tell
end tell
EOT

echo "Removing raw log files and moving the compressed version to the archive"

#Cleanup
rm -rf /Library/Logs/com.trmacs/pi/current/*
mv -f "$attachment" "$archive"

echo "Closing"
date
echo " "
exit 0