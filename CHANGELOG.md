# Changelog

## v1.0.1 — 2026-05-19
- **Fixed**: `service.sh` wrote to `$LOG=/data/wireless-adb-keeper.log`
  on the very first `log()` call before any explicit `mkdir`. In boot
  states where `/data` was momentarily unwritable the first append
  silently failed and we lost diagnostic lines. Now does a defensive
  `mkdir -p "$(dirname "$LOG")"` up front.

## v1.0.0
- Initial public release
