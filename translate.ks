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
    if hastarget {
        local targetVessel to target.
        if target:istype("DockingPort") {
            set targetVessel to target:ship.
        }

        local oldRCS to rcs.
        rcs on.

        if mode = availableModes:CancelVelocity {
            local getVelocityError to {
                return targetVessel:velocity:orbit - ship:velocity:orbit.
            }.
            local stopCondition to {
                return (not rcs) or ag10 or abort.
            }.
            translationLib:cancelVelocityError(getVelocityError, stopCondition).
        }
        else if mode = availableModes:MaintainPosition {
            local oldSAS to sas.
            sas off.

            local originalSteering to (-targetVessel:facing) * ship:facing.
            lock steering to targetVessel:facing * originalSteering.

            local originalPosition to (-targetVessel:facing) * (-targetVessel:position).
            local stopCondition to {
                return (not rcs) or ag10 or abort.
            }.
            local targetPosition to {
                return targetVessel:position + (targetVessel:facing * originalPosition).
            }.
            local tp to translationLib:translateToPosition(targetPosition, stopCondition).
            tp:start().
            
            unlock steering.
            set sas to oldSAS.
        }

        set rcs to oldRCS.
        exit(0).
    }
    else {
        stderr("No target selected").
        exit(2).
    }
}
else {
    stderr("Invalid mode '" + mode + "'").
    exit(1).
}
