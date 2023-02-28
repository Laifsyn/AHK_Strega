/* Todo list
-Finish S_getOrCreate_TimeMark()
	Needs to store a file mark for the file in question
-Create a LogFile for when a file is succesfully moved

*/

Watchdog(InputTime:="") {
	
	Global PathTargets, WatchPaths
	Static Index, watchDog_Data
	Start_Tick:= A_TickCount
	watchDog_Data:=watchDog_Data=""?{}:watchDog_Data
	watchDog_Data.StartTime:=InputTime=""?watchDog_Data.StartTime:new StartTime(InputTime)
	;tooltip, % Format("StartTime:{}, Index:{}",Watchdog_Data.StartTime.tick , Index), 0, 0, 1
	Index+=1
	For Key, Paths in WatchPaths.Paths {
		WP_Index+=1
		If Paths.Skip
			Continue
		Text.=Format("PathName:[{}]`r`n", Key)
		Paths:=S_RefineWatchPaths(Key, Paths)
		
		For Index, Name in Paths["Source[asArray]"]
			{
			Text.="[" Name "]`r`n"
			Name:=S_ProcessWatchPaths(Name,WatchPaths["Available Common Keywords(Comment)"])	
			If !FileExist(Name)
				{	Warnings.= LogFormat(Format("Unknown Source Path! [{1}]",Name),"WARNING",Format("{1}:""{}"".{}",A_LineNumber,Key,A_Index))
					Continue
				}
			Loop, Files, % Name ,F
				{
					
					FileData:=S_RefineData(Paths["AgeType(Age as Countdown)"])
					Text.= A_Tab Format(">[{4}][Last Edited:{3}{2}]({5}){1}",FileData.FullName,FileData.DetailedAge, A_Tab,Key, JSON.Dump(Paths.TargetKeys)) "`r`n" 
					If True ;FileData.Age >= Paths.TimeUp
						{
						WarningText:=S_ProcessFile_to_Target(Paths, FileData, Key)
						}
					
					DebugText.= WarningText.Text
				}
			Warnings .= WarningText.Warning
			DebugText:=Paths.SourceName "[" Name "]`r`n"DebugText
			}
		Text.= "`r`n`r`n"
		}
	DebugText:=""  , Text:=""
	
	If DebugText
		SetListVars("Debugs Text`r`n" DebugText,1)
	If (Warnings and A_Index <2)
		SetListVars( Format("{1}{3}`r`n`tThis Run Summary:`r`n{2}{4}ms to Process a first iteration",FormatTime("[yyyy/MM/dd HH:mm:ss.ms]"), Warnings, "" ,A_TickCount - Start_Tick), 1)
	If Text
		SetlistVars(Text,1)
	pause
	SetTimer, Watchdog, -1000
	}

ListParse(InputObject := ""){ ; Parse a list of Strings in the next format "String1|String2|String3|....|StringN"
	For Key,Val in InputObject
			{ if (Key = 1)
				Delimiter := ""
			else
				Delimiter := "|" 
			Output.=Delimiter Val 
			}
	return Output
	}
S_getOrCreate_TimeMark(I_Object, FilePattern){
	DisplayObject(I_Object,A_LineNumber)
	IniRead(Filename, Section :="" ,Key :="" , Default:="" , Auto:="")
	Time:=IniRead()
	return
	}
S_RefineData(treatAsCountdown){
	RegExMatch(A_LoopFileName, "O)(?P<Name>.*)\." A_LoopFileExt "?", SubPat)
	
	Map:={}
	, Map.Extension:=A_LoopFileExt
	, Map.Name:=SubPat.Name
	, Map.FullName:= A_LoopFileName
	, Map.FullPath:= A_LoopFileLongPath
	, Map.Path := A_LoopFileDir "\"
	, Map.Time["LastModified"] := A_LoopFileTimeModified
	, Map.Time["LastModified_Month"] := FormatTime("MM",A_LoopFileTimeModified)
	, Map.Time["LastModified_Year"] := FormatTime("yyyy",A_LoopFileTimeModified)
	, Map.Time["LastModified_Day"] := FormatTime("dd",A_LoopFileTimeModified)
	, Map.Time["TimeCreated"] := A_LoopFileTimeCreated
	, Map.Time["TimeCreated_Month"] := FormatTime("MM",A_LoopFileTimeCreated)
	, Map.Time["TimeCreated_Year"] := FormatTime("yyyy",A_LoopFileTimeCreated)
	, Map.Time["TimeCreated_Day"] := FormatTime("dd",A_LoopFileTimeCreated)
	

	
		File_Birth:=treatAsCountdown?S_getOrCreate_TimeMark(Map,Format("{}\FileData.ini",A_ScriptDir)):A_LoopFileTimeModified
			; Defines the Age(in seconds) of the file. In these 2 cases, we will either
			; obtain the age in terms of since the file was modified, vs the age in terms of
			; when it was first "found" by the script
	
	Map.Age:=EnvSub(A_Now,File_Birth, "s")
	, Map.DetailedAge:=FormatSeconds(Map.Age)
	DisplayObject(Map)
	return Map
	}	
