Class StoredTimestamp extends Watchdog_Base {
    __New(Path := "", type := "Text", encoding := this._encoding) {
        this.DefineProp("__path", { Value: A_ScriptDir "\configs\Timestamps.json" })
        if (Path = "") ; this is for in case there's no data stored, so we skip all this below
            return this
        if FileExist(Path)
            this.DefineProp("__path", { Value: Path })
        this.DefineProp("__fileLastModified", { Value: FileGetTime(this.__path, "M") })
            , JsonMap := this.transformString(this.__path, Type, encoding)
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

    getMap() {
        ; for k_Path, v_Files in this
        ;     for k_Files, v_props in v_Files
        ;         if Random(1, 2) = 1
        ;             this[k_Path][k_Files].modified := A_sec "." A_MSec " - " A_Index

        tempMap := Map()
        for k_Path, v_Files in this
        { tempFile := Map()
            for k_Files, v_props in v_Files
            { tempProp := Map()
                value := unset
                for k_prop, v_value in v_props.OwnProps()
                    TempProp.Set(k_prop, value := v_value)
                else
                    value:="Empty"
                if TempProp.Count > 1
                    tempFile.Set(k_Files, tempProp)
                else
                    tempFile.Set(k_Files, value)

            }
            tempMap.Set(k_path, tempFile)
        }
        ; tempPath.Set(k_path, tempFile.Set(k_Files, tempProp.Set(k_Prop, IsObject(v_value) ? "Object:" Type(v_value) : v_value)))
        return tempMap
    }

    Dump(inputMap := this, path := this.__path) {
        tempMap := Map()
        for k_Path, v_Files in inputMap
        { tempFile := Map()
            for k_Files, v_other in v_Files
                tempFile.Set(k_files, inputMap[k_Path][k_Files].Value)
            tempMap.Set(k_path, tempFile)
        }
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