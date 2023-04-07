#Requires AutoHotkey v2.0


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
	Static ErrorFormat(errObject) =>
		Format("{1}: {2}.`n`nFile:`t{3}`nLine:`t{4}`nWhat:`t{5}`nStack:`n{6}"
        , type(errObject), errObject.Message, errObject.File, errObject.Line, errObject.What, errObject.Stack)

	Static getPropsList(inputObject){
		Text:=""
		for prop,_ in inputObject.OwnProps()
			Text.= prop (IsObject(_)?"":" : " SubStr(_,1,50)) "`r`n" 
		return Text
	}

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

