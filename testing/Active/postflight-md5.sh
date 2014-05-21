#!/bin/bash

launchctl load /Library/LaunchDaemons/com.trmacs.pinotify.plist
# loads the just installed launchdaemon.  If previously loaded, was unloaded in Preflight.
vers="pinotify_postflight_v.0.3"

echo "$vers"
echo "loading Private Eyes Launchd's; pinotify, pi-checkin and pi-schedule "
launchctl load -w /Library/LaunchDaemons/com.trmacs.pinotify.plist
launchctl load -w /Library/LaunchDaemons/com.trmacs.pi-schedule.plist
launchctl load -w /Library/LaunchDaemons/com.trmacs.pi-checkin.plist



#Checking to see if settings.plist is populated, and populating with defaults.
/usr/libexec/PlistBuddy -c "Add :PIEnabled bool True" /Library/Scripts/trmacs/settings.plist
/usr/libexec/PlistBuddy -c "Add :PI string 'ben@trmacs.com'" /Library/Scripts/trmacs/settings.plist
/usr/libexec/PlistBuddy -c "Add :alerts string 'ben@trmacs.com'" /Library/Scripts/trmacs/settings.plist
/usr/libexec/PlistBuddy -c "Add :SendPILogs bool True" /Library/Scripts/trmacs/settings.plist
/usr/libexec/PlistBuddy -c "Add :EveryDay bool False" /Library/Scripts/trmacs/settings.plist
/usr/libexec/PlistBuddy -c "Add :hash string 00000000000000000000000000000000" /Library/Scripts/trmacs/settings.plist

sleep 2

#running pi-schedule again to set IsWeekday
/Library/Scripts/trmacs/pi-schedule.sh

echo "done"
echo "exiting"

exit 0