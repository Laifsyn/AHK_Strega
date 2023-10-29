Class StoredTimestamp extends StoredTimestamp_Internals {
    __New(absolute_path, parent) {
        this.parent := parent
            , SplitPath(absolute_path, &filename, &path, , &namespace)
            , this.namespace := namespace
            , this.path := path
            , this.filename := filename
            , this.LoadMap()
        this.off_sync := false
        return this
    }
    /**
     * Dumps the data
     */
    SyncFile() {
        if !this.off_sync
            return ;MsgBox("Nothing to sync")
        base_map := Map()
        for path, files in this {
            if !base_map.Has(path)
                base_map[path] := Map()
            for file, obj in files
                base_map[path][file] := obj.Value
        }
        serialized_str := JXON.Dump(base_map, 2)
        timestamp_file := FileOpen(this.search_path, 0x3, this.Encoding)
            , timestamp_file.Write(serialized_str)
            , timestamp_file.Length := timestamp_file.pos
            , timestamp_file.Close()
            , this.off_sync := false
    }

    HasKeys(path, filename) => this.Has(path) && this[path].has(filename)
    Reload() => this.LoadMap()
}


Class StoredTimestamp_Internals extends Map {
    CaseSense := "Off"
    off_sync := true
    Synced := false
    isValid := true
    Encoding := A_FileEncoding
    __Delete() {
        this.parent := ""
        for k, v in this
            this[k].Clear()
        this.Clear()
    }

    search_path {
        get => this.path "\" this.filename
    }
    CastCloneMap(CastTarget, MapToCast, NestLevel := 1) => CastCloneMap(CastTarget, MaptoCast, NestLevel)

    ClearUnused() {
        for key_path, filenames in this
            for key_filename, timestamps in filenames
                if !super[key_path][key_filename].HasOwnProp("last_read")
                    super[key_path].Delete(key_filename)
    }
    /**
     * updates the map's content
     */
    Update(absolute_path, value) {
        if (FileExist(absolute_path) != "A")
            throw ValueError("Path doesn't point to a file!", , absolute_path)
        SplitPath(absolute_path, &filename, &dir)
            , super[dir][filename].Value := value
            , super[dir][filename].lastModified := A_Now
            , this.off_sync := true
    }
    /**
     * 
     * @param absolute_path 
     * @param value 
     * @returns {void} 
     */
    Create(absolute_path, value) {
        if (FileExist(absolute_path) != "A")
            throw ValueError("Path doesn't point to a file!", , absolute_path)
        SplitPath(absolute_path, &filename, &dir)
        ; Populates unexistent nodes
        if !super.Has(dir)
            super[dir] := Map(), super[dir].CaseSense := "Off"
        if !super[dir].has(filename)
            super[dir][filename] := Object()
        else {
            this.Update(absolute_path, value)
            return
        }
        super[dir][filename].Value := value
            , super[dir][filename].created_timestamp := A_Now
            , super[dir][filename].last_modified := super[dir][filename].created_timestamp
            , this.off_sync := true
    }

    Clear_file(absolute_path) {
        if (FileExist(absolute_path) != "A")
            throw ValueError("Path doesn't point to a file!", , absolute_path)
        SplitPath(absolute_path, &filename, &dir)
        if !super.Has(dir)
            return
        if !super[dir].Has(filename)
            return
        super[dir].Delete(filename)
            , this.off_sync := true
        if super[dir].Count == 0
            super.Delete(dir)
    }

    /**
     * Get timestamp stored from an absolute_path
     */
    Get(absolute_path) {
        SplitPath(absolute_path, &filename, &dir)
        if !this.HasKeys(dir, filename)
            throw Error("Object has no data stored for this path", , absolute_path)
        super[dir][filename].last_read := A_Now
        return super[dir][filename].Value
    }

    FileRead() {
        If !FileExist(this.search_path) {
            FileAppend("{}", this.search_path, this.Encoding)
            return "{}"
        }
        return FileRead(this.search_path, this.Encoding)
    }
    /**
     * Loads a map from file
     * @returns {storedtimestamp} 
     */
    LoadMap() {
        file_data := this.FileRead()
        last_modified := FileGetTime(this.search_path, "M")
        file_map := JXON.Load(file_data)
        ; populate the class with the data
        for key_path, filenames in file_map {
            if !super.Has(key_path)
                super[key_path] := Map(),
                    super[key_path].CaseSense := "Off"
            for key_filename, timestamps in filenames {
                if !FileExist(absolute_path := key_path "\" key_filename)
                    continue
                if !super[key_path].Has(key_filename)
                    super[key_path][key_filename] := Object()
                super[key_path][key_filename].created_timestamp := A_Now
                if timestamps is Map {
                    for prop_name, value in timestamps {
                        if prop_name = "Value"
                            this.Update(absolute_path, value)
                    }
                    if !super[key_path][key_filename].HasOwnProp("Value")
                        this.Update(absolute_path, last_modified)
                }
                else
                    this.Update(absolute_path, timestamps)
            }
        }
        return this
    }
}