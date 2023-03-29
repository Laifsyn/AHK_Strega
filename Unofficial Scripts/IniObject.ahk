#Requires AutoHotkey v2.0
#Include <toml\toml>
#Include <JXON>
#Include <UDF>
; Something:=Ini("UDF IniRead.ini")
; text
Test:=Toml().read("
(
    [company]
    name = "Acme Corp"
    address = { street = "123 Main St.", city = "Anytown", state = "CA", zip = "12345" }
    phone = "+1 555-555-5555"
    website = "https://acmecorp.com"
    founded = 1995-09-01T00:00:00Z
    
    [company.ceo]
    name = "Jane Doe"
    age = 50
    isMale = false
    salary = 150000.0
    startDate = 2010-01-01T08:00:00Z
    performanceRatings = [4.5, 4.7, 4.8, 4.9, 5.0]
    hobbies = ["hiking", "reading", "yoga"]
    address = { street = "456 Park Ave.", city = "Bigcity", state = "NY", zip = "54321" }
    
    [company.departments]
    [company.departments.hr]
    name = "Human Resources"
    [company.departments.hr.manager]
    name = "John Smith"
    age = 45
    isMale = true
    salary = 100000.0
    startDate = 2015-01-01T08:00:00Z
    performanceRatings = [4.0, 4.2, 4.3, 4.5, 4.6]
    hobbies = ["swimming", "cooking", "guitar"]
    
    [[company.departments.hr.employees]]
      name = "Mary Brown"
      age = 30
      isMale = false
      salary = 50000.0
      startDate = 2020-01-01T08:00:00Z
      performanceRatings = [4.2, 4.3, 4.4, 4.5, 4.6]
      hobbies = ["painting", "sailing"]
      address = { street = "789 Elm St.", city = "Smalltown", state = "TX", zip = "67890" }
    [[company.departments.hr.employees]]
      name = "Mark Green"
      age = 35
      isMale = true
      salary = 60000.0
      startDate = 2018-01-01T08:00:00Z
      performanceRatings = [4.3, 4.5, 4.7, 4.8, 4.9]
      hobbies = ["photography", "golf"]
      address = { street = "234 Oak St.", city = "Othercity", state = "IL", zip = "45678" }
    
    [company.departments.it]
    name = "Information Technology"
    [company.departments.it.manager]
    name = "Sarah Lee"
    age = 40
    isMale = false
    salary = 120000.0
    startDate = 2013-01-01T08:00:00Z
    performanceRatings = [4.7, 4.8, 4.9, 5.0]
    hobbies = ["traveling", "baking", "piano"]
    
    [[company.departments.it.employees]]
      name = "David Wong"
      age = 28
      isMale = true
      salary = 80000.0
      startDate = 2021-01-01T08:00:00Z
      performanceRatings = [4.0, 4.2, 4.3]
    
)"
)

text:=""
; s:=Test.values["a"]["c"]["e"]["g"]["i"]["j"]
; for k,v in s
;     text.=Format("[{}]:={}`r`n",k, IsObject(v)?"object":v)
; msgbox Text
; text:=""
; for k,v in s.OwnProps()
;     text.=Format("[{}]:={}`r`n",k, IsObject(v)?"object":v)
; msgbox Text
msgbox Test.Values["company"]["website"]
DisplayMap(Test.values)
SetListVars(Text)
class Ini extends Map {
    CaseSense := "Off" ; Because since I'm using it to store Window's Folder paths etc, case sense isn't a necessity
    SpecialChar := "¤"
        __FileEncoding := "UTF-16"


