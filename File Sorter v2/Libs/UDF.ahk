﻿#Requires AutoHotkey v2.0


; Functions

SetListVars(Text, DoWaitMsg:=0){
	ListVars
	WinWaitActive "ahk_class AutoHotkey"
	ControlSetText Text, "Edit1"
	if DoWaitMsg
		Msgbox "Waiting....."
	}
	
    DisplayMap(InputObject, LineNumber:="",Padding:=4){
        Static Iteration:=0
        SetlistVars(StrReplace(JXON.Dump(InputObject,Padding), "`n", "`r`n"))
        msgbox "Displaying Map :" (Iteration+=1 ) " `r`n" LineNumber
        }	

Class UDF {
	Class Map Extends Map{
		CaseSense:="Off"
		StartUp:=A_Now
	}
	Static IniRead(Filename, Section :="" ,Key :="" , Default:="" , Auto:=""){
			; Auto is for what value to Write&Return in case the IniRead Target doesn't exists
		OutputVar:=IniRead( Filename, Section, Key , Default)
		If ( !(Auto="") and OutputVar = Default)
			{
			this.IniWrite(Auto, Filename,  Section,  Key, True)
			return Auto
			}
		return OutputVar
		}
	Static IniWrite(Input, Filename , Section :="" ,Key :="", AutoCreate:=False){
		If (!(FileExist(Filename)) and AutoCreate)
				DirCreate RegExReplace(Filename, "[^\\]+$", "") ; This is in case you have something like "C:\Path\Path2\SomeFile.ini" -> "C:\Path\Path2\"
			IniWrite Input , Filename, Section, Key
		return A_LastError ;I honestly don't know what this does. So I'm leaving this just in case. 
		}
}
