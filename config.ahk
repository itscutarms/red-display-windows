; config.ahk — tunable constants for red-display Windows.
; All other modules read these values; do not redefine inline elsewhere.

; Gamma presets. Each is [red, green, blue] ceiling on a 0.0..1.0 scale.
; 1.0 = channel at full system brightness; 0.0 = channel suppressed.
global MODE_OFF  := [1.00, 1.00, 1.00]
global MODE_WARM := [1.00, 0.45, 0.20]
global MODE_DEEP := [1.00, 0.10, 0.05]

; Order in which the cycle hotkey advances modes.
global MODE_CYCLE := ["off", "warm", "deep"]

; Hours after sunset to switch warm -> deep.
global DEEP_OFFSET_HOURS := 2

; Hotkeys (AHK v2 syntax: ^=Ctrl !=Alt #=Win, then key).
global HOTKEY_CYCLE := "^!#R"
global HOTKEY_RESET := "^!#0"

; Daily refresh time (24h local time, HH:MM).
global DAILY_REFRESH_TIME := "00:05"

; Geolocation HTTP endpoint.
global IPAPI_URL := "https://ipapi.co/json/"

; Disk cache for location response. Resolved at runtime via EnvGet.
global LOCATION_CACHE_FILENAME := "location.json"
global LOCATION_CACHE_TTL_DAYS := 7

; Fixed-time fallback when geolocation is unavailable (HH:MM local).
; Deep time is derived as FALLBACK_WARM_TIME + DEEP_OFFSET_HOURS.
global FALLBACK_WARM_TIME := "20:00"
global FALLBACK_OFF_TIME  := "06:30"

; Persistence polling interval (milliseconds).
global PERSISTENCE_INTERVAL_MS := 30000
