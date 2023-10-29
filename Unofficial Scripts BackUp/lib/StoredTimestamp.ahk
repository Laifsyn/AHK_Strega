Class StoredTimestamp extends Watchdog_Base {
    CaseSense := "Off"
    __New(Wrapper, InputMap := "") {
        this.DefineProp("__parent", { Value: Wrapper })
        this.DefineProp("__path", { Value: Wrapper.__path })
        this.DefineProp("__fileLastModified", { Value: Wrapper.__fileLastModified })
        if (InputMap = "") ; this is for in case there's no data to load, so we skip all this below
            return this

        for k_Path, v_Files in InputMap
            for k_Files, v_storedTimeStamp in v_Files
                If FileExist(k_Path "\" k_Files)
                    this[k_Path].push(k_Files, {
                        Value: v_storedTimeStamp,
                        stored: v_storedTimeStamp,
                        lastModified: this.__fileLastModified
                    })
        DisplayMap(this.__parent.getMap(this, "All"), A_LineNumber, 1)
        return this
    }
    __Item[keyName] {
        get {
            keyName := Trim(keyName, " \")
            ; These trims should stay for consistency sakes. If you use the path pieces, you should add by yourself the inverted slash
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

    Dump() => this.__parent.Dump() ; If it makes sense: If you dump the child, then you want to dump the whole wrapper.

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
        CaseSense := "Off"
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

        Push(key, Data) {
            this.Set(key, Data)
            return this
        }
    }
}

Class Wrapper_FileData extends Watchdog_Base {
    TimestampWrapper := "StoredTimestamp"
    _encoding := "UTF-8"
    __New(Path := "", type := "Text", encoding := this._encoding) {
        this.DefineProp("__path", { Value: A_WorkingDir "\configs\Timestamps.json" })
        this.DefineProp("__fileLastModified", { Value: 0 })
        if (Path = "") ; this is for in case there's no data to load, so we skip all this below
            return this
        if FileExist(Path)
            this.DefineProp("__path", { Value: Path })
        else
            FileAppend("{}", this.__path, this._encoding) ; File doesn't exists? creates it.
        this.DefineProp("__fileLastModified", { Value: FileGetTime(this.__path, "M") })
            , JsonMap := this.transformString(this.__path, Type, encoding)
            , this.DefineProp("storedFile", { Value: JsonMap })
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
    Static lastCall := A_Now
    tempMap := this.getMap(mapToDump, ["Value"])
    myString := JXON.Dump(tempMap, padding)
    if (JXON.Dump(this.storedFile, padding) = myString) and (DateDiff(lastCall, A_Now, "s") > 300)
        return { result: False, timestamp: lastCall }
    lastCall := A_Now
    super.Dump(myString, path, encoding)

    return { result: True, timestamp: lastCall }
}

}