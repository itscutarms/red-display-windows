; persistence.ahk — periodic re-apply of current mode.
; SetDeviceGammaRamp resets on session lock, sleep/resume, RDP, fast user switch.
; A 30-second SetTimer is the simplest reliable compensation.

Persistence_Install() {
    global PERSISTENCE_INTERVAL_MS
    SetTimer(Persistence_Tick, PERSISTENCE_INTERVAL_MS)
}

Persistence_Tick() {
    current := Modes_GetCurrent()
    if (current = "off") {
        return  ; nothing to maintain
    }
    Modes_Apply(current)
}