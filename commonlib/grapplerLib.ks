@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/asyncLib").

global grapplerLib to ({
    local function getGrapplers {
        parameter vesselObj is ship.
        local grapplersList to vesselObj:partsnamedpattern("GrapplingDevice|smallClaw").
        return grapplersList.
    }

    local function controlFrom {
        parameter part.
        
        local module to part:getModule("ModuleGrappleNode").
        module:doevent("control from here").
    }
    
    local function setArmed {
        parameter part, armed.
        
        local module to part:getModule("ModuleAnimateGeneric").
        local eventName to "arm".
        if not armed {
            set eventName to "disarm".
        }
        if module:hasevent(eventName) {
            module:doevent(eventName).
        }
    }
    
    local function arm {
        parameter part.
        setArmed(part, true).
    }
    
    local function disarm {
        parameter part.
        setArmed(part, false).
    }
    
    local function doGrappleNodeEvent {
        parameter part, eventName.
        
        local module to part:getModule("ModuleGrappleNode").
        if module:hasevent(eventName) {
            module:doevent(eventName).
        }
    }
    
    local function release {
        parameter part.
        doGrappleNodeEvent(part, "release").
    }
    
    local function freePivot {
        parameter part.
        doGrappleNodeEvent(part, "free pivot").
    }
    
    local function lockPivot {
        parameter part.
        doGrappleNodeEvent(part, "lock pivot").
    }
    
    local function grabDone {
        parameter part.
        return part:getModule("ModuleGrappleNode"):hasevent("release").
    }
    
    local function grabDoneAsync {
        parameter part.
        
        local module to part:getModule("ModuleGrappleNode").
        local isDone to { return module:hasevent("release"). }.
        return asyncLib:newTask(isDone@).
    }
        
    return lexicon(
        "getGrapplers", getGrapplers@,
        "controlFrom", controlFrom@,
        "setArmed", setArmed@,
        "arm", arm@,
        "disarm", disarm@,
        "release", release@,
        "freePivot", freePivot@,
        "lockPivot", lockPivot@,
        "grabDone", grabDone@,
        "grabDoneAsync", grabDoneAsync@
    ).
}):call().