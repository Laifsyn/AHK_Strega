Class class_logger {
    static store_path := A_WorkingDir "\configs\log - " RegExReplace(A_ScriptName, "\.ahk$", "") ".txt"
    session_id := 0
    is_appending := false
    __New() {
        this.try_create_file()
        FileAppend("`r`n" this.session_header() "`r`n", class_logger.store_path)
    }
    append(Text := "", level := 0) {
        FileAppend(FormatTime(A_Now, "[yyyy.MM.dd HH:mm:ss." A_MSec "] ") Text "`r`n", class_logger.store_path)
    }
    append_to_stack := Array()
    consume_stack(f := "") {

        if !this.append_to_stack.Length {
            return
        }


    }
    try_create_file() {
        if !FileExist(class_logger.store_path) or !FileRead(class_logger.store_path) {
            content_to_write := this.log_header()
            FileAppend(content_to_write "`r`n", class_logger.store_path)
            return 0
        }
        else
        {
            if (size := FileGetSize(class_logger.store_path, "M")) > (limit := 10) {
                if msgbox(Format("the log files currently weights {} MBs. `r`nWanna zip it or leave it as is?`r`n{}", size, class_logger.store_path), , "YesNo") != "yes"
                    return
                SplitPath(class_logger.store_path, , &path, , &name)
                if !FileExist(path "\logs")
                    DirCreate(path "\logs")
                new_path := Format("{}\logs\{} {}.zip", path, FormatTime(FileGetTime(class_logger.store_path, "M"), "yyyy-MM-dd HH.mm.ss"), name)
                RunWait "PowerShell.exe -Command Compress-Archive -LiteralPath '" class_logger.store_path "' -CompressionLevel Optimal -DestinationPath '" new_path "'"
                FileDelete(class_logger.store_path)
                this.try_create_file()
            }
        }
    }

    log_header() {
        return format("{} {}", FormatTime(A_Now, "[yyyy, MM, dd HH:mm:ss]"), A_ScriptName)
    }
    session_header() {
        return format("{}", FormatTime(A_Now, "#[yyyy, MM, dd HH:mm:ss]"))
    }
}