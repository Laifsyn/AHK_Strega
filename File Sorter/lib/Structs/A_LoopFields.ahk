Class A_LoopFields {
    fullName := 0
    ext := 0
    name := 0
    fullPath := 0
    path := 0
    timeModified := 0

    __new(obj) {
        for prop, _content in this.OwnProps() {
            if obj.HasOwnProp(prop)
                this.%prop% := obj.%prop%
            else
                throw Error("Object is missing a property!", , prop)
        }
        ; SetListVars(UDF.getPropsList(obj), 1, A_LineNumber)
    }
}