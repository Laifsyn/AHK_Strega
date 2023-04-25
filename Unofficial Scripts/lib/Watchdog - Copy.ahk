/* Todo list
-Finish S_getOrCreate_TimeMark()
	Needs to store a file mark for the file in question
-Create a LogFile for when a file is succesfully moved



*/
#Requires AutoHotkey v2.0

class Watchdog_Base extends Map {
    _encoding := "UTF-8"
    CaseSense := "Off"
    Summary[Line, Function := "", type := "INFO"] {
        set {
            Static Cycles := 0, Content := ""
            Content .= Format("{1}({2})(Func.{3})({4}){5}`r`n", this.LogFormat(), Line, Function, Cycles, value)
            this._Summary := value
            if !Mod(Cycles, 50)
                return
            ; msgbox Content
        }
        get {
            Try
                return this._Summary
            catch
                return ""
        }
    }

    CloneMap(InputMap) { ; Still experimenting if it works
        Val := InputMap.Clone()
        { for k, v in Val
            {
                if (v is Object)
                    val[k] := this.CloneMap(v)
            } }
        return Val
    }

    InQuote(Input) => "`"" Input "`""

    LogFormat() {
        Return FormatTime(A_Now, "[HH:mm:ss." A_MSec "]")
    }

    mergeMap(InstRef, Map) { ;Shallow merge.
        For k, v in Map
            InstRef[k] := v
    }

    process_invalidKeywords(Input) => RegExReplace(Input, "i)(<|>)", "")

    process_Keywords(Input, SupportedKeyWords := "A_(Username|Y(YYY|Day|Week)|M{2,4}|D{2,4}|WDay|Desktop|ComputerName|AppData|MyDocuments|Mon)") {
        While (Input ~= "i)<.*>")
        {
            Try
            { RegExMatch(Input, "i)<(" SupportedKeyWords ")>", &SubPat)
                , Input := RegExReplace(Input, "i)<(" SubPat[1] ")>", %SubPat[1]%)
            }
            catch ; Once there's no more matches, it stops iterating
                Break
        }
        ; msgbox "PropList" A_LineNumber  "`r`n" UDF.getPropsList(this) "`r`n" Input
        Return Input
    }

    process_CustomKeywords(Input, UDK) {
        StartingPos := 1, KeyWords := Array()
        While StartingPos := RegExMatch(Input, "i)<([^>\\]+)>", &SubPat, StartingPos) + 1
        {
            If !SubPat
                break
            KeyWords.Push(SubPat[1])
        }
        For Value in KeyWords {
            if UDK.Has(Value)
                Input := RegExReplace(Input, "i)<(" Value ")>", UDK[Value])
            ; else
            ;     throw ValueError("<" this.InQuote(Value) "> isn't a defined key", Type(this), Input)
        }
        ; msgbox "PropList" A_LineNumber  "`r`n" UDF.getPropsList(this) "`r`n" Input
        Return Input
    }

    process_AddEnding(Input) { ;Adds the ending of the path. For File Loop, it always requires to you specificate what to iterate in the folder
        if !(Input ~= "\\\*?$")
            Input := Input "\"
        if (Input ~= "\\$")
            Input := Input "*"
        return input
    }

    process_TimeString(Input) {
        this.Set("TimeInfo", Map()) ;Call for a Set() so it doesn't call the __Item[] property
            , this["TimeInfo"].CaseSense := "Off"
        If IsNumber(Input) {
            Time := 20000101 ;Arbitrary midnight of any date
            time := DateAdd(time, Integer(Input), "Seconds")
                ; msgbox Input//86400 "d" FormatTime(time, "H'h'mm'm's's'")
                , this["TimeInfo"]["Days"] := Input // 86400
                , this["TimeInfo"]["Hours"] := FormatTime(time, "H")
                , this["TimeInfo"]["Minutes"] := FormatTime(time, "m")
                , this["TimeInfo"]["Seconds"] := FormatTime(time, "s")  ;Enclosed in parentheses because auto formatter is funny at times
            Return Input
        }
        ; this["TimeInfo"]["Months"] := (RegExMatch(Input, "((?<Months>\d+)[M])", &Months) ? Months[2] : 0) ;Because I feel like it makes more sense for it to be up to days as the highest number
        this["TimeInfo"]["Days"] := (RegExMatch(Input, "((?<Days>\d+)[Dd])", &Days) ? Days[2] : 0)
            , this["TimeInfo"]["Hours"] := (RegExMatch(Input, "((?<Hours>\d+)[Hh])", &Hours) ? Hours[2] : 0)
            , this["TimeInfo"]["Minutes"] := (RegExMatch(Input, "((?<Minutes>\d+)[m])", &Minutes) ? Minutes[2] : 0)
            , this["TimeInfo"]["Seconds"] := (RegExMatch(Input, "((?<Seconds>\d+)[sS])", &Seconds) ? Seconds[2] : 0) ;Enclosed in parentheses because auto formatter is funny at times
            , Input := this["TimeInfo"]["Days"] * 86400 + this["TimeInfo"]["Hours"] * 3600 + this["TimeInfo"]["Minutes"] * 60 + this["TimeInfo"]["Seconds"]
        return Input
    }

    renameKey(baseObject, OldKey, NewKey) {
        baseObject[NewKey] := baseObject[OldKey]
            , baseObject.Delete(OldKey)
    }

    transformString(Path, Type, encoding) { ; To transform a string path into a possibly JSON String
        if Path is file
            JsonString := Path.read()
                , Path.Close()
        else if Type = "File"
            JsonString := fileread(Path, encoding)
                , this.DefineProp("__path", { Value: Path }) ; It means that this.__path stores the string path that was used to retrieve the file.
        else if Type = "Text"
            JsonString := Path
        else
            throw ValueError("No matching data? Expects a path or string, but registered " Type, Type(this))
        return JXON.Load(JsonString)
    }
}

Class TargetFile extends Watchdog_Base {
    __New(Path, type := "Text", encoding := this._encoding) {
        this.DefineProp("__path", { Value: StrLen(path) })
            , this.DefineProp("__fileLastModified", { Value: FileGetTime(Path, "M") })
            , JsonMap := this.transformString(Path, Type, encoding)
            , this.mergeMap(this, JsonMap)
            , this.Targets := TargetFile.Configs(this["Targets"], this) ; I will be able to keep an intact this["Targets"]
        return this
    }

    Class Configs extends Watchdog_Base {
        __New(Configs, Parent) {
            this.DefineProp("__parent", { Value: Parent })
                , this.DefineProp("__original", { Value: Configs }) ; Stores a pointer to directly access the Original configs
            for Key, A_Settings in Configs
                this[key] := TargetFile.TargetPath(A_Settings, Key, this)
            return this
        }

        __Item[KeyName] {
            get {
                if this.Has(KeyName)
                    return super[KeyName] ;Changed to Super to avoid Infinite Recursion
                return this[KeyName] := TargetFile.TargetPath("s", KeyName, this)
            }
        }
    }
    Class TargetPath Extends Watchdog_Base { ;; Auto Initialize a SubClass Instance in case there's the setting of a not defined Target Or Watcher
        __New(InputSettings, parentKey, Parent) {
            ; msgbox Watcher " " A_LineNumber
            this.DefineProp("__parent", { Value: Parent })
                , this.DefineProp("__parentKey", { Value: parentKey })
                , this.DefineProp("__setting", { Value: InputSettings })
            for Key, val in this.__setting
                this[Key] := val
            Return this
        }

        __Item[KeyName] {
            set {
                switch KeyName, 0 {
                    case "SearchKeys":
                        Val := Array()
                        , Value := Value is Array ? Value : Array(Value)
                        For _, v in Value {
                            v := this.process_Keywords(v)
                                , v := this.process_CustomKeywords(v, this.__parent.__parent["UserDefined"])
                            Val.Push(v)
                        }
                        this.Targets := this.refine_Targets(this.__setting["Type"], Val*)
                        Value := Val
                    case "Target":
                        v := Value
                        , v := this.process_Keywords(v)
                        , v := this.process_CustomKeywords(v, this.__parent.__parent["UserDefined"])
                        , value := v
                    default:
                        If value is Object
                        {
                            err := ValueError(this.InQuote(this.__parentKey) "[" KeyName "] expects string, but got " Type(value), Type(this))
                                , msgbox(UDF.ErrorFormat(err))
                        }
                }
                Super[KeyName] := Value
            }
        }

        refine_Targets(InputType, A_TargetValues*) { ; This is to convert Filetype/Keyword Keywords into a single RegEx if possible. This should solve cases when data is updated on the run
            temp := "", RegEx := Array()

            For Val in A_TargetValues {
                if RegExMatch(Val, "r/(.*)/(.*)", &SubPat)
                {
                    RegEx.Push(SubPat[1])
                    continue
                }
                temp .= val "|"
            }
            temp := "(" Trim(temp, "|") ")"
            if RegEx.Length ;will replace >this.__setting["Type"]< so to store as a temporal value of the result type of the refinement
                this.type := "Mixed"
            else
                this.type := InputType
            If (this.Type = "Mixed") { ; it matters to know if it's mixed, so It can work with A_LoopFileName without issues
                switch InputType, 0 { ; Case Insensitive - Checks for the original Expected InputType
                    case "Filetype":
                        temp := "iS)\." temp "$"
                    case "Keyword":
                        temp := "iS)" temp "(?=.*\.[^\.]+)$"
                    default:
                        throw ValueError("Unknown Type! Expects `"Filetype`" or `"Keyword`"", Type(this), "TargetKey [" this.__parentKey "]:=" this.InQuote(InputType))
                } }
            else
                temp := "iS)" temp
            RegEx.InsertAt(1, temp)
            return RegEx
        }
    }
}

