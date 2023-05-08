#Requires AutoHotkey v2.0
#Include <StoredTimestamp>

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

    Append(stringText, path, encoding := this._encoding) => FileOpen(path, 0x2, encoding).Write(stringText)

    cloneMap(InputMap) { ; Still experimenting if it works
        Val := InputMap.Clone()
        { for k, v in Val
            {
                if (v is Object)
                    val[k] := this.cloneMap(v)
            } }
        return Val
    }

    Dump(stringText, path, encoding := this._encoding) {
        myFile := FileOpen(path, 0x2, encoding)
            , myFile.Seek(0, 0), myFile.Write(stringText), myFile.Length:= myFile.Pos

    }

    getMap(Input, validProps := ["Value"], level := 1, cap := 10) {
        tempMap := Map()
        if Input is Map
        {
            For k, v in Input ; Gives priority to Map's data.
            {
                If (isObj := IsObject(v)) && (level < cap)
                    v := this.getMap(v, validProps, level + 1)
                else if level >= cap && isObj
                    v := Type(v)
                tempMap.Set(k, v)
            }
        }
        else
            for prop, v in Input.OwnProps()
            {
                If (isObj := IsObject(v)) && (level < cap)
                    v := this.getMap(v, validProps, level + 1)
                else if (level >= cap && isObj)
                    v := Type(v)
                if (validProps = "All")
                    tempMap.Set(prop, v)
                Else
                    for validName in validProps
                        if (prop = validName)
                        {
                            if validProps.Length = 1
                                tempMap := v
                            else
                                tempMap.Set(prop, v)
                        }
            }
        return tempMap
    }
    InQuote(Input, chars := "`"") => chars Input chars

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
        else if Path is Map
            Return Path
        else if Type = "File" or "Path"
            JsonString := fileread(Path, encoding)
                , this.DefineProp("__path", { Value: Path }) ; It means that this.__path stores the string path that was used to retrieve the file.
        else if Type = "Text"
            JsonString := Path
        else
            throw ValueError("No matching data? Expects a path, Map string, but registered " Type, Type(this))
        return JXON.Load(JsonString)
    }
    hasChanges {
        set => this.__hasChanges:=this.hasChanges + (!!Value)
        get{
            try 
                return this.__hasChanges
            catch
                return 0
        }
    }
}

