#!/bin/bash
# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# PI checkin
vers="pi-checkin-0.5
# 0.1 Initial testing
# 0.2 Populates empty settings.plist
# 0.3 HostName as Name, and ComputerName if hostname is not set.
# 0.4 Moving to miniserver.trmacs.com for checkins.
# 0.5 Removed spaces from NAME when using ComputerName


# Curls remote settings from the server.
# loads or unloads com.trmacs.pinotify.plist if PIEnabled is false
# loads com.trmacs.pinotify.plist if PIEnabled is true.

log="/Library/Logs/com.trmacs/pi-checkin.log"
err_log="/Library/Logs/com.trmacs/pi-checkin-err.log"
exec 1>> "${log}" 
exec 2>> "${err_log}"
when=$(date +%Y-%m-%d)
#NAME=`scutil --get ComputerName`

# Get the hosts name. Using Computername if HostName is not set.
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
if [ "$remote_chck" = ! ]; then
	remote=$(curl -s http://miniserver.trmacs.com/pi/default.plist)
fi

echo "$remote" > /Library/Scripts/trmacs/"$NAME".plist

# If the settings.plist does not exist, Merge it with the curled version
if [ ! -f /Library/Scripts/trmacs/settings.plist ]; then 
/usr/libexec/PlistBuddy -c  "Merge /Library/Scripts/trmacs/"$NAME".plist" /Library/Scripts/trmacs/settings.plist
fi


#Variables for checking that settings.plist is populated.
IsWeekday_chck=`/usr/libexec/PlistBuddy -c "Print :IsWeekday" /Library/Scripts/trmacs/settings.plist`
PIEnabled_chck=`/usr/libexec/PlistBuddy -c "Print :PIEnabled" /Library/Scripts/trmacs/settings.plist`
PI_chck=`/usr/libexec/PlistBuddy -c "Print :PI" /Library/Scripts/trmacs/settings.plist`
alerts_chck=`/usr/libexec/PlistBuddy -c "Print :alerts" /Library/Scripts/trmacs/settings.plist`
SendPILogs_chck=`/usr/libexec/PlistBuddy -c "Print :SendPILogs" /Library/Scripts/trmacs/settings.plist`
EveryDay_chck=`/usr/libexec/PlistBuddy -c "Print :EveryDay" /Library/Scripts/trmacs/settings.plist`

#Checking to see if settings.plist is populated, and populating with defaults.
if [ -z "$PIEnabled_chck" ]; then 
echo "PIEnabled does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :PIEnabled bool True" /Library/Scripts/trmacs/settings.plist
fi

if [ -z "$PI_chck" ]; then 
echo "PI does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :PI string 'ben@trmacs.com'" /Library/Scripts/trmacs/settings.plist
fi

if [ -z "$alerts_chck" ]; then 
echo "alerts does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :alerts string 'ben@trmacs.com'" /Library/Scripts/trmacs/settings.plist
fi

if [ -z "$SendPILogs_chck" ]; then 
echo "SendPILogs does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :SendPILogs bool True" /Library/Scripts/trmacs/settings.plist
fi

if [ -z "$EveryDay_chck" ]; then 
echo "EveryDay does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :EveryDay bool False" /Library/Scripts/trmacs/settings.plist
fi


#Read settings from downloaded plist.
PIEnabled="$(/usr/libexec/PlistBuddy -c  "Print PIEnabled" /Library/Scripts/trmacs/"$NAME".plist)"
PI="$(/usr/libexec/PlistBuddy -c  "Print PI" /Library/Scripts/trmacs/"$NAME".plist)"
alerts="$(/usr/libexec/PlistBuddy -c  "Print alerts" /Library/Scripts/trmacs/"$NAME".plist)"
SendPILogs="$(/usr/libexec/PlistBuddy -c  "Print SendPILogs" /Library/Scripts/trmacs/"$NAME".plist)"
EveryDay="$(/usr/libexec/PlistBuddy -c  "Print EveryDay" /Library/Scripts/trmacs/"$NAME".plist)"

#Set settings from downloaded plist into settings.plist
/usr/libexec/PlistBuddy -c  "Set PIEnabled "$PIEnabled"" /Library/Scripts/trmacs/settings.plist
/usr/libexec/PlistBuddy -c  "Set PI "$PI"" /Library/Scripts/trmacs/settings.plist
/usr/libexec/PlistBuddy -c  "Set alerts "$alerts"" /Library/Scripts/trmacs/settings.plist
/usr/libexec/PlistBuddy -c  "Set SendPILogs "$SendPILogs"" /Library/Scripts/trmacs/settings.plist
/usr/libexec/PlistBuddy -c  "Set EveryDay "$EveryDay"" /Library/Scripts/trmacs/settings.plist

#used to determine if pinotify is loaded.
launchd_chk="$(launchctl list | grep trma | grep com.trmacs.pinotify)"

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
echo "Deleting /Library/Scripts/trmacs/"$NAME".plist"
rm -rf /Library/Scripts/trmacs/"$NAME".plist

exit 0