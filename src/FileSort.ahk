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
;A_clipboard:=RegExReplace(ProcessPath , "[^\\]+$" , "")

    Class paths{
        static mconfig {   
				get {
				dir:=A_ScriptDir "\configs"
				if !FileExist(dir)
					DirCreate dir
				return "The File `"Dir`" Doesn't Exist"
				}			
            }
        } ; end of Path class

msgbox(paths.mconfig, "TITTLEEE")

/*
Run "C:\Scripts\AHK_Strega-main\DirTest.txt"
Run "properties C:\Scripts\AHK_Strega-main\DirTest.txt"
;Persistent  ; Keep the script from exiting, otherwise the properties dialog will close.
*/
return
~^r::reload