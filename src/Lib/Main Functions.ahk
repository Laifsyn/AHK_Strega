
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
    freq:=DllCall("QueryPerformanceFrequency", "Int64*")
    CounterBefore:=DllCall("QueryPerformanceCounter", "Int64*")
    Sleep Time
    CounterAfter:=DllCall("QueryPerformanceCounter", "Int64*")
    Expression := (CounterAfter - CounterBefore) / freq * 1000 
    if ( skip = false )
        MsgBox "Elapsed QPC time is " . Expression " ms"
    return (CounterAfter - CounterBefore) / freq * 1000 
}



AddToTray(){ ;Commons AddToTray Objects
;global thisFile, NotepadPP, VSCode
; Remove the standard menu items temporarily
MyMenu := Menu()
MyMenu.delete()
; Add our custom MyMenu item labeled "Edit With Notepad++" 
; and calls the function above
if myReturn := FileExist(NotepadPP.App())
    MyMenu.Add("Edit With Notepad++", thisFile.OpenWith.NotePP)
if myReturn := FileExist(VSCode.App())
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

emptyTooltip(number := 1) {
	tooltip "" ,,,number
}
CleanTooltip(tooltipId:="1") { ; Clears tooltips as individual, or as a range or in array
    if InStr(tooltipId, "-" ){
		tooltipId := StrSplit(tooltipId, "-",,2 )
        If (tooltipId[1] == tooltipId[2]) { ; If the 2 tooltipIds are the same, removes only 1 tooltip
            emptyTooltip(tooltipId[1])
                return
            }
        loop Abs(tooltipId[2] - tooltipId[1])+1 {
		msgbox("Loop Result" Abs(tooltipId[2] - tooltipId[1])+1)
            emptyTooltip(tooltipId[1])
            tooltipId[1]+=1
        }
        
        return
        }
	emptyTooltip(Number)
    return
    }
    
Timer(label, period, prio := 0){
    SetTimer label, period, prio
}
