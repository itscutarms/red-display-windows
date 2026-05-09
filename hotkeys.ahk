; hotkeys.ahk — global hotkey bindings for cycle and reset.

Hotkeys_Bind() {
    global HOTKEY_CYCLE, HOTKEY_RESET
    Hotkey(HOTKEY_CYCLE, Hotkeys_OnCycle)
    Hotkey(HOTKEY_RESET, Hotkeys_OnReset)
}

Hotkeys_OnCycle(*) {
    newMode := Modes_CycleNext()
    TrayTip("red-display: " . newMode, "", 0x10)
}

Hotkeys_OnReset(*) {
    Modes_Apply("off")
    TrayTip("red-display: reset to off", "", 0x10)
}