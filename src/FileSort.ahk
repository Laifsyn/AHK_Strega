#Warn Unreachable, Off  ; Enable warnings to assist with detecting common errors.
;SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.
#Requires AutoHotkey v2.0-beta
MyTimeout:= "Y/N T10"
msgbox "Message", "Title", MyTimeout

;#include "%A_ScriptDir%\Lib\Main Functions.ahk"
;#include "%A_ScriptDir%\Lib\Classes\"
msgbox(quote, "Title")
Run quote NotepadPP.App() quote, quote A_ScriptFullPath quote
~^r::reload