#!/bin/bash
# Created by Ben Bass
# Copyright 2013 Technology Revealed. All rights reserved.
# TR Daily output for PInotify
vers="trdaily-0.6.5"
# 0.4.1 Now prints the version in the logs
# 0.5 Checks versions of installed scripts
# 0.5.2 Introduction of checking CCC logs.
# 0.5.3 Cleanup of CCC checking
# 0.5.4 Addition of external IP check
# 0.5.5 Addition of uptime code and tweaks to CCC.  Still need to work on formating of CCC logs.
# 0.5.6 Added exit status to CCC logging, OS, and hostname to the top.  Tweaked formatting.
# 0.6.0 Added AFP & SMB check for 10.8.2 Server.  Cleaned up some CCC logs  Tested on 10.6.8 min and 10.8.2 mini.  Not tested on 10.7
# 0.6.1 Tweak of server app handling in 10.8 - Check loginElapsesTime, state.  maybe put AFP + SMB in same array as serviceType is called too.
# 0.6.2 Basic testing on 10.7
# 0.6.3 Adding section for User specific variables and adding to display at bottom.  - re-write to clean up?
# 0.6.4 Added connection time in AFP & SMB connections.  Included format function for cleanliness.
# 0.6.5 Updated CCC logging

# set a variable for a unique log files.
when=$(date +%Y-%m-%d)

# Set log files for stdout & stderror
log="/Library/Logs/com.trmacs/pi/current/"$when"-trdaily.log"
err_log="/Library/Logs/com.trmacs/pi/current/"$when"-trdaily.error.log"

exec 1>> "${log}" 
exec 2>> "${err_log}"

#------------ Variables --------------------

# Set the host name for easy identification.
host_raw="$(scutil --get HostName)"

if [[ -z "$host_raw" ]]; then
	host_name="$(scutil --get ComputerName)"
else	
	host_name="$host_raw"
fi

# Determine uptime
then=$(sysctl kern.boottime | awk '{print $5}' | sed "s/,//")
now=$(date +%s)
diff=$(($now-$then))

days=$(($diff/86400));
diff=$(($diff-($days*86400)))
hours=$(($diff/3600))
diff=$(($diff-($hours*3600)))
minutes=$(($diff/60))
seconds=$(($diff-($minutes*60)))

function format {
	if [ "$1" == "1" ]; then
		echo "$1" " " "$2"
	else
		echo "$1" " " "$2""s"
	fi
}

display_time="$(date +"%A %B %e, %G at %I:%M %p")"
vers_chck_raw="$(grep -hR 'vers=' /Library/Scripts/trmacs/)"
vers_chck="$(echo "$vers_chck_raw" | grep -v /Library/Scripts/trmacs/ | cut -d = -f2 | sed s/\"//g)"
externalip="$(curl -s www.icanhazip.com | awk '{print $1}')"
ethernet=$(ifconfig en0 | GREP "inet " | awk '{print $2}')
os_chck="$(system_profiler SPSoftwareDataType | grep "System Version:" | cut -d : -f2 | sed 's/ //')"
os_vers_chck="$(echo "$os_chck" | sed 's/[MacOSXerv .]//g' | cut -f1 -d\( | cut -c 1-3)"

#------------ Client Specific Variables --------------------

# user_1="$(tail -28 /Library/Logs/com.trmacs/user_1.log)"
# user_2="$(tail -31 /Library/Logs/com.trmacs/user_2.log)"
#user_3="$(find '/Volumes/User CCC/CCC Backups/' -name *.sparsebundle -depth 1 -print0 |  xargs -0 stat -f "%Sm%t%N" | grep -v 'DS_Store')"



#------------ Checking OS and setting AFP & SMB Variables --------------------

# 10.6 doesn't have the server app - set afp status to builtin serveradmin
if [[ "$os_vers_chck" -le 107 ]]; then
	srvr_vchck=22
	afp_status_raw=$(/usr/sbin/serveradmin command afp:command = getConnectedUsers)
	smb_status_raw=$(/usr/sbin/serveradmin command smb:command = getConnectedUsers)
