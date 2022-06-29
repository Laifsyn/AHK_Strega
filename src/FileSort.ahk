#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Requires AutoHotkey v2.0
ClassPath:=A_ScriptDir + "\Lib\Classes\"
FunctionPath:=A_ScriptDir + "\Lib\*.ahk"
#include *i %FunctionPath%
#include %ClassPath%Strega.ahk
