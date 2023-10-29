#Requires AutoHotkey v2.0
SetWorkingDir A_ScriptDir
#Include <toml\toml>
#Include <JXON>
#Include <UDF>
#Include <StoredTimestamp>

; Library that's reserved for the Strega project
#Include <Strega_Lib>
#include <class_WatcherFilePaths>
; Library to manage how the Path Watcher Settings is managed
#Include <class_WatcherPath>
; Library to manage how the Path Watcher Settings is managed
#Include <class_TargetPath>

#Include <Watchdog - Copy>
msgbox "wait!"
global_variables()

path := A_Scriptdir "\configs\StregaWatcher"
t := Strega_Watcher(path, path)
t.doProcedure()
if 1
    Exit

global_variables() {
    global
    VarSetStrCapacity(&year, 4)
        , VarSetStrCapacity(&month, 2)
        , VarSetStrCapacity(&day, 2)
        , VarSetStrCapacity(&today, 10)
        , VarSetStrCapacity(&tomorrow, 10)
        , year := A_YYYY, month := A_MM, day := A_DD
        , today := FormatTime(A_Now, "yyyy\MM\dd")
        , tomorrow := FormatTime(DateAdd(A_Now, 1, "Days"), "yyyy\MM\dd")
}

!^r:: Reload