fi	
if [[ "$os_vers_chck" == 108 ]]; then
	srvr_vchck_raw="$(defaults read /Applications/Server.app/Contents/Info CFBundleShortVersionString)"
	srvr_vchck="$(echo "$srvr_vchck_raw" | sed 's/\.//g' | cut -c 1-2)"
	afp_status_raw=$(/Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin command afp:command = getConnectedUsers)
	smb_status_raw=$(/Applications/Server.app/Contents/ServerRoot/usr/sbin/serveradmin command smb:command = getConnectedUsers)
fi	

if [[ -z "$srvr_vchck" ]]; then
	srvr_log="Server App is not installed"
	else
	srvr_log="Supported in versions of Server App greater than 2.2.  Your current version is "$srvr_vchck_raw""
fi


ccc_vchck_raw="$(defaults read /Applications/Carbon\ Copy\ Cloner.app/Contents/Info CFBundleShortVersionString)"
ccc_vchck="$(echo "$ccc_vchck_raw" | sed 's/\.//g' | cut -c 1-2)"

if [[ -z "$ccc_vchck" ]]; then
	ccc_log="Carbon Copy Cloner is not installed"
	else
		ccc_log="Supported in versions of CCC greater than 3.5.  Your current version is "$ccc_vchck_raw""
fi

#-------------------------------------Begin writing the info---------------------------


echo "Data collected on "$display_time""
echo ""
echo -e "Computer Name"'\t''\t'"$host_name"
echo -e "Operating System:"'\t'"$os_chck"
echo -e "Uptime: "'\t''\t'`format "$days" "day"` `format "$hours" "hour"` `format "$minutes" "minute"`
echo -e "Current External IP:"'\t'"$externalip"
echo -e "Current Internal IP:"'\t'"$ethernet"
echo ""

#------------ AFP Check --------------------

