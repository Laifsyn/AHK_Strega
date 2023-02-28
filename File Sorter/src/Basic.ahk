;msgbox, % OneDrive.CurrentSemesterPath " - Result"
#include Libs\JSON.ahk
#include Libs\Watchdog.ahk


Startup()
;SetListVars(WatchPaths.Paths.Watch_1.TargetKeys[1])




;CreateSemesterFolder()
FuncWatchdog := Func("Watchdog").Bind(A_TickCount)
SetTimer, % FuncWatchdog, -50
exit

!^r::reload  
!c::
sendInput,{ctrl down}c{ctrl up}
msgbox, % Clipboard
Clipboard:=Trim(Clipboard, """")
msgbox, % Clipboard
return
#u::run, % OneDrive.CurrentSemesterPath
#i:: run, % a_workingDir
#c:: run, % OneDrive.ScreenShotFolder
exit
Startup(){
Global PathTargets:=JSON.Load(FileRead(A_ScriptDir "\configs\Targets.json")), WatchPaths:=JSON.Load(FileRead(A_ScriptDir "\configs\Paths.json"))

}

CreateSemesterFolder(){
	
	Loop, Files, % OneDrive.CurrentSemesterPath "\*" , D
		RegisteredFolders .= A_LoopFileName ", "
	MainSection:="Semester Folders"
	RegisteredFolders := "[" RegisteredFolders "]"
	if !(IniRead(OneDrive.Filename, MainSection , "Existing Folders") == (RegisteredFolders) )
		IniWrite(RegisteredFolders, OneDrive.Filename, MainSection , "Existing Folders", True)
	DoFolder:= IniRead( OneDrive.Filename, MainSection , "Auto Create (1:do, 0:don't)", "ERROR", False)
	If !DoFolder	
		return
	Folders := IniRead( OneDrive.Filename, MainSection , "Folders i.e.:([Calculo II, Calculo III, Programacion])", "ERROR", "[Misc]")
	Folders := StrSplit(Folders , "," , " []")
	for index, value in Folders
		{if (value="")
			continue
		File := OneDrive.CurrentSemesterPath "\" value
		if FileExist(File)
			Continue
		FileCreateDir, % File
		Result .= "...\" Value "`n"
		}
	IniWrite(False, OneDrive.Filename, MainSection , "Auto Create (1:do, 0:don't)")
	msgbox, % "Folders Created in [" OneDrive.CurrentSemesterPath  "]`n" Result
	return Result
	}
; Classes
Class StartTime {
	__New(InputTime){
		this.tick :=InputTime
		}
	}
Class OneDrive {
	static Filename := A_workingDir "\configs\config.ini"
	static MainSection:= "Gabriel"
	static R_SA:="Ruta del Semestre Actual (Comentario)"
	static SSP:="ScreenshotPath (Comentario)"
	_Init(){
		}
	CurrentSemesterPath {
	Get{
		This.Store_CSP:=IniRead( this.Filename, this.MainSection, this.R_SA, "ERROR")
		If This.Store_CSP="ERROR"
			{
			IniWrite("NaN", this.Filename, This.MainSection, this.R_SA, True)
			This.Store_CSP:=IniRead( this.Filename, this.MainSection, this.R_SA, "ERROR")
			}
		return this.store_CSP
		}
	Set{
		IniWrite(value, this.Filename, This.MainSection, this.R_SA, True)
		return this.store_CSP := value
		}
	}
	ScreenShotFolder {
	Get{
		This.Store_SSP:=IniRead( this.Filename, this.MainSection, this.SSP, "ERROR")
		If This.Store_SSP="ERROR"
			{
			IniWrite("NaN", this.Filename, This.MainSection, this.SSP, True)
			This.Store_SSP:=IniRead( this.Filename, this.MainSection, this.SSP, "ERROR")
			}
		return this.store_SSP
		}
	Set{
		IniWrite(value, this.Filename, This.MainSection, this.SSP, True)
		return this.store_SSP := value
		}
	}
}


; Functions
EnvSub(Time1, Time2, Type="days"){

	EnvSub, Time1, % Time2 , % Type
	return Time1
	}
	
FileAppend(Text, Filename, Encoding:=""){
	FileAppend, % Text, % Filename, % Encoding
	}
FileCreateDir(DirName)	{
	FileCreateDir, % DirName
		Return ErrorLevel
	}
FileMove(SourcePattern, DestPattern, OverWrite:=0, AutoCreatePath:=0) {
	FileMove, % SourcePattern, % DestPattern , % OverWrite	
	Return ErrorLevel
	}
FileRead(Filename){
	FileRead, OutputVar, % Filename
	Switch ErrorLevel{
		Case 1:
		MsgBox("Couldn't find File `r`n<" Filename ">", Laifsyn.AHK_Title)
		exit
		Case 2:
		MsgBox("Couldn't get access to File `r`n<" Filename "> ", Laifsyn.AHK_Title)
		exit
		Case 3:
		MsgBox("There's not enough memory to load the File `r`n<" Filename "> ", Laifsyn.AHK_Title)
		exit
		}
	return OutputVar
	}
FormatTime(Format:="", Input :=""){
	FormatTime, OutputVar , % Input , % Format
	Return OutputVar
	}
IniRead(Filename, Section :="" ,Key :="" , Default:="" , Auto:=""){
	IniRead, OutputVar, % Filename, % Section, % Key , % Default
	If ( !(Auto="") && OutputVar = Default)
		{
		IniWrite(Auto, Filename,  Section,  Key, True)
		return Auto
		}
	return OutputVar
	}
IniWrite(Input, Filename , Section :="" ,Key :="", AutoCreate:=False){
	If (!FileExist(Filename) && AutoCreate)
			{
			FileCreateDir, % RegExReplace(Filename, "[^\\]+$", "")
			}
	IniWrite, % Input , % Filename, % Section, % Key
	return ErrorLevel
	}
MsgBox(Text, Title:="",Options:="", Timeout:=""){
	MsgBox , % Options, % Title, % Text, % Timeout
	}
SetListVars(Text, DoWaitMsg:=0){
	ListVars
	WinWaitActive ahk_class AutoHotkey
	ControlSetText Edit1, % Text
	if DoWaitMsg
		Msgbox, Waiting.....
	}
	
; Common Classes

Class Laifsyn{
	Static AHK_Title:= "File Sorter (Laifsyn)"
	Static AHK_ScriptVersion:= "b0.1"
	
	}