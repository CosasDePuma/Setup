#!/bin/sh

if test -n "$(/usr/sbin/ifconfig | grep tun0 | awk '{ print $1 }' | tr -d ':' )"
then iface="tun0"
else iface="wlan0"
fi

address="$(/usr/sbin/ifconfig ${iface} | grep inet | awk '{ print $2 }')"
if test -z "${address}"
then address="-"
fi

echo " ${address}"
