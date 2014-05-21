#!/bin/bash
# Private Eyes log automation part 1
# Created by Ben Bass
vers="a_hwraid_drivecheck-0.5.3"
# Copyright 2012 Technology Revealed. All rights reserved.
# Checks the name and status of the Apple hardware RAID and the SMART status of the drives.
# This is for 3 installed drives.
# 0.5.3 changed vers variable to have _ only in name before the number.


log_when=$(date +%Y-%m-%d)

# Set log files for stdout & stderror
log="/Library/Logs/com.trmacs/pi/current/"$log_when"-drive.log"
err_log="/Library/Logs/com.trmacs/pi/current/"$log_when"-drive.error.log"

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

when="$(date +"%A %B %e, %G at %I:%M %p")"

hw_check_raw="$(system_profiler SPHardwareRAIDDataType)"

hw_raid_status=$(echo "$hw_check_raw" | grep "Status:" | tail -2 | head -1 | awk '{print $2" "$3}')
hw_raid_name=$(echo "$hw_check_raw" | grep "Volumes:" | head -1 | awk '{print $2}')
hw_smart_status_1=$(echo "$hw_check_raw" | grep "SMART Status:" | awk '{print $3}' | head -1)
hw_smart_status_2=$(echo "$hw_check_raw" | grep "SMART Status:" | awk '{print $3}' | head -2 | tail -1)
hw_smart_status_3=$(echo "$hw_check_raw" | grep "SMART Status:" | awk '{print $3}' | tail -1)

hw_smart_dev_name_1=$(echo "$hw_check_raw" | grep "Serial Number:" | cut -d : -f 2 | sed 's/^......//g'| head -1) 
hw_smart_dev_name_2=$(echo "$hw_check_raw" | grep "Serial Number:" | cut -d : -f 2 | sed 's/^......//g'| head -2| tail -1) 
hw_smart_dev_name_3=$(echo "$hw_check_raw" | grep "Serial Number:" | cut -d : -f 2 | sed 's/^......//g'| tail -1) 

# Space used/Available on all attached drives.
disk_usage_raw="$(df -Hla)"
disk_name=$(echo "$disk_usage_raw" | awk -v OFS="\t" '{print $4"/"$2" free", "("$5" used)"}')


#-------------------------------------------------------------------------------------------------


echo " "
echo "-------------------------"
echo "Hard drive and Raid Status of "$host_name" on "$when"."
echo ""$vers""
echo " "

if [ -n "$hw_raid_name" ]; then
	echo "The Apple Hardware RAID "$hw_raid_name" on "$host_name" is currently "$hw_raid_status"."
fi	
	echo "the SMART status of Drive 1, Serial # "$hw_smart_dev_name_1" on "$host_name" is currently "$hw_smart_status_1""
	echo "the SMART status of Drive 2, Serial # "$hw_smart_dev_name_2" on "$host_name" is currently "$hw_smart_status_2""
	echo "the SMART status of Drive 3, Serial # "$hw_smart_dev_name_3" on "$host_name" is currently "$hw_smart_status_3""
echo " "
#
# Stiching the name of each drive with the info from df.  
echo "-------------------------"
echo "Disk Usage Summary"
echo ""
echo -e "Volume Name"'\t'"Avail/Total"'\t'"Percent Used"
echo "$disk_usage_raw" | tail -n +2 | awk '{print $1}' | while read DISK_ID
do
	VOL_NAME="$(diskutil info $DISK_ID | grep 'Volume Name' | cut -c 30-50)"
	PARTIAL=$(echo "$disk_usage_raw" | grep $DISK_ID | awk -v OFS="\t" '{print $4"/"$2, "("$5" used)"}')
	echo -e "$VOL_NAME"'\t'"$PARTIAL"
done
echo " "
echo "Data collected on "$when"."
echo " "

exit 0