if [[ -z "$srvr_vchck" ]]; then
	echo "$srvr_log"
	elif [[ "$srvr_vchck" -ge 20 ]]; then
		afp_status="$(echo "$afp_status_raw" | grep -i "afp:state =" | awk '{print$3}' | sed 's/\"//g')"
			if [[ "$afp_status" = "STOPPED" ]]; then
				echo "The AFP Service is currently "$afp_status""
				else
		# grab the raw data for AFP users, then get the usernames and IP's.
		usname="$(echo "$afp_status_raw" | grep -i "name" | cut -f 2 -d = | sed 's/\"//g' | sed 's/ //g')"
		uip="$(echo "$afp_status_raw" | grep -i "ipaddress" | cut -f 2 -d = | sed 's/\"//g' | sed 's/ //g')"
		ct="$(echo "$afp_status_raw" | grep -i "loginelapsedtime" | cut -f 2 -d = | sed 's/\"//g' | sed 's/ //g')"
		
		# Create an array for the usernames, IP's and connection time.  Each username will match with each IP, so element 1 in usname will 	correspond with uip element 1.
		usname_array=($(echo $usname))
		uip_array=($(echo $uip))
		ct_array=($(echo $ct))
		usname_ct=${#usname_array[*]}

		# Put it together and make it pretty.
		echo "The AFP Service is currently "$afp_status" with "$usname_ct" users connected"
		echo ""
		if [[ "$usname_ct" -gt 0 ]]; then
			echo -e "Username"'\t''\t'"IP Address"'\t''\t'"Connected For"
			echo "---------------------------------------------------------------------------"
			# Number of items in the username array, so we know how many times to iterate through
			# the count of items in each array should match - might add checking in later versions
			# Iterate through each array - printing the username then corresponding IP.  
			# using the IF statements for formatting purposes
			for ((i=0;i<$usname_ct;i++)); do
					cdiff=${ct_array[${i}]}
					cdays=$(($cdiff/86400));
					cdiff=$(($cdiff-($cdays*86400)))
					chours=$(($cdiff/3600))
					cdiff=$(($cdiff-($chours*3600)))
					cminutes=$(($cdiff/60))
					cseconds=$(($cdiff-($cminutes*60)))
				if [[ ${#usname_array[${i}]} -ge 8 ]]; then	
					echo -e "${usname_array[${i}]}"'\t''\t'"${uip_array[${i}]}"'\t''\t'`format "$cdays" "day"` `format "$chours" "hour"` `format "$cminutes" "minute"`
					echo "---------------------------------------------------------------------------"
				else
					echo -e "${usname_array[${i}]}"'\t''\t''\t'"${uip_array[${i}]}"'\t''\t'`format "$cdays" "day"` `format "$chours" "hour"` `format "$cminutes" "minute"`
					echo "---------------------------------------------------------------------------"
				fi
			done
		else
			echo "There are no users connected via AFP"
		fi
	fi
	else 
		echo "$srvr_log"
fi

#------------ SMB Check --------------------

echo ""

if [[ -z "$srvr_vchck" ]]; then
	echo "$srvr_log"
	elif [[ "$srvr_vchck" -ge 20 ]]; then
		smb_status="$(echo "$smb_status_raw" | grep -i "smb:state =" | awk '{print$3}' | sed 's/\"//g')"
			if [[ "$smb_status" = "STOPPED" ]]; then
				echo "The SMB Service is currently "$smb_status""
				else
		# grab the raw data for AFP users, then get the usernames and IP's.
		usname="$(echo "$smb_status_raw" | grep -i "name"| cut -f 2 -d = | sed 's/\"//g' | sed 's/ //g')"
		uip="$(echo "$smb_status_raw" | grep -i "ipaddress" | cut -f 2 -d = | sed 's/\"//g' | sed 's/ //g')"
		ct="$(echo "$afp_status_raw" | grep -i "loginelapsedtime" | cut -f 2 -d = | sed 's/\"//g' | sed 's/ //g')"

		# Create an array for the usernames, IP's and connection time.  Each username will match with each IP, so element 1 in usname will 	correspond with uip element 1.
		usname_array=($(echo $usname))
		uip_array=($(echo $uip))
		ct_array=($(echo $ct))
		usname_ct=${#usname_array[*]}

		# Put it together and make it pretty.
		echo "The SMB Service is currently "$smb_status" with "$usname_ct" users connected"
		echo ""
		if [[ "$usname_ct" -gt 0 ]]; then
			echo -e "Username"'\t''\t'"IP Address"
			echo "---------------------------------------------------------------------------"
			# Number of items in the username array, so we know how many times to iterate through
			# the count of items in each array should match - might add checking in later versions
			# Iterate through each array - printing the username then corresponding IP.  
			# using the IF statements for formatting purposes
			
			
			for ((i=0;i<$usname_ct;i++)); do
					cdiff=${ct_array[${i}]}
					cdays=$(($cdiff/86400));
					cdiff=$(($cdiff-($cdays*86400)))
					chours=$(($cdiff/3600))
					cdiff=$(($cdiff-($chours*3600)))
					cminutes=$(($cdiff/60))
					cseconds=$(($cdiff-($cminutes*60)))
				if [[ ${#usname_array[${i}]} -ge 8 ]]; then
					echo -e "${usname_array[${i}]}"'\t''\t'"${uip_array[${i}]}"'\t''\t'`format "$cdays" "day"` `format "$chours" "hour"` `format "$cminutes" "minute"`
					echo "---------------------------------------------------------------------------"
				else
					echo -e "${usname_array[${i}]}"'\t''\t''\t'"${uip_array[${i}]}"'\t''\t'`format "$cdays" "day"` `format "$chours" "hour"` `format "$cminutes" "minute"`
					echo "---------------------------------------------------------------------------"
				fi
			done
			
		else
			echo "There are no users connected via SMB"
		fi
	fi
	else 
		echo "$srvr_log"
fi

#------------ CCC Check --------------------

#echo ""
#echo "Carbon Copy Cloner Status"
#if [[ -z "$ccc_vchck" ]]; then
#	echo "$ccc_log"
#	elif [[ "$ccc_vchck" -ge 35 ]]; then
#		echo -e "Status"'\t'"Start Time"'\t''\t''\t'"Source"'\t''\t''\t'"Destination"'\t''\t'"Data Copied"
#		grep 'exit_status=' /Library/Logs/CCC.log | tail -5 | while read CCC_LOG
#		do
#			ccc_exit_status=$(echo "$CCC_LOG" | cut -d '=' -f2 | sed s/elapsed_time//g)
#			ccc_elapsed_time=$(echo "$CCC_LOG" | cut -d '=' -f3 | sed s/source//g)
#			ccc_source=$(echo "$CCC_LOG" | cut -d '=' -f4 | sed s/destination//g)
#			ccc_destination=$(echo " $CCC_LOG" | cut -d '=' -f5 | sed s/end_time//g)
#			ccc_end_time=$(echo "$CCC_LOG" | cut -d '=' -f6 | sed s/start_time//g)
#			ccc_start_time=$(echo "$CCC_LOG" | cut -d '=' -f7 | sed s/data_copied//g)
#			ccc_data_copied=$(echo "$CCC_LOG" | cut -d '=' -f8 | sed s/task_name//g)
#			ccc_task_name=$(echo "$CCC_LOG" | cut -d '=' -f9)
#			echo -e "$ccc_exit_status"'\t'"$ccc_start_time"'\t'"$ccc_source"'\t'"$ccc_destination"'\t'"$ccc_data_copied"
#		done
#	else 
#		echo "$ccc_log"
#fi

# testing as of 7/2/13

echo ""
echo "Carbon Copy Cloner Status"
if [[ -z "$ccc_vchck" ]]; then
	echo "$ccc_log"
	elif [[ "$ccc_vchck" -ge 35 ]]; then
		grep 'exit_status=' /Library/Logs/CCC.log | cut -d '=' -f9 | sort -bd | uniq -i | while read CCC_TASK
			do
				ccc_log=$(grep 'exit_status' /Library/Logs/CCC.log | grep "$CCC_TASK")
				ccc_source=$(echo "$ccc_log" | cut -d '=' -f4 | sed s/destination//g | uniq -i)
				ccc_destination=$(echo " $ccc_log" | cut -d '=' -f5 | sed s/end_time//g | uniq -i)
				echo ""
				echo -e "Task"'\t''\t'"$CCC_TASK"
				echo -e "Source"'\t''\t'"$ccc_source"
				echo -e "Destination"'\t'"$ccc_destination"
				echo -e "Status"'\t'"Start Time"'\t''\t''\t'"Data Copied"
				echo " $ccc_log" | tail -5 | while read CCC_STATUS
					do
						ccc_exit_status=$(echo "$CCC_STATUS" | cut -d '=' -f2 | sed s/elapsed_time//g)
						ccc_elapsed_time=$(echo "$CCC_STATUS" | cut -d '=' -f3 | sed s/source//g)
						ccc_end_time=$(echo "$CCC_STATUS" | cut -d '=' -f6 | sed s/start_time//g)
						ccc_start_time=$(echo "$CCC_STATUS" | cut -d '=' -f7 | sed s/data_copied//g)
						ccc_data_copied=$(echo "$CCC_STATUS" | cut -d '=' -f8 | sed s/task_name//g)
						echo -e "$ccc_exit_status"'\t'"$ccc_start_time"'\t'"$ccc_data_copied"
					done		
			done
	else
		echo "$ccc_log"
fi 


#------------ Echoing logs and version checks from above --------------------

echo ""
#echo "$user_1"
#echo ""
#echo "$user_2"
#echo ""
#echo "Date & Time Modified	File Name"
#echo "$user_3"
#echo ""
echo "Versions of TR installed Scripts"
echo ""
echo "$vers_chck"
echo ""
echo "$display_time"

exit 0