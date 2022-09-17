

^+.::kb_SendTodayDate()
^+,::kb_SendTodayDate_AsSpanish()

kb_SendTodayDate(){
    date := getTodayDate()
    myExcel_english_Date:=date.month "/" date.day "/" date.year
    SendInput, % myExcel_english_Date
    tooltip, month/day/year, A_CaretX, A_caretY,1
    sleep, 2500
    tooltip,, , ,1

}
kb_SendTodayDate_AsSpanish(){
    date := getTodayDate()
    myExcel_english_Date:=date.day "/" date.month "/" date.year
    SendInput, % myExcel_english_Date
    tooltip, day/month/year, A_CaretX, A_caretY,1
    sleep, 2500
    tooltip,, , ,1
}

getTodayDate() {
    return {year:A_YYYY, month:A_Mon, day:A_DD, Weekday:A_WDay, yearDay:A_YDay, name:{fullDay:A_DDDD, shortDay:A_DDD, fullMonth:A_MMMM, shortMonth:A_MMM}}
}