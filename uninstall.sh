#!/system/bin/sh
pkill -f wireless-adb-keeper/service.sh 2>/dev/null
# Restore default port 5555 (matches UFI / typical Android default)
setprop persist.service.adb.tcp.port 5555
setprop service.adb.tcp.port 5555
setprop ctl.restart adbd
