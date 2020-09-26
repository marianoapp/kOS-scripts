@LAZYGLOBAL off.

global schedulingLib to ({
    local function timeoutScheduler {
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

    local function eventScheduler {
        local eventList to list().
        local eventIndex to 0.
        local currentEvent to list(0, {}).
        local stopFlag to false.
        local liveTrigger to false.

        local function addEvent {
            parameter eventTime, action.
            
            if eventTime > time:seconds {            
                local newEvent to list(eventTime, action).

                // insert at the end
                if eventList:length = 0 or eventList[eventList:length-1][0] < eventTime {
                    eventList:add(newEvent).
                    if eventList:length = 1 {
                        addTrigger().
                    }
                }
                else {
                    // insert sorted
                    for index in range(eventList:length) {
                        if eventList[index][0] > eventTime {
                            eventList:insert(index, newEvent).
                            break.
                        }
                    }
                    if eventTime < currentEvent[0] {
                        set currentEvent to newEvent.
                    }
                }
            }
        }

        local function addTrigger {
            set stopFlag to false.
            set eventIndex to 0.
            set currentEvent to eventList[eventIndex].

            if not liveTrigger {
                set liveTrigger to true.

                when abs(currentEvent[0] - time:seconds) < 0.01 then {
                    local returnValue to false.
                    if not stopFlag {
                        currentEvent[1]().
                        set eventIndex to eventIndex + 1.
                        if eventIndex < eventList:length {
                            set currentEvent to eventList[eventIndex].
                            set returnValue to true.
                        }
                        else {
                            // reset the list when we reach the end
                            eventList:clear().
                        }
                    }
                    set liveTrigger to returnValue.
                    return returnValue.
                }
            }
        }

        local function reset {
            set stopFlag to true.
            eventList:clear().
        }
        
        return lexicon(
            "addEvent", addEvent@,
            "reset", reset@
        ).
    }

    local function sequenceScheduler {
        local eventList to list().
        local currentEvent to list({}, {}).
        local eventIndex to 0.
        local stopFlag to false.
        local liveTrigger to false.
        
        local function addEvent {
            parameter condition, action.

            eventList:add(list(condition, action)).
            if eventList:length = 1 {
                addTrigger().
            }
        }

        local function addTrigger {
            set stopFlag to false.
            set eventIndex to 0.
            set currentEvent to eventList[eventIndex].

            if not liveTrigger {
                set liveTrigger to true.

                when currentEvent[0]() then {
                    local returnValue to false.
                    if not stopFlag {
                        currentEvent[1]().
                        set eventIndex to eventIndex + 1.
                        if eventIndex < eventList:length {
                            set currentEvent to eventList[eventIndex].
                            set returnValue to true.
                        }
                        else {
                            // reset the list when we reach the end
                            eventList:clear().
                        }
                    }
                    set liveTrigger to returnValue.
                    return returnValue.
                }
            }
        }

        local function reset {
            set stopFlag to true.
            eventList:clear().
        }

        return lexicon(
            "addEvent", addEvent@,
            "reset", reset@
        ).
    }


    return lexicon(
        "timeoutScheduler", timeoutScheduler@,
        "eventScheduler", eventScheduler@,
        "sequenceScheduler", sequenceScheduler@
    ).
}):call().