; scheduler.ahk — owns transition timers, daily refresh, IP geolocation w/ disk cache.

global Scheduler_DailyTimerArmed := false

; Internal: resolve the cache path (depends on %LOCALAPPDATA%).
Scheduler_CachePath() {
    global LOCATION_CACHE_FILENAME
    return EnvGet("LOCALAPPDATA") . "\red-display\" . LOCATION_CACHE_FILENAME
}

; Internal: read cached location if present and fresh. Returns
; { lat, lon } or "" (empty string for "no cache").
Scheduler_ReadCache() {
    global LOCATION_CACHE_TTL_DAYS
    path := Scheduler_CachePath()
    if (!FileExist(path)) {
        return ""
    }
    ; Cache freshness: file modification time within TTL.
    fileAge := FileGetTime(path, "M")
    cutoff := FormatTime(DateAdd(A_Now, -LOCATION_CACHE_TTL_DAYS, "Days"), "yyyyMMddHHmmss")
    if (fileAge < cutoff) {
        return ""
    }
    body := FileRead(path)
    return Scheduler_ParseLatLon(body)
}

; Internal: write JSON body to disk cache.
Scheduler_WriteCache(body) {
    path := Scheduler_CachePath()
    DirCreate(EnvGet("LOCALAPPDATA") . "\red-display")
    try {
        FileDelete(path)
    } catch {
        ; ignore — file may not exist yet
    }
    FileAppend(body, path)
}

; Internal: extract latitude/longitude from a flat JSON body via regex.
; ipapi.co response includes top-level "latitude" and "longitude" numeric fields.
Scheduler_ParseLatLon(body) {
    if (!RegExMatch(body, '"latitude"\s*:\s*(-?\d+\.?\d*)', &m1)) {
        return ""
    }
    if (!RegExMatch(body, '"longitude"\s*:\s*(-?\d+\.?\d*)', &m2)) {
        return ""
    }
    return { lat: m1[1] + 0, lon: m2[1] + 0 }
}

; Internal: HTTP GET via WinHttp. Returns response body or "" on failure.
Scheduler_HttpGet(url) {
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("GET", url, false)
        http.SetTimeouts(5000, 5000, 10000, 10000)
        http.Send()
        if (http.Status = 200) {
            return http.ResponseText
        }
    } catch {
        ; ignore — fall through to ""
    }
    return ""
}

; Public: try cache, then HTTP, then return "" if both fail.
; On HTTP success, write the body to the disk cache.
Scheduler_GetLocation() {
    global IPAPI_URL

    cached := Scheduler_ReadCache()
    if (cached != "") {
        return cached
    }

    body := Scheduler_HttpGet(IPAPI_URL)
    if (body = "") {
        return ""
    }

    parsed := Scheduler_ParseLatLon(body)
    if (parsed = "") {
        return ""
    }

    Scheduler_WriteCache(body)
    return parsed
}

; Internal: convert HH:MM local-time string into a true Unix timestamp
; (UTC seconds since 1970). Returns int.
Scheduler_TimeToToday(hhmm) {
    parts := StrSplit(hhmm, ":")
    h := Integer(parts[1]), mn := Integer(parts[2])
    today := FormatTime(A_Now, "yyyyMMdd")  ; today in local time
    targetLocal := today . Format("{:02d}{:02d}00", h, mn)

    ; Compute Unix timestamp by accounting for the local timezone offset.
    ; tzOffset = local - UTC (positive east of UTC). For Lisbon UTC+1: +3600.
    tzOffset := DateDiff(A_Now, A_NowUTC, "Seconds")
    ; naiveUnix treats targetLocal as if it were UTC.
    naiveUnix := DateDiff(targetLocal, "19700101000000", "Seconds")
    ; Subtract tzOffset to convert local to UTC.
    return naiveUnix - tzOffset
}

