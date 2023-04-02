;msgbox, % OneDrive.CurrentSemesterPath " - Result"
#include <JXON>
#include <Watchdog>
#Include <UDF>
#Requires AutoHotkey v2.0

Startup()
;SetListVars(WatchPaths.Paths.Watch_1.TargetKeys[1])
Some:= A_Now
StartTime:= Laifsyn(A_Now)
test:=UDF.Map("A",50)


FuncWatchdog := Watchdog.Bind(A_TickCount)
SetTimer FuncWatchdog, -50
 
Class NoCaseMap extends Map {
	CaseSense := "off"
}
!^r::reload  

#u::run OneDrive.CurrentSemesterPath
#i:: run a_workingDir
#c:: run OneDrive.ScreenShotFolder

Startup(){
	
Global PathTargets:=JXON.Load(&SrcPath:=FileRead(A_ScriptDir "\configs\Targets.json"))
		, WatchPaths:=JXON.Load(&SrcPath:=FileRead(A_ScriptDir "\configs\Paths.json"))
		, _rn := "`r`n"
		WatchPaths.DefineProp("CaseSense", {Value: "Off"})
		Map.Prototype.DefineProp("Default", {Value: ""})
		
}


; Classes

Class OneDrive {
	static Filename := A_workingDir "\configs\config.ini"
	
	static R_SA:="Ruta del Semestre Actual (Comentario)"
	static SSP:="ScreenshotPath (Comentario)"
	_Init(){
		}
	Static MainSection{
		Get{

		}
		Set{
			static 
		}
	}
	Static CurrentSemesterPath {
	Get{
		This.Store_CSP:=IniRead( this.Filename, this.MainSection, this.R_SA, "ERROR")
		If This.Store_CSP="ERROR"
			{
			UDF.IniWrite("NaN", this.Filename, This.MainSection, this.R_SA, True)
			This.Store_CSP:=IniRead( this.Filename, this.MainSection, this.R_SA, "ERROR")
			}
		return this.store_CSP
		}
	Set{
		UDF.IniWrite(value, this.Filename, This.MainSection, this.R_SA, True)
		return this.store_CSP := value
		}
	}
	Static ScreenShotFolder {
	Get{
		This.Store_SSP:=IniRead( this.Filename, this.MainSection, this.SSP, "ERROR")
		If This.Store_SSP="ERROR"
			{
				UDF.IniWrite("NaN", this.Filename, This.MainSection, this.SSP, True)
			This.Store_SSP:=IniRead( this.Filename, this.MainSection, this.SSP, "ERROR")
			}
		return this.store_SSP
		}
	Set{
		UDF.IniWrite(value, this.Filename, This.MainSection, this.SSP, True)
		return this.store_SSP := value
		}
	}
}


; Common Classes


Class Laifsyn{
	__New(InputTime){
		this.Tick:=InputTime
		}
	Tick :=A_Now
	Static AHK_Title:= "File Sorter (Laifsyn)"
	Static AHK_ScriptVersion:= "b0.1"

	}
	Initialize(this,Value) {
		msgbox this ="" "`r`nTest" 
		Return
	}