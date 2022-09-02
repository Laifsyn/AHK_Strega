#Warn all, off
;SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.
#Requires AutoHotkey v2.0-beta
MyTimeout:= "Y/N"
msgbox "Message", "Title", MyTimeout

;#include "%A_ScriptDir%\Lib\Main Functions.ahk"
;#include "%A_ScriptDir%\Lib\Classes\"
;msgbox("quote", "Title")
;Run "Notepad++.exe"
ProcessPath := WinGetProcessPath("ahk_exe notepad++.exe")
A_clipboard:=RegExReplace(ProcessPath , "[^\\]+$" , "")
;C:\Program Files\Notepad++\
msgbox(ProcessPath, "TITTLEEE")
/*
Run "C:\Scripts\AHK_Strega-main\DirTest.txt"
Run "properties C:\Scripts\AHK_Strega-main\DirTest.txt"
;Persistent  ; Keep the script from exiting, otherwise the properties dialog will close.
*/
return
~^r::reload