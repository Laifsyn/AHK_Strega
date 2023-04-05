/* Todo list
-Finish S_getOrCreate_TimeMark()
	Needs to store a file mark for the file in question
-Create a LogFile for when a file is succesfully moved

*/
#Requires AutoHotkey v2.0

class Watchdog_Base extends Map {
	_encoding := "UTF-16"
	
	LogFormat() {
		Return FormatTime(A_Now, "[HH:mm:ss." A_MSec "]")
	}
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
			, this["TimeInfo"]["Months"] := RegExMatch(Input, "((?<Months>\d+)[M])", &Months) ? Months[2] : 0
			, this["TimeInfo"]["Days"] := RegExMatch(Input, "((?<Months>\d+)[Dd])", &Days) ? Days[2] : 0
			, this["TimeInfo"]["Hours"] := RegExMatch(Input, "((?<Months>\d+)[Hh])", &Hours) ? Hours[2] : 0
			, this["TimeInfo"]["Minutes"] := RegExMatch(Input, "((?<Months>\d+)[m])", &Minutes) ? Minutes[2] : 0
			, this["TimeInfo"]["Seconds"] := RegExMatch(Input, "((?<Months>\d+)[sS])", &Seconds) ? Seconds[2] : 0
			, Input := this["TimeInfo"]["Months"] * 86400 * 30 + this["TimeInfo"]["Days"] * 86400 + this["TimeInfo"]["Hours"] * 3600 + this["TimeInfo"]["Minutes"] * 60 + this["TimeInfo"]["Seconds"]

		return Input
	}
	process_invalidKeywords(Input) => RegExReplace(Input, "i)(<|>)", "")
}

Class TargetFile extends Watchdog_Base {
	__New(Path, type := "Text", encoding := this._encoding) {
		this.DefineProp("__path", { Value: StrLen(path) })
		, this.DefineProp("__fileLastModified", { Value: FileGetTime(Path, "M") })
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
		else if Type is "File"
			JsonString := fileread(Path, encoding)
			, this.DefineProp("__path", { Value: Path })
		this := JXON.Load(JsonString)
			, this.Paths := Map()
		For Key, A_Settings in this["Paths"] {
			If !!(A_Settings["Skip"])
				Continue
			Temp := WatchFile.WatchPath(A_Settings, Key, this)
				, this.Summary[A_LineNumber, A_ThisFunc] := Format("{}({})")
				, Temp.DeleteProp("Summary")
				, this.Paths[Key] := Temp
		}
	}
}

Class WatchFile Extends Watchdog_Base {
	__New(Path, type := "Text", encoding := this._encoding) {
		this.DefineProp("__path", { Value: StrLen(path) })
		, this.DefineProp("__fileLastModified", { Value: FileGetTime(Path, "M") })
		if Path is file
		{
			watchFileString := Path.read()
			Try
				Path.Close()
			catch as E
			{
				msgbox(E.What)
				return
			}
		}
		else if Type is "File"
			watchFileString := fileread(Path, encoding)
			, this.DefineProp("__path", { Value: Path })
		this := JXON.Load(watchFileString)
			, this.Paths := Map()
		For Watcher, A_Settings in this["Paths"] {
			If !!(A_Settings["Skip"])
				Continue
			Temp := WatchFile.WatchPath(A_Settings, Watcher, this)
				, this.Summary[A_LineNumber, A_ThisFunc] := Format("{}({})")
				, Temp.DeleteProp("Summary")
				, this.Paths[Watcher] := Temp
		}
	}
	; 

	Class WatchPath Extends Watchdog_Base { ; Wrapper to process the watcher's parameters
		CaseSense := 0

		__New(InputSettings, Watcher, Parent) {
			This.DefineProp("__parent", Parent)
			 , This.DefineProp("__watcher", Watcher)
			 for Key, val in InputSettings 
			 	this[Key] := val
			 
			Return this
		}
		__Item[KeyName] {
			set {
				switch KeyName, 0 {
					case "Source":
						Val:=Array()
						, Value:=Value is Array?Value:Array(Value)
						For _,v in Value {
							v := this.process_AddEnding(v) 
							, v := this.__parent.process_Keywords(v)
							, v := this.__parent.process_invalidKeywords(v)
							, Val.Push(v)
						}
						Value:=Val
					case "TargetKeys":
						Val:=Array()
						, Value:=Value is Array?Value:Array(Value)
						For _,v in Value {
							v := this.process_AddEnding(v)
							, v := this.__parent.process_Keywords(v)
							, v := this.__parent.process_invalidKeywords(v)
							, Val.Push(v)
						}
						Value:=Val
					case "TimeUp":
						Value := this.process_TimeString(Value)
					default:
						If value is Object
							{
								err:= ValueError(this.__watcher "[" KeyName "] expects string, but got " Type(value), Type(this))
								, msgbox(UDF.ErrorFormat(err))
							}
				}
				Super[KeyName] := Value
			}
		}
	}

}

WatchPaths:=""
PathTargets:=""
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

Class WatchPath {
	__New(Paths, Targets) {


	}


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