S_RefineWatchPaths(Key, Paths){
	Global WatchPaths
	
	if ( !Paths.processedTimeup ){
			SubMap:=S_TimeTextFormat_to_Seconds(Paths.Timeup)
			Paths.Timeup:=SubMap.TimeUp
			WatchPaths.Paths[Key].TimeUp:=SubMap.TimeUp
			WatchPaths.Paths[Key].TimeInfo:=SubMap.TimeInfo
			WatchPaths.Paths[Key].processedTimeup:= 1
			;SetlistVars(StrReplace(JSON.Dump(WatchPaths.Paths[Key],,4), "`n", "`r`n"))
			}
		Paths.SourceName:= Key
		Return Paths
		}
S_RefineTargetPath(ByRef InputString, I_Object, TargetObject:=""){
	Global PathTargets
	Target_DateKeys := ListParse(PathTargets.DateKeys)
	Target_DateKeys := RegExReplace(Target_DateKeys, "<|>", "") ; Target_DateKeys := "<Year>|<Month>|<Day>"
	DateType:=PathTargets.FileDateType
	OdInput:=InputString
	While ( InputString ~=  "i)<(" Target_DateKeys ")>" )
		{	RegExMatch( InputString , "iO)(" Target_DateKeys ")" , SubPat)
			InputString:=RegExReplace(InputString, "<" SubPat.Value(1) ">", I_Object.Time[Format("{}_{}", DateType, SubPat.Value(1) )] )
		}
	If !RegExMatch(InputString, "\\$")
						InputString.="\"
	
	Return InputString
	}
