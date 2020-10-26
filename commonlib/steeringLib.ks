@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/asyncLib").

global steeringLib to ({
    local function getDirectionNoRoll {
        parameter vector.
        return lookdirup(vector, ship:facing:topvector).
    }
    
    local function getVesselDirection {
        parameter targetVessel.
        return getDirectionNoRoll(targetVessel:position).
    }
    
    local function steerToConstant {
        parameter direction.
        
        lock steering to direction.
        // local isDone to getDoneCheck().
        wait until isDone().
    }
    
    local function steerToConstantAsync {
        parameter direction.
        
        lock steering to direction.
        return asyncLib:newTask(isDone@).
    }
    
    local function steerToDelegate {
        parameter delegate.
        
        lock steering to delegate().
        // local isDone to getDoneCheck().
        wait until isDone().
    }
    
    local function steerToDelegateAsync {
        parameter delegate.
        
        lock steering to delegate().
        return asyncLib:newTask(isDone@).
    }
    
    local function isDone {
        return steeringmanager:angleerror > 0 and steeringmanager:angleerror < 20 and steeringmanager:rollerror < 20.
    }

    local function getNewSteeringTask {
        return asyncLib:newTask(isDone@).
    }
    
    // local function getDoneCheck {
        // // the steering manager takes a few frames to start returning valid data
        // local count to 5.
        // return {
            // if count = 0 {
                // return steeringmanager:angleerror > 0 and steeringmanager:angleerror < 10.
            // }
            // else {
                // set count to count - 1.
                // return false.
            // }
        // }.
    // }

    return lexicon(
        "getDirectionNoRoll", getDirectionNoRoll@,
        "getVesselDirection", getVesselDirection@,
        "steerToConstant", steerToConstant@,
        "steerToConstantAsync", steerToConstantAsync@,
        "steerToDelegate", steerToDelegate@,
        "steerToDelegateAsync", steerToDelegateAsync@,
        "getNewSteeringTask", getNewSteeringTask@
    ).
}):call().