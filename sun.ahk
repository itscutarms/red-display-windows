; sun.ahk — pure NOAA solar position calculation. Port of Lua sun.lua.
; Reference: https://gml.noaa.gov/grad/solcalc/solareqns.PDF
; Accuracy: ~1 minute for years 1950-2050.

; Returns sunrise/sunset Unix timestamps for a given UTC date and location.
; year, month, day: integers
; lat:  decimal degrees, north positive
; lon:  decimal degrees, east positive (so Lisbon is negative)
; Returns: { sunrise: int, sunset: int, polar: ""|"day"|"night" }
Sun_RiseSet(year, month, day, lat, lon) {
    pi := 3.141592653589793
    rad := (d) => d * pi / 180
    deg := (r) => r * 180 / pi

    ; Julian Day at 00:00 UT of the given date (algorithm with -1524.5).
    y := year, m := month
    if (m <= 2) {
        y := y - 1
        m := m + 12
    }
    A := Floor(y / 100)
    B := 2 - A + Floor(A / 4)
    jd := Floor(365.25 * (y + 4716)) + Floor(30.6001 * (m + 1)) + day + B - 1524.5

    ; Add 0.5 because the standard formula returns midnight-UT JD,
    ; but NOAA's `n` is referenced to J2000 noon. Without this, sunrise/sunset flip.
    jd := jd + 0.5

    n := jd - 2451545.0 + 0.0008
    Jstar := n - lon / 360.0
    Mdeg := Mod(357.5291 + 0.98560028 * Jstar, 360)
    M_ := rad(Mdeg)
    C := 1.9148 * Sin(M_) + 0.0200 * Sin(2 * M_) + 0.0003 * Sin(3 * M_)
    lambda := rad(Mod(Mdeg + C + 180 + 102.9372, 360))
    Jtransit := 2451545.0 + Jstar + 0.0053 * Sin(M_) - 0.0069 * Sin(2 * lambda)
    sinDecl := Sin(lambda) * Sin(rad(23.44))
    decl := ASin(sinDecl)

    cosH := (Sin(rad(-0.83)) - Sin(rad(lat)) * sinDecl) / (Cos(rad(lat)) * Cos(decl))

    if (cosH > 1) {
        return { sunrise: 0, sunset: 0, polar: "night" }
    }
    if (cosH < -1) {
        return { sunrise: 0, sunset: 0, polar: "day" }
    }

    H := deg(ACos(cosH))
    Jset  := Jtransit + H / 360.0
    Jrise := Jtransit - H / 360.0

    ; Convert Julian Day to Unix timestamp (seconds since 1970-01-01 UTC).
    ; 2440587.5 is the JD of 1970-01-01 00:00 UTC.
    return {
        sunrise: Round((Jrise - 2440587.5) * 86400),
        sunset:  Round((Jset  - 2440587.5) * 86400),
        polar: ""
    }
}
