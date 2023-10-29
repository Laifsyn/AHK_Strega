#Requires AutoHotkey v2.0
#Include <StoredTimestamp>

Class Strega_Watcher {
    History_CountThreshold := 500
    _encoding := "UTF-8"
    __New(watcher_path, targets_path, timestamp_path := StoredTimestamp(A_ScriptDir "\configs\Timestamps.json", this)) {
        this.DefineProp("startUp", { Value: A_Now })
            , this.DefineProp("Watchers", { Value: WatchFile(watcher_path) })
            , this.DefineProp("Targets", { Value: TargetFile(targets_path) })
            , this.StoredTimestamp := timestamp_path is string ? StoredTimestamp(timestamp_path, this) : timestamp_path
            , this.DefineProp("Ticks", { Value: Object() })
            , this.loop := Object()
            , this.SweepConfigs()
        return this
    }
    /**
     * Checks if the watchers TargetKeys are Valid
     */
    SweepConfigs() {
        this._Sweep_WatchersTargets()
        this._Sweep_Paths()
    }
    /**
     * Sweeps the Watcher's Data to check for invalid Target Entries
     */
    _Sweep_WatchersTargets() {
        targets := this.Targets["Settings"]
        unexistent_keys := []
        for watcher_namespace, Settings in this.Watchers["Settings"] {
            for _index, target_key in Settings["TargetKeys"] {
                if !targets.has(target_key) {
                    unexistent_keys.Push({ File: Settings.namespace, TargetKey: target_key, FileFullPath: Settings.search_path })
                }
            }
        }
        if unexistent_keys.Length {
            text := ""
            for index, item in unexistent_keys
                text .= Format("
            (join`r`n
                Unknown Target Key No. {} in "{}.json"
                    Target Key: "{}"
                    Absolute Path: "{}"
                    `r`n
            )", index, item.File, item.issue_item, item.FileFullPath)
            ;End of formatting
            SetListVars("Unknown Target Keys has been detected. Please either delete invalid Keys, or create their Target Config`r`n" text)
            if unexistent_keys.Length = 1
                throw Error(Format("Unknown Target key in {}", unexistent_keys[1].File), , unexistent_keys[1].TargetKey)
            else
                throw Error(Format("Unknown Target keys ({} Unknown Targets)", unexistent_keys.Length))
        }
    }

    /**
     * Sweeps for the Watcher's paths to check if they exists
     */
    _Sweep_Paths() {
        targets := this.Targets["Settings"]
            , Issues := Map()
            , Issues.Length := 0
        for _, Settings in this.Watchers["Settings"] {
            for _index, path in Settings["Source"] {
                if !this._Sweep_Paths_FileExist(Settings, &path) {
                    if !Issues.Has(Settings.search_path)
                        Issues[Settings.search_path] := []
                    Issues[Settings.search_path].push(path), Issues.Length += 1
                }
            }
        }
        if Issues.Length {
            text := ""
            paths_dont_exist := ""
            for full_path, items in Issues {
                text .= Format('`r`n{}-)Unknown Path in " {} "`r`n', A_index, full_path)

                for index, item in items {
                    if items.Length <= 1
                        text .= Format("...... {}`r`n", item)
                    else
                        text .= Format("...... {}-) {}`r`n", A_Index, item)
                    paths_dont_exist .= Format("...... {}`r`n", item)
                }
            }
            SetListVars("Undefined Paths has been detected. Please either delete invalid Paths, or validate them`r`n" text "`r`nSummary:`r`n" paths_dont_exist)
            if Issues.Length = 1
                throw Error(Format("Unknown path in {}", Issues[1].File), , Issues[1].TargetKey)
            else
                throw Error(Format("Unknown paths ({} items)", Issues.Length))
        }
    }
    /**
     * 
     */
    _Sweep_Paths_FileExist(SettingsObject, &path) {
        original := ""
        path := RegExReplace(path, "\\+", "\")
        if (SettingsObject.Has_UnprocessedKeywords.Length) && ((result := RegExReplace(path, "<.*", "")) != path)
            original := Format('", original: "{}', path), path := result
        path := Trim(path, "*\")
        check_path := path
        path := path original
        return FileExist(check_path)
    }

    doProcedure() {
        this.procedureIndex += 1
        ; DisplayMap(this.Watchers, A_LineNumber)
        ; DisplayMap(this.Targets, A_LineNumber)
        ; * This will iterate over Paths.json[Paths].Watchers→Settings
        VarSetStrCapacity(&watcherTicks, 10000), totalTime := 0
        DisplayMap(this.Watchers, A_LineNumber)
        text := []
        for watcher_namespace, Settings in this.Watchers["settings"] {
            this.watcher := Settings
                , this.loop.namespace := Settings.namespace
                , this.loop.TimeUp := Settings["TimeUp"]

            for source_index, source_path in Settings["Source"] {

                if Settings.Has_UnprocessedKeywords.Length and IsInList(A_Index, Settings.Has_UnprocessedKeywords) {
                    Settings.ConvertKeyword(&source_path, settings.parent["UserDefined"])
                }
                ; if !FileExist(source_path) {
                ;     throw Error(Format('Unexistent path in "{}"', this.watcher.namespace),,source_path)
                ; }
                this.loop.source := source_path
                    , this.loop.sourceIndex := source_index
                    , this.loop.matchedFiles := 0 ; Counts the amount of files that matches the search keys
                ; This searches for all the files in the source.
                loop files this.loop.source, "F"
                {
                    this.loop.fileIndex := A_Index ; * helps enumerate the current file it's iterating over
                        , this.store_FileInstance() ; * this is to store the Loop Files variables into an object
                    if !this.fileMatch_Logic()
                        continue
                    msgbox this.loop.matched_firstTargetPath
                    if 1
                        throw Error("Uh... Finish this")
                    if this.hasTimestamp()
                        text.Push(this.loop.LF.fullName, FormatTime(this.get_timestamp(), "yyyy-MM-dd hh:mm:ss"))
                    ; this.send_File()

                }
                ; temp := QPC(this.Ticks.Folder)
                ;     , ticks := Round(ticks + temp, 2)
                ;     , this.loop.totalFiles += this.loop.fileIndex
                ;     , this.loop.pastMatchedFiles := this.loop.matchedFiles

                ; If this.loop.matchedFiles > this.loop.matchingThreshold
                ;     this.History[, "INFO", 0] := Format("Total Matching Files: {}`r`n`tTime:{}ms, avg. {}ms/File`r`n"
                ;         , this.loop.matchedFiles
                ;         , Temp
                ;         , Round(temp / this.loop.fileIndex, 3))
            }
            ; totalTime += ticks
            ;     , watcherTicks .= A_Tab ticks "ms " Format("[p:{}]f:{} {}`r`n", this.loop.sourceIndex, this.loop.totalFiles, Watcher)
            ;     , (this.loop.matchedFiles > 0) ? this.History[, ""] := "`r`n" : ""
        }

        DisplayMap(text, A_LineNumber, 2)
        DisplayMap(this.StoredTimestamp, A_LineNumber, 2)
    }
    /**
     * Returns true if it matches the logic defined in TargetFile
     * @returns {bool} 
     */
    fileMatch_Logic() { ; * Tells whether the file matches the predefined conditions
        ; msgbox this.loop.source " `r`n" this.LF.fullName
        If this.watcher["Age_asCountdown"] {
            if (has_timestamp := this.hasTimestamp())
                ; * If hasTimestamp registers as true, we can then know that we're working with a countdown, and that the timestamp already exists.
                ; * Otherwise, if we detect that hasTimeStamp is false, we will return false after creating the timestamp
                If (DateDiff(A_Now, digitalTimeStamp := this.get_timestamp(), "s") <= this.watcher["TimeUp"]) ; * If the file's digital timestamp is below the TimeUp it will skip the file
                    return 0
        }
        this.loop.conflicts := [] ; * This will keep tracks cases when there're more than a single target match
        ; Also means if we have a matching
        ; We iterate over each target_key that's been defined to know of possible conflicts
        for TargetKey in this.Watcher["TargetKeys"]
        {
            this.Target := this.Targets["settings"][TargetKey]
            switch this.Target["Type"], !!this.Target["CaseSensitive"] {
                default:
                    fileName := this.loop.LF.fullName
                case "Filetype":
                    fileName := this.loop.LF.ext
                case "Keyword":
                    fileName := this.loop.LF.name
            }
            match := []

            For search_key in this.Target["SearchKeys"] {
                regKey := this.generate_regkey(search_key)
                If RegExMatch(fileName, regKey is string ? regKey : regKey[1])
                    match.Push(regKey)  ; * To know how many regex keys matches the filename
            }
            ; If we have a matching "regKey", it will then store the match into
            if match.Length
            {
                this.loop.conflicts.Push(TargetKey)
                if (this.loop.conflicts.Length = 1) ; * Code block that only runs for the first matching Watcher's TargetKey
                {
                    this.loop.matched_firstTargetPath := this.Target["Target"],
                        this.loop.matched_firstTargetKey := TargetKey,
                        this.loop.regex_matches := match.Length,
                        this.loop.regEx := match[1]
                    ; if timestamp is set, we know we're dealing with a timed file
                    if IsSet(has_timestamp) {
                        ; If timestamp result to be false, we create the timestamp, and skip inmediately by returning false
                        if !has_timestamp {
                            this.StoredTimestamp.Create(this.loop.LF.fullPath, A_Now)
                            return False
                        }
                        ; We know we're dealing with a timed file, therefore if there's a timestamp value, and it managed to reach here, we delete the key
                        If IsSet(digitalTimeStamp)
                            this.storedTimestamp[this.loop.LF.path].Delete(this.loop.LF.fullName)
                    }
                }
            }
        }
        if !!this.loop.conflicts.Length
            this.loop.matchedFiles += 1
        return !!this.loop.conflicts.Length
    }
    hasTimestamp() => this.storedTimestamp.HasKeys(this.loop.LF.path, this.loop.LF.fullName)

    get_timestamp() => this.storedTimestamp.Get(this.loop.LF.fullPath)

    send_File() {
        Target := this.loop.matched_firstTargetKey
        If this.loop.matchedFiles = 1 ; * This is to discriminate between the first match and subsequent ones.
            ; * It's purpose is to add a header to the list that will identify the start of logging data
        { if this.loop.sourceIndex > 1 and this.loop.pastMatchedFiles > 2
            this.History[, ""] := stringJoin("-", 50) "`r`n"
            ; this.History["", "INFO", 0] := Format("{1}`r`n{4}{2}→RegExs:{3}`r`n",
            ;     this.loop.source, this.Targets[Target].type, JXON.Dump(this.Targets[Target].Targets), A_Tab
            ; )
        }
        ; Printing a Log. Might need tuning
        if this.loop.conflicts.Length > 1
        {
            Conflicts := Format("`r`n" A_Tab "Conflicts({}): ", this.loop.conflicts.Length)
            for val in this.loop.conflicts
                Conflicts .= Format("{}, ", val)
            Conflicts := RTrim(Conflicts, ", ")
        }
        SourcePattern := Format("{}\{}", RTrim(this.loop.source, "\*"), this.LF.fullName)
        if !(this.loop.regEx is string)
            MsgBox(UDF.getPropsList(this.LF, A_LineNumber, 100)), MsgBox(this.loop.regEx "`r`n" A_LineNumber)
        if 1
            throw ValueError("Finish formatting the destpattern name depending on the matching regex data.")

        DestPattern := this.process_CustomKeywords(Format("{}\", RTrim(this.loop.matched_firstTargetPath, "")), this.get_contextKeywords())
        source_Dest := SourcePattern " → " DestPattern
        this.History := Format("[{1}]{6}{2}[{3}]{4}`r`n"
            , this.loop.fileIndex
            , " "
            , source_Dest
            , IsSet(Conflicts) ? Conflicts : ""
            , JXON.Dump(this.loop.regEx)
            , Format("T[`"{}`"]", this.Targets[Target].__parentKey)
        )

        if !FileExist(DestPattern)
            try
                DirCreate(DestPattern)
            catch Error as E
                msgbox UDF.ErrorFormat(E)
        ; msgbox "Source`r`n" "`r`n" SourcePattern "→" FileExist(SourcePattern) "`r`n" this.LF.fullPath "→" FileExist(this.LF.fullPath) "`r`nTarget" "`r`n" DestPattern "→" FileExist(DestPattern)
        ;FileCopy SourcePattern, DestPattern "\*.*", 0

        ; this.History["Target: " this.loop.]
    }
    generate_regkey(search_key) {
        if RegExMatch(search_key, "r\/(?<regex_literal>.*)\/", &patt) {
            regkey := patt["regex_literal"]
            if !RegExMatch(regkey, "^([imsxADJUXSC]|``a|``r|``n|)+\)")
                regkey := "i)" regkey
        }
        else
            regkey := "i)" search_key
        return regkey
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

    /**
     * Acc
     */
    store_FileInstance() {
        SplitPath(A_LoopFileFullPath, &FullName, &Path, &Ext, &name)
            , fileObj := Object()
            , fileObj.fullName := FullName
            , fileObj.ext := Ext
            , fileObj.name := name
            , fileObj.fullPath := A_LoopFileFullPath
            , fileObj.path := Path
            ; , fileObj.timeAccess := A_LoopFileTimeAccessed ; * Commented out because I don't know if storing this equals to a read instance of the file
            , fileObj.timeModified := A_LoopFileTimeModified
        ; , fileObj.timeCreated:=A_LoopFileTimeAccessed ; * Commented out because I don't know if storing this equals to a read instance of the file
        this.loop.DefineProp("LF", { value: fileObj })
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