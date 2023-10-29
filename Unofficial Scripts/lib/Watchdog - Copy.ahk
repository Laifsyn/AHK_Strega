#Requires AutoHotkey v2.0
#Include <StoredTimestamp>
#Include <Structs\A_LoopFields>
#Include <Classes\SendFile>

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
            for _idx, path in Settings["Source"] {
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
                throw Error(Format("Unknown paths ({} items)", "Issues found: " Issues.Length))
        }
    }
    /**
     * 
     */
    _Sweep_Paths_FileExist(SettingsObject, &path) {
        original := ""
        path := RegExReplace(path, "\\+", "\")
        if (SettingsObject.UnprocessedKeywords.Length) && ((result := RegExReplace(path, "<.*", "")) != path)
            original := Format('", original: "{}', path), path := result
        path := Trim(path, "*\")
        check_path := path
        path := path original
        return FileExist(check_path)
    }

    doProcedure() {
        this_procedure_start_time := A_TickCount
        this.procedureIndex += 1
        ; DisplayMap(this.Watchers, A_LineNumber)
        ; DisplayMap(this.Targets, A_LineNumber)
        ; * This will iterate over Paths.json[Paths].Watchers→Settings
        VarSetStrCapacity(&watcherTicks, 10000), totalTime := 0
        for watcher_namespace, Settings in this.Watchers["settings"] {
            this.watcher := Settings
                , this.loop.namespace := Settings.namespace
                , this.loop.TimeUp := Settings["TimeUp"]

            for source_index, source_path in Settings["Source"] {

                if Settings.UnprocessedKeywords.Length and IsInList(A_Index, Settings.UnprocessedKeywords) {
                    Settings.ConvertKeyword(&source_path, settings.parent["UserDefined"], Array())
                }
                ; if !FileExist(source_path) {
                ;     throw Error(Format('Unexistent path in "{}"', this.watcher.namespace),,source_path)
                ; }
                this.loop.source := source_path
                    , this.loop.sourceIndex := source_index
                    , this.loop.matchedFiles := 0 ; Counts the amount of files that matches the search keys
                ; This searches for all the files in the source.
                mark_time := A_TickCount
                loop files this.loop.source, "F"
                {
                    this.loop.fileIndex := A_Index ; * helps enumerate the current file it's iterating over
                        , A_LoopFile := A_LoopFields(this.storeA_LoopFile()) ; * Stores A_LoppFile variants


                    If this.watcher["Age_asCountdown"] &&
                        has_timestamp := this.hasTimestamp(A_LoopFile.path, A_LoopFile.fullName, this.StoredTimestamp)
                        If DateDiff(A_Now, this.get_timestamp_from(this.StoredTimestamp, A_LoopFile.fullPath), "s") <= this.watcher["TimeUp"]
                            continue
                    ; else
                    ;      MsgBox("hey, hey. You got something" Format("}{} <= {}", DateDiff(A_Now, this.get_timestamp_from(this.StoredTimestamp, A_LoopFile.fullPath), "s"), this.watcher["TimeUp"]))

                    matching_target_key := unset
                    for target_key in this.Watcher["TargetKeys"] {
                        matching_target_key := target_key
                        if (new_path := this.file_matches_target_config((target := this.Targets["settings"][target_key]), A_LoopFile))
                            break ; We got a new_path, so we stop searching
                    }
                    if !new_path
                        continue
                    if this.watcher["Age_asCountdown"] {
                        ; So we have a Countdown and a file that matches the Target configs, what happens to the timestamp?
                        if !has_timestamp {
                            this.StoredTimestamp.Create(A_loopFile.fullPath, A_Now)
                            continue ; Fresh Timestamp has been set, so we skip
                        }
                        else ; Because by this step we already know that timestamp is over its limit, we will delete the timestamp
                            this.StoredTimestamp.Clear_file(A_LoopFile.fullPath)
                    }

                    mark_time := QPC()
                    if target.has_unprocessed_keywords()
                        target.ConvertKeyword(&new_path, this.get_contextKeywords(A_LoopFile), Array())
                    time_to_convert := QPC(mark_time)
                    mark_time := QPC()
                    new_path := Format("{}\", Trim(new_path, "\"))
                    ; if this.Targets["Settings"][target_key]["Action"] = "Move"

                    append_to_logger := () =>
                        RegExReplace(Format("
                    (join`r`n
                        Moving Files
                        `tFrom: {}
                        `tto  : {}
                    )", A_LoopFile.fullPath, SendFile(A_LoopFile.fullPath, Format("{}\{}.{}", new_path, A_LoopFile.name, A_LoopFile.ext)).MoveFile(SendFile.ENUMS_MOVE)),
                            "\\+", "\")
                    logger.append(append_to_logger())
                    mark_time := A_TickCount


                }
            }
        }
        this.StoredTimestamp.SyncFile()
        static cycle_time_in_ms := 60 * 1000
        re_doing := cycle_time_in_ms - Mod(A_TickCount - this_procedure_start_time, cycle_time_in_ms)
        SetTimer(ObjBindMethod(this, "doProcedure"), -re_doing)
    }

    /**
     * 
     * @param target_config {`TargetFile()`}
     * @returns {false, String of source_file's new_path}
     */
    file_matches_target_config(target_instance_config, A_LoopFile) { ; * Tells whether the file matches the predefined conditions
        ; msgbox this.loop.source " `r`n" this.LF.fullName


        switch target_instance_config["Type"] {
            default:
                matching_name := A_LoopFile.fullName
            case "Filetype":
                matching_name := A_LoopFile.ext
            case "Keyword":
                matching_name := A_LoopFile.name
        }
        match := []
        For search_key in target_instance_config["SearchKeys"] {
            regKey := this.generate_regkey(search_key)
            If RegExMatch(matching_name, regKey is string ? regKey : regKey[1])
                match.Push(regKey)  ; * To know how many regex keys matches the filename
        }
        ; If we have a matching "regKey", it will then store the match into
        if match.Length
        {
            this.loop.regex_matches := match.Length,
                this.loop.regEx := match[1]
            return target_instance_config["Target"]
        }
        return ""
    }
    /**
     * 
     * @param path {key string of `sources_of_stored_timestamp`}
     * @param file_name {key string of `sources_of_stored_timestamp`}
     * @param sources_of_stored_timestamp {`StoredTimestamp()`}
     * @returns {bool} 
     */
    hasTimestamp(path, file_name, sources_of_stored_timestamp := this.StoredTimestamp) => sources_of_stored_timestamp.HasKeys(path, file_name)
    get_timestamp_from(stored_timestamp, full_path) => stored_timestamp.Get(full_path)
    ; hasTimestamp() => this.storedTimestamp.HasKeys(this.loop.LF.path, this.loop.LF.fullName)

    ; get_timestamp() => this.storedTimestamp.Get(this.loop.LF.fullPath)

    generate_regkey(search_key) {
        if RegExMatch(search_key, "r\/(?<regex_literal>.*)\/", &patt) {
            regkey := patt["regex_literal"]
            if !RegExMatch(regkey, "^([imsxADJUXSC]|``a|``r|``n|)+\)")
                regkey := "i)" regkey ; Defaults RegEx flag to insensitive
        }
        else
            regkey := "i)" search_key ; Defaults RegEx flag to insensitive
        return regkey
    }
    get_contextKeywords(A_LoopFile) {
        ; Registered ~06.65E-3ms per call using Arrow Function 2023/04/23
        ; Registered ~13.65E-3ms per call using strings 2023/04/23
        temp := A_LoopFile.timeModified,
            myMap := Map(),
            myMap.CaseSense := "Off",
            myMap.Set(
                "M_YearMonth", FormatTime(temp, "YearMonth"),
                "M_YDay", FormatTime(temp, "YDay"),
                "M_YDay0", FormatTime(temp, "YDay0"),
                "M_WDay", FormatTime(temp, "WDay"),
                "M_YWeek", FormatTime(temp, "YWeek"),
                "M_d", FormatTime(temp, "d"),
                "M_dd", FormatTime(temp, "dd"),
                "M_ddd", FormatTime(temp, "ddd"),
                "M_dddd", FormatTime(temp, "dddd"),
                "M_M", FormatTime(temp, "M"),
                "M_MM", FormatTime(temp, "MM"),
                "M_MMM", FormatTime(temp, "MMM"),
                "M_MMMM", FormatTime(temp, "MMMM"),
                "M_y", FormatTime(temp, "y"),
                "M_yy", FormatTime(temp, "yy"),
                "M_yyyy", FormatTime(temp, "yyyy"),
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
            , myMap.Set("Year", myMap["M_yyyy"], "Month", myMap["M_MM"], "Mon", myMap["M_MM"], "Day", myMap["M_dd"])
        return myMap
    }

    /**
     * 
     * @returns {object} 
     * fields defined:
     * fileObj.fullName := FullName
     * fileObj.ext := Ext
     * fileObj.name := name
     * fileObj.fullPath := A_LoopFileFullPath
     * fileObj.path := Path
     * fileObj.timeModified := A_LoopFileTimeModified
     */
    storeA_LoopFile() {
        SplitPath(A_LoopFileFullPath, &FullName, &Path, &Ext, &name)
            , fileObj := Object()
            , fileObj.fullName := FullName
            , fileObj.ext := Ext
            , fileObj.name := name
            , fileObj.fullPath := A_LoopFileFullPath
            , fileObj.path := Path
            , fileObj.timeModified := A_LoopFileTimeModified
        ; , fileObj.timeAccess := A_LoopFileTimeAccessed ; * Commented out because I don't know if storing this equals to a read instance of the file
        ; , fileObj.timeCreated:=A_LoopFileTimeAccessed ; * Commented out because I don't know if storing this equals to a read instance of the file
        this.loop.DefineProp("A_LoopFiles", { value: fileObj })
        return fileObj
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