@LAZYGLOBAL off.

parameter landingMode,                  // Scalar       one of landingModeEnum values
          altitudeMargin is 0,          // Scalar       altitude margin above the surface/target
          targetPosition is V(0,0,0).   // Vector       target position in BODY-RAW coordinates

// import libraries
runoncepath("/commonlib/landingLib").
runoncepath("/commonlib/streamsLib").
runoncepath("/commonlib/schedulingLib").
runoncepath("/commonlib/estimationLib").
runoncepath("/commonlib/translationLib").
runoncepath("/commonlib/vectorLib").

local landingModeEnum to lexicon(
    "LandNow", 1,
    "LandAtPosition", 2
).

streamsLib:initConsoleStreams().

abort off.

local scheduler to schedulingLib:eventScheduler().
local execQueue to queue().
global exitCode to -1.

local function exit {
    parameter paramExitCode.
    execQueue:push({ set exitCode to paramExitCode. }).
}

local function getIsp {
    // TODO: fix this
    // assume all active engines have the same Isp
    local engineList to list(). // <-- this shouldn't be required
    list engines in engineList.
    for eng in engineList {
        if eng:ignition {
            return eng:isp.
        }
    }.
    return 0.
}

local function landNow {
    local progressUpdater to {
        parameter simInfo.
        stdout("Sim done in " + simInfo:steps + " steps with dt " + simInfo:dt + "            ", 0,0).
        stdout("AltErr: " + simInfo:altitudeError + ", VelErr: " + simInfo:velocityError + ", BSD: " + simInfo:burnStartDelay + "          ", 0,1).
    }.

    local landingInfo to landingLib:calculateLanding(ship:availablethrust, getIsp(), altitudeMargin, progressUpdater@).

    scheduler:addEvent(landingInfo:burnStartTime, { lock throttle to 1. }).
    scheduler:addEvent(landingInfo:burnEndTime, {
        unlock throttle.
        execQueue:push(pointRadialOut@).
        execQueue:push(landingDone@).
    }).

    stdout("Burn will start at " + time(landingInfo:burnStartTime):clock).
    stdout("Landing at " + time(landingInfo:burnEndTime):clock).

    drawLandingPosArrow(landingInfo:landingPosition).
}

local function landAtPosition {
    if altitudeMargin > 0 {
        set targetPosition to targetPosition + (targetPosition:normalized * altitudeMargin).
    }

    local burnDirection to ship:facing.
    lock steering to burnDirection.

    local progressUpdater to {
        parameter simInfo.

        if simInfo:haskey("landingSimInfo") {
            local landingSimInfo to simInfo:landingSimInfo.
            stdout("Sim done in " + landingSimInfo:steps + " steps with dt " + landingSimInfo:dt + "            ", 0,0).
            stdout("AltErr: " + landingSimInfo:altitudeError + ", VelErr: " + landingSimInfo:velocityError + ", BSD: " + landingSimInfo:burnStartDelay + "          ", 0,1).
        }
        else {
            stdout("ProgradeErr: " + round(simInfo:progradeError, 2) + ", NormalErr: " + round(simInfo:normalError, 2) + "        ", 0,3).
            stdout("ManeuverDV: " + vectorLib:roundVector(simInfo:nodeDV, 4) + "        ", 0,4).
            stdout("DeorbitThrust: " + round(simInfo:deorbitThrust, 4) + "        ", 0,5).
            stdout("LoopCount: " + simInfo:loopCount + "  ", 0,6).

            // start steering when the solution gets close enough
            if abs(simInfo:progradeError) < 5000 and abs(simInfo:normalError) < 500 {
                set burnDirection to lookdirup(simInfo:burnVector, ship:facing:topvector).
            }
        }
    }.

    local deorbitInfo to landingLib:calculateDeorbitBurn(ship:availablethrust, getIsp(), targetPosition, progressUpdater@).
    
    sas off.
    lock steering to lookdirup(deorbitInfo:burnVector, ship:facing:topvector).
    local throttleValue to deorbitInfo:burnThrust / ship:availablethrust.

    scheduler:addEvent(deorbitInfo:burnStartTime, { lock throttle to throttleValue. }).
    scheduler:addEvent(deorbitInfo:burnEndTime, {
        unlock throttle.
        unlock steering.
        execQueue:push({ refineOrbit(deorbitInfo:trajectoryData). }).
    }).
    scheduler:addEvent(deorbitInfo:landingInfo:burnStartTime, { lock throttle to 1. }).
    scheduler:addEvent(deorbitInfo:landingInfo:burnEndTime, {
        unlock throttle.
        execQueue:push(pointRadialOut@).
        execQueue:push({ refineLanding(targetPosition). }).
        execQueue:push(landingDone@).
    }).

    drawLandingPosArrow(deorbitInfo:landingInfo:landingPosition).
}

