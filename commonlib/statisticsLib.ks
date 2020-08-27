@LAZYGLOBAL off.


global statisticsLib to ({
    local function movingAvgVector {
        parameter maxCount.
        
        local items to queue().
        local total to V(0,0,0).
        
        local function addItem {
            parameter newItem.
            
            items:push(newItem).
            set total to total + newItem.
            if items:length > maxCount {
                set total to total - items:pop().
            }
            return total / items:length.
        }
        
        return lexicon(
            "addItem", addItem@
        ).
    }
        
    return lexicon(
        "movingAvgVector", movingAvgVector@
    ).
}):call().