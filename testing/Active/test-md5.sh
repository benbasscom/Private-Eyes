#!/bin/bash
# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# PI checkin
vers="pi-checkin-0.6.3"
# 0.1 Initial testing
# 0.2 Populates empty settings.plist
# 0.3 HostName as Name, and ComputerName if hostname is not set.
# 0.4 Moving to miniserver.trmacs.com for checkins.
# 0.5 Removed spaces from NAME when using ComputerName
# 0.5.1 Changed remote check character to match new web server.
# 0.6.0 First shot at md5 hashing the plists.  Need to create md5.plist for each machine as well.
# 0.6.1 MD5 check tweaks.
# 0.6.2 Single quotes around variables being added to settings.plist.
# 0.6.3 variables for pi logs and for settings.plist, changing miniserver.trmacs to server.trmacs.com

# Curls remote settings from the server.
# loads or unloads com.trmacs.pinotify.plist if PIEnabled is false
# loads com.trmacs.pinotify.plist if PIEnabled is true.

#log="/Library/Logs/com.trmacs/pi-checkin.log"
#err_log="/Library/Logs/com.trmacs/pi-checkin-err.log"
#exec 1>> "${log}" 
#exec 2>> "${err_log}"

when=$(date +%Y-%m-%d)

pi_log="/Library/Logs/com.trmacs/pi/log.log"
settings="/Library/Scripts/trmacs/settings.plist"

# Get the hosts name. Using Computername if HostName is not set.
host_raw="$(scutil --get HostName)"

if [ -z "$host_raw" ]; then
	NAME="$(scutil --get ComputerName | sed 's/ //g')"
else	
	NAME="$host_raw"
fi

