Class StoredTimestamp extends StoredTimestamp_Internals {
    __New(absolute_path, parent) {
        this.parent := parent
            , SplitPath(absolute_path, &filename, &path, , &namespace)
            , this.namespace := namespace
            , this.path := path
            , this.filename := filename
            , this.LoadMap()
        return this
    }
    /**
     * Dumps the data
     */
    SyncFile() {
        base_map := Map()
        for path, files in this {
            if !base_map.Has(path)
                base_map[path] := Map()
            for file, obj in files
                base_map[path][file] := obj.Value
        }

        serialized_str := JXON.Dump(this, 1)
            , timestamp_file := FileOpen(this.path, 0x3, this.Encoding)
            , timestamp_file.Write(serialized_str)
            , timestamp_file.Length := timestamp_file.pos
            , timestamp_file.Close()
    }

    HasKeys(path, filename) => this.Has(path) && this[path].has(filename)
    Reload() => this.LoadMap()
}


Class StoredTimestamp_Internals extends Map {
    CaseSense := "Off"
    Sync := true
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
        if !(FileExist(absolute_path) != "A")
            throw ValueError("Path doesn't point to a file!", , absolute_path)
        SplitPath(absolute_path, &filename, &dir)
            , super[dir][filename].Value := value
            , super[dir][filename].lastModified := A_Now
    }
    /**
     * Create a space in memory for the address
     * 
     * @return void
     */
    Create(absolute_path, value) {
        if (FileExist(absolute_path) != "A")
            throw ValueError("Path doesn't point to a file!", , absolute_path)
        SplitPath(absolute_path, &filename, &dir)
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
        If !FileExist(this.search_path){
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
                absolute_path := key_path "\" key_filename
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