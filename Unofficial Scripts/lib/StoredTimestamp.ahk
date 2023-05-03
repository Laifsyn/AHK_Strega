Class StoredTimestamp extends Watchdog_Base {
    __New(Wrapper, InputMap := "") {
        this.DefineProp("Wrapper", { Value: Wrapper })
        this.DefineProp("__path", { Value: Wrapper.__path })
        this.DefineProp("__fileLastModified", { Value: Wrapper.__fileLastModified })
        if (InputMap = "") ; this is for in case there's no data to load, so we skip all this below
            return this
        for k_Path, v_Files in InputMap
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

    getMap() {
        tempMap := Map()
        for k_Path, v_Files in this
        { tempFile := Map()
            for k_Files, v_props in v_Files
            { tempProp := Map()
                value := unset
                for k_prop, v_value in v_props.OwnProps()
                    TempProp.Set(k_prop, value := v_value)
                else
                    value := "Empty"
                if TempProp.Count > 1
                    tempFile.Set(k_Files, tempProp)
                else
                    tempFile.Set(k_Files, value)
            }
            tempMap.Set(k_path, tempFile)
        }
        return tempMap
    }

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

Class Wrapper_StoredTimestamp extends Watchdog_Base {
    TimestampWrapper := "StoredTimestamp"

    __New(Path := "", type := "Text", encoding := this._encoding) {
        this.DefineProp("__path", { Value: A_ScriptDir "\configs\Timestamps.json" })
        this.DefineProp("__fileLastModified", { Value: 0 })
        if (Path = "") ; this is for in case there's no data to load, so we skip all this below
            return this
        if FileExist(Path)
            this.DefineProp("__path", { Value: Path })
        this.DefineProp("__fileLastModified", { Value: FileGetTime(this.__path, "M") })
            , JsonMap := this.transformString(this.__path, Type, encoding)
        for wrapperKey, data in JsonMap
            this[wrapperKey] := data
        return this
    }

    __Item[keyName] {
        set {
            if keyName = this.TimestampWrapper
            {
                if !(value is Map)
                    Throw ValueError(Format("{}[{}] expects a Map object, but got {} instead!", Type(this), keyName, Type(Value)), , Type(Value))
                if Value is StoredTimestamp
                { super[keyName] := Value
                return
            }
            super[keyName] := StoredTimestamp(this, value)
            return
        }
        super[keyName] := Value
    }
    get {
        if (keyName = this.TimestampWrapper) && !(this.Has(keyName))
            temp := StoredTimestamp(this, "")
                , this[keyName] := temp
        return super[keyName]
    }
}

Dump(mapToDump := this, path := this.__path, encoding := this._encoding, padding := 1) {
    tempMap := Map()
    For _, v in mapToDump
        v := this.getMap(v, ["Value"]), tempMap.Set(_, v)
    myString := JXON.Dump(tempMap, padding)
    SetListVars(myString, 1, A_LineNumber)
    super.Dump(myString, path, encoding)
}

}