/************************************************************************
 * @description 
 * @file class_WatcherFilePaths.ahk
 * @author 
 * @date 2023/08/09
 * @version 1.0.0
 ***********************************************************************/

/************************************************************************
 * Tests Summary: Somewhere is causing a memory leak which source I haven't pinpointed yet
 * TODO: Find the memory leak
 ***********************************************************************/


/**
 * This Class manages the Folder Path where all the settings for the watcher will be stored.
 * The file name of "common.config" is reserved. 
 * 
 * The other settings Files can be any other .json file.
 * 
 */
Class WatcherFile Extends WatcherFile_Internals {

    /**
     * @param Path The root path where the Class will be loading all the configs for the WatcherFile 
     */
    __New(Path) {
        if !FileExist(Path)
            DirCreate(Path)
        this.__path := Path
        this.LoadConfigs()
        if 1
            return
    }
}

Class WatcherFile_Internals Extends Map {
    __FileEncoding := A_FileEncoding
    /*
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
    
    */
    KeywordsExceptions := Array("A_Hour",
        "A_Min",
        "A_Sec",
        "A_MSec",
        "A_DD",
        "A_DDD",
        "A_DDDD")
    CaseSense := "Off"
    /**
     * An array of keys that are expected to be an array in the settings watcher
     */
    ; ArrayAbles := Array("Source", "TargetKeys")
    LoadConfigs() {
        this.CreateSettingsTemplate(this.__path "\settings_template.json.template")
            , this.CastCloneMap(this, JXON.Load(this.GetCommonConfigs(this.__path "\common.config")))
            , this["settings"] := Map()
            , this["settings"].CaseSense := "Off"
        loop files this.__path "\*.json" {
            ; Store the path names in lowercase because Map is Case Sensitive
            fullpath := StrLower(A_LoopFileFullPath)
                , SplitPath(fullpath, , &file_path, , &file_name)
                , result := WatcherFiles_Paths(this, file_name, fullpath, this.__FileEncoding)
            if !(result.isValid) {
                result.parent := ""
                continue
            }
            this["settings"][file_name] := result
            ;   SetListVars(Format("{}`r`n`r`n{}`r`n`r`n", A_LoopFileFullPath, t))
        } else
            throw Error("No .json files to load configs in " Type(this), , this.__path)
    }
    /**
     * Method to call before deleting the instance
     */
    Delete() {
        for _namespace, object in this["settings"]
            object.parent := "", object.initial_map := "", object.ArrayAbles := ""
        this.ArrayAbles := ""
    }

    CreateSettingsTemplate(path) {
        static default_string := this.settings_template_data
        ;
        file := FileOpen(path, 0x3, this.__FileEncoding)
        openPos := file.pos, file_text := file.read()
        if file_text != default_string {
            file.pos := openPos, File.Write(default_string), File.Length := File.Pos
        }
        File.Close()
    }
    GetCommonConfigs(path) {
        if !(FileExist(path) = "A")
            this.CreateDefaultCommonConfig(path)
        SplitPath(path, , &dir)
        return FileRead(path, this.__FileEncoding)
    }
    CreateDefaultCommonConfig(path) {
        static default_string := this.settings_common_data
        config_file := FileOpen(path, 0x3, this.__FileEncoding)
        config_file.Write(default_string), config_file.Close()

    }
    CastCloneMap(CastTarget, MapToCast, NestLevel := 1) => CastCloneMap(CastTarget, MapToCast, NestLevel)
}


/**
 * 
 * 
 * 
 * 
 * 
 */
class WatcherFiles_Paths extends WatcherFiles_Paths_Internals {
    __FileEncoding := A_FileEncoding
    /**
     * 
     * @param namespace The key in which this Class Instance is stored in
     * @param path The path where search for the settings' data, i.e. This instance of the Settings' File Location. stored as search_path
     * @param data_json? Optional Parameter : If no json_data  is provided, the class will load from path
     * @returns {void} 
     */
    __New(parent, namespace, path, encoding?) {
        this.namespace := namespace
        if IsSet(encoding)
            this.__FileEncoding := encoding
        this.parent := parent
            , this.ArrayAbles := parent.ArrayAbles
            , this.expects_keywords := parent.expects_keywords
            , this.KeywordsExceptions := parent.KeywordsExceptions
            , this.search_path := path
            , this.Has_UnprocessedKeywords := Array()
        if !this.IsValidInstance()
            return this.isValid := 0
        SplitPath(path, , &dir), this.path := dir
        return this.isValid := 1
    }
}