S_ProcessFile_to_Target(Paths, FileData, Name){
			Global PathTargets
			
			For Index, TargetKey in Paths.TargetKeys{
					Target:=PathTargets[TargetKey]
					If !Target
						{Warning.=LogFormat(Format("There's no such Key: ""{1}""",TargetKey),"WARNING", Format("{1}:""{}"" {}",A_LineNumber,Name,A_IndexZ))
						Continue
						}
					If ( (FileExist(DestPattern:=S_RefineTargetPath(Target["Target"],FileData, Target)) <> "D") and !( Target["Target"]~="i)" ListParse(PathTargets.DateKeys) ))
						{	
							Warning.= LogFormat(Format("Unknown Target Path! [{}]",DestPattern), "WARNING", Format("{1}:{}[""{}""]",A_LineNumber,Name,TargetKey))
							Continue
						}
					
					If Target
					Switch Target["Type"]{
						case "Keyword":
							RegExList:= "i)(" ListParse(Target["Key"]) ")"
							If !( FileData.Name ~=  RegExList )
								Continue
							Text.= A_Tab "Keyword:" FileData.Name "`r`n"
							
						case "FileType":
							RegExList:= "i)(" ListParse(Target["Key"]) ")"
							If !( FileData.Extension ~= RegExList )
								Continue
							Text.= A_Tab Format("FileType({}):", FileData.Extension) FileData.FullName "`r`n"
						Default:
						Warning.=LogFormat("UNKNOWN KEY!: """ Target["Type"] """ from " Paths.SourceName " in """ TargetKey """" ,"WARNING", Format("{1}:""{}"" {}",A_LineNumber,Name,A_Index) )
						Continue
						}

					;DestPattern:=S_RefineTargetPath(Target["Target"],FileData, Target)
					;DestPattern:= "C:\Temp - AHK\Test\Targets\"
					
					If !FileExist(DestPattern)
							FileCreateDir( RegExReplace( DestPattern, "\*$",""))
					FileSource:=FileData.FullPath
					FileSource:="C:\Temp - AHK\Test\New Microsoft Word Document.docx"
					;DestPattern:= DestPattern 
					;SetlistVars(FileSource "`r`n" DestPattern)
					WhileIndex:=1
					While WhileIndex<= 256
					{
						
						If ErrorCount >1
							Subfix:=Format("* {1} ({2}).*",FormatTime("[yyyy.MM.dd HH.mm.ss]",FileData.Time[PathTargets.FileDateType]),ErrorCount-1)
						else if ErrorCount
							Subfix:=Format("* {1}.*",FormatTime("[yyyy.MM.dd HH.mm.ss]",FileData.Time[PathTargets.FileDateType]))
						;if Subfix
							;Msgbox, % Subfix
						if FileMove(FileSource,DestPattern Subfix)
							ErrorCount+=1
						else
							break
						WhileIndex+=1
					}
					
					msgbox, Continue?
				}
			
			OutputText:={}
			OutputText.Warning:=Warning
			OutputText.Text:=Text
			Return OutputText
			}
S_ProcessWatchPaths(Input, StringList){
	Name:=Input
	Name:=RegExReplace(Name, "<(A_|)UserName>" , A_UserName)
	 
	CommonKeywordsList:= "\A(" ListParse(StringList) ")$"
	IF (Name ~= CommonKeywordsList )
			Name:=A_%Name% "\"
	if (Name ~= "\\$" )
		Name:=Name "*"
	
	Return Name
	}
S_TimeTextFormat_to_Seconds(Time_asString){
	Map:={TimeInfo:{}}
	something:=RegExMatch(Time_asString, "O)((?<Months>\d+)[M])", Months)
	something:=RegExMatch(Time_asString, "O)((?<Months>\d+)[Dd])", Days)
	something:=RegExMatch(Time_asString, "O)((?<Months>\d+)[Hh])", Hours)
	something:=RegExMatch(Time_asString, "O)((?<Months>\d+)[m])", Minutes)
	something:=RegExMatch(Time_asString, "O)((?<Months>\d+)[sS])", Seconds)
	Map.TimeInfo.Months 	:= Months.Value(2)?Months.Value(2):0
	, Map.TimeInfo.Days	:= Days.Value(2)?Days.Value(2):0
	, Map.TimeInfo.Hours	:= Hours.Value(2)?Hours.Value(2):0
	, Map.TimeInfo.Minutes	:= Minutes.Value(2)?Minutes.Value(2):0
	, Map.TimeInfo.Seconds	:= Seconds.Value(2)?Seconds.Value(2):0
	, Map.TimeUp:= Map.TimeInfo.Months * 86400*30 + Map.TimeInfo.Days * 86400 + Map.TimeInfo.Hours * 3600 + Map.TimeInfo.Minutes * 60 + Map.TimeInfo.Seconds   
	
	;SetlistVars(Time_asString "`r`n" StrReplace(JSON.Dump(Map,,4), "`n", "`r`n"))
	;msgbox % Time_asString "-" Map.Months
	return Map 
	}

Class WatchPath{
	__New(Paths,Targets){
		
		
		
		}
	
	
	}
DisplayObject(InputObject, LineNumber:="",Padding:=4){
	SetlistVars(StrReplace(JSON.Dump(InputObject,,Padding), "`n", "`r`n"))
	msgbox, OK? `r`n%LineNumber%
	}	

Log(String, Action:="",SourceLine:="", FilePath:=""){
	If (FilePath="")
		FilePath:=A_ScriptDir "\log.log"
	If !(SourceLine = "")
		SourceLine:= Format("({})",SourceLine)
	String:=LogFormat(String, Action, SourceLine)
	FileAppend(String,FilePath)
	}

LogFormat(String:="", Level:="LOG", SourceLine:=""){
	If !(SourceLine = "")
		SourceLine:= Format("({})",SourceLine)
	Type := Level SourceLine
	Return Format("{1}{2}:{4}{3}`r`n",FormatTime("[hh:mm:ss.ms]"),Type,String,"")
	}

FormatSeconds(NumberOfSeconds)  ; Convert the specified number of seconds to hh:mm:ss format.
{
    
	time := 19990101  ; *Midnight* of an arbitrary date.
    time += NumberOfSeconds, seconds
    HHmmss:=FormatTime("HH:mm:ss", time)

    return NumberOfSeconds//86400 " Days " HHmmss
    /*
	Formats up to Days.
    https://www.autohotkey.com/docs/v1/lib/FormatTime.htm
    */
}
