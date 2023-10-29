#Requires AutoHotkey v2.0


/**
 * Used to better estimate the StrCapacity size that we need to allocate when using ReplaceString().
 * 
 * @param src 
 * @param char 
 * @returns {number} 
 */
countChar(&src, char) {
    count := 0
    Loop Parse src
        if A_LoopField == char
            count++
    return count
}
/**
 * This function is to be used to make it easier to write Window's paths.
 * 
 * You would write "C:\Program Files\something.txt" instead of 'C:\\\Program Files\\\something.txt' in the JSON file
 * @param &src String to input
 * @returns &str
 */
ReplaceString(&src) {
    Static specialChars := '', next := (pos) => SubStr(src, pos + 1, 1)
    pos := 0
    estimatedSize := VarSetStrCapacity(&new, StrLen(src) + countChar(&src, "\"))

    while ((ch := SubStr(src, ++pos, 1)) != "") {
        new .= ch
        ; this will duplicate every instance of inverted slash in the string. It ultimately will disable special chars and treat them as string literals. Double Quotes is still supported though
        ; if ch == "\" and !InStr(specialChars, next(pos))  ; Removed because I see no moment when there might be the need for convert a special char
        if ch == "\"
            new .= ch
        if ch == "\" and InStr(specialChars, next(pos))
            new .= ch
    }
    ; actualSize := VarSetStrCapacity(&new)
    ; msgbox Format("Estimated: {}, `r`nactualSize:{}`r`n{}`r`n{}", estimatedSize, actualsize, src, new)
    ; Replace the old string.
    src := new
    return src
}