    __New(Path) {
        this.DefineProp("__path", { Value: Path }) ; __path where the file is stored
        this.DefineProp("TimeStamp", { Value: FileGetTime(Path) }) ;Stores a Timestamp of the last Modified time to the Ini
        for I_section, pairsMap in this.Load() {
            sect := Ini.Section(Path, I_section, this) ; Create a Section Instance, and pass on the thisInstance as a parent to the Instance Child "Ini.Section()"
            for Key, value in pairsMap {
                sect.Set(1, Key, value) ; stores a TimeStamp of this Key-Value Pair data as a property
            }
            super[I_section] := sect             ; Set the KeyPair. Calling Super so it doesn't activates the instance's __Item
        }
    }
    __Item[SectionName] {
        set {
            If !this.Has(SectionName) ; In case the section doesn't exists, It will create a Section Instance
                Super[SectionName] := this.SetSection(SectionName)
            If IsObject(Value)
            {
                For k, v in Value
                    Super[SectionName][k] := v
                Return
            }
            ; This will manage cases when you define a string to the SectionKey
            If (Value == SectionName)
                Return
            this.UpdateSectionKey(, SectionName, Value)
        }
        ; This will manage cases where the section isn't defined.
        get => super.has(SectionName)
            ? Super[SectionName]
            : Super[SectionName] := this.SetSection(SectionName)
    }
    SetSection(Section) {
        this.Changes[, , , -1] := "Creating this[" Section "]"
        return Ini.Section(this.__path, Section, This)
    }
    ; UpdateKey(OldName, NewName, Log:=1){
    UpdateSectionKey(Log := 1, Params*) { ; It is expected to be more efficient if you load all the SectionKeys updates into an array
        NewParams := Array()
        For _, v in Params ; to flatten the Params in case there's an array inside among the parameters but wasn't explicitly defined as a "var*". Pretty much it should allow (Parameters and Array) as parameters
        {
            If Type(v) = "Array"
            {
                For _, v in v
                    NewParams.Push(v)
                Continue
            }
            NewParams.Push(v)
        }
        Params := NewParams, NewParams := ""
        If !Params.Length or Mod(Params.Length, 2) ; Because
        {
            Text := ""
            For _, v in Params
                Text .= V ", "
            this.Changes[A_ThisFunc "() received an odd(" Params.Length ") ammount of Parameters", "•WARN", , -1] := "(" Trim(Text, ", ") ")"
            Return
        }
        File := FileOpen(this.__path, "rw", this.__FileEncoding)
            , File.Text := File.Read(), File.Pos := 2
            , OldText := File.text
        Loop Params.Length / 2
        {
            Super[Params[2]] := this[Params[1]] ; should be equivalent to >Super[NewName]:=this[OldName]<
            Super.Delete(Params[1])
            File.Text := RegExReplace(File.Text, "(\[)(?<Section>" Params[1] ")(\][^=]*)", "$1" Params[2] "$3", , 1)
            ; It's to keep intact whatever other text there might be, i.e "[AnArbitrarySection Name] ;asdasasdasdsdsa"
            If Log
                this.Changes[Format("Updating Section in This[{}]", Params[1]), , , -1] := Params[2]
            Params.RemoveAt(1, 2)
        }
        if (File.Text = OldText)
            Return File.Close()
        File.Write(File.Text), File.Length := File.Pos
            , File.Close()
    }
    Delete(Name) { ; Delete a Map's Key, and furthermore will delete the Section from the file
        Super.Delete(Name)
        IniDelete(this.__path, Name)
        this.Changes["Deleting the Section [" Name "] through IniDelete"] := A_LastError
    }
    Dump(ShowLogs := 0) {
        Text := ""
        For Section, KeyValMap in this {
            Text .= Format("[{}]`r`n", Section)
            For Key, Value in KeyValMap
                Text .= Format("{}={} `;;{}`r`n", key, value, this[Section].%Key%)
        }
        File := FileOpen(this.__path, "rw", this.__FileEncoding)
            , File.seek(2, 0)
            , File.Write(Text)
            , File.Length := File.Pos
            , File.Close()
            , this.TimeStamp := FileGetTime(this.__path)
    }
    Load(CreateProperty := 0) { ; This loads the ini file and returns an Map equivalent to the file
        ;The Map structure is expected to be "this[Section][Pair's Key]:= Pair's Value"
        ; as well as "this[Section].%Pair's Key%:= Pair's Comment"
        ; Creates appends the map to an accessible property as "this.__file" when asked
        file_asMap := Map()
            , FileTimeStamp := FileGetTime(this.__path, "M"), file_asMap.TimeStamp := FileTimeStamp
            , this.Changes := "Reading data of [" this.__path "]"
            , File := FileOpen(this.__path, "r", this.__FileEncoding)
        Map := TOML().Read(this.__path)
        Loop Read this.__path {
            If RegExMatch(A_LoopReadLine, "\[(.*)\]", &Section)
            {
                LatestSection := Section[1]
                , file_asMap[Section[1]] := Map()
                , SectionFound := 1
                Continue
            }
            else if !IsSet(SectionFound) ; This is here just in case you have a bunch of not in-a-section lines at the top of the file.
                ; It's worth noting that, those lines at the start of the file will be ignored though
                Continue
            if RegExMatch(A_LoopReadLine, "(?<key>[^=]+)=(?<value>.*)", &Pair)
            {
                If RegExMatch(pair.value, "(?<value>.*);;(?<Comment>.*)", &Value)
                    Pair.Comment := value.Comment, pair.Value := value.Value
                else
                    Pair.Comment := FileTimeStamp
                Pair.Value := RegExReplace(Pair.Value, "\\;", ";") ; It should recognize  whatever comes after the last pair of ";;" as a comment. I'm not sure how to properly make a escape
                    , Pair.Value := Trim(Pair.Value, " `t")
                    , file_asMap[LatestSection][Pair.key] := Pair.value
                    , file_asMap[LatestSection].%Pair.key% := IsInteger(pair.Comment) ? Pair.Comment : FileTimeStamp
                ; If the comment isn't a Integer, then I'm assuming that it is a data that should've been there ever since the first time the file is read.
                ; Either that, or there wasn't a "timestamp" in the first place.
                ; Otherwise, I get an integer-string that I can compare with the timestamp that I'd earlier defined through the class
            }
        }
        if !CreateProperty
            Return file_asMap
        else
            Return this.__file := file_asMap
    }

    syncUpdates() { ;Based on the newest data written in the inifile, it will load it. Do note that, updates to a Key name won't reflect on the file, instead will be appended
        ; this might result on the old key remaining, and therefore need manual removal

        ; 1-) What to do if the Section doesn't exists in memory? *** Append it to memory
        ;       ** Any In-Memory update to a Section will immediately reflect the new name inside the .ini file
        ; 2-) And what if I changed a section name? *** Sorry, you gotta restart if you want to change a Section Name. I haven't figured a senseful way to make it so knows how to properly update into the new section
        ; 3-) What if I want to load a change in a Pair into memory? ***
        ;       * Changing a pair key will append the new key
        ;       * Loading its new(?) value should require you to delete the value comment

        For section, Pairs in var := this.Load()
        {   ; It's unnecesary to check if the section already exists in this[*], since if the getter of this.__Item[] results to be invalid(No value),
            ; it will create a Ini.Section Instance automatically, and continue to work normally as if the section existed since then
            For key, val in Pairs {
                If !(this[section].Has(Key))
                {
                    this[Section].Set(0, key, val)
                        , this.Changes[Format("[0]Appending this[{}][{}] {}", section, key, this[section].%key%), , , -1] := val
                }
                else
                {
                    old := this[Section][key]
                    , told := this[Section].%key%
                    , OldComparison := (var[Section].%key% > this[Section].%key%)
                    , this[Section][key] := OldComparison
                    ? val : this[Section][key]
                    if (Old != val) ;In case the values are the same, it will just report that the timestamp is updated, otherwise reports the update to the value
                        this.Changes[Format("[{}]Memory[{}({}])", (OldComparison ? "→" : "←"), Old, FormatTime(Told, "yyyy/MM/dd HH:mm:ss")), , , -1] := Format("FileData[{}({})]", val, FormatTime(var[Section].%key%, "yyyy/MM/dd HH:mm:ss"))
                    ; This will report what was in memory and what's stored in file. In case the data stored in file is older(The one in memory is newer)
                    ; than the one in memory, then the one in memory will remain
                }
            }
        }
        this.Dump() ; Saves updates
        ; this.TimeStamp:=A_Now ; Unneeded to have it because the this.TimeStamp will get updated after dumping the data
    }
    Logs(LineText, Append := 0, ExtraText := "", ShowSummary := 0, FileToAppend := "Logs.txt") {
        Static Content := "", summaryI := 0, Calls := 0
        Content .= LineText
            , Calls += 1
        If !(Append + ShowSummary) or !Content ; It skips when content is empty, or when it isn't asked to append/ShowSummary
            return Content
        summaryI += 1
        Content .= Format("{1}{2}({3}) {4}/{5} Chars`r`n" ExtraText
            , FormatTime(A_Now, "[HH:mm:ss." A_MSec "]")
            , LoggingType := "[SUMMARY]"
            , summaryI
            , StrLen(Content)
            , VarSetStrCapacity(&Content)
        )
        If ShowSummary
        {
            SetListVars("Calls done to Logger:" Calls "`r`n`r`n" Content "`r`n" "FileLine:" A_LineNumber)
            if MsgBox("Wanna to append?", A_ScriptName, 4) = "No"
                Return
        }
        File := FileOpen(FileToAppend, "rw", this.__FileEncoding)
            , File.seek(2, 0)
        if (File.Length > 2000000) ; ~2MB(?) worth of data will be trimmed by half
        { TotalChars := (File.Length) / 2, charsToRemove := Round(TotalChars / 2), String := File.Read()
            , File.Seek(charsToRemove * 2, 0)
            String := Format("....[{}] Removed {}/{} chars`r`n{}", FormatTime(A_Now, "yyyy/MM/dd HH:mm:ss"), charsToRemove, Integer(totalChars), File.Read()), File.seek(2, 0)
                , Content .= Format("Trimmed {} chars from file`r`n", charsToRemove)
                , File.Write(String), File.Length := File.Pos
        }
        File.Seek(0, 2), File.Write(Content)
            , File.Close
            , Cap := VarSetStrCapacity(&Content)
            , VarSetStrCapacity(&Content, Cap)
    }

    Changes[OldData := "", LoggingType := "INFO", Compile := 0, Offset := 0] {
        set {
            Static LastCycle := A_TickCount, Count := 0   ;This allows me to store data regarding the changes done.
            ; Count is here so to control when to append the logs(In case the Changes property is being called by by a big loop, those iterations won't really affect the frequency on when the log is appended)
            OldData := (IsObject(OldData) ? JXON.Dump(OldData) : OldData)
            Value := (IsObject(Value) ? JXON.Dump(Value) : Value)
            Stored := this.Changes
            Inputs := FormatTime(A_Now, "[HH:mm:ss." A_MSec "]") Format("[{}]({}){}{}", LoggingType, Stored, OldData = "" ? "" : OldData . "¤", Value) . "`r`n"
            If (Stored = 0)
            { this._Changes := Stored + 1
                Inputs := Format("{} {}`r`n{}ChangeStart`r`n{}", FormatTime(A_Now, "<yyyy/MM/dd>"), this.__path, FormatTime(A_Now, "[HH:mm:ss." A_MSec "]"), Inputs)
                this.Logs(Inputs)
                Return
            }
            this.Logs(Inputs)
                , this._Changes := Stored + 1
                , Count := Count + 1 + Offset ;Offset is so to tell the property that this call shouldn't count towards the "meter" of when it should append
            If Mod(Count, 50) or Count = 0
                return
            this.Logs("", 1)
                , LastCycle := A_TickCount
        }
        get {
            try
                Return this._Changes
            catch
                Return 0
        }

    } ; end of Changes[,,,,]

    class Section extends Map {
        Default := ""
        __New(Path, Section, Parent, params*) {
            this.__path := Path
            this.__section := Section
            this.__parent := Parent
            If !IsSet(Params)
                return
            If Mod(Params.Length, 2)
            {
                this.__parent.Changes["Odd number (" Params.Length ")of parameters has been detected in " Type(this), "•WARN", , -1] := JXON.Dump(params)
                return
            }
            this.Set(0, Params*)
        }
        Set(CreateLogs := 1, Params*) { ;A redirect so I can create a record and also set the timestamp
            super.Set(Params*)
            if mod(Params.Length, 2)
                msgbox "The params received an odd amount of entries`r`n" JXON.Dump(Params, 4)
            Loop Params.Length / 2
            {
                If CreateLogs
                {
                    Details := Format("Setting of this[{}][{}]", this.__section, Params[1])
                    this.__parent.Changes[Details, , , -1] := Params[2]
                }
                super.DefineProp(Params[1], { Value: A_Now })
                    , Params.RemoveAt(1, 2)
            }

        }

        __Item[Key] {
            set {
                OldData := Super[key]
                If (OldData == value)
                {
                    If this.Has(Key) ; If the key already exists, but the new Value and old value are the same, it will just log that the timestamp is updated
                        OldT := this.%key%, this.%key% := A_Now
                            , this.__parent.Changes[Format("Updating Timestamp of This[{}][{}]:={}", this.__section, key, oldT), , , -1] := A_Now
                    return
                }

                If this.Has(Key)
                    Action := "Updating", OldData := ":=♥" OldData "♥"
                else
                    Action := "Creating", OldData := ""
                super[Key] := value
                    , this.DefineProp(key, { Value: A_Now }) ;Definining this somehow fixes issues with Undefined prop
                    , this.__parent.Changes[Format("{} Value of This[{}][{}]{}", Action, this.__section, key, OldData)] := "" Value ";; With Timestamp:" this.%key%
            }
        }

    }

    ; Functions which I don't expect to be used outside of here (Private functions?)
    LogTime(Time := A_Now, Format := "[HH:mm:ss." A_MSec "]") => FormatTime(Time, Format)
    CreateSection(Section) => Ini.Section(this.__path, Section, This)


}



^r::Reload