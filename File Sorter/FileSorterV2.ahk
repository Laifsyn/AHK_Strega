#Requires AutoHotkey v2.0
start_up := QPC()
SetWorkingDir A_ScriptDir
FileEncoding("UTF-8")
#Include <JXON>
#Include <UDF>
#Include <StoredTimestamp>

; Library of things I think would only be used for this project
#Include <Strega_Lib>
#include <class_WatcherFilePaths>
; Library to manage how the Path Watcher Settings is managed
#Include <class_WatcherPath>
; Library to manage how the Path Watcher Settings is managed
#Include <class_TargetPath>
#Include <class_logger>
#Include <Strega Watcher>

Tooltip(Format("Initializing {}.....", A_ScriptName))
global_variables()

path := A_Scriptdir "\configs\StregaWatcher"
t := Strega_Watcher(path, path)

e := FileGetTime(A_ScriptFullPath, "M")
ToolTip(Format("Initializing.....{} - `r`n{}`r`n{} days ago({}/86400s)"
    , A_ScriptName
    , FormatTime(e, "yyyy-MM-dd(dddd) HH:mm:ss, ")
    , DateDiff(A_Now, e, "Days")
    , Mod(DateDiff(A_Now, e, "S"), 86400)))
SetTimer(ToolTip.Bind(), -3500)
Suspend
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
        , logger := class_logger()
}

!^r:: Reload