
; FormatTime(Input := "", Format:=""){
;     if !(RegExMatch(Format, "(^[gyMdHhmst]+)"))
;        { MsgBox "Error in format:" Format
;        return ErrorData:="Error in Format input(" Format ")"
;        }
;     if (Input = ""){
;         return  this . "Error In FormatTime Input"
;     }   
    
;     FormatTime, Output , % Input, % Format
;     return Output
; }



FirstQuery(&CounterOutput) {
    DllCall("QueryPerformanceCounter", "Int64*", CounterOutput)
    return CounterOutput
    }

LastQuery(&CounterOutput) {
    DllCall("QueryPerformanceCounter", "Int64*", CounterOutput)
    return CounterOutput
    }
GetFrequency(&Frequency){
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
        MsgBox "Elapsed QPC time is " . Expression " ms"
    return (CounterAfter - CounterBefore) / freq * 1000 
}



AddToTray(){ ;Commons AddToTray Objects
; Remove the standard menu items temporarily
MyMenu := Menu()
MyMenu.delete()
; Add our custom MyMenu item labeled "Edit With Notepad++" 
; and calls the function above
if FileExist(NotepadPP.App())
    MyMenu.Add("Edit With Notepad++", thisFile.OpenWith.NotePP)
if FileExist(VSCode.App())
    MyMenu.Add("Edit With VSCode", thisFile.OpenWith.VSCode)
MyMenu.Add("Open this File Dir", ThisFile.Open.Dir)
;MyMenu, Tray, Add, Open AHK Window 
; Add a separator
MyMenu.Add
; Put the standard MyMenu items back, under our custom MyMenu item
MyMenu.AddStandard
return 
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
