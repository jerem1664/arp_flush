#!/bin/bash

# Force arp refresh after vip migration
# Jerem

GW=`/sbin/ip route list  | grep via | /usr/bin/awk '{print $3}' | sort -n | uniq`
DEV=`/sbin/ip route list | /bin/grep via | /usr/bin/awk '{print $5}' | sort -n | uniq`

for DEVS in $DEV ; do
    for ip in `/sbin/ip address list $DEVS | /bin/grep "inet " | /usr/bin/awk '{print $2}' | /usr/bin/cut -d'/' -f1 | /bin/grep -v "10.0" | /bin/grep -v "172.16" | /bin/grep -v "192.168" ` ; do
            for IPS in $GW ; do
                    if [ `/usr/bin/fping -S $ip -c 1 $IPS 2>&1 | /bin/grep "0% loss" | /usr/bin/wc -l` -eq 0 ] ; then
                            for gateway in $GW ; do
                                    echo "ARPING from $ip for $gateway"
                                    /usr/sbin/arping -S $ip -c 1 -w 2 -i $DEVS $gateway &> /dev/null
                            done
                    fi
            done
    done
done

for DEV in `/sbin/ip address list | /bin/grep mtu | /usr/bin/cut -d':' -f2 | /usr/bin/cut -d'@' -f1` ; do
        for ip in `/sbin/ip address list $DEV | /bin/grep "inet " | /usr/bin/awk '{print $2}' | /usr/bin/cut -d'/' -f1 | /bin/grep "\(10.0\|172.16\|192.168\)" ` ; do
                echo "ARPING broadcast for $ip to $DEV"
                /usr/sbin/arping -S $ip -c 1 -w 2 -i $DEV -B &> /dev/null
        done
done