Class WatchFile Extends Watchdog_Base {
    __New(Path, Type := "Text", encoding := this._encoding) {
        this.DefineProp("__path", { Value: StrLen(path) })
            , this.DefineProp("__fileLastModified", { Value: FileGetTime(Path, "M") })
            , JsonMap := this.transformString(Path, Type, encoding)
            , this.mergeMap(this, JsonMap)
            , WatcherConfigs := this["WatcherConfigs"]
            , this.Paths := WatchFile.Configs(this[WatcherConfigs], this) ; I will be able to keep an intact this["Paths"]
        return this
        ; For Watcher, A_Settings in this.Paths { ; Create a shallow Clone because it seems that deleting the key mess up with the Enumeration

        ;     Temp := WatchFile.Configs(A_Settings, Watcher, this)
        ;         , this.Summary[A_LineNumber, A_ThisFunc] := Format("{}({})")
        ;         , Temp.DeleteProp("Summarys")
        ;         , this.Paths[Watcher] := Temp
        ; }
    }

    Class Configs extends Watchdog_Base {
        __New(Configs, Parent) {
            this.DefineProp("__parent", { Value: Parent })
                , this.DefineProp("__original", { Value: Configs }) ; Stores a pointer to directly access the Original configs
            toDelete := []
            for Key, A_Settings in Configs
            {
                If !!(A_Settings["Skip"])
                    Continue
                Temp := WatchFile.WatchPath(A_Settings, Key, this)
                if !Temp["Source"].Length
                    Continue
                this[key] := Temp

            }
            return this
        }

        __Item[KeyName] {
            set {
                super[KeyName] := Value
            }
            get {
                if this.Has(KeyName)
                    return super[KeyName] ;Has to use Super otherwise it will infinitely recurse.
                return this[KeyName] := WatchFile.WatchPath(Map(), KeyName, this)
            }
        }
    }
    Class WatchPath Extends Watchdog_Base { ; Wrapper to process the watcher's parameters
        CaseSense := 0

        __New(InputSettings, parentKey, Parent) {
            ; msgbox Watcher " " A_LineNumber
            this.DefineProp("__parent", { Value: Parent })
                , this.DefineProp("__parentKey", { Value: parentKey })
            for Key, val in InputSettings
                this[Key] := val

            Return this
        }

        __Item[KeyName] {
            set {
                switch KeyName, 0 {
                    case "Source":
                        Val := Array()
                        , Value := Value is Array ? Value : Array(Value)
                        For _, v in Value {
                            if RegExMatch(v, "[A-Z]:\\Program Files")
                                msgboxResult := MsgBox("You're trying to watch a System file, wanna discard this entry? `r`n" v, , 0x4)
                            if InStr(v, ";", , (-StrLen(v))) or (IsSet(msgboxResult) and msgboxResult = "Yes")
                                continue
                            v := this.process_Keywords(v)
                                , oldv := v
                                , v := this.process_CustomKeywords(v, this.__parent.__parent["UserDefined"])
                                , v := this.process_invalidKeywords(v) ; It means that "C:\<sometext\*>" → "C:\sometext\*"
                                , v := this.process_AddEnding(v)
                            if FileExist(Trim(v, "*\")) ;Trim it because "Path\*" can be wonky
                                Val.Push(v)
                            else
                                throw ValueError("File path doesn't exists! " v "`r`nYou can add a ';' at the start to ignore the key",
                                    , Format("Watcher[`"{}`"](Item no.{}):={}", this.__parentKey, A_Index, oldv))
                            ; msgbox v " " A_LineNumber
                        }
                        Value := Val
                    case "TargetKeys":
                        Val := Array()
                        , Value := Value is Array ? Value : Array(Value)
                        For _, v in Value {
                            Val.Push(v)
                        }
                        Value := Val
                    case "TimeUp":
                        Value := this.process_TimeString(Value)
                    default:
                        If value is Object
                        {
                            err := ValueError(this.__parentKey "[" KeyName "] expects string, but got " Type(value), Type(this))
                                , msgbox(UDF.ErrorFormat(err))
                        }
                }
                Super[KeyName] := Value
            }
        }
    }

}

Class Strega_Watcher extends Watchdog_Base {
    History_CountThreshold := 500
    _encoding := "UTF-8"
    __New(PathsObj, TargetObj, objStoredTimestamp := StoredTimestamp()) {
        this.DefineProp("startUp", { Value: A_Now })
            , this.DefineProp("Count", { Value: { History: 0 } })
            ; , this.DefineProp("Watchers", { Value: PathsObj })
            ; , this.DefineProp("Targets", { Value: TargetObj })
            ; In case I need a pointer to the original Obj. Otherwise this should suffice
            , this.DefineProp("Watchers", { Value: PathsObj.Paths })
            , this.DefineProp("Targets", { Value: TargetObj.Targets })
            , this.DefineProp("Class", { Value: { watcher: PathsObj, target: TargetObj } })
            , this.DefineProp("storedTimestamp", { Value: objStoredTimestamp })
            , this.DefineProp("Ticks", { Value: Object() })

        return this
    }

    QPC(Counter := "", Decimals := 2) {
        If Counter = ""
        {
            DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
                , this.freq := freq
                , DllCall("QueryPerformanceCounter", "Int64*", &Counter := 0)
            return Counter
        }
        DllCall("QueryPerformanceCounter", "Int64*", &CounterAfter := 0)
        return Round((CounterAfter - Counter) / this.freq * 1000, Decimals)
    }

    LogFormat(Detail, Result, InfoType, Count, Time := A_Now) => Format("[{1}]{4}({2}){3}",
        Format("{}.{}", FormatTime(Time, "HH:mm:ss"), A_MSec),
        InfoType,
        ResultInfo := Detail = "" ? Result : Detail " ≡ " Result,
        !!Count ? Format("[{}]", Count) : ""
        )

    FormatSeconds(Input) {
        Time := 20000101 ;Arbitrary midnight of any date
            , Time := DateAdd(Time, Integer(Input), "Seconds")
        return (Input // 86400) " Days" FormatTime(time, " HH:mm:ss")
    }
    doProcedure() {
        this.procedureIndex += 1
        ; DisplayMap(this.Watchers, A_LineNumber)
        ; DisplayMap(this.Targets, A_LineNumber)
        ; * This will iterate over Paths.json[Paths].Watchers→Settings
        VarSetStrCapacity(&watcherTicks, 10000), totalTime := 0
        for Watcher, Settings in this.Watchers
        {

            ; ; * Due to the existence of _Watcher.Value.__parentKey I might not need the use of _Watcher.KeyName
            this.DefineProp("_Watcher", { Value: { KeyName: Watcher, Value: Settings } })
                , last_fileIndex := 0, last_sourceIndex := 0
            ; displaymap(this._Watcher.Value, A_LineNumber, 1)
            ; DisplayMap(Settings, A_LineNumber)
            ; * This will iterate over Paths.json["Paths"][Watchers]["Source"]→Array Values  ( Source Paths)
            for Source in this._Watcher.Value["Source"]
            {

                this.DefineProp("_loop", { value: { source: Source,
                    sourceIndex: A_Index,
                    conflicts: "",
                    fileIndex: "",
                    matchedFiles: 0,
                    matched_firstTargetPath: "",
                    matched_firstTargetKey: ""
                } }) ; * a way to access the current Source Path I'm iterating

                this.DefineProp("_loopDesc", { value: { source: "Access the current Iterating Source Path",
                    sourceIndex: "This leaves access to the current Source Index ",
                    conflicts: "This will help to find in case there're multiple target keys that matches the item. only if (conflicts.Length>1) is there a conflict",
                    fileIndex: "Access the current Index of the loop file",
                    matchedFiles: "Access the current amount of matched files in the iteration",
                    matched_firstTargetPath: "This will store the first target match of the file",
                    matched_firstTargetKey: "Stores the Target Key of the first match"
                } }) ; Descriptions of this._loop's properties
                    , this.Ticks.Folder := this.QPC()
                loop files this._loop.source, "F"
                {
                    this._loop.fileIndex := A_Index ; * So I can get access to the current file index that's in iteration
                        , this.store_FileInstance() ; * this is to store the Loop Files variables into an object
                    If this.fileMatch_Logic()
                        this.send_File()
                    last_fileIndex += 1
                }
                this.History := "`r`n" ; Logging Related - Adds a blank line to separate a Source Iteration
                    , last_sourceIndex += 1
            }
            ticks := this.QPC(this.ticks.Folder)
                , totalTime += ticks
                , watcherTicks .= A_Tab ticks "ms " Format("[p:{}]f:{} {}`r`n", last_sourceIndex, last_fileIndex, Watcher)
                , last_fileIndex := 0, last_sourceIndex := 0
        }
        SetListVars(this.History, 1)
        msgbox Round(totalTime, 2) "ms `r`n" watcherTicks
    }
    fileMatch_Logic() { ; * Tells whether the file matches the predefined conditions
        ; msgbox this._loop.source " `r`n" this.LF.fullName
        DisplayMap(this.Class.target["UserDefined"], A_LineNumber)
        If this._Watcher.Value["Age_asCountdown"] and (hasTimestamp := this.hasTimestamp())
        ; * If hasTimestamp registers as set, we can then know that we're working with a countdown, and that the timestamp has to be created.
        ; * If it's set, we just update the digital timestamp.
            If DateDiff(A_Now, this.get_StoredAge(), "s") <= this._Watcher.Value["TimeUp"] ; * If the file has a registered timestamp and it's below the TimeUp it will skip the file
                return 0
        ; msgbox UDF.getPropsList(this._Watcher, A_LineNumber)
        ; msgbox UDF.getPropsList(this.LF, A_LineNumber)
        this._loop.conflicts := [] ; * This will keep tracks cases when there're more than a single target match
        for TargetKey in this._Watcher.Value["TargetKeys"]
        {
            switch this.Targets[TargetKey].type, 0 {
                case "mixed":
                    fileName := this.LF.fullName
                case "Filetype":
                    fileName := this.LF.ext
                case "Keyword":
                    fileName := this.LF.name
            }
            match := 0
            For regKey in this.Targets[TargetKey].Targets
                match += !!RegExMatch(fileName, regKey)  ; * To know how many regex keys matches the filename
            if match
            {
                this._loop.conflicts.Push(TargetKey)
                if (this._loop.conflicts.Length = 1) ; * Code block that only runs for the first matching Watcher's TargetKey
                    this._loop.matched_firstTargetPath := this.Targets[TargetKey]["Target"],
                    this._loop.matched_firstTargetKey := TargetKey,
                    this._loop.regex_matches := match,
                    this.storedTimestamp[this._loop.source][this.LF.fullName] := A_Now
                ; * so If I'm not wrong, if I want to clean up unused Timestamps, I only have to compare if both StoreTimeStamp[][].Value == StoreTimeStamp[][].lastModified to know it didn't trigger
                ; * This method should let me know that the file no longer exists, and there's no use to keep it in system... Hopefully works as intended
            }
        }
        if !!this._loop.conflicts.Length
            this._loop.matchedFiles += 1
        return !!this._loop.conflicts.Length
    }
    hasTimestamp() => this.storedTimestamp.Has(this.LF.path) And this.storedTimestamp[this.__loop.source].Has(this.LF.fullName)

    get_StoredAge() => this.storedTimestamp[this.__loop.source][this.LF.fullName].Value

    process_StoredAge() {
    }

    send_File() {
        Target := this._loop.matched_firstTargetKey
        If this._loop.matchedFiles = 1 ; * This is to discriminate between the first match and subsequent ones.
            ; * It's purpose is to add a header to the list that will identify the start of logging data
            this.History["", "INFO", 0] := Format("{1}`r`n{4}{2}→RegExs:{3}",
                this._loop.source, this.Targets[Target].type, JXON.Dump(this.Targets[Target].Targets), A_Tab
            )
        if this._loop.conflicts.Length {
            if this._loop.conflicts.Length > 1
            {
                Conflicts := "`r`n" A_Tab "Conflicts:`r`n"
                for val in this._loop.conflicts
                    Conflicts .= A_Tab Val "`r`n"
            }
            this.History := Format("[{1}]{2}({3}){4}", this._loop.fileIndex, this.LF.fullName, this._loop.regex_matches, IsSet(Conflicts) ? Conflicts : "")
            ; msgbox UDF.getPropsList(this._loop, A_LineNumber) ; * This has the purpose of letting me know which properties are already occupied
        }

        msgbox UDF.getPropsList(this._loop, A_LineNumber)
        SourcePattern := Format("{}\{}", RTrim(this._loop.source, "*"), this.LF.fullName)
        DestPattern := this.process_CustomKeywords(Format("{}\", RTrim(this._loop.matched_firstTargetPath, "")), this.get_contextKeywords())
        if !FileExist(DestPattern)
            try
                DirCreate(DestPattern)
            catch Error as E
                msgbox UDF.ErrorFormat(E)
        msgbox "Source`r`n" "`r`n" SourcePattern "→" FileExist(SourcePattern) "`r`n" this.LF.fullPath "→" FileExist(this.LF.fullPath) "`r`nTarget" "`r`n" DestPattern "→" FileExist(DestPattern)
        FileCopy SourcePattern, DestPattern "\*.*", 0
        pause
        ; this.History["Target: " this._loop.]
    }

    get_contextKeywords() {
        ; Registered ~06.65E-3ms per call using Arrow Function 2023/04/23
        ; Registered ~13.65E-3ms per call using strings 2023/04/23
        temp := this.LF.timeModified,
            myMap := Map(),
            myMap.CaseSense := "Off",
            myMap.Set(
                "YearMonth", FormatTime(temp, "YearMonth"),
                "YDay", FormatTime(temp, "YDay"),
                "YDay0", FormatTime(temp, "YDay0"),
                "WDay", FormatTime(temp, "WDay"),
                "YWeek", FormatTime(temp, "YWeek"),
                "d", FormatTime(temp, "d"),
                "dd", FormatTime(temp, "dd"),
                "ddd", FormatTime(temp, "ddd"),
                "dddd", FormatTime(temp, "dddd"),
                "M", FormatTime(temp, "M"),
                "MM", FormatTime(temp, "MM"),
                "MMM", FormatTime(temp, "MMM"),
                "MMMM", FormatTime(temp, "MMMM"),
                "y", FormatTime(temp, "y"),
                "yy", FormatTime(temp, "yy"),
                "yyyy", FormatTime(temp, "yyyy"),
            )
            ; myMap.Set(
            ;     "YearMonth", () => FormatTime(temp, "YearMonth"),
            ;     "YDay", () => FormatTime(temp, "YDay"),
            ;     "YDay0", () => FormatTime(temp, "YDay0"),
            ;     "WDay", () => FormatTime(temp, "WDay"),
            ;     "YWeek", () => FormatTime(temp, "YWeek"),
            ;     "d", () => FormatTime(temp, "d"),
            ;     "dd", () => FormatTime(temp, "dd"),
            ;     "ddd", () => FormatTime(temp, "ddd"),
            ;     "dddd", () => FormatTime(temp, "dddd"),
            ;     "M", () => FormatTime(temp, "M"),
            ;     "MM", () => FormatTime(temp, "MM"),
            ;     "MMM", () => FormatTime(temp, "MMM"),
            ;     "MMMM", () => FormatTime(temp, "MMMM"),
            ;     "y", () => FormatTime(temp, "y"),
            ;     "yy", () => FormatTime(temp, "yy"),
            ;     "yyyy", () => FormatTime(temp, "yyyy"),
            ; )
            , myMap.Set("Year", myMap["yyyy"], "Month", myMap["MM"], "Mon", myMap["MM"], "Day", myMap["dd"])
        return myMap
    }

    store_FileInstance() {
        SplitPath A_LoopFileFullPath, &FullName, &Path, &Ext, &name
        fileObj := Object()
            , fileObj.fullName := FullName, fileObj.ext := Ext
            , fileObj.name := name
            , fileObj.fullPath := A_LoopFileFullPath, fileObj.path := Path
            ; , fileObj.timeAccess := A_LoopFileTimeAccessed ; * Commented out because I don't know if storing this equals to a read instance of the file
            , fileObj.timeModified := A_LoopFileTimeModified
        ; , fileObj.timeCreated:=A_LoopFileTimeAccessed ; * Commented out because I don't know if storing this equals to a read instance of the file
        this.DefineProp("LF", { value: fileObj })
    }
    Dump(content, file := A_ScriptDir "\logs.txt", Encryption := this._encoding, overwrite := 0) { ; Dumps history into the file
        ;* Unfinished
    }
    procedureIndex {
        set {
            this._procedureIndex := value
        }
        get {
            try
                return this._procedureIndex
            catch
                return this.procedureIndex := 0
        }
    }
    History[Detail := "", InfoType := "LOG", CountStep := 1, Dump := 0] {
        set {
            if Value = "`r`n"
            {
                this._History := this.History "`r`n"
                return
            }
            this.Count.History += CountStep
                , this._History := this.History this.LogFormat(Detail, Value, InfoType, !!CountStep ? this.Count.History : 0)

            if (!Dump and (Mod(this.Count.History, this.History_CountThreshold) and this.Count.History >= 0)) or this.Count.History = 0
                return
            msgbox "dumping " . Format(this.Count.History "){1}={2}`r`n{3}", Mod(this.Count.History, this.History_CountThreshold), this.Count.History >= 0, !Dump and (Mod(this.Count.History, 50) and this.Count.History >= 0))
            this.Dump(this.History),
                this._History := ""
        }
        get {
            try
                return this._History
            catch
                return this._History := Format("[{}]`r`n",
                    FormatTime(A_Now, "yyyy/MM/dd HH:mm:ss")
                )

        }
    }

}

Class StoredTimestamp extends Watchdog_Base {
    __New(Path := "", type := "Text", encoding := this._encoding) {
        if (Path = "") ; this is for in case there's no data stored, so we skip all this below
            return this
        this.DefineProp("__path", { Value: StrLen(path) })
            , this.DefineProp("__fileLastModified", { Value: FileGetTime(Path, "M") })
            , JsonMap := this.transformString(Path, Type, encoding)
        for k_Path, v_Files in JsonMap
            for k_Files, v_storedTimeStamp in v_Files
                this[k_Path] := StoredTimestamp.File(k_Files, {
                    Value: A_Now,
                    stored: v_storedTimeStamp,
                    lastModified: this.__fileLastModified
                })
        return this
    }
    __Item[keyName] {
        get {
            keyName := Trim(keyName, " \")
            if this.Has(keyName)
                return super[keyName]
            newInst := StoredTimestamp.File().DefineProp("_pathName", { Value: KeyName }) ; * If the key didn't exist previously, it will create a key that contains an empty instance of StoredTimestamp.File
            return this[KeyName] := newInst
        }
        set {
            if !(Value is StoredTimestamp.File)
                throw ValueError(Format("{}[{}] expects {}, but got {}!", Type(this), keyName, Type(this) ".File", Type(Value)))
            keyName := Trim(keyName, " \")
            Value._pathName := keyName
            super[keyName] := Value
        }
    }

    Dump(inputMap, path := this.__path) {
        tempMap := Map()
        for k_Path, v_Files in inputMap
            for k_Files, v_other in v_Files
                tempMap.Set(k_path, Map(k_Files, inputMap[k_Path][k_Files].Value))
        if !FileExist(path) {
            DisplayMap(tempMap, A_LineNumber, 1)
            throw ValueError(Format("There's no valid path to dump values in {}", Type(this)), , path)
        } else DisplayMap(tempMap, A_LineNumber, 1)
        FileOpen(path, 0x1, this._encoding).Write(JXON.dump(tempMap, 1))
    }
    ; { Inner Classes

    Class File extends Map {

        __Item[keyName] {
            get {
                if !this.Has(keyName)
                    super[KeyName] := { Value: A_Now }
                return super[keyName]
            }
            set {
                if !IsNumber(Value)
                    throw ValueError(Format("{}[{}] Expects a Number, but got " Type(Value), Type(this), keyName), , Format("[{}][{}]", this._pathName, keyName)) ; Test with StoredTimestamp["C:\???"]["myfile.ahk"] := {}
                this[keyName].Value := Value
                ; * Value stores the digital timestamp. It means that the latest timestamp is here
                super[keyName] := this[keyName]
            }
        }
    }

}