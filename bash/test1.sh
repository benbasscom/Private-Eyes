#!/bin/bash
when_s=$(date +%Y-%m-%d-%s)

#con_chk_raw="$(lsof -i)"


lsof -i | grep -i 'established' > "/var/tmp/"$when_s"-lsof.tmp"
con_chk_estb_ct=$(grep -ic 'established' "/var/tmp/"$when_s"-lsof.tmp")



echo "-------------------------"
echo "Current network connections"
echo " " 
if [ "${con_chk_estb_ct}" == 0 ]; then
	echo " "
	echo "There are no active network connections"
	else
	echo "Test if true" 
	cat "/var/tmp/"$when_s"-lsof.tmp"
fi
echo " " 
echo "-------------------------"

rm "/var/tmp/"$when_s"-lsof.tmp"