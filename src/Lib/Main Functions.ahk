#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


FormatTime(Input := "", Format:=""){
    if !(RegExMatch(Format, "(^[gyMdHhmst]+)"))
       { MsgBox, Error in format: "%Format%"
       Return ErrorData:="Error in Format input(" Format ")"
       }
    if (Input = ""){
        return % this . "Error In FormatTime Input"
    }   
    
    FormatTime, Output , % Input, % Format
    return Output
}



FirstQuery(ByRef CounterOutput) {
    DllCall("QueryPerformanceCounter", "Int64*", CounterOutput)
    return CounterOutput
    }

LastQuery(ByRef CounterOutput) {
    DllCall("QueryPerformanceCounter", "Int64*", CounterOutput)
    return CounterOutput
    }
GetFrequency(ByRef Frequency){
    DllCall("QueryPerformanceFrequency", "Int64*", Frequency)
    return Frequency
    }
ComputeQuery(FirstQuery, LastQuery, Frequency := ""){
    if (Frequency = "")
        GetFrequency(Frequency)
    return (LastQuery - FirstQuery) / Frequency * 1000
}
DoQuery(Time:=1000, skip:=false)     {
    DllCall("QueryPerformanceFrequency", "Int64*", freq)
    DllCall("QueryPerformanceCounter", "Int64*", CounterBefore)
    Sleep Time
    DllCall("QueryPerformanceCounter", "Int64*", CounterAfter)
    Expression := (CounterAfter - CounterBefore) / freq * 1000 
    if ( skip = false )
        MsgBox % "Elapsed QPC time is " . Expression " ms"
    return (CounterAfter - CounterBefore) / freq * 1000 
}



AddToTray1(){ ;Commons AddToTray Objects
; Remove the standard menu items temporarily
Menu, Tray, NoStandard 
; Add our custom menu item labeled "Edit With Notepad++" 
; and calls the function above
if FileExist(NotepadPP.App())
    Menu, Tray, Add, Edit With Notepad++, thisFile.OpenWith.NotePP
if FileExist(VSCode.App())
    Menu, Tray, Add, Edit With VSCode, thisFile.OpenWith.VSCode
Menu, Tray, Add, Open this File Dir, ThisFile.Open.Dir
;Menu, Tray, Add, Open AHK Window 
; Add a separator
Menu, Tray, Add 
; Put the standard menu items back, under our custom menu item
Menu, Tray, Standard 
return
}


FuncMsgBox(Message:="Default Message", Timeout:="", Option:=0) {
    MsgBox % Options, Strega AutoHotkey - File Organizer, % Message, % Timeout
    return ErrorLevel
    }

ClearTooltip(Number, Period:="", Prio:= 0) {
    if !(Period = ""){
        Timer(Func("CleanTooltip").bind(Number), Period, Prio)
        Return
        }
    CleanTooltip(Number)
    }


CleanTooltip(Number:="1") { ; Clears tooltips as individual, or as a range or in array
    if Number contains -  
            {Array := StrSplit(Number, "-",,2 )
        If (Array[1] == Array[2]) { ; If the 2 arrays are the same, removes only 1 tooltip
            Tooltip,,,, % Array[1]
                return
            }
        loop, % Abs(Array[2] - Array[1])+1 {
            tooltip,,,,Array[1]
            Array[1]+=1
        }
        
        return
        }
    Tooltip,,,, % Number
    return
    }
    
Timer(label, period, prio := 0){
    SetTimer, % label, % period, % prio
}
