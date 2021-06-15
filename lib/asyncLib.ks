@LAZYGLOBAL off.

// #EXTERNAL_IDS asyncLib
global asyncLib to ({
    local function newTask {
        parameter isDone,                   // () => boolean
                  whenDone is donothing.    // () => void
        
        if whenDone:typename = "KosDelegate" {
            local done to false.
            when isDone() then {
                whenDone().
                set done to true.
            }
            return { return done. }.
        }
        else {
            return isDone@.
        }
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