Class TargetFile extends Watchdog_Base {
    __New(Path, type := "Text", encoding := this._encoding) {
        this.DefineProp("__path", { Value: A_WorkingDir "\configs\Targets.json" })
        if FileExist(Path)
            this.DefineProp("__path", { Value: Path })
        if FileExist(this.__path)
            this.DefineProp("__fileLastModified", { Value: FileGetTime(this.__path, "M") })
        JsonMap := this.transformString(Path, Type, encoding)
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
                    ; msgbox "R:>" SubPat[2] "<"
                    ; RegEx.Push({ RegEx: SubPat[1], Replace: SubPat[2] })
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
        this.DefineProp("__path", { Value: A_WorkingDir "\configs\Paths.json" }) ; By defining a default path, I can initialize an empty instance and be able to store the changes
        if FileExist(Path)
            this.DefineProp("__path", { Value: Path })
        if FileExist(this.__path)
            this.DefineProp("__fileLastModified", { Value: FileGetTime(this.__path, "M") })
        JsonMap := this.transformString(Path, Type, encoding)
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
    __New(PathsObj, TargetObj, fileDataWrapper := Wrapper_FileData(A_WorkingDir "\configs\Timestamps.json")) {
        this.DefineProp("startUp", { Value: A_Now })
            , this.DefineProp("Count", { Value: { History: 0 } })
            ; , this.DefineProp("Watchers", { Value: PathsObj })
            ; , this.DefineProp("Targets", { Value: TargetObj })
            ; In case I need a pointer to the original Obj. Otherwise this should suffice
            , this.DefineProp("Watchers", { Value: PathsObj.Paths })
            , this.DefineProp("Targets", { Value: TargetObj.Targets })
            , this.DefineProp("Class", { Value: { watcher: PathsObj, target: TargetObj } })
            , this.DefineProp("Wrapper_Ts", { Value: fileDataWrapper })
            , this.DefineProp("storedTimestamp", { Value: fileDataWrapper[fileDataWrapper.TimestampWrapper] })
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
            ; displaymap(this._Watcher.Value, A_LineNumber, 1)
            ; DisplayMap(Settings, A_LineNumber)
            ; * This will iterate over Paths.json["Paths"][Watchers]["Source"]→Array Values  ( Source Paths)
            this.DefineProp("_loop", { value: { source: "",
                sourceIndex: 0,
                conflicts: [],
                fileIndex: 0,
                totalFiles: 0,
                pastMatchedFiles: 0,
                matchedFiles: 0,
                matched_firstTargetPath: "",
                matched_firstTargetKey: "",
                matchingThreshold: 5,
                regex_matches: 0,
                regEx: []
            } }) ; * Data that's related to the current iterating _loop
            if false ; This skips the step of having it getting set. I keep it uncommented just for the sakes of keeping the formatting in the code editor
                this.DefineProp("_loopDesc", { value: { source: "Access the current Iterating Source Path",
                    sourceIndex: "This leaves access to the current Source Index. Depending on where yo ucall, you might as well call it the last index of the iteration",
                    conflicts: "This will help to find in case there're multiple target keys that matches the item. only if (conflicts.Length>1) is there a conflict",
                    fileIndex: "Access the current Index of the loop file. Depending on where you call, you might as well call it the last index of the iteration",
                    totalFiles: "Stores the total files that the program has already iterated in the Watcher. However, its increments goes by n Amount, where n is the amount a Watcher's source path has been gone through",
                    pastMatchedFiles: "Stores the last matchedFiles iteration amount ",
                    matchedFiles: "Access the current amount of matched files in the iteration",
                    matched_firstTargetPath: "This will store the first target match of the file",
                    matched_firstTargetKey: "Stores the Target Key of the first match",
                    matchingThreshold: "This describe the amounts of matched files it requires to let it add separation lines for readability",
                    regex_matches: "Stores how many regEx keys matched",
                    regEx: "Stores the regex keys that matched"
                } }) ; Descriptions of this._loop's properties
            this.Ticks.Watcher := this.QPC()
            ticks := 0
            for Source in this._Watcher.Value["Source"]
            {

                this._loop.source := Source
                    , this._loop.sourceIndex := A_Index
                    , this._loop.matchedFiles := 0
                    , this.Ticks.Folder := this.QPC()
                loop files this._loop.source, "F"
                {
                    this._loop.fileIndex := A_Index ; * So I can get access to the current file index that's in iteration
                        , this.store_FileInstance() ; * this is to store the Loop Files variables into an object
                    If this.fileMatch_Logic()
                        this.send_File()
                }

                temp := this.QPC(this.Ticks.Folder)
                    , ticks := Round(ticks + temp, 2)
                    , this._loop.totalFiles += this._loop.fileIndex
                    , this._loop.pastMatchedFiles := this._loop.matchedFiles

                If this._loop.matchedFiles > this._loop.matchingThreshold
                    this.History[, "INFO", 0] := Format("Total Matching Files: {}`r`n`tTime:{}ms, avg. {}ms/File`r`n"
                        , this._loop.matchedFiles
                        , Temp
                        , Round(temp / this._loop.fileIndex, 3))
            }
            totalTime += ticks
                , watcherTicks .= A_Tab ticks "ms " Format("[p:{}]f:{} {}`r`n", this._loop.sourceIndex, this._loop.totalFiles, Watcher)
                , (this._loop.matchedFiles > 0) ? this.History[, ""] := "`r`n" : ""
        }
        text := ""
        ; DisplayMap(this.getMap(this.storedTimestamp), A_LineNumber, 1)
        ; DisplayMap(this.getMap(this.Wrapper_Ts), A_LineNumber, 2)
        this.Wrapper_Ts.Dump()
        if true
        { for key, val in this.storedTimestamp.clone()
            for key2, val2 in val.clone()
                text .= Format("{}{} = {}`r`n", rTrim(key, '* '), key2, val2.Value)
            SetListVars(text "`r`n" this.History "`r`n`r`n" Round(totalTime, 2) "ms `r`n" watcherTicks)
            ; msgbox Round(totalTime, 2) "ms `r`n" watcherTicks
        }
    }

    fileMatch_Logic() { ; * Tells whether the file matches the predefined conditions
        ; msgbox this._loop.source " `r`n" this.LF.fullName
        If this._Watcher.Value["Age_asCountdown"] and (hasTimeStamp := this.hasTimestamp())
        ; * If hasTimestamp registers as true, we can then know that we're working with a countdown, and that the timestamp already exists.
        ; * Otherwise, if we detect that hasTimeStamp is false, we will return false after creating the timestamp
            If DateDiff(A_Now, digitalTimeStamp := this.get_StoredAge(), "s") <= this._Watcher.Value["TimeUp"] ; * If the file's digital timestamp is below the TimeUp it will skip the file
                return 0
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
            match := []
            For regKey in this.Targets[TargetKey].Targets
                If RegExMatch(fileName, regKey)
                    match.Push(regKey)  ; * To know how many regex keys matches the filename
            if match.Length
            {
                this._loop.conflicts.Push(TargetKey)
                if (this._loop.conflicts.Length = 1) ; * Code block that only runs for the first matching Watcher's TargetKey
                {
                    this._loop.matched_firstTargetPath := this.Targets[TargetKey]["Target"],
                    this._loop.matched_firstTargetKey := TargetKey,
                    this._loop.regex_matches := match.Length,
                    this._loop.regEx := match
                    If IsSet(digitalTimeStamp)
                        this.storedTimestamp[this.LF.path].Delete(this.LF.fullName)
                    else
                        this.storedTimestamp[this.LF.path][this.LF.fullName] := A_Now
                    if IsSet(hasTimeStamp) and !hasTimeStamp
                        return False
                }
                ; * so If I'm not wrong, if I want to clean up unused Timestamps, I only have to compare if both StoreTimeStamp[][].Value == StoreTimeStamp[][].lastModified to know it didn't trigger
                ; * This method should let me know that the file no longer exists, and there's no use to keep it in system... Hopefully works as intended
            }
        }
        if !!this._loop.conflicts.Length
            this._loop.matchedFiles += 1
        return !!this._loop.conflicts.Length
    }

    hasTimestamp() => this.storedTimestamp.Has(this.LF.path) And this.storedTimestamp[this.LF.path].Has(this.LF.fullName)

    get_StoredAge() => this.storedTimestamp[this.LF.path][this.LF.fullName].Value

    process_StoredAge() {
    }

    send_File() {
        Target := this._loop.matched_firstTargetKey
        If this._loop.matchedFiles = 1 ; * This is to discriminate between the first match and subsequent ones.
            ; * It's purpose is to add a header to the list that will identify the start of logging data
        { if this._loop.sourceIndex > 1 and this._loop.pastMatchedFiles > 2
            this.History[, ""] := stringJoin("-", 50) "`r`n"
            ; this.History["", "INFO", 0] := Format("{1}`r`n{4}{2}→RegExs:{3}`r`n",
            ;     this._loop.source, this.Targets[Target].type, JXON.Dump(this.Targets[Target].Targets), A_Tab
            ; )
        }
        if this._loop.conflicts.Length > 1
        {
            Conflicts := Format("`r`n" A_Tab "Conflicts({}): ", this._loop.conflicts.Length)
            for val in this._loop.conflicts
                Conflicts .= Format("{}, ", val)
            Conflicts := RTrim(Conflicts, ", ")
        }
        SourcePattern := Format("{}\{}", RTrim(this._loop.source, "\\*"), this.LF.fullName)
        DestPattern := this.process_CustomKeywords(Format("{}\", RTrim(this._loop.matched_firstTargetPath, "")), this.get_contextKeywords())
        source_Dest := SourcePattern " → " DestPattern "*.*"
        this.History := Format("[{1}]{6}{2}[{3}]{4}`r`n"
            , this._loop.fileIndex
            , " "
            , source_Dest
            , IsSet(Conflicts) ? Conflicts : ""
            , JXON.Dump(this._loop.regEx)
            , Format("T[`"{}`"]", this.Targets[Target].__parentKey)
        )

        if !FileExist(DestPattern)
            try
                DirCreate(DestPattern)
            catch Error as E
                msgbox UDF.ErrorFormat(E)
        ; msgbox "Source`r`n" "`r`n" SourcePattern "→" FileExist(SourcePattern) "`r`n" this.LF.fullPath "→" FileExist(this.LF.fullPath) "`r`nTarget" "`r`n" DestPattern "→" FileExist(DestPattern)
        ;FileCopy SourcePattern, DestPattern "\*.*", 0

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
    Dump(content, file := A_WorkingDir "\logs.txt", Encryption := this._encoding, overwrite := 0) { ; Dumps history into the file
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
            if (InfoType = "")
            {
                this._History := this.History (Detail = "" ? "" : Detail "→") Value
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