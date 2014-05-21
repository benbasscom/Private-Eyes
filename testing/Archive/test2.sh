#!/bin/bash

# Get the hosts name. Using Computername if HostName is not set  Pulls spaces if using ComputerName.
host_raw="$(scutil --get HostName)"

if [ -z "$host_raw" ]; then
	NAME="$(scutil --get ComputerName | sed 's/ //g')"
else	
	NAME="$host_raw"
fi

echo "$NAME"

exit 0