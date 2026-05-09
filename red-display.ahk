; red-display.ahk — entry point. Loaded by AutoHotkey when the user runs the script.
#Requires AutoHotkey v2.0
#SingleInstance Force

#Include config.ahk
#Include sun.ahk
#Include modes.ahk
#Include scheduler.ahk
#Include hotkeys.ahk
#Include persistence.ahk

Scheduler_Setup()
Hotkeys_Bind()
Persistence_Install()

TrayTip("red-display loaded", "", 0x10)