@LAZYGLOBAL off.

// #EXTERNAL_IDS timeLib
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
    
    return lex(
        "alignTimestamp", alignTimestamp@,
        "alignOffset", alignOffset@
    ).
}):call().