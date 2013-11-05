#!/bin/bash
# Private Eyes log automation part 2
# Created by Ben Bass
vers="trsyscheck-0.7.4"
# Copyright 2012 Technology Revealed. All rights reserved.
# 0.7.2 Now printing the version in the log files.
# 0.7.3 added network connections.
# 0.7.4 fully added network connection logging as a tmp file.

# set a variable for a unique log files.  Also used in syslog check for todays log entries.
when=$(date +%Y-%m-%d)

# Set log files for stdout & stderror
log="/Library/Logs/com.trmacs/pi/current/"$when"-syslog.log"
err_log="/Library/Logs/com.trmacs/pi/current/"$when"-syslog.error.log"

# exec 1 captures stdtout and exec 2 captures stderr and we are appending to log files.
exec 1>> "${log}" 
exec 2>> "${err_log}"

# set the basic syslog query to a variable.
day="$(date '+%b %e')"
display_time="$(date +"%A %B %e, %G at %I:%M %p")"

# Set the host name for easy identification.
host_raw="$(scutil --get HostName)"

if [ -z "$host_raw" ]; then
	host_name="$(scutil --get ComputerName)"
else	
	host_name="$host_raw"
fi

cpu_chk="$(top -l 5 -stats pid,command,cpu,state,user -o cpu -n 6 | grep -v 'top' | tail -17)"

when_s=$(date +%Y-%m-%d-%s)
lsof -i | grep -i 'established' > "/var/tmp/"$when_s"-lsof.tmp"
con_chk_estb_ct=$(grep -ic 'established' "/var/tmp/"$when_s"-lsof.tmp")

sys_raw=$(syslog -F '$Time $Host $(Sender) [$(PID)] <$((Level)(str))>: $Message')
sys_today=$(echo "$sys_raw" | grep "$day")

# grep the full syslog variable for each item.
sys_fail=$(echo "$sys_today" | grep -i 'fail')
sys_io=$(echo "$sys_today" | grep -i 'i/o')
sys_bus=$(echo "$sys_today" | grep -i 'bus')
sys_disk=$(echo "$sys_today" | grep -i 'disk')
sys_error=$(echo "$sys_today" | grep -i 'error')
sys_crash=$(echo "$sys_today" | grep -i 'crash')
sys_volumes=$(echo "$sys_today" | grep -i 'volumes')

# Count the number of each result.
sys_fail_ct=$(echo "$sys_fail" | grep -ic 'fail')
sys_io_ct=$(echo "$sys_io" | grep -ic 'i/o')
sys_bus_ct=$(echo "$sys_bus" | grep -ic 'bus')
sys_disk_ct=$(echo "$sys_disk" | grep -ic 'disk')
sys_error_ct=$(echo "$sys_error" | grep -ic 'error')
sys_crash_ct=$(echo "$sys_crash" | grep -ic 'crash')
sys_volumes_ct=$(echo "$sys_volumes" | grep -ic 'volumes')

# Time Machine check
tm_last=$(cat /private/var/log/system.log | grep "Backup completed successfully" | tail -5)

#function to make singular/plural
function format {
	if [ $1 == 1 ]; then
		echo $1 ' ' $2
	else
		echo $1 ' ' $2's'
	fi
}

# echo output to std out - which is being trapped to the log file above.
echo "Data Collected on "$display_time" by "$vers""
echo " " 
echo "-------------------------"
echo "Search Result Summary for "$host_name""
echo `format "${sys_fail_ct}" "Result"`" for 'Fail'"
echo `format "${sys_io_ct}" "Result"`" for 'I/O'"
echo `format "${sys_bus_ct}" "Result"`" for 'Bus'"
echo `format "${sys_disk_ct}" "Result"`" for 'Disk'"
echo `format "${sys_error_ct}" "Result"`" for 'Error'"
echo `format "${sys_crash_ct}" "Result"`" for 'Crash'"
echo `format "${sys_volumes_ct}" "Result"`" for 'Volumes'"
echo `format "${con_chk_estb_ct}" "Network Connection"`
echo "-------------------------"
echo "Search Results for 'Fail'"
if [ "${sys_fail_ct}" == 0 ]; then
	echo " "
	echo "There are 0 Results"
	else
	echo " " 
	echo "${sys_fail}" 
fi
echo " " 
echo "-------------------------"
echo "Search Results for 'I/O'" 
if [ "${sys_io_ct}" == 0 ]; then
	echo " "
	echo "There are 0 Results"
	else
	echo " " 
	echo "${sys_io}" 
fi
echo " " 
echo "-------------------------"
echo "Search Results for 'bus'" 
if [ "${sys_bus_ct}" == 0 ]; then
	echo " "
	echo "There are 0 Results"
	else
	echo " " 
	echo "${sys_bus}" 
fi
echo " " 
echo "-------------------------"
echo "Search Results for 'disk'" 
if [ "${sys_disk_ct}" == 0 ]; then
	echo " "
	echo "There are 0 Results"
	else
	echo " " 
	echo "${sys_disk}" 
fi
echo " " 
echo "-------------------------"
echo "Search Results for 'error'" 
if [ "${sys_error_ct}" == 0 ]; then
	echo " "
	echo "There are 0 Results"
	else
	echo " " 
	echo "${sys_error}" 
fi
echo " " 
echo "-------------------------"
echo "Search Results for 'crash'" 
if [ "${sys_crash_ct}" == 0 ]; then
	echo " "
	echo "There are 0 Results"
	else
	echo " " 
	echo "${sys_crash}" 
fi
echo " " 
echo "-------------------------"
echo "Search Results for 'volumes'" 
if [ "${sys_volumes_ct}" == 0 ]; then
	echo " "
	echo "There are 0 Results"
	else
	echo " " 
	echo "${sys_volumes}" 
fi
echo " " 
echo "-------------------------"
echo "Last 5 successful Time Machine Backups on "$host_name"" 
echo " " 
echo "${tm_last}" 
echo " " 
echo "-------------------------"
echo "Current network connections"
echo " " 
if [ "${con_chk_estb_ct}" == 0 ]; then
	echo " "
	echo "There are no active network connections"
	else
	cat "/var/tmp/"$when_s"-lsof.tmp"
fi
echo " " 
echo "-------------------------"
echo "Current System resource utilization"
echo " " 
echo "$cpu_chk"
echo " " 
echo "-------------------------"
echo " " 
echo "End of system check log" 
echo ""$display_time""

# clean up tmp file
rm "/var/tmp/"$when_s"-lsof.tmp"
exit 0