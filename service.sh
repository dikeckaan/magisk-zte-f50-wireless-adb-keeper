#!/system/bin/sh
# Wireless ADB Keeper - force ADB to listen on a dedicated port (avoids UFI conflict)
# Runs at late_start, after Android boot completes.

PORT=55555
LOG=/data/wireless-adb-keeper.log

# Ensure the log's parent dir exists. /data is normally there, but
# `mkdir -p` is cheap and protects against weird boot states where
# the path isn't writable yet.
mkdir -p "$(dirname "$LOG")" 2>/dev/null

log() {
    if [ -f "$LOG" ]; then
        sz=$(stat -c %s "$LOG" 2>/dev/null || echo 0)
        [ "$sz" -gt 524288 ] && mv "$LOG" "$LOG.1"
    fi
    echo "[$(date)] $*" >> "$LOG"
}

# Small warm-up — boot may still be settling adbd
sleep 10

# Loop: keep wireless ADB actually reachable.
#
# Two independent failure modes, both seen on real devices:
#
#   1. Something (UFI-TOOLS re-enabling its own ADB) flips the port back to
#      5555. Detected by comparing service.adb.tcp.port.
#
#   2. adbd DIES while the port property still reads 55555. This was the
#      blind spot: the old loop only compared the property, so a dead adbd
#      looked healthy and was never restarted. Observed repeatedly on the
#      U30 Pro -- adbd stopped listening (nothing on the port at all, on any
#      interface) and stayed down until a manual USB session revived it.
#      init does not bring it back on its own.
#
# init.svc.adbd is the authoritative "is the service alive" signal, so it is
# checked separately from the port.
(
    while true; do
        current=$(getprop service.adb.tcp.port)
        state=$(getprop init.svc.adbd)

        if [ "$current" != "$PORT" ]; then
            log "service.adb.tcp.port=$current -> setting to $PORT"
            setprop persist.service.adb.tcp.port "$PORT"
            setprop service.adb.tcp.port "$PORT"
            setprop ctl.restart adbd
            sleep 5
            log "adbd restarted on $PORT"
        elif [ "$state" != "running" ]; then
            # Port is right but the service is gone -- restart it. Without
            # this the module reported success while ADB was unreachable.
            log "adbd not running (init.svc.adbd=$state) -> restarting"
            setprop ctl.restart adbd
            sleep 5
            log "adbd restarted, init.svc.adbd=$(getprop init.svc.adbd)"
        fi

        sleep 60
    done
) &
