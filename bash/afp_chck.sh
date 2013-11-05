#!/bin/bash
# Created by Ben Bass
# Copyright 2013 Technology Revealed. All rights reserved.
# AFP info update


#------------ Checking OS and setting AFP & SMB Variables --------------------

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
	srvr_log="Supported in versions of Server App greater than 2.0.  Your current version is "$srvr_vchck_raw""
fi

function format {
	if [ "$1" == "1" ]; then
		echo "$1" " " "$2"
	else
		echo "$1" " " "$2""s"
	fi
}


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
		state="$(echo "$afp_status_raw" | grep -i "state" | grep -v "RUNNING" | cut -f 2 -d = | sed 's/\"//g' | sed 's/ //g')"

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

exit 0