; modes.ahk — apply gamma to all displays via SetDeviceGammaRamp; track current mode.

global Modes_Current := "off"
global Modes_FailureNotified := false

; Apply the named mode ("off" | "warm" | "deep") by computing a 256-entry
; gamma ramp per channel and calling Win32 SetDeviceGammaRamp.
Modes_Apply(name) {
    global Modes_Current, MODE_OFF, MODE_WARM, MODE_DEEP, Modes_FailureNotified

    rgb := MODE_OFF
    if (name = "warm") {
        rgb := MODE_WARM
    } else if (name = "deep") {
        rgb := MODE_DEEP
    }

    ; Build 1536-byte buffer: 256 entries * 3 channels * 2 bytes (UShort).
    ramp := Buffer(256 * 3 * 2, 0)
    rR := rgb[1], rG := rgb[2], rB := rgb[3]
    Loop 256 {
        i := A_Index - 1
        ratio := i / 255
        rVal := Round(ratio * rR * 65535)
        gVal := Round(ratio * rG * 65535)
        bVal := Round(ratio * rB * 65535)
        if (rVal > 65535)
            rVal := 65535
        if (gVal > 65535)
            gVal := 65535
        if (bVal > 65535)
            bVal := 65535
        NumPut("UShort", rVal, ramp,           i * 2)
        NumPut("UShort", gVal, ramp, 256 * 2 + i * 2)
        NumPut("UShort", bVal, ramp, 256 * 4 + i * 2)
    }

    hDC := DllCall("GetDC", "Ptr", 0, "Ptr")
    result := DllCall("gdi32\SetDeviceGammaRamp", "Ptr", hDC, "Ptr", ramp, "Int")
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hDC)

    if (result = 0) {
        ; Common cause: HDR is enabled and the display ignores gamma calls.
        ; Notify once per session, then stay quiet.
        if (!Modes_FailureNotified) {
            TrayTip("red-display: gamma call failed",
                    "If you have HDR enabled, try turning it off.", 0x12)
            Modes_FailureNotified := true
        }
    }

    Modes_Current := name
}

; Return the active mode name.
Modes_GetCurrent() {
    global Modes_Current
    return Modes_Current
}

; Advance off->warm->deep->off based on current mode. Apply, return new name.
Modes_CycleNext() {
    global Modes_Current, MODE_CYCLE
    idx := 1
    Loop MODE_CYCLE.Length {
        if (MODE_CYCLE[A_Index] = Modes_Current) {
            idx := A_Index
            break
        }
    }
    nextIdx := Mod(idx, MODE_CYCLE.Length) + 1
    Modes_Apply(MODE_CYCLE[nextIdx])
    return MODE_CYCLE[nextIdx]
}
