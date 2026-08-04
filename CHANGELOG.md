# Changelog

## v1.1.0 — 2026-08-04
- **Fixed**: the watchdog only compared `service.adb.tcp.port`. When adbd
  died while the property still read `55555`, the loop saw a correct port,
  concluded all was well, and never restarted anything — so wireless ADB
  stayed down until someone revived it over USB. Observed repeatedly on a
  ZTE U30 Pro: adbd stopped listening entirely (verified: nothing bound to
  the port on any interface, and adbd binds `::`, so this was not an
  interface-teardown side effect), and `init` did not bring it back.
- Added an independent liveness check on `init.svc.adbd`; if the port is
  correct but the service is not `running`, adbd is restarted.

## v1.0.1 — 2026-05-19
- **Fixed**: `service.sh` wrote to `$LOG=/data/wireless-adb-keeper.log`
  on the very first `log()` call before any explicit `mkdir`. In boot
  states where `/data` was momentarily unwritable the first append
  silently failed and we lost diagnostic lines. Now does a defensive
  `mkdir -p "$(dirname "$LOG")"` up front.

## v1.0.0
- Initial public release
