Watchdog(InputTime:="") {
	Global PathTargets, WatchPaths
	Static Index, watchDog_Data
	watchDog_Data:=watchDog_Data=""?{}:watchDog_Data
	watchDog_Data.StartTime:=InputTime=""?watchDog_Data.StartTime:new StartTime(InputTime)
	;tooltip, % Format("StartTime:{}, Index:{}",Watchdog_Data.StartTime.tick , Index), 0, 0, 1
	Index+=1
	For Key, Paths in WatchPaths.Paths {
		Paths:=S_RefinePaths(Key, Paths)
		For Key, Name in Paths["Source[asArray]"]
			{
			Text.="[" Name "]`r`n"
			Name:=S_ProcessWatchPaths(Name,WatchPaths["Available Common Keywords(Comment)"])	
			Loop, Files, % Name ,F
				{

					Some:=EnvSub(A_Now,A_LoopFileTimeModified, "s")
					
					Time:=FormatSeconds(Some)
					Text.= A_Tab Format(">{1} [Last Edited:{3}{2}]",A_LoopFileName,Time, A_Tab) "`r`n" 
					
				}
			}
		}

	SetlistVars(Key "`r`n" Text)
	pause
	SetTimer, Watchdog, -1000
	}

ListParse(InputObject := ""){
	For Key,Val in InputObject
			{ if (Key = 1)
				Delimiter := ""
			else
				Delimiter := "|" 
			Output.=Delimiter Val 
			}
	return "i)\A(" Output ")$"
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
		Return Paths
		}
S_ProcessWatchPaths(Input, StringList){
	Name:=Input
	Name:=RegExReplace(Name, "<(A_|)UserName>" , A_UserName)
	CommonKeywordsList:= ListParse(StringList)
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