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

# Loop: ensure adbd listens on our port. If something else (UFI re-enabled?) flips
# it back to 5555, restore once per minute.
(
    while true; do
        current=$(getprop service.adb.tcp.port)
        if [ "$current" != "$PORT" ]; then
            log "service.adb.tcp.port=$current → setting to $PORT"
            setprop persist.service.adb.tcp.port "$PORT"
            setprop service.adb.tcp.port "$PORT"
            setprop ctl.restart adbd
            sleep 5
            log "adbd restarted on $PORT"
        fi
        sleep 60
    done
) &
