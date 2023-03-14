/* Todo list
-Finish S_getOrCreate_TimeMark()
	Needs to store a file mark for the file in question
-Create a LogFile for when a file is succesfully moved

*/
#Requires AutoHotkey v2.0
Watchdog(InputTime:="") {
	
	Global PathTargets, WatchPaths, _rn
	Static Index:=0, watchDog_Data:=UDF.Map(StartTime, InputTime)
	Start_Tick:= A_TickCount
	;tooltip, % Format("StartTime:{}, Index:{}",Watchdog_Data.StartTime.tick , Index), 0, 0, 1
	Index+=1
	WP_Index:=0
	
	For Key, Paths in WatchPaths["Paths"] {
		
		WP_Index+=1
		If Paths["Skip"]
			{	
				Continue
			}
		Text.=Format("PathName:[{}]`r`n", Key)
		Paths:=S_RefineWatchPaths(Key, Paths)
		
		For Index, Name in Paths["Source[asArray]"]
			{
			
			Text.="[" Name "]`r`n"
			Name:=S_ProcessWatchPaths(Name,WatchPaths["Available Common Keywords(Comment)"])	
			If !FileExist(Name)
				{	Warnings.= LogFormat(Format("Unknown Source Path! [{1}]",Name),"WARNING",Format("{1}:`"{}`".{}",A_LineNumber,Key,A_Index))
					Format(".{}",_rn)
					Continue
				}
			Loop Files Name ,"F"
				{	
					
					FileData:=S_LoopFileData(Paths["AgeType(Age as Countdown)"])
					WarningText:=S_ProcessFile_to_Target(Paths, FileData, Key)
					DebugText.= WarningText["Text"]
				}
			Warnings .= WarningText["Warning"]
			DebugText:=Paths["SourceName"] "[" Name "]`r`n" DebugText
			}
		Text.= _rn _rn
		}
	DebugText:=""  , Text:=""
	If DebugText
		SetListVars("Debugs Text`r`n" DebugText,1)
	If (Warnings and A_Index <2)
		SetListVars( Format("{1}{3}`r`n`tThis Run Summary:`r`n{2}{4}ms to Process a first iteration",FormatTime(A_Now,"[yyyy/MM/dd HH:mm:ss.ms]"), Warnings, "" ,A_TickCount - Start_Tick), 1)
	If Text
		SetlistVars(Text,1)
	pause
	SetTimer Watchdog, -1000
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
	;define Section, and Keys.

	DisplayMap(I_Object,A_LineNumber)
	;UDF.IniRead(Filename, Section :="" ,Key :="" , Default:="" , Auto:="")
	;Time:=UDF.IniRead(FilePattern, )
	return
	}
S_LoopFileData(treatAsCountdown){
	RegExMatch(A_LoopFileName, "(?P<Name>.*)\." A_LoopFileExt "?", &SubPat)
	Local Map
	Map:=NoCaseMap()
	Map["Extension"]:=A_LoopFileExt
	, Map["Name"]:=SubPat[1]
	, Map["FullName"]:= A_LoopFileName
	, Map["FullPath"]:= A_LoopFileFullPath
	, Map["Path"] := A_LoopFileDir "\"
	, Map["Time"]:= UDF.Map()
	, Map["Time"]["LastModified"] := A_LoopFileTimeModified
	, Map["Time"]["LastModified_Month"] := FormatTime(A_LoopFileTimeModified,"MM")
	, Map["Time"]["LastModified_Year"] := FormatTime(A_LoopFileTimeModified, "yyyy")
	, Map["Time"]["LastModified_Day"] := FormatTime(A_LoopFileTimeModified, "dd")
	, Map["Time"]["TimeCreated"] := A_LoopFileTimeCreated
	, Map["Time"]["TimeCreated_Month"] := FormatTime(A_LoopFileTimeCreated, "MM")
	, Map["Time"]["TimeCreated_Year"] := FormatTime(A_LoopFileTimeCreated, "yyyy")
	, Map["Time"]["TimeCreated_Day"] := FormatTime(A_LoopFileTimeCreated, "dd")
	

	
		File_Birth:=!treatAsCountdown?S_getOrCreate_TimeMark(Map,Format("{}\Files Data.ini",A_ScriptDir)):A_LoopFileTimeModified
			; Defines the Age(in seconds) of the file. In these 2 cases, we will either
			; obtain the age in terms of since the file was modified, vs the age in terms of
			; when it was first "found" by the script
	
	
	Map["Age"]:=DateDiff(A_Now,File_Birth, "s")
	, Map["DetailedAge"]:=FormatSeconds(Map["Age"])
	return Map
	}	
S_RefineWatchPaths(Key, Paths){
	;Key is the WatchPaths[NKey] Pointer, whereas
	Global WatchPaths
	
	if ( !Paths["processedTimeUp"] ){
			For ArrIndex, Value in Paths["Source[asArray]"]
				{ 	;If !RegExMatch(Value, "(<|>)")
					;	Continue
					;; Just in case so I know to try this IF Condition to improve performance, even if minimally	
					Paths["Source[asArray]"][ArrIndex]:= S_ProcessPathKeywords(Value)
				}
			
			SubMap:=S_TimeTextFormat_to_Seconds(Paths["TimeUp"])
			Paths["TimeUp"]:=SubMap["TimeUp"]
			, Paths["TimeInfo"]:=SubMap["TimeInfo"]
			, Paths["processedTimeUp"]:= 1
			, WatchPaths["Paths"][Key]:=Paths
			}
		
		Paths["SourceName"]:= Key
		
		Return Paths
		}

S_RefineTargetPath(InputString, I_Object, TargetObject:=""){
	Global PathTargets
	Target_DateKeys := ListParse(PathTargets["DateKeys"])
	Target_DateKeys := RegExReplace(Target_DateKeys, "<|>", "") ; Target_DateKeys := "<Year>|<Month>|<Day>"
	DateType:=PathTargets["FileDateType"]
	OdInput:=InputString
	While ( InputString ~=  "i)<(" Target_DateKeys ")>" )
		{	RegExMatch( InputString , "i)(" Target_DateKeys ")" , &SubPat)
			InputString:=RegExReplace(InputString, "<" SubPat[1] ">", I_Object["Time"][Format("{}_{}", DateType, SubPat[1] )] )
			
		}
	InputString:=S_ProcessPathKeywords(InputString)
	msgbox InputString
	If !RegExMatch(InputString, "\\$")
						InputString.="\"
	
	Return InputString
	}

S_ProcessFile_to_Target(Paths, FileData, Name){
			Global PathTargets
			Local Text:=""
			For Index, TargetKey in Paths["TargetKeys"]{

				
				;DisplayMap(FileData,A_LineNumber)
					Target:=PathTargets[TargetKey]
					If !Target
						{Warning.=LogFormat(Format("There's no such Key: `"{1}`"",TargetKey),"WARNING", Format("{1}:`"{}`" {}",A_LineNumber,Name,A_Index))
						Continue
						}
					If ( (FileExist(DestPattern:=S_RefineTargetPath(Target["Target"],FileData, Target)) != "D") 
						and !( Target["Target"] ~= ("i)" ListParse(PathTargets["DateKeys"])) )) ; It skips current iteration if the TargetPath either doesn't exists, or isn't a Variadic Target
						{	
							Warning.= LogFormat(Format("Unknown Target Path! [{}]",DestPattern), "WARNING", Format("{1}:{}[`"{}`"]",A_LineNumber,Name,TargetKey))
							Continue
						}
					
					If Target
					Switch Target["Type"], 0 
					{
						case "Keyword":
							RegExList:= "i)(" ListParse(Target["Key"]) ")"
							If !( FileData.Name ~=  RegExList )
								Continue
							Text.= A_Tab "Keyword:" FileData.Name "`r`n"
							
						case "FileType":
							RegExList:= "i)(" ListParse(Target["Key"]) ")"
							If !( FileData["Extension"] ~= RegExList )
								Continue
							Text.= A_Tab Format("FileType({}):", FileData["Extension"]) FileData["FullName"] "`r`n"
						Default:
						Warning.=LogFormat("UNKNOWN KEY!: `"" Target["Type"] "`" from " Paths["SourceName"] " in `"" TargetKey "`"" ,"WARNING", Format("{1}:`"{}`" {}",A_LineNumber,Name,A_Index) )
						Continue
						}

					;DestPattern:=S_RefineTargetPath(Target["Target"],FileData, Target)
					;DestPattern:= "C:\Temp - AHK\Test\Targets\"
					
					If !FileExist(DestPattern)
						DirCreate( RegExReplace( DestPattern, "\*$",""))
					FileSource:=FileData["FullPath"]
					;FileSource:="C:\Temp - AHK\Test\New Microsoft Word Document.docx"

					;DestPattern:= DestPattern 
					;SetlistVars(FileSource "`r`n" DestPattern)
					WhileIndex:=0, ErrorCount :=0, Subfix :=""
					msgbox  "asdds"
					While WhileIndex<= 256
					{
						WhileIndex:=A_Index
						If ErrorCount >1
							Subfix:=Format("* {1} ({2}).*",FormatTime("[yyyy.MM.dd HH.mm.ss]",FileData["Time"][PathTargets["FileDateType"]]),ErrorCount-1)
						else if ErrorCount
							Subfix:=Format("* {1}.*",FormatTime("[yyyy.MM.dd HH.mm.ss]",FileData["Time"][PathTargets["FileDateType"]]))
						try
							{ Msgbox A_LineNumber ")`r`nAttempts:" ErrorCount _rn FileSource _rn DestPattern Subfix _rn 
							;FileMove(FileSource,DestPattern Subfix)
								Break
							}
						catch as E
							{	
								ErrorCount+=1
							}
						
					}
					
					msgbox "Continue? " _rn A_LineNumber
				}
			
			OutputText:=UDF.Map()
			OutputText["Warning"]:=Warning
			OutputText["Text"]:=Text
			Return OutputText
			}
	; Value is Path as String
S_ProcessPathKeywords(Value, SupportedKeyWords:= "A_(Username|Y(YYY|Day|Week)|M{2,4}|D{2,4}|WDay|Desktop|ComputerName|AppData|MyDocuments|Mon)")
	{
		While (Value ~= "i)<.*>")
			{
				Try
					{RegExMatch(Value, "i)<(" SupportedKeyWords ")>", &SubPat )
					Value:=RegExReplace(Value, "i)<(" SubPat[1] ")>", %SubPat[1]%)
				}
				catch ; Once there's no more matches, the Try Block seems to Spook out and I can simply just remove the invalids "<Keyplace>" from the Source Paths
					{Value:=RegExReplace(Value, "i)(<|>)", "")
					Break
					}
			}
		Return Value
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
	vMap:=UDF.Map("TimeInfo",Map())
	
	vMap["TimeInfo"]["Months"] 	:= RegExMatch(Time_asString, "((?<Months>\d+)[M])", &Months)		?Months[2]:0
	, vMap["TimeInfo"]["Days"]	:= RegExMatch(Time_asString, "((?<Months>\d+)[Dd])", &Days)			?Days[2]:0
	, vMap["TimeInfo"]["Hours"]	:= RegExMatch(Time_asString, "((?<Months>\d+)[Hh])", &Hours)		?Hours[2]:0
	, vMap["TimeInfo"]["Minutes"]	:= RegExMatch(Time_asString, "((?<Months>\d+)[m])", &Minutes)	?Minutes[2]:0
	, vMap["TimeInfo"]["Seconds"]	:= RegExMatch(Time_asString, "((?<Months>\d+)[sS])", &Seconds)	?Seconds[2]:0
	, vMap["TimeUp"]:= vMap["TimeInfo"]["Months"] * 86400*30 + vMap["TimeInfo"]["Days"] * 86400 + vMap["TimeInfo"]["Hours"] * 3600 + vMap["TimeInfo"]["Minutes"] * 60 + vMap["TimeInfo"]["Seconds"]   
	;SetlistVars(Time_asString "`r`n" StrReplace(JSON.Dump(Map,,4), "`n", "`r`n"))
	;msgbox % Time_asString "-" Map.Months
	return vMap 
	}

Class WatchPath{
	__New(Paths,Targets){
		
		
		
		}
	
	
	}
DisplayMap(InputObject, LineNumber:="",Padding:=4){
	Static Iteration:=0
	SetlistVars(StrReplace(JXON.Dump(InputObject,Padding), "`n", "`r`n"))
	msgbox "Displaying Map :" (Iteration+=1 ) " `r`n" LineNumber
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
	Return Format("{1}{2}:{4}{3}`r`n",FormatTime(A_Now,"[hh:mm:ss.ms]"),Type,String,"")
	}

FormatSeconds(NumberOfSeconds)  ; Convert the specified number of seconds to hh:mm:ss format.
{
    
	time := 19990101  ; *Midnight* of an arbitrary date.
    time := DateAdd(time, NumberOfSeconds, "Seconds")
	
    HHmmss:=FormatTime(time,"HH:mm:ss")
    return NumberOfSeconds//86400 " Days " HHmmss
    /*
	Formats up to Days.
    https://www.autohotkey.com/docs/v1/lib/FormatTime.htm
    */
}