local function drawLandingPosArrow {
    parameter landingPosition.

    local sp to vecdrawargs(v(0,0,0), v(0,0,0), green, "", 1, true).
    set sp:width to 10.
    local landingPosNorm to landingPosition:normalized.
    local landingPosStart to landingPosition + (landingPosNorm * 1000).
    set sp:startupdater to { return landingPosStart + body:position. }.
    set sp:vec to -landingPosNorm * 1000.
}

local function refineOrbit {
    parameter trajectoryData.

    // extract time and velocity from the trajectory data
    local dataList to list().
    for dataPoint in trajectoryData {
        dataList:add(list(dataPoint[0], dataPoint[2])).
    }
    local interpolator to estimationLib:forwardLinearInterpolator(dataList).

    stdout("Fine tuning orbit", 0, 8).
    local velocityError to V(100,0,0).
    local getVelocityError to {
        local vel to interpolator:getValue(time:seconds).
        set velocityError to vel - velocityat(ship, time):surface.
        stdout("VelErr: " + round(velocityError:mag, 6) + "        ", 0, 9).
        return velocityError.
    }.
    local stopCondition to {
        return (velocityError:mag < 0.00025) or interpolator:EOF() or (not rcs) or abort.
    }.

    wait until abs(dataList[0][0] - time:seconds) < 0.01.   // wait until the first data point
    sas on.
    rcs on.
    translationLib:cancelVelocityError(getVelocityError@, stopCondition@).
}

local function refineLanding {
    parameter landingPosition.

    local stopFlag to false.
    // TODO: use the main engines to hover / slow the descent
    local upVector to landingPosition:normalized.    // a BODY centered vector always points in a radial out direction
    local landingPositionFunc to { return vxcl(upVector, landingPosition + body:position). }.
    local stopCondition to { return stopFlag or ship:status = "landed" or abort. }.
    local tp to translationLib:translateToPosition(landingPositionFunc, stopCondition, V(0,0,0), 1).
    when tp:getDistance():mag < 0.25 then {
        set stopFlag to true.
    }
    rcs on.
    tp:start().
}

local function pointRadialOut {
    sas on.
    wait 0.
    set sasmode to "RADIALOUT".
}

local function landingDone {
    wait until ship:status = "landed" or abort.
    rcs off.
    exit(0).
}


if landingMode = landingModeEnum:LandNow {
    if ship:status = "SUB_ORBITAL" {
        execQueue:push(landNow@).
    }
    else {
        stderr("Invalid status, 'LandNow' can only be used when on a suborbital trajectory").
        exit(2).
    }
}
else if landingMode = landingModeEnum:LandAtPosition {
    if ship:status = "ORBITING" {
        execQueue:push(landAtPosition@).
    }
    else {
        stderr("Invalid status, 'LandAtPosition' can only be used while in orbit").
        exit(2).
    }
}
else {
    stderr("Invalid landing mode").
    exit(1).
}


// main loop
until exitCode >= 0 {
    wait until execQueue:length > 0.
    local nextStep to execQueue:pop().
    nextStep().
}

clearvecdraws().