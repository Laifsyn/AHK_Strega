#Requires AutoHotkey v2.0

/**
 * watcherPath("Hello World", "G:\Git\AHK_Strega\Unofficial Scripts") ==
 * {
 * "Age_asCountdown": 1,
 * "isPath": 1,
 * "Skip": 0,
 * "Source": [],
 * "TargetKeys": [],
 * "TimeUp": "8d18h"
 * }
 */
class watcherPath extends watcherPath_Internals {
    __New(namespace, path, dataJSON?) {
        this.namespace := namespace
        if !(t := this.IsValidPath(&path))
            throw Error(Format("Invalid Path - Got {}", t), , path)
        if !this.IsValidWatcher(&path, dataJSON?)
            return
        this.search_path := path
        SplitPath(path, , &dir), this.path := dir
        DisplayMap(this)
    }
}

class watcherPath_Internals extends Map {
    CaseSense := "Off"
    ArrayAbles := Array("Source", "TargetKeys")
    default_data := "
    (lTrim Rtrim 
        {
            "Skip":0,
			"Source":[],
			"isPath":true,
			"TargetKeys":[],
			"TimeUp":"8d18h",
			"Age_asCountdown": 1
        }
    )"
    /**
     * Validates Settings and the object
     * @param &path 
     * @returns class_Object
     */
    IsValidWatcher(&path, data_obj := this.default_data) {
        if data_obj is String
            if !(data_obj := JXON.Load(data_obj))
                return false
        if !(data_obj is Map)
            return false
        this.CastMap(data_obj)
        return true
    }
    /**
     * Validates Settings and the object
     * @param &path 
     * @returns class_Object
     */
    CastMap(settings_map) {
        for key, value in settings_map {
            expectsArray := 0
            if IsInList(key, this.ArrayAbles, true) {
                ; We're looking for to convert into array key:Values that were supposed to be array, but were written as string
                if value is String
                    value := Array(value)
                expectsArray := true
            }
            if !expectsArray && (value is Object)
                throw ValueError(Format("Settings doesn't expect an object, but got <{}> as data", Type(value)), , Format('"{}"["{}"] : <{}>,', this.namespace, key, type(value)))
            this[key] := value
        }
    }
    /**
     * Checks if the path exists after reformatting it.
     * @param &path 
     * @returns class_Object
     */
    IsValidPath(&path) {
        this.FixPath(&path)
        return FileExist(path)
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
    }
}