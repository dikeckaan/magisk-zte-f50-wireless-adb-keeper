# wireless-adb-keeper

A tiny Magisk module that forces wireless ADB to listen on a **non-default port (55555)** every boot, and keeps it there if something else (e.g., the UFI-TOOLS Android app) tries to switch it back to 5555.

## Why

UFI-TOOLS' "Wireless ADB on boot" feature uses port `5555` and actively manages the prop. If you disable UFI, the prop can be wiped and ADB stops listening — or if UFI is later re-enabled, it forces 5555.

This module:
- Keeps your remote-ADB stack on its own port, decoupled from UFI's state.
- Restarts `adbd` once at boot to apply, then polls every 60 s as a safety net.

## What it does

`service.sh` (Magisk `late_start service`):
1. Waits 10 s for boot to settle.
2. In a background loop, every 60 s:
   - If `service.adb.tcp.port != 55555`, set both `service.adb.tcp.port` and `persist.service.adb.tcp.port` to `55555` and `ctl.restart adbd`.

Result: ADB always listens on `:55555` while this module is enabled.

## Installation

1. Flash the zip from Magisk Manager.
2. Reboot.
3. Update your cloudflared tunnel ingress (or any other remote-access config) from `tcp://localhost:5555` to `tcp://localhost:55555`.
4. `adb connect <host>:55555` instead of `:5555`.

## Coexistence with UFI-TOOLS

- UFI's port toggle (5555) is harmless — this module overrides it within ≤ 60 s after every boot.
- If UFI is **frozen / disabled**, this module guarantees ADB stays up regardless.

## Uninstall

Removing the module via Magisk Manager runs `uninstall.sh`, which:
- Stops the keeper loop.
- Restores `service.adb.tcp.port = 5555` (Android default) and restarts `adbd`.

## Log

Live log: `tail -f /data/wireless-adb-keeper.log` — records every port flip it corrects.

## Bootloop safety

`late_start service` mode → runs *after* Android boot completes. The script does nothing risky; worst case is wireless ADB doesn't start, but the device boots normally.
