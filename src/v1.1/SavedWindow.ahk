
~^r::reload
!^s::Suspend, 

!F1:: ; Saves the active window's instance
myWinInst:=myWinInst=""? new savedWindowsInstance:myWinInst ; If The instance hasn't been assigned yet, it will assign a SavedWindowsInstance
myWinInst.id:=WinGet() ;Updates the isntance.id with the active window
exit
#1::
myWinInst:=myWinInst=""? new savedWindowsInstance:myWinInst
myWinInst.winActivate("ahk_id " myWinInst.id) ; Activates the windows with the windows.id, if it can't it will update the instance.id with the active window's id
exit


Class savedWindowsInstance {
    static id :=""
    winActivate(winTitle:="", WinText:="" , ExcludeTitle:="" , ExcludeText:="") {
    if !winActive(winTitle, WinText, ExcludeTitle, ExcludeText)     ;Checks if the window with x Parameters is not active
        if winExist(WinTitle, WinText, ExcludeTitle, ExcludeText)   ;Checks if the window with x Parameters exists
            WinActivate, % winTitle , % WinText, % ExcludeTitle, % ExcludeText ;Since the windows with x Parameters exists, it activates it
        else
            this.id:=WinGet() ;Since the windows with x Parameters doesn't exists, it updates the active window's id into this class instance's id
    }
}

WinGet(SubCommand:="ID", WinTitle:="A", WinText:="", ExcludeTitle:="", ExcludeText:="") {
    WinGet, OutputVar , % SubCommand, % WinTitle, % WinText, % ExcludeTitle, % ExcludeText
    return OutputVar
    }
winMinMaxState(winTitle:="A", WinText :="" , ExcludeTitle :="" , ExcludeText :="") {
    WinGet, state, MinMax, % winTitle
    return state
}
