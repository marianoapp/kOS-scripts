@LAZYGLOBAL off.

parameter mode.

// import libraries
runoncepath("/commonlib/translationLib").
runoncepath("/commonlib/streamsLib").

abort off.
ag10 off.

streamsLib:initConsoleStreams().
global exitCode to -1.


local function exit {
    parameter paramExitCode.
    set exitCode to paramExitCode.
}

local availableModes to lexicon(
    "CancelVelocity", 1,
    "MaintainPosition", 2
).

if availableModes:hasvalue(mode) {
    if hastarget or ship:velocity:surface:mag < 20 {
        local oldRCS to rcs.
        rcs on.

        local stopCondition to {
            return (not rcs) or ag10 or abort.
        }.

        if hastarget {
            // TODO: make sure the target is a vessel (or part of a vessel) and that the speed difference isn't too high
            // target mode
            local targetVessel to target.
            if target:istype("DockingPort") {
                set targetVessel to target:ship.
            }

            if mode = availableModes:CancelVelocity {
                local getVelocityError to {
                    return targetVessel:velocity:orbit - ship:velocity:orbit.
                }.
                translationLib:cancelVelocityError(getVelocityError, stopCondition).
            }
            else if mode = availableModes:MaintainPosition {
                local oldSAS to sas.
                sas off.
            
                local originalSteering to (-targetVessel:facing) * ship:facing.
                lock steering to targetVessel:facing * originalSteering.

                local originalPosition to (-targetVessel:facing) * (-targetVessel:position).
                local targetPosition to {
                    return targetVessel:position + (targetVessel:facing * originalPosition).
                }.
                
                local tp to translationLib:translateToPosition(targetPosition, stopCondition).
                tp:start().

                unlock steering.
                set sas to oldSAS.
            }
        }
        else {
            // surface mode
            if mode = availableModes:CancelVelocity {
                local getVelocityError to {
                    return -ship:velocity:surface.
                }.
                translationLib:cancelVelocityError(getVelocityError, stopCondition).
            }
            else if mode = availableModes:MaintainPosition {
                local originalPosition to -body:position.
                local targetPosition to {
                    return originalPosition + body:position.
                }.
                local tp to translationLib:translateToPosition(targetPosition, stopCondition).
                tp:start().
            }
        }

        set rcs to oldRCS.
        exit(0).
    }
    else {
        stderr("No target selected and moving too fast").
        exit(2).
    }
}
else {
    stderr("Invalid mode '" + mode + "'").
    exit(1).
}
