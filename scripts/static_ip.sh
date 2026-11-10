#!/system/bin/sh
ip addr add 172.18.144.40/24 dev wlan0 2>/dev/null
ip route add default via 172.18.144.1 2>/dev/null
setprop net.dns1 8.8.8.8
setprop net.dns2 1.1.1.1
