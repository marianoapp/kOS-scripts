@LAZYGLOBAL off.

global schedulingLib to ({
    local function simpleScheduler {
        parameter action, timeout.

        local stopFlag to false.

        local function addTrigger {
            local nextTime to time:seconds + timeout.
            when time:seconds > nextTime then {
                action().
                if stopFlag {
                    return false.
                }
                else {
                    set nextTime to time:seconds + timeout.
                    return true.
                }
            }
        }

        local function start {
            set stopFlag to false.
            action().
            addTrigger().
        }

        local function stop {
            set stopFlag to true.
        }
        
        return lexicon(
            "start", start@,
            "stop", stop@
        ).
    }


    return lexicon(
        "simpleScheduler", simpleScheduler@
    ).
}):call().