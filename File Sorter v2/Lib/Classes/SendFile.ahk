Class SendFile {
    old_path := unset
    new_path := unset
    static ENUMS_MOVE := 2
    static ENUMS_COPY := 4
    static ENUMS_REPLACE := 8
    static ENUMS_SYNC := 16

    __New(from, to) {
        if !FileExist(from)
            throw Error("File couldn't be found", , from)
        if (file_type := FileExist(from)) != "A"
            throw Error("Expects a File, but got " file_type, , from)

        this.old_path := from,
            this.new_path := to

    }

    MoveFile(Move_Copy_Sync := this.ENUMS_MOVE) {
        cycles := 0
        switch Move_Copy_Sync {
            case SendFile.ENUMS_MOVE:
                original_new_path := this.new_path
                while FileExist(this.new_path) {
                    this.new_path := this.add_copy_index(original_new_path, A_Index)
                    if A_Index > 255
                        throw Error("Index overflowed. Too many copies!", , this.new_path)
                    cycles := A_index
                }
                ; MsgBox(StrReplace(this.old_path, "\\", "\") "`r`n" StrReplace(this.new_path, "\\", "\") "`r`n" A_ScriptName "`r`nLineNUmber:" A_LineNumber)
                SplitPath(this.new_path, , &path)
                if !FileExist(path)
                    DirCreate(path)
                FileMove(this.old_path, this.new_path)
                return this.new_path
            case SendFile.ENUMS_COPY:
                throw Error("TODO!!", , "UNDEFINED BEHAVIOUR")
            case SendFile.ENUMS_REPLACE:
                throw Error("TODO!!", , "UNDEFINED BEHAVIOUR")
            case SendFile.ENUMS_SYNC:
                if 1
                    throw Error("TODO!!", , "UNDEFINED BEHAVIOUR")
                if FileExist(this.new_path) {
                    modified_new := FileGetTime(this.new_path, "M")
                    modified_old := FileGetTime(this.old_path, "M")
                    ; if DateDiff(modified_new, modified_old, "s") <= 0
                    ;     FileCopy
                }
            default:
                throw Error("TODO!!", , "UNDEFINED BEHAVIOUR")

        }
    }

    add_copy_index(full_path, index) {
        SplitPath(full_path, , &path, &ext, &file_name)
        return Format("{}\{} ({}).{}", path, file_name, index, ext)
    }
}