class WatcherFiles_Paths_Internals extends Map {
    CaseSense := "Off"
    literalize_json(&src) => ReplaceString(&src)
    __Delete() {
        this.parent := ""
        for k, v in this
            this[k].Clear()
        this.Clear()
    }
    /**
     * Checks for the Setting Instance Validity
     * @returns TRUE|FALSE
     */
    IsValidInstance() {
        path := this.search_path
        if !FileExist(path)
            throw Error(Format("Un-existent File Path"), , path)
        data_json := FileRead(path, this.__FileEncoding)
        this.literalize_json(&data_json)
        this.initial_map := JXON.Load(data_json)
        CastCloneMap(this, this.initial_map)
        if !this.CheckSettings()
            return false
        return true
    }
    /**
     * Checks for the instance's settings. Mainly fix json data that're supposedly formatted as Arrays, but were written as strings
     * @returns TRUE|FALSE
     */
    CheckSettings() {
        for key, value in this {
            expectsArray := 0
            if IsInList(key, this.ArrayAbles, true) {
                ; We're looking for to convert into array key:Values that were supposed to be array, but were written as string
                if value is String
                    value := Array(value)
                expectsArray := true
            }
            if !expectsArray && (value is Object)
                throw ValueError(Format("Settings doesn't expect an object, but got <{}> as data", Type(value)), , Format('"{}"["{}"] : <{}>,' Type(this), this.namespace, key, type(value)))
            this[key] := value
        }
        this.FixSettings()
        return true
    }
    /**
     * Checks for the instance's settings. Converts KeyWords
     * @returns void
     */
    FixSettings() {
        ; Checks the Keys that are expected to be arrays because they're supposed to hold keywords within
        checkKeys := this.expects_keywords
        for i, v in checkKeys {
            value := this[v]
            ; if value is object
            ;     old := value.Clone()
            if value is Array {
                for ArrIndex, IndexString in value {
                    if this.ConvertKeyword(&IndexString, this.parent["UserDefined"], this.KeywordsExceptions)
                        this.Has_UnprocessedKeywords.push(ArrIndex)
                    value[ArrIndex] := IndexString
                }
            } else
                this.ConvertKeyword(&value, this.parent["UserDefined"], this.KeywordsExceptions)
            ;SetListVars(Format("{}`r`nOld:`r`n{}`r`nNew:`r`n{}", this.search_path, JXON.Dump(old, 1), JXON.Dump(value, 1)), 1)
            this[v] := value
        }

    }

    /**
     * Converts KeyWords that're enclosed in between "<" and ">". Doesn't support multiple nesting however.
     * 
     * The Capturing instance stops once keyword["count"] changes from 1 to 0. This Mean you can have a keyword as "something<other text>...Hi" enclosed in between the identifier
     * @param StringToConvert The String to convert. It could also be an Array of Strings 
     * @param keyword_list The keyword list to load
     * @returns fixed string
     */
    ConvertKeyword(&StringToConvert, keyword_list, keywords_exceptions) {
        NextCh := (pos) => SubStr(StringToConvert, pos + 1, 1)
        pos := 0, capture := false
            , string_has_unprocessed_keywords := false
        keyword := Map("count", 0, "string", "") ; Helps to keep track of the items
        resultString := "" ; Final String
        static specialChars := "<>"

        while ((ch := SubStr(StringToConvert, ++pos, 1)) != "") {
            if capture {
                ; Chars to escape behaviour only applies while inside the capturing pattern
                if ch == "\" and InStr(specialChars, NextCh(pos), true) {
                    if capture
                        keyword["string"] .= NextCh(pos)
                    else
                        resultString .= NextCh(pos)
                    pos += 1
                    continue
                }
                keyword["string"] .= ch
            }
            if ch == "<" {
                if (++keyword["count"]) and capture = 10
                    throw Error("Error. Can't have < inside the keyword", , keyword["string"])
                capture := true
                continue
            } else if ch == ">" {
                if (--keyword["count"]) = 0 {
                    capture := false
                    patt := SubStr(keyword["string"], 1, StrLen(keyword["string"]) - 1) ; The captured pattern
                    if this.get_keyword_value(&patt, keyword_list, keywords_exceptions)
                        string_has_unprocessed_keywords += 1
                    resultString .= patt
                    keyword["string"] := ""
                    continue
                }
            } else if !capture
                resultString .= ch
        }
        StringToConvert := resultString
        return string_has_unprocessed_keywords

    }

    get_keyword_value(&keyword_string, keyword_list, keywords_exceptions) {
        SplitPath(this.search_path, &filename)
        if i := IsInList(keyword_string, keywords_exceptions)
            return keyword_string := Format("<{}>", keyword_string)
        if converted_keyword := %keyword_string% ?? "" ; Checks if this is an integrated keyword
            keyword_string := converted_keyword
        else {
            if !keyword_list.has(keyword_string) {
                throw Error(Format("Keyword without definitinion in `"{}`"", filename), , Format('"{}"', keyword_string))
            }
            keyword_string := keyword_list[keyword_string]
        }
    }

    /**
     * Checks if the String has any keyword left to check
     * @param StringToCheck 
     * @return True | False
     */
    hasKeywords(StringToCheck) {

    }
    /**
     * Checks if the settings's path exists after reformatting it.
     * @param &path 
     * @returns class_Object
     */
    IsValidPath(&path) {
        return FileExist(&path)
    }

}