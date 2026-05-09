; tests/run.ahk — assert harness for sun.ahk. Run with AutoHotkey v2 on Windows.
;   "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" tests\run.ahk
;
; Tests use known geometric anchor points (equinox at equator, solstices at Lisbon)
; so they're robust without external lookups.

#Requires AutoHotkey v2.0
#Include ..\sun.ahk

global TestsPassed := 0
global TestsFailed := 0
global TestReport := ""

Assert(condition, label, detail := "") {
    global TestsPassed, TestsFailed, TestReport
    if (condition) {
        TestsPassed += 1
        TestReport .= "  PASS: " . label . "`n"
    } else {
        TestsFailed += 1
        TestReport .= "  FAIL: " . label
        if (detail != "") {
            TestReport .= " (" . detail . ")"
        }
        TestReport .= "`n"
    }
}

UtcHour(ts) {
    ; Convert Unix timestamp to UTC hour-of-day (decimal).
    ; Use AHK date math. Subtract midnight UTC of that day.
    secondsInDay := Mod(ts, 86400)
    if (secondsInDay < 0) {
        secondsInDay := secondsInDay + 86400
    }
    return secondsInDay / 3600
}

; Test 1: returns numeric sunrise and sunset.
r := Sun_RiseSet(2026, 6, 21, 38.7223, -9.1393)
Assert(IsNumber(r.sunrise), "returns numeric sunrise")
Assert(IsNumber(r.sunset),  "returns numeric sunset")

; Test 2: sunrise before sunset on the same day.
Assert(r.sunrise < r.sunset, "sunrise < sunset")

; Test 3: equator on equinox -> ~06:00 / ~18:00 UTC, ±15 min.
r := Sun_RiseSet(2026, 3, 20, 0, 0)
sunriseHour := UtcHour(r.sunrise)
sunsetHour := UtcHour(r.sunset)
Assert(Abs(sunriseHour - 6.0) < 0.25, "equator equinox sunrise ~06:00 UTC", "got " . sunriseHour)
Assert(Abs(sunsetHour - 18.0) < 0.25, "equator equinox sunset ~18:00 UTC", "got " . sunsetHour)

; Test 4: Lisbon summer solstice has long day (>14h).
r := Sun_RiseSet(2026, 6, 21, 38.7223, -9.1393)
dayLen := (r.sunset - r.sunrise) / 3600
Assert(dayLen > 14, "Lisbon summer solstice day > 14h", "got " . dayLen)

; Test 5: Lisbon winter solstice has short day (<10h).
r := Sun_RiseSet(2026, 12, 21, 38.7223, -9.1393)
dayLen := (r.sunset - r.sunrise) / 3600
Assert(dayLen < 10, "Lisbon winter solstice day < 10h", "got " . dayLen)

; Show report and set exit code.
summary := "red-display tests`n=================`n" . TestReport . "`n" .
           TestsPassed . " passed, " . TestsFailed . " failed`n"
MsgBox(summary, "Test Results")
ExitApp(TestsFailed > 0 ? 1 : 0)