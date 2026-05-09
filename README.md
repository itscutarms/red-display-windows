# red-display (Windows)

Auto-red-shifts your Windows display in the evening to reduce eye strain. Windows port of [red-display for macOS](https://github.com/itscutarms/red-display).

- **At sunset** → display turns warm red.
- **At sunset + 2h** → deep red (near-monochrome, like a darkroom).
- **At sunrise** → back to normal.
- Hotkey `Win+Ctrl+Alt+R` cycles `off → warm → deep` any time.
- Hotkey `Win+Ctrl+Alt+0` resets to normal (escape hatch).

Built on [AutoHotkey v2](https://www.autohotkey.com/). Free, no telemetry.

## Install

### Step 1 — Install AutoHotkey v2 (you do this yourself)

AutoHotkey is an external dependency. Install it through whichever path you prefer:

- **Using winget** (recommended, one command):
  ```cmd
  winget install AutoHotkey.AutoHotkey
  ```
- **Or download manually** from [autohotkey.com](https://www.autohotkey.com/) and run the installer.

> Why this step is on you: AutoHotkey is third-party software hosted on autohotkey.com, not a part of this repository. AI tools like Claude Code will (correctly) refuse to download external installers on your behalf, so you need to do this one yourself.

### Step 2 — Clone this repo and start the script

> **Using [Claude Code](https://claude.com/claude-code)?** Once AutoHotkey is installed, just tell it: *"I've installed AutoHotkey. Now install red-display from https://github.com/itscutarms/red-display-windows"* — it will run steps 2–4 for you. The repo-internal commands below are all it needs.

```cmd
git clone https://github.com/itscutarms/red-display-windows %USERPROFILE%\red-display
```

### Step 3 — Run it

Double-click `red-display.ahk` in `%USERPROFILE%\red-display`. A green **H** icon appears in your system tray. Test the hotkey: `Win+Ctrl+Alt+R` cycles modes.

### Step 4 — (Optional) Autostart at login

Press `Win+R`, type `shell:startup`, press Enter, and drag a shortcut to `red-display.ahk` into the folder that opens.

The script fetches your approximate location from `ipapi.co` once on startup to compute today's sunset and sunrise. It caches the result in `%LOCALAPPDATA%\red-display\location.json` for 7 days. If the network call fails and there's no cache, it falls back to fixed clock times (warm at 20:00, deep at 22:00, off at 06:30 local).

## Configure

Edit `config.ahk` and right-click the tray icon → **Reload This Script**. All tunables (gamma values, hotkey, fallback times, cache TTL) are constants near the top.

## Known limitations

- **HDR displays**: `SetDeviceGammaRamp` is silently ignored on HDR-enabled outputs. Disable HDR if the script seems to do nothing.
- **Polling persistence**: After screen lock, sleep, or RDP disconnect, the display can show wrong colors for up to 30 seconds before the next polling tick re-applies.
- **Antivirus**: AHK + DllCall can trigger AV heuristics. You may need to whitelist `AutoHotkey64.exe`.

## Uninstall

Right-click the tray icon → **Exit**. Delete the cloned folder. Optionally uninstall AutoHotkey via Settings → Apps.

## License

MIT — see [LICENSE](./LICENSE).
