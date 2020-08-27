@LAZYGLOBAL off.

global asyncLib to ({
    local function newTask {
        parameter isDone.           // () => boolean
        parameter whenDone is {}.   // () => void
        
        local done to false.
        when isDone() then {
            whenDone().
            set done to true.
        }
        return { return done. }.
    }

    local function await {
        parameter task.
        if not task() {
            wait until task().
        }
    }
    
    local function taskDone {
        parameter task.
        return task().
    }

    return lexicon(
        "newTask", newTask@,
        "await", await@,
        "taskDone", taskDone@
    ).
}):call().