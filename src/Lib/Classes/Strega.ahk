
; Create an object.
now:= A_Now
class NotepadPP {
    Path(){
        return A_ProgramFiles "\Notepad++"
        }
    App(){
            Clipboard:= this.Path() "\notepad++.exe"
        return this.Path() "\notepad++.exe"
        }
    }
Class VSCode {
    Path(){
        return "C:\Users\" A_UserName "\AppData\Local\Programs\Microsoft VS Code"
        }
    App(){
        ;dir:=A_StartMenu "\Programs\Microsoft VS Code.exe"
        VSCodeName:= ["Microsof t VS Code.exe", "Code.exe"]
        dir := This.Path()
        Switch 
            {Case FileExist( dir "\" VSCodeName[1] ):
                dir := dir "\" VSCodeName[1]
            Case FileExist( dir "\" VSCodeName[2] ):
                dir := dir "\" VSCodeName[2]
            default:
                loop, % VSCodeName.Length()
                    Text:= Text dir "\" VSCodeName[A_Index] "`n"
                msgbox, % "The next " VSCodeName.Length() " File paths doesn't exists`n" Text
                return
            }
        return dir    
        }
    }
class thisAHK {
;static StartupT := A_now  
    __Init() {
        if !(ThisAHK.StartupT = ""){
            msgbox % "Tried to redefine vars"
            return
        }

    ThisAHK.StartupT := A_Now
    ThisAHK.StartupMs := A_MSec
    ThisAHK.StartupTick := A_TickCount
    }
    __Call(Name, Params*){
        if (Name = "") {
                return thisAHK.StartupT
        }
    }

    Time(showMs := false){
        if ShowMS = false
        return FormatTime(this.StartupT, "yyyy M/d/yyyy HH:mm tt")
        else
        return FormatTime(this.StartupT, "yyyy M/d/yyyy HH:mm:ss") "." StartupTime.Ms() " "
    }
    Era(Format:="yyyy"){
        return FormatTime(this.StartupT, Format)
    }
    Year(Format:="yyyy"){
        return FormatTime(this.StartupT, Format)
    }
    Month(Format:="MM"){
        return FormatTime(this.StartupT, Format)
    }
    Day(Format:="dd"){
        return FormatTime(this.StartupT, Format)
    }
    Hour(Format:="HH"){
        return FormatTime(this.StartupT, Format)
    }
    Minute(Format:="mm"){
        return FormatTime(this.StartupT, Format)
    }
    Second(Format:="ss"){
        return FormatTime(ThisAHK.StartupT, Format)
    }
    Ms(){
         return this.StartupMs
    }
    Msec(){
         return this.StartupMs
    }
    
    ConfigPath(){
    dir:=A_ScriptDir "\config"
    if !FileExist(dir)
        FileCreateDir, % dir
    return dir
    }
    
    Clear(){
            
        }
    }
    
new thisAHK()

Class ThisFile {
    static Dir:=A_Scriptdir
    static FullDir:= FullPath:=A_ScriptFullPath
    
    Class Open {
        Dir(){
            Run %A_Scriptdir%
            }
        }
    Class OpenWith {
        VSCode(){
            Run % quote VSCode.App() quote " " quote A_ScriptFullPath quote
            }
        NotePP(){
            Run % quote NotepadPP.App() quote " " quote A_ScriptFullPath quote
            }
        }

    }

class StartupTime extends thisAHK {
    
    }
class UpTime extends thisAHK {
    MSec(MeasureUnit:=false){
        Input := (A_TickCount - this.StartupTick)
        if (Input == 0 ){
            return 0
        }
        return Input (MeasureUnit ? " ms":"")
    }
    Seconds(MeasureUnit:=false){
        Input := (A_TickCount - this.StartupTick)/1000
        if (Input == 0 ){
                return 0 (MeasureUnit ? " s":"")
        }
        return Format("{:.3f}", Input) (MeasureUnit ? " s":"")
    }
    Minutes(MeasureUnit:=false){
        Input := (A_TickCount - this.StartupTick)/60000
        return Format("{:.3f}", Input) (MeasureUnit ? "'":"")
    }   
    Hours(MeasureUnit:=false){
        Input := (A_TickCount - this.StartupTick)/3600000
        return Format("{:.3f}", Input) (MeasureUnit ? " Hrs":"")
    }   
    Days(MeasureUnit:=false){
        Input := (A_TickCount - this.StartupTick)/86400000
        return Format("{:.3f}", Input) (MeasureUnit ? " Days":"")
    }
     
    }
    



b:=A_msec


thing_test() {
    MsgBox % this.Hours " ABC"
    }
    
thisAHK.test()
thisAHK.startupTime := ""
thisAHK.startupTime.Func1()

    ;MsgBox % "asdasd " thisAHK.startupTime.Hours "hours"



/*
counter := new SecondCounter
;counter.Start()
Sleep 5000
;counter.Stop()
Sleep 2000
*/
; An example class for counting the seconds...
class SecondCounter {
    __New() {
        this.interval := 1000
        this.count := 0
        ; Tick() has an implicit parameter "this" which is a reference to
        ; the object, so we need to create a function which encapsulates
        ; "this" and the method to call:
        this.timer := ObjBindMethod(this, "Tick")
    }
    Start() {
        msgbox, asdasd
        ; Known limitation: SetTimer requires a plain variable reference.
        timer := this.timer
        SetTimer % timer, % this.interval
        ToolTip % "Counter started"
    }
    Stop() {
        ; To turn off the timer, we must pass the same object as before:
        timer := this.timer
        SetTimer % timer, Off
        ToolTip % "Counter stopped at " this.count
    }
    ; In this example, the timer calls this method:
    Tick() {
        ToolTip % ++this.count
    }
    Clear() {
        this.timer := ""
        SetTimer % timer, Delete
    }
}
