@LAZYGLOBAL off.

// #EXTERNAL_IDS stringLib
global stringLib to ({
    local function findAll {
        parameter content, searchFor.
        
        local index to 0.
        local lastIndex to 0.
        local matches to list().
        
        until index = -1 {
            set index to content:findat(searchFor, lastIndex).
            if index > -1 {
                matches:add(index).
                set lastIndex to index + 1.
            }
        }
        
        return matches.
    }
    
    return lex(
        "findAll", findAll@
    ).
}):call().