# Grab remote settings - grab default if none specific for the computer.
remote=$(curl -s http://server.trmacs.com/pi/"$NAME".plist)
remote_chck="$(echo "$remote" | head -1 | cut -c 2)" 

#writing out curled files.
echo "$remote" > /Library/Scripts/trmacs/"$NAME".plist

# if not a valid plist and a http error code the second character will be a ! instead of a ?
if [ "$remote_chck" = "H" ]; then
	remote=$(curl -s http://server.trmacs.com/pi/default.plist)
	remote_md5_plist=$(curl -s http://server.trmacs.com/pi/default.md5.plist)
	remote_hash="$(curl -s http://server.trmacs.com/pi/default.plist | md5)"
		# If the settings.plist does not exist, Merge it with the curled version
		if [ ! -f "$settings" ]; then 
		/usr/libexec/PlistBuddy -c  "Merge /Library/Scripts/trmacs/"$NAME".plist" "$settings"
		fi
	else
	remote_md5_plist=$(curl -s http://server.trmacs.com/pi/"$NAME".md5.plist)
	remote_hash="$(curl -s http://server.trmacs.com/pi/"$NAME".plist | md5)"
	# If the settings.plist does not exist, Merge it with the curled version
	if [ ! -f "$settings" ]; then 
	/usr/libexec/PlistBuddy -c  "Merge /Library/Scripts/trmacs/"$NAME".plist" "$settings"
	fi
fi

echo "$remote_md5_plist" > /Library/Scripts/trmacs/"$NAME".md5.plist

#Getting the stored & correct md5 of the downloaded file from the secondary stored plist.
remote_md5=`/usr/libexec/PlistBuddy -c "Print :hash" /Library/Scripts/trmacs/"$NAME".md5.plist`


#############################################################################################
#  Use these for testing what each of the md5's actually are.
#echo "This is the remote_md5 - pulled from the md5.plist"
#echo "$remote_md5"
#echo ""
#echo "This is the remote_hash - pulled from md5'ing the remote file."
#echo "$remote_hash"
#############################################################################################


#############################################################################################
#  Checking if the specified md5 matches the generated md5.
#  If not, re-downloads the files and checks the hashes again.
#  If we still have a mis match - continue on using the existing settings.plist.
#############################################################################################

if [ "$remote_md5" != "$remote_hash" ]; then
	echo "Remote hash mismatch, trying again."
		#re-checking and downloading previous files to see if we get it right this time.
		remote=$(curl -s http://server.trmacs.com/pi/"$NAME".plist)
		remote_chck="$(echo "$remote" | head -1 | cut -c 2)" 
		# if not a valid plist and a http error code the second character will be a ! instead of a ?
		if [ "$remote_chck" = "H" ]; then
			remote=$(curl -s http://server.trmacs.com/pi/default.plist)
			remote_md5_plist=$(curl -s http://server.trmacs.com/pi/default.md5.plist)
			remote_hash="$(curl -s http://server.trmacs.com/pi/default.plist | md5)"
			echo "default - take 2"
			else
			remote_md5_plist=$(curl -s http://server.trmacs.com/pi/"$NAME".md5.plist)
			remote_hash="$(curl -s http://server.trmacs.com/pi/"$NAME".plist | md5)"
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

#############################################################################################
# Checking to see if the settings.plist is populated at all.  If not, populating with 
# default values.  They will be over-written with what is pulled from the webserver.
#############################################################################################

#Variables for checking that settings.plist is populated.
IsWeekday_chck=`/usr/libexec/PlistBuddy -c "Print :IsWeekday" "$settings"`
PIEnabled_chck=`/usr/libexec/PlistBuddy -c "Print :PIEnabled" "$settings"`
PI_chck=`/usr/libexec/PlistBuddy -c "Print :PI" "$settings"`
alerts_chck=`/usr/libexec/PlistBuddy -c "Print :alerts" "$settings"`
SendPILogs_chck=`/usr/libexec/PlistBuddy -c "Print :SendPILogs" "$settings"`
EveryDay_chck=`/usr/libexec/PlistBuddy -c "Print :EveryDay" "$settings"`
hash_chck=`/usr/libexec/PlistBuddy -c "Print :hash" "$settings"`


#Checking to see if settings.plist is populated, and populating with defaults.
if [ -z "$PIEnabled_chck" ]; then 
echo "PIEnabled does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :PIEnabled bool True" "$settings"
fi

if [ -z "$PI_chck" ]; then 
echo "PI does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :PI string 'alerts@technologyrevealed.com'" "$settings"
fi

if [ -z "$alerts_chck" ]; then 
echo "alerts does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :alerts string 'alerts@technologyrevealed.com'" "$settings"
fi

if [ -z "$SendPILogs_chck" ]; then 
echo "SendPILogs does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :SendPILogs bool True" "$settings"
fi

if [ -z "$EveryDay_chck" ]; then 
echo "EveryDay does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :EveryDay bool False" "$settings"
fi

if [ -z "$hash_chck" ]; then 
echo "Hash does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c "Add :hash string 00000000000000000000000000000000" "$settings"
fi



if [ "$remote_md5" = "$remote_hash" ]; then
	echo "remote hashes match, continuing."
		# retrieve previous hash from settings.plist
		existing_md5=`/usr/libexec/PlistBuddy -c "Print :hash" "$settings"`
	if [ "$remote_hash" = "$existing_md5" ]; then
			echo "external and existing hashes match, no need to merge."
			else
				PIEnabled="$(/usr/libexec/PlistBuddy -c  "Print PIEnabled" /Library/Scripts/trmacs/"$NAME".plist)"
				PI="$(/usr/libexec/PlistBuddy -c  "Print PI" /Library/Scripts/trmacs/"$NAME".plist)"
				alerts="$(/usr/libexec/PlistBuddy -c  "Print alerts" /Library/Scripts/trmacs/"$NAME".plist)"
				SendPILogs="$(/usr/libexec/PlistBuddy -c  "Print SendPILogs" /Library/Scripts/trmacs/"$NAME".plist)"
				EveryDay="$(/usr/libexec/PlistBuddy -c  "Print EveryDay" /Library/Scripts/trmacs/"$NAME".plist)"
				echo "Updating settings.plist"
				#Set settings from downloaded plist into settings.plist
				/usr/libexec/PlistBuddy -c  "Set PIEnabled '$PIEnabled'" "$settings"
				/usr/libexec/PlistBuddy -c  "Set PI '$PI'" "$settings"
				/usr/libexec/PlistBuddy -c  "Set alerts '$alerts'" "$settings"
				/usr/libexec/PlistBuddy -c  "Set SendPILogs '$SendPILogs'" "$settings"
				/usr/libexec/PlistBuddy -c  "Set EveryDay '$EveryDay'" "$settings"
				/usr/libexec/PlistBuddy -c  "Set hash '$remote_hash'" "$settings"
	fi
fi

#used to determine if pinotify is loaded.
launchd_chk="$(launchctl list | grep com.trmacs.pinotify)"

# Reading PIEnabled from settings.plist
PIEnabled="$(/usr/libexec/PlistBuddy -c  "Print PIEnabled" "$settings")"

if [ "$PIEnabled" = "false" ]; then
# Checks to see if the launchd is loaded, and if not null (-n), then loads it.
	if [ -n "$launchd_chk" ]; then
		launchctl unload -w /Library/LaunchDaemons/com.trmacs.pinotify.plist
		echo "Disabling PI Log generation on $when" | tee -a "$pi_log"
	fi
fi

if [ "$PIEnabled" = "true" ]; then
#Checks to see if the launchd is loaded, and if null (-z), then loads it.
	if [ -z "$launchd_chk" ]; then
#		launchctl load -w /Library/LaunchDaemons/com.trmacs.pinotify.plist
		echo "loading PI Log generation plist" | tee -a "$pi_log"
	fi
fi

#Cleanup remote downloaded file.
#echo "Deleting /Library/Scripts/trmacs/"$NAME".plist"
#rm -rf /Library/Scripts/trmacs/"$NAME".plist


exit 0