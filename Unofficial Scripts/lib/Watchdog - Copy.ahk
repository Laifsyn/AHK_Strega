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
    process_invalidKeywords(Input) => RegExReplace(Input, "i)(<|>)", "")

    renameKey(baseObject, OldKey, NewKey) {
        baseObject[NewKey] := baseObject[OldKey]
            , baseObject.Delete(OldKey)
    }

    transformString(Path, Type, encoding) { ; To transform a string path into a possibly JSON String
        if Path is file
        {
            JsonString := Path.read()
            Try
                Path.Close()
            catch as E
            {
                msgbox(E.What)
                return
            }
        }
        else if Type = "File"
            JsonString := fileread(Path, encoding)
                , this.DefineProp("__path", { Value: Path })
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
            , this.Targets := TargetFile.Configs(this["Targets"], this) ; This will leave an un-edited version of this["Targets"]
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
                    RegEx.Push(Val)
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
            , this.Paths := WatchFile.Configs(this[WatcherConfigs], this) ; This will leave an un-edited version of this["Paths"]

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
                            if InStr(v, ";", , (-StrLen(v)))
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

Class Strega_Watcher {
    History_CountThreshold := 50
    __New(PathsObj, TargetObj) {
        this.DefineProp("startUp", { Value: A_Now })
            ; , this.DefineProp("Watchers", { Value: PathsObj })
            ; , this.DefineProp("Targets", { Value: TargetObj })
            ; In case I need a pointer to the original Obj. Otherwise this should suffice
            , this.DefineProp("Watchers", { Value: PathsObj.Paths })
            , this.DefineProp("Targets", { Value: TargetObj.Targets })
            , DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
            , this.freq := freq
            , this.DefineProp("Ticks", { Value: Object() })

        return this
    }

    QPC(Counter := "", Decimals := 2) {
        If Counter = ""
        {
            DllCall("QueryPerformanceCounter", "Int64*", &Counter := 0)
            return Counter
        }
        DllCall("QueryPerformanceCounter", "Int64*", &CounterAfter := 0)
        return Round((CounterAfter - Counter) / this.freq * 1000, Decimals)
    }

    LogFormat(Detail, Result, InfoType, Time := A_Now) => Format("[{1}]({2}){3}",
        Format("{}.{}", FormatTime(Time, "HH:mm:ss"), A_MSec)
        InfoType,
        ResultInfo := Detail = "" ? Result : Detail " ≡ " Result
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
        for Watcher, Settings in this.Watchers
        {
            ; ; * Due to the existence of _Watcher.Value.__parentKey I might not need the use of _Watcher.KeyName
            this.DefineProp("_Watcher", { Value: { KeyName: Watcher, Value: Settings } })
            ; displaymap(this._Watcher.Value, A_LineNumber, 1)
            ; DisplayMap(Settings, A_LineNumber)
            ; * This will iterate over Paths.json["Paths"][Watchers]["Source"]→Array Values  ( Source Paths)
            for Source in this._Watcher.Value["Source"]
            {
                this.Ticks.Folder := this.QPC()
                loop files Source, "F"
                {
                    this.store_FileInstance() ;this is to store the Loop Files variables into an object
                    msgbox this.FormatSeconds(DateDiff(A_Now, this.LF.timeModified, "s"))
                }

            }
        }
    }
    store_FileInstance() {
        fileObj := Object()
            , fileObj.fullName := A_LoopFileName, fileObj.ext := A_LoopFileExt
            , fileObj.name := RegExReplace(fileObj.fullName, "\..*$", "")
            , fileObj.fullPath := A_LoopFileFullPath, fileObj.path := A_LoopFileDir
            ; , fileObj.timeAccess := A_LoopFileTimeAccessed ; * Commented out because I don't know if storing this equals to a read instance of the file
            , fileObj.timeModified := A_LoopFileTimeModified
        ; , fileObj.timeCreated:=A_LoopFileTimeAccessed ; * Commented out because I don't know if storing this equals to a read instance of the file
        this.DefineProp("LF", { value: fileObj })
    }
    Dump(content) {

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
            Static Count := 0
            Count += CountStep
                , this._History := this.History this.LogFormat(Detail, Value, InfoType "[" Count "]")

            if !Dump and (Mod(Count, 50) and Count > 0)
                Return
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

WatchPaths := ""
PathTargets := ""
Watchdog(InputTime := "") {

    Global PathTargets, WatchPaths, _rn
    Static Index := 0, watchDog_Data := UDF.Map("StartTime", InputTime)
    Start_Tick := A_TickCount
    ;tooltip, % Format("StartTime:{}, Index:{}",Watchdog_Data.StartTime.tick , Index), 0, 0, 1
    Index += 1
        , WP_Index := 0, Warnings := "", DebugText := ""

    For Key, Paths in WatchPaths["Paths"] {

        WP_Index += 1
        If Paths["Skip"]
        {
            Continue
        }
        Text .= Format("PathName:[{}]`r`n", Key)
        Paths := S_RefineWatchPaths(Key, Paths)

        For WatchSource_Index, Name in Paths["Source[asArray]"]
        {
            WarningText := UDF.Map()
            Text .= "[" Name "]`r`n"
            If !FileExist(Name)
            { Warnings .= LogFormat(Format("Unknown Source Path! [{1}]", Name), "WARNING", Format("{1}:`"{}`".{}", A_LineNumber, Key, A_Index))
                Format(".{}", _rn)
                Continue
            }
            Loop Files Name, "F"
            {
                FileData := S_LoopFileData(Paths)
                WarningText := S_ProcessFile_to_Target(Paths, FileData, Key)
                DebugText .= WarningText["Text"]
            }
            Warnings .= WarningText["Warning"]
            DebugText := Paths["SourceName"] "[" Name "]`r`n" DebugText
        }
        Text .= _rn _rn
    }
    DebugText := "", Text := ""
    If DebugText
        SetListVars("Debugs Text`r`n" DebugText, 1)
    If (Warnings and A_Index < 2)
        SetListVars(Format("{1}{3}`r`n`tThis Run Summary:`r`n{2}{4}ms to Process a first iteration", FormatTime(A_Now, "[yyyy/MM/dd HH:mm:ss.ms]"), Warnings, "", A_TickCount - Start_Tick), 1)
    If Text
        SetlistVars(Text, 1)
    SetlistVars(MyText _rn A_LineNumber, 1)
    pause
    SetTimer Watchdog, -1000
}

ListParse(InputObject := "") { ; Parse a list of Strings in the next format "String1|String2|String3|....|StringN"
    For Key, Val in InputObject
    { if (Key = 1)
        Delimiter := ""
        else
            Delimiter := "|"
        Output .= Delimiter Val
    }
    return Output
}
S_getFileAge(I_Object, FilePattern) {
    ;define Section, and Keys.

    ; I_Object["File_Age"]:=I_Object["isAgeCountdown"]?S_getOrCreate_TimeMark(FileData,Format("{}\Files Data.ini",A_ScriptDir))
    ;DisplayMap(I_Object,A_LineNumber)
    If !I_Object["isAgeCountdown"]
        Age := I_Object["Time"]["LastModified"]
    else
    {
        /*
        	Age:=UDF.IniRead(FilePattern, I_Object["SourceName"]
        	, RegExReplace(I_Object["FullPath"],"=","``|") ; KeyName
        	, "N/A", A_Now)
        */
        ; I noticed that this Method of reading and defining file age is possibly terrible. I'll try to remember finish this some other day
        ; Some Source to consider: https://gist.github.com/anonymous1184/737749e83ade98c84cf619aabf66b063
        ; https://www.reddit.com/r/AutoHotkey/comments/s1it4j/automagically_readwrite_configuration_files/
        ;Age:=UDF.IniRead(FilePattern, I_Object["SourceName"],I_Object["FullPath"] "=ASAS", "N/A")
        Age := 0
    }

    ;	Msgbox !I_Object["isAgeCountdown"] _rn Age _rn A_LineNumber _rn "Finished ?"
    ;DisplayMap(I_Object,A_LineNumber)


    I_Object["Age"] := DateDiff(A_Now, Age, "s")
        , I_Object["DetailedAge"] := FormatSeconds(I_Object["Age"])
    ;UDF.IniRead(Filename, Section :="" ,Key :="" , Default:="" , Auto:="")
    ;Time:=UDF.IniRead(FilePattern, )
    return I_Object
}
S_LoopFileData(I_Object) {
    RegExMatch(A_LoopFileName, "(?P<Name>.*)\." A_LoopFileExt "?", &SubPat)
    Local Map
    Map := UDF.Map()
    Map["Extension"] := A_LoopFileExt
        , Map["SourceName"] := I_Object["SourceName"]
        , Map["isAgeCountdown"] := I_Object["Age_asCountdown"]
        , Map["Name"] := SubPat[1]
        , Map["FullName"] := A_LoopFileName
        , Map["FullPath"] := A_LoopFileFullPath
        , Map["Path"] := A_LoopFileDir "\"
        , Map["Time"] := UDF.Map()
        , Map["Time"]["LastModified"] := A_LoopFileTimeModified
        , Map["Time"]["LastModified_Month"] := FormatTime(A_LoopFileTimeModified, "MM")
        , Map["Time"]["LastModified_Year"] := FormatTime(A_LoopFileTimeModified, "yyyy")
        , Map["Time"]["LastModified_Day"] := FormatTime(A_LoopFileTimeModified, "dd")
        , Map["Time"]["TimeCreated"] := A_LoopFileTimeCreated
        , Map["Time"]["TimeCreated_Month"] := FormatTime(A_LoopFileTimeCreated, "MM")
        , Map["Time"]["TimeCreated_Year"] := FormatTime(A_LoopFileTimeCreated, "yyyy")
        , Map["Time"]["TimeCreated_Day"] := FormatTime(A_LoopFileTimeCreated, "dd")
    return Map
}
S_RefineWatchPaths(Key, Paths) {
    ;Key is the WatchPaths[NKey] Pointer, whereas
    Global WatchPaths

    if (!Paths["processedTimeUp"]) {
        For ArrIndex, Value in Paths["Source[asArray]"]
        { 	;If !RegExMatch(Value, "(<|>)")
            ;	Continue
            ;; Just in case so I know to try this IF Condition to improve performance, even if minimally
            if !(Value ~= "\\\*?$")
                Value := Value "\"
            if (Value ~= "\\$")
                Value := Value "*"

            Paths["Source[asArray]"][ArrIndex] := S_ProcessPathKeywords(Value)

        }

        SubMap := S_TimeTextFormat_to_Seconds(Paths["TimeUp"])
        Paths["TimeUp"] := SubMap["TimeUp"]
            , Paths["TimeInfo"] := SubMap["TimeInfo"]
            , Paths["processedTimeUp"] := 1
            , WatchPaths["Paths"][Key] := Paths
    }
    Paths["SourceName"] := Key

    Return Paths
}

S_RefineTargetPath(InputString, I_Object, TargetObject := "") {
    Global PathTargets
    Target_DateKeys := ListParse(PathTargets["DateKeys"])
    Target_DateKeys := RegExReplace(Target_DateKeys, "<|>", "") ; Target_DateKeys := "<Year>|<Month>|<Day>"
    DateType := PathTargets["FileDateType"]
    OdInput := InputString
    While (InputString ~= "i)<(" Target_DateKeys ")>")
    { RegExMatch(InputString, "i)(" Target_DateKeys ")", &SubPat)
        InputString := RegExReplace(InputString, "<" SubPat[1] ">", I_Object["Time"][Format("{}_{}", DateType, SubPat[1])])

    }
    InputString := S_ProcessPathKeywords(InputString)

    If !RegExMatch(InputString, "\\$")
        InputString .= "\"

    Return InputString
}


/*



*/
S_ProcessFile_to_Target(Paths, FileData, Name := "") {
    Global PathTargets
    Local Text := ""
    For Index, TargetKey in Paths["TargetKeys"] {
        Target := PathTargets[TargetKey]
        If !Target
        { Warning .= LogFormat(Format("There's no such Key: `"{1}`"", TargetKey), "WARNING", Format("{1}:`"{}`" {}", A_LineNumber, Name, A_Index))
            Continue
        }
        If ((FileExist(DestPattern := S_RefineTargetPath(Target["Target"], FileData, Target)) != "D")
            and !(Target["Target"] ~= ("i)" ListParse(PathTargets["DateKeys"])))) ; It skips current iteration if the TargetPath either doesn't exists, or isn't a Variadic Target
        {
            Warning .= LogFormat(Format("Unknown Target Path! [{}]", DestPattern), "WARNING", Format("{1}:{}[`"{}`"]", A_LineNumber, Name, TargetKey))
            Continue
        }

        If Target
            Switch Target["Type"], 0
            {
                case "Keyword":
                    ;RegExList:= "i)(" ListParse(Target["Key"]) ")"
                    ;If !( FileData["Name"] ~=  RegExList )
                    ;	Continue
                    MatchObject := FileData["Name"]
                case "FileType":
                    ;RegExList:= "i)(" ListParse(Target["Key"]) ")"
                    ;If !( FileData["Extension"] ~= RegExList )
                    ;	Continue
                    MatchObject := FileData["Extension"]
                Default:
                    Warning .= LogFormat("UNKNOWN KEY!: `"" Target["Type"] "`" from " Paths["SourceName"] " in `"" TargetKey "`"", "WARNING", Format("{1}:`"{}`" {}", A_LineNumber, Name, A_Index))
                    Continue
            }

        ParsingResult := 0
        For Index, Value in Target["Key"]
        { If (RegExMatch(Value, "i)R/(.*)/", &SubPat))
            { ParsingResult += RegExMatch(FileData["FullName"], SubPat[1]) ? 1 : 0
                Continue
            }
            ParsingResult += (MatchObject ~= "i)" Value) ? 1 : 0 ; Hopefully this method is faster compared to using If Condition
        }
        If !(ParsingResult)
            continue
        ;DestPattern:= "C:\Temp - AHK\Test\Targets\"

        If !FileExist(DestPattern)
            DirCreate(RegExReplace(DestPattern, "\*$", ""))
        FileSource := FileData["FullPath"]
        ;FileSource:="C:\Temp - AHK\Test\New Microsoft Word Document.docx"

        ;DestPattern:= DestPattern
        ;SetlistVars(FileSource "`r`n" DestPattern)

        FileData := S_getFileAge(FileData, Format("{}\logs\Files Data.ini", A_ScriptDir))
        ;ToDelete: FileData["File_Age"]:=FileData["isAgeCountdown"]?S_getOrCreate_TimeMark(FileData,Format("{}\Files Data.ini",A_ScriptDir)):FileData["Time"]["LastModified"]
        ; Defines the Age(in seconds) of the file. In these 2 cases, we will either
        ; obtain the age in terms of since the file was modified, vs the age in terms of
        ; when it was first "found" by the script
        DisplayMap(FileData, A_LineNumber)

        WhileIndex := 0, ErrorCount := 0, Subfix := ""
        While WhileIndex <= 256
        {
            WhileIndex := A_Index
            If ErrorCount > 1
                Subfix := Format("* {1} ({2}).*", FormatTime("[yyyy.MM.dd HH.mm.ss]", FileData["Time"][PathTargets["FileDateType"]]), ErrorCount - 1)
            else if ErrorCount
                Subfix := Format("* {1}.*", FormatTime("[yyyy.MM.dd HH.mm.ss]", FileData["Time"][PathTargets["FileDateType"]]))
            try
            {
                ;FileMove(FileSource,DestPattern Subfix)
                ;Global myText.=(
                ;	A_LineNumber ")`r`nAttempts:" ErrorCount _rn FileSource _rn DestPattern Subfix _rn _rn )
                Global myText .= Format("
								( LTrim Join
								{1} ") `r`n
								{5} Attempts:" {2}`r`n 
								{5} {3} ->`r`n
								{5} {4}

							)", A_LineNumber, ErrorCount, FileSource, DestPattern Subfix, A_Tab) _rn
    Break
        }
            catch as E
                ErrorCount += 1

        }

        ;					msgbox "Continue? " _rn A_LineNumber
    }

    OutputText := UDF.Map()
    OutputText["Warning"] := Warning
    OutputText["Text"] := Text
    Return OutputText
}
; Value is Path as String
S_ProcessPathKeywords(Value, SupportedKeyWords := "A_(Username|Y(YYY|Day|Week)|M{2,4}|D{2,4}|WDay|Desktop|ComputerName|AppData|MyDocuments|Mon)")
{
    While (Value ~= "i)<.*>")
    {
        Try
        { RegExMatch(Value, "i)<(" SupportedKeyWords ")>", &SubPat)
            Value := RegExReplace(Value, "i)<(" SubPat[1] ")>", %SubPat[1]%)
        }
        catch ; Once there's no more matches, the Try Block seems to Spook out and I can simply just remove the invalids "<Keyplace>" from the Source Paths
        { Value := RegExReplace(Value, "i)(<|>)", "")
            Break
        }
    }
    Return Value
}

S_TimeTextFormat_to_Seconds(Time_asString) {
    vMap := UDF.Map("TimeInfo", Map())

    vMap["TimeInfo"]["Months"] := RegExMatch(Time_asString, "((?<Months>\d+)[M])", &Months) ? Months[2] : 0
        , vMap["TimeInfo"]["Days"] := RegExMatch(Time_asString, "((?<Months>\d+)[Dd])", &Days) ? Days[2] : 0
            , vMap["TimeInfo"]["Hours"] := RegExMatch(Time_asString, "((?<Months>\d+)[Hh])", &Hours) ? Hours[2] : 0
                , vMap["TimeInfo"]["Minutes"] := RegExMatch(Time_asString, "((?<Months>\d+)[m])", &Minutes) ? Minutes[2] : 0
                    , vMap["TimeInfo"]["Seconds"] := RegExMatch(Time_asString, "((?<Months>\d+)[sS])", &Seconds) ? Seconds[2] : 0
                        , vMap["TimeUp"] := vMap["TimeInfo"]["Months"] * 86400 * 30 + vMap["TimeInfo"]["Days"] * 86400 + vMap["TimeInfo"]["Hours"] * 3600 + vMap["TimeInfo"]["Minutes"] * 60 + vMap["TimeInfo"]["Seconds"]
    ;SetlistVars(Time_asString "`r`n" StrReplace(JSON.Dump(Map,,4), "`n", "`r`n"))
    ;msgbox % Time_asString "-" Map.Months
    return vMap
}

; DisplayMap(InputObject, LineNumber := "", Padding := 4) {
; 	Static Iteration := 0
; 	SetlistVars(StrReplace(JXON.Dump(InputObject, Padding), "`n", "`r`n"))
; 	msgbox "Displaying Map :" (Iteration += 1) " `r`n" LineNumber
; }

Log(String, Action := "", SourceLine := "", FilePath := "") {
    If (FilePath = "")
        FilePath := A_ScriptDir "\log.log"
    If !(SourceLine = "")
        SourceLine := Format("({})", SourceLine)
    String := LogFormat(String, Action, SourceLine)
    FileAppend(String, FilePath)
}

LogFormat(String := "", Level := "LOG", SourceLine := "") {
    If !(SourceLine = "")
        SourceLine := Format("({})", SourceLine)
    Type := Level SourceLine
    Return Format("{1}{2}:{4}{3}`r`n"
        , FormatTime(A_Now
            , "[hh:mm:ss.ms]")
        , Type
        , String, "")
}

FormatSeconds(NumberOfSeconds)  ; Convert the specified number of seconds to hh:mm:ss format.
{

    time := 19990101  ; *Midnight* of an arbitrary date.
    time := DateAdd(time, NumberOfSeconds, "Seconds")

    HHmmss := FormatTime(time, "HH:mm:ss")
    return NumberOfSeconds // 86400 " Days " HHmmss
    /*
    	Formats up to Days.
    https://www.autohotkey.com/docs/v1/lib/FormatTime.htm
    */
}