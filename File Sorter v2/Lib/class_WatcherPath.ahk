#Requires AutoHotkey v2.0

Class WatchFile Extends WatcherFile {
    ArrayAbles := Array("Source", "TargetKeys")
    expects_keywords := this.ArrayAbles
    stack_unexistentPaths := Array()
    settings_template_data := "
    ( join`r`n
    {
        "Source":[],
        "isPath":true,
        "TargetKeys":[],
        "TimeUp":"8d18h",
        "Age_asCountdown": 1
    }
    )"
    settings_common_data := "
    (join`r`n
    {
        "UserDefined":{"Nombre1" : "NombreArbitrario1"},
        "Available Common Keywords(Comment)" : ["<A_DD>", "<A_MM>", "<A_YYYY>", "<A_UserName>", "<A_Desktop>" , 
        "<A_MyDocuments>", "<A_AppData>" , "<A_ComputerName>" , "<A_DDD>", "<A_DDDD>", 
        "<A_WDay>", "<A_MMMM>", "<A_Mon>", "<A_MMM>", "<A_YDay>", "<A_YWeek>"
        ],
        "LoadDefault" : 0
    }
    )"
    /**
     * @param Path The root path where the Class will be loading all the configs for the Watch
     */
    __New(Path) {
        Path := Path "\watchers"
        super.__New(Path)
        tick := A_TickCount
        this.FixPaths()
    }

    /**
     * Confirmed this doesn't create memory leak
     */
    FixPaths() {
        for _instance_namespace, watcherpath_instance in this["settings"] {
            ; Fixes the path through this.FixPath()
            for i, path in watcherpath_instance["source"]
                watcherpath_instance["source"][i] := this.FixPath(&path), this.Push_ToStack(path)
            this.consume_UnexistentPaths()
            watcherpath_instance["TimeUp"] := this.TranslateTimeUp(watcherpath_instance["TimeUp"], &s)
        }
    }

    /**
     * Re-formats the path string to fit the program's path criteria
     * @param &path 
     * @returns class_Object
     * 
     * EXAMPLES:
     * 
     * C:\myFolder => C:\myFolder\\*
     * 
     * C:\myFolder\ => C:\myFolder\\*
     * 
     * C:\myFolder\* => C:\myFolder\\*
     * 
     * C:\myFolder* => C:\myFolder*\\* ; This is Invalid entry
     */
    FixPath(&path) {
        append := ""
        ; Checks if the last char is "*"
        if SubStr(path, -1) != "*"
            append := "*"
        if (SubStr(path, -1, 1) != "\" && SubStr(path, -2, 1) != "\")
            append := "\" append
        path .= append
        return path
    }
    /**
     * Pushes N Items to the stack of unexistent paths in Source_Paths
     */
    Push_ToStack(path) {
        path := RegExReplace(path, "<.*", "")
        path := Trim(path, " \*")
        if !FileExist(path) and !IsInList(path, this.stack_unexistentPaths)
            this.stack_unexistentPaths.Push(path)
    }
    /**
     * Consumes this.stack_unexistentPaths
     */
    consume_UnexistentPaths() {
        if this.stack_unexistentPaths.Length {
            msgbox RegExReplace(JXON.Dump(this.stack_unexistentPaths), "\\+", "\")
            for path in this.stack_unexistentPaths
                DirCreate(path)
            this.stack_unexistentPaths := []
        }
    }
    /**
     * 
     * @param Input 
     * @param TimeInfo Variable to store Deserialized TimeUp string
     * @returns {number} 
     */
    TranslateTimeUp(Input, &TimeInfo?) {
        TimeInfo := Map() ;Call for a Set() so it doesn't call the __Item[] property
            , TimeInfo.CaseSense := "Off"
        ; Check's if it's in second's format
        If IsNumber(Input) {
            Time := 20000101 ;Arbitrary midnight of any date
            time := DateAdd(time, Integer(Input), "Seconds")
                , TimeInfo["Days"] := Input // 86400
                , TimeInfo["Hours"] := FormatTime(time, "H")
                , TimeInfo["Minutes"] := FormatTime(time, "m")
                , TimeInfo["Seconds"] := FormatTime(time, "s")  ;Enclosed in parentheses because auto formatter is funny at times
            Return Input
        }
        ; TimeInfo["Months"] := (RegExMatch(Input, "((?<Months>\d+)[M])", &Months) ? Months[2] : 0) ;Because I feel like it makes more sense for it to be up to days as the highest number
        TimeInfo["Days"] := (RegExMatch(Input, "((?<Days>\d+)[Dd])", &Days) ? Days[2] : 0)
            , TimeInfo["Hours"] := (RegExMatch(Input, "((?<Hours>\d+)[Hh])", &Hours) ? Hours[2] : 0)
            , TimeInfo["Minutes"] := (RegExMatch(Input, "((?<Minutes>\d+)[m])", &Minutes) ? Minutes[2] : 0)
            , TimeInfo["Seconds"] := (RegExMatch(Input, "((?<Seconds>\d+)[sS])", &Seconds) ? Seconds[2] : 0) ;Enclosed in parentheses because auto formatter is funny at times
            , Input := TimeInfo["Days"] * 86400 + TimeInfo["Hours"] * 3600 + TimeInfo["Minutes"] * 60 + TimeInfo["Seconds"]
        return Input
    }
}