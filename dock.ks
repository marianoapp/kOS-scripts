@LAZYGLOBAL off.

parameter rollMatchMode, maxSpeed.

// import libraries
runoncepath("/commonlib/dockingLib").
runoncepath("/commonlib/streamsLib").

abort off.

streamsLib:initConsoleStreams().
global exitCode to -1.


local function exit {
    parameter paramExitCode.
    set exitCode to paramExitCode.
}

if hastarget {
    local ownPort to false.
    local targetPort to false.
    
    // TODO: compare the size of the docking ports

    // own port
    if ship:controlpart:istype("DockingPort") {
        set ownPort to ship:controlpart.
    }
    else {
        local ports to ship:dockingports.
        if ports:length > 0 {
            set ownPort to ports[0].
        }
        else {
            stderr("No docking ports on this vessel").
            exit(2).
        }
    }

    // target port
    if target:istype("DockingPort") {
        // target is a docking port
        set targetPort to target.
    }
    else {
        // target is a ship
        set targetPort to dockingLib:findDockingPort(target).
    }

    if targetPort:istype("DockingPort") {
        if maxSpeed > 5 {
            set maxSpeed to 5.
            stdout("Limiting max speed to 5 m/s").
        }

        sas off.
        rcs on.

        // dock with the target
        dockingLib:dock(ownPort, targetPort, rollMatchMode, maxSpeed).
        exit(0).
        
        rcs off.
        sas on.
    }
    else {
        stderr("No docking ports on target vessel").
        exit(3).
    }
}
else {
    stderr("No target selected").
    exit(1).
}

