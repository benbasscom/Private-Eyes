#!/bin/bash -x
# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# PI checkin
vers="pi-checkin-0.6.0"

host_raw="$(scutil --get HostName)"

if [ -z "$host_raw" ]; then
	NAME="$(scutil --get ComputerName | sed 's/ //g')"
else	
	NAME="$host_raw"
fi

# Grab remote settings - grab default if none specific for the computer.
remote=$(curl -s http://miniserver.trmacs.com/pi/"$NAME".plist)
remote_chck="$(echo "$remote" | head -1 | cut -c 2)" 


# if not a valid plist and a http error code the second character will be a ! instead of a ?
if [ "$remote_chck" = "H" ]; then
	remote=$(curl -s http://miniserver.trmacs.com/pi/default.plist)
	remote_md5_plist=$(curl -s http://miniserver.trmacs.com/pi/default.md5.plist)
	remote_hash="$(curl -s http://miniserver.trmacs.com/pi/default.plist | md5)"
	else
	remote_md5_plist=$(curl -s http://miniserver.trmacs.com/pi/"$NAME".md5.plist)
	remote_hash="$(curl -s http://miniserver.trmacs.com/pi/"$NAME".plist | md5)"
fi

#writing out curled files.
echo "$remote" > /Library/Scripts/trmacs/"$NAME".plist
echo "$remote_md5_plist" > /Library/Scripts/trmacs/"$NAME".md5.plist

#Getting the stored & correct md5 of the downloaded file from the secondary stored plist.
remote_md5=`/usr/libexec/PlistBuddy -c "Print :hash" /Library/Scripts/trmacs/"$NAME".md5.plist`
#md5 of the actually downloaded hostname.plist
#remote_hash="$(curl -s http://miniserver.trmacs.com/pi/"$NAME".plist | md5)"


echo "This is the remote_md5 - pulled from the md5.plist"
echo "$remote_md5"
echo ""
echo "This is the remote_hash - pulled from md5'ing the remote file."
echo "$remote_hash"


if [ "$remote_md5" != "$remote_hash" ]; then
	echo "Remote hash mismatch, using existing settings.plist"
		#re-checking and downloading previous files to see if we get it right this time.
		remote=$(curl -s http://miniserver.trmacs.com/pi/"$NAME".plist)
		remote_chck="$(echo "$remote" | head -1 | cut -c 2)" 
		# if not a valid plist and a http error code the second character will be a ! instead of a ?
		if [ "$remote_chck" = "H" ]; then
			remote=$(curl -s http://miniserver.trmacs.com/pi/default.plist)
			remote_md5_plist=$(curl -s http://miniserver.trmacs.com/pi/default.md5.plist)
			remote_hash="$(curl -s http://miniserver.trmacs.com/pi/default.plist | md5)"
			echo "default - take 2"
			else
			remote_md5_plist=$(curl -s http://miniserver.trmacs.com/pi/"$NAME".md5.plist)
			remote_hash="$(curl -s http://miniserver.trmacs.com/pi/"$NAME".plist | md5)"
			echo "real take 2"
		fi
		#writing out curled files.
		echo "$remote" > /Library/Scripts/trmacs/"$NAME".plist
		echo "$remote_md5_plist" > /Library/Scripts/trmacs/"$NAME".md5.plist

		#Getting the stored & correct md5 of the downloaded file from the secondary stored plist.
		remote_md5=`/usr/libexec/PlistBuddy -c "Print :hash" /Library/Scripts/trmacs/"$NAME".md5.plist`
		echo "This is the remote_md5 - pulled from the md5.plist - take 2"
		echo "$remote_md5"
		echo ""
		echo "This is the remote_hash - pulled from md5'ing the remote file. - take 2"
		echo "$remote_hash"
fi

if [ "$remote_md5" = "$remote_hash" ]; then
	echo "remote hashes match, continuing."
		# retrieve previous hash from settings.plist
		existing_md5=`/usr/libexec/PlistBuddy -c "Print :hash" /Library/Scripts/trmacs/settings.plist`
	if [ "$remote_hash" = "$existing_md5" ]; then
			echo "external and existing hashes match, no need to merge."
			else
				PIEnabled="$(/usr/libexec/PlistBuddy -c  "Print PIEnabled" /Library/Scripts/trmacs/"$NAME".plist)"
				PI="$(/usr/libexec/PlistBuddy -c  "Print PI" /Library/Scripts/trmacs/"$NAME".plist)"
				alerts="$(/usr/libexec/PlistBuddy -c  "Print alerts" /Library/Scripts/trmacs/"$NAME".plist)"
				SendPILogs="$(/usr/libexec/PlistBuddy -c  "Print SendPILogs" /Library/Scripts/trmacs/"$NAME".plist)"
				EveryDay="$(/usr/libexec/PlistBuddy -c  "Print EveryDay" /Library/Scripts/trmacs/"$NAME".plist)"
				echo "Updating settings.plist"
				#Set settings from downloaded plist into settings.plist and update hash for future use.
				/usr/libexec/PlistBuddy -c  "Set PIEnabled "$PIEnabled"" /Library/Scripts/trmacs/settings.plist
				/usr/libexec/PlistBuddy -c  "Set PI "$PI"" /Library/Scripts/trmacs/settings.plist
				/usr/libexec/PlistBuddy -c  "Set alerts "$alerts"" /Library/Scripts/trmacs/settings.plist
				/usr/libexec/PlistBuddy -c  "Set SendPILogs "$SendPILogs"" /Library/Scripts/trmacs/settings.plist
				/usr/libexec/PlistBuddy -c  "Set EveryDay "$EveryDay"" /Library/Scripts/trmacs/settings.plist
				/usr/libexec/PlistBuddy -c  "Set hash "$remote_hash"" /Library/Scripts/trmacs/settings.plist
	fi
fi

#used to determine if pinotify is loaded.
launchd_chk="$(launchctl list | grep trma | grep com.trmacs.pinotify)"

# Reading PIEnabled from settings.plist
PIEnabled="$(/usr/libexec/PlistBuddy -c  "Print PIEnabled" /Library/Scripts/trmacs/settings.plist)"

if [ "$PIEnabled" = "false" ]; then

# Checks to see if the launchd is loaded, and if not null (-n), then loads it.
	if [ -n "$launchd_chk" ]; then
		launchctl unload -w /Library/LaunchDaemons/com.trmacs.pinotify.plist
		echo "Disabling PI Log generation on $when" | tee -a /Library/Logs/com.trmacs/pi/log.log
	fi
fi

if [ "$PIEnabled" = "true" ]; then
#Checks to see if the launchd is loaded, and if null (-z), then loads it.
	if [ -z "$launchd_chk" ]; then
		launchctl load -w /Library/LaunchDaemons/com.trmacs.pinotify.plist
		echo "loading PI Log generation plist" | tee -a /Library/Logs/com.trmacs/pi/log.log
	fi
fi

#Cleanup remote downloaded file.
echo "Deleting /Library/Scripts/trmacs/"$NAME".plist & /Library/Scripts/trmacs/"$NAME".md5.plist"
rm -rf /Library/Scripts/trmacs/"$NAME".plist
rm -rf /Library/Scripts/trmacs/"$NAME".md5.plist

exit 0