; Internal: determine which mode SHOULD be active right now given today's events.
Scheduler_ExpectedMode(now, sunrise, sunset) {
    global DEEP_OFFSET_HOURS
    deepStart := sunset + (DEEP_OFFSET_HOURS * 3600)
    if (now >= sunrise && now < sunset) {
        return "off"
    }
    if (now >= sunset && now < deepStart) {
        return "warm"
    }
    if (now >= deepStart) {
        return "deep"
    }
    ; Before today's sunrise: still in last night's deep window.
    return "deep"
}

; Internal: schedule a one-shot transition. Skip if `when` is in the past.
Scheduler_ScheduleAt(when, name) {
    now := DateDiff(A_NowUTC, "19700101000000", "Seconds")
    delay := when - now
    if (delay <= 0) {
        return
    }
    SetTimer(() => Modes_Apply(name), -delay * 1000)
}

; Public: compute today's events (or fall back to fixed times) and register transitions.
Scheduler_Refresh() {
    global FALLBACK_WARM_TIME, FALLBACK_OFF_TIME, DEEP_OFFSET_HOURS

    loc := Scheduler_GetLocation()
    nowUtc := DateDiff(A_NowUTC, "19700101000000", "Seconds")

    if (loc = "") {
        ; Fallback path: fixed clock times (interpreted as local).
        ; Deep is derived from warm + DEEP_OFFSET_HOURS, matching the live path.
        warmTs := Scheduler_TimeToToday(FALLBACK_WARM_TIME)
        deepTs := warmTs + DEEP_OFFSET_HOURS * 3600
        offTs  := Scheduler_TimeToToday(FALLBACK_OFF_TIME)
        TrayTip("red-display", "Geolocation unavailable. Using fixed times.", 0x12)
        Scheduler_ScheduleAt(warmTs, "warm")
        Scheduler_ScheduleAt(deepTs, "deep")
        Scheduler_ScheduleAt(offTs,  "off")
        Modes_Apply(Scheduler_ExpectedMode(nowUtc, offTs, warmTs))
        return
    }

    todayUtc := FormatTime(A_NowUTC, "yyyyMMdd")
    y := Integer(SubStr(todayUtc, 1, 4))
    mo := Integer(SubStr(todayUtc, 5, 2))
    d := Integer(SubStr(todayUtc, 7, 2))
    events := Sun_RiseSet(y, mo, d, loc.lat, loc.lon)

    if (events.polar != "") {
        TrayTip("red-display", "Polar " . events.polar . ", schedule skipped.", 0x12)
        return
    }

    deepStart := events.sunset + (DEEP_OFFSET_HOURS * 3600)
    Scheduler_ScheduleAt(events.sunset,  "warm")
    Scheduler_ScheduleAt(deepStart,      "deep")
    Scheduler_ScheduleAt(events.sunrise, "off")
    Modes_Apply(Scheduler_ExpectedMode(nowUtc, events.sunrise, events.sunset))
}

; Internal: the daily-refresh callback. Re-runs Scheduler_Refresh
; and re-arms itself for the next day.
Scheduler_DailyTick() {
    Scheduler_Refresh()
    Scheduler_ArmDailyRefresh()
}

; Internal: schedule the next daily refresh based on DAILY_REFRESH_TIME (HH:MM local).
Scheduler_ArmDailyRefresh() {
    global DAILY_REFRESH_TIME, Scheduler_DailyTimerArmed
    parts := StrSplit(DAILY_REFRESH_TIME, ":")
    h := Integer(parts[1]), mn := Integer(parts[2])

    ; Compute milliseconds until next HH:MM. If past today, schedule for tomorrow.
    now := A_Now  ; local YYYYMMDDHHMISS
    todayTarget := SubStr(now, 1, 8) . Format("{:02d}{:02d}00", h, mn)
    targetMs := DateDiff(todayTarget, now, "Seconds") * 1000
    if (targetMs <= 0) {
        ; Past today's HH:MM; add 24h.
        targetMs := targetMs + 86400 * 1000
    }

    SetTimer(Scheduler_DailyTick, -targetMs)
    Scheduler_DailyTimerArmed := true
}

; Public: bootstrap.
Scheduler_Setup() {
    Scheduler_Refresh()
    Scheduler_ArmDailyRefresh()
}
