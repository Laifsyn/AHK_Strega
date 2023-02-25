Watchdog(InputTime:="") {
	Global PathTargets, WatchPaths
	Static Index, watchDog_Data
	watchDog_Data:=watchDog_Data=""?{}:watchDog_Data
	watchDog_Data.StartTime:=InputTime=""?watchDog_Data.StartTime:new StartTime(InputTime)
	;tooltip, % Format("StartTime:{}, Index:{}",Watchdog_Data.StartTime.tick , Index), 0, 0, 1
	Index+=1
	For Key, Paths in WatchPaths.Paths {
		If Paths.Skip
			Continue
		Text.=Format("PathName:[{}]`r`n", Key)
		Paths:=S_RefinePaths(Key, Paths)
		For Index, Name in Paths["Source[asArray]"]
			{
			Text.="[" Name "]`r`n"
			Name:=S_ProcessWatchPaths(Name,WatchPaths["Available Common Keywords(Comment)"])	
			Loop, Files, % Name ,F
				{
					
					FileData:=S_RefineData(A_Now)
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
		SetListVars(Warnings, 1)
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
S_RefineData(Time){
	RegExMatch(A_LoopFileName, "O)(?P<Name>.*)\." A_LoopFileExt "?", SubPat)
	Map:={}
	, Map.Extension:=A_LoopFileExt
	, Map.Name:=SubPat.Name
	, Map.FullName:= A_LoopFileName
	, Map.Age:=EnvSub(A_Now,A_LoopFileTimeModified, "s")
	, Map.DetailedAge:=FormatSeconds(Map.Age)
	, Map.FullPath:= A_LoopFileLongPath
	, Map.Path := A_LoopFileDir "\"
	return Map
	}	
S_RefinePaths(Key, Paths){
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
S_ProcessFile_to_Target(Paths, FileData, Name){
			Global PathTargets

			
			For Key, TargetKey in Paths.TargetKeys{
					Target:=PathTargets[TargetKey]
					If !Target
						{Warning.=LogFormat(Format("There's no ""{1}"" key for Watcher:""{2}"" ",TargetKey, Name),"WARNING", A_LineNumber)
						Continue
						}
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
						Warning.=LogFormat("UNKNOWN KEY:""" Target["Type"] """ from " Paths.SourceName " in """ TargetKey """" ,"WARNING",A_LineNumber)
						Continue
						}
					DisplayObject(Target)
					;msgbox, % FormatTime("yyyy\MM\dd\",A_LoopFileTimeModified) ":" FileData.FullName "`r`n" FileData.FullPath
					If Target["SortByDate"]
						DatePath:=FormatTime("yyyy\MM\dd\",A_LoopFileTimeModified)
					FileSource:=FileData.FullPath
					If !RegExMatch(Target["Target"], "\\$")
						Target["Target"].="\"
					TargetPath:= Target["Target"] DatePath FileData.FullName
					SetlistVars(FileSource "`r`n" TargetPath,1)
					DisplayObject(Paths, A_LineNumber "`r`n" FileData.FullPath "`r`n" Target["Target"])	
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
