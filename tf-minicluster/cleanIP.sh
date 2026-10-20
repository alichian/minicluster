#! /bin/bash 

IPS=($@)
KNW_HST=~/.ssh/known_hosts


function is_a_valid_ip() {
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}



for ip in ${IPS[@]} ; do 
	if is_a_valid_ip $ip; then
		echo "cleaning ${ip}"	
		if [[ `grep -c ${ip} $KNW_HST` == 0 ]] ; then 
			echo "${ip} is not in the known_hosts file!"
		else
			sed -i '/^'$ip'/d' $KNW_HST
			echo "Done"
		fi
	else
		echo "${ip} is not a valid ip...nothing to do!"	
	fi
done

