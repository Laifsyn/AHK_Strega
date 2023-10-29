#Requires AutoHotkey v2.0

/**
 * This Class manages the Folder Path where all the settings for the target will be stored.
 * The file name of "common.config" is reserved. 
 * 
 * The other settings Files can be any other .json file.
 * 
 */
Class TargetFile Extends WatcherFile {

    ArrayAbles := Array("SearchKeys")
    expects_keywords := Array("Target")
    settings_template_data := "
    ( join`r`n
    {
        "SearchKeys": [
            "Converted",
            "r/asdasda/",
            "karen"
        ],
        "Target": "C:\\Macro\\Basic 1\\Test\\<A_Mon>\\<myName1>",
        "Type": "Keyword|FileType|RegEx - Leaving as RegEx will make a match to the whole filename (including extension)",
        "SortByDate": 1,
        "CaseSensitive": "<default>"
    }
    )"
    settings_common_data := "
    (join`r`n
    {
        "FileDateType": "LastModified",
        "UserDefined": {
            "myName1": "NombreArbitrario1"
        }
    }
    )"

    /**
     * @param Path The root path where the Class will be loading all the configs for the target
     */
    __New(Path) {
        Path := Path "\Targets"
        super.__New(Path)
    }
}