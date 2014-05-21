#!/bin/bash
# Created by Ben Bass
# Copyright 2013 Technology Revealed. All rights reserved.
# PI schedule
vers="pi-schedule-0.4"
# 0.1 Initial testing
# 0.2 default setting to true, changed logic for Saturday and Sunday.
# 0.3 Changing local to local.plist, and variable to IsWeekday from SendPILogs, and swapped default to False.
# 0.4 Added settings variable.


#log="/Library/Logs/com.trmacs/pi-schedule.log"
#err_log="/Library/Logs/com.trmacs/pi-schedule-err.log"
#exec 1>> "${log}" 
#exec 2>> "${err_log}"

settings="/Library/Scripts/trmacs/settings.plist"

dayofweek=$(date +%A)
when=$(date +"%A %B %e, %G at %I:%M %p")
IsWeekday=`/usr/libexec/PlistBuddy -c "Print :IsWeekday" "$settings"`

# Check to see if IsWeekday exists, if not, then add it.

if [ -z "$IsWeekday" ]; then 
echo "SendPILogs does not exits, Adding. on $when"
/usr/libexec/PlistBuddy -c  "Add :IsWeekday bool True" "$settings"
fi


if [ "$dayofweek" == "Saturday" ]; then
echo "Disabling the mailing of PI logs for the weekend on $when"
/usr/libexec/PlistBuddy -c  "Set :IsWeekday False" "$settings"
exit 0
fi

if [ "$dayofweek" == "Sunday" ]; then
echo "Disabling the mailing of PI logs for the weekend on $when"
/usr/libexec/PlistBuddy -c  "Set :IsWeekday False" "$settings"
exit 0
fi

if [ "$dayofweek" == "Monday" ]; then
echo "Enabling PI logs to be mailed on $when"
echo " "
/usr/libexec/PlistBuddy -c  "Set :IsWeekday True" "$settings"
exit 0
fi

# default set the sending of the logs to true
echo "Closing - Setting to True by default on $when"
/usr/libexec/PlistBuddy -c  "Set :IsWeekday True" "$settings"
exit 0
