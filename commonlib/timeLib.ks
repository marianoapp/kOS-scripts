@LAZYGLOBAL off.

global timeLib to ({
    local function alignTimestamp {
        parameter timeValue.
        local referenceValue to time:seconds.
        return alignOffset(timeValue-referenceValue) + referenceValue.
    }

    local function alignOffset {
        parameter timeOffset.
        return round(timeOffset*50) / 50.
    }
    
    return lexicon(
        "alignTimestamp", alignTimestamp@,
        "alignOffset", alignOffset@
    ).
}):call().