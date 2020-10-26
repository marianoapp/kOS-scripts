@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/pidLib").
runoncepath("/commonlib/vectorLib").
runoncepath("/commonlib/calculusLib").
runoncepath("/commonlib/rcsLib").
runoncepath("/commonlib/asyncLib").

global translationLib to ({
    local pidTuneMode to lexicon(
        "SetpointTracking", 1,
        "DisturbanceRejection", 2
    ).

    local function translate {
        parameter translation, duration.
        set ship:control:translation to translation.
        wait duration.
        set ship:control:translation to V(0,0,0).
    }

    local function translateAsync {
        parameter translation, duration.
        
        local endTime to time:seconds + duration.
        local isDone to { return time:seconds >= endTime. }.
        local whenDone to { set ship:control:translation to V(0,0,0). }.
        
        set ship:control:translation to translation.
        return asyncLib:newTask(isDone, whenDone).
    }
    
    local function initializePids {
        parameter tuneMode.
        
        // TODO: cache these values, maybe in a file in the local core memory
        local rcsThrust to rcsLib:getTotalThrustList().
        
        local minAxisAccs to vectorLib:elementWiseMin(rcsThrust[0] / ship:mass, rcsThrust[1] / ship:mass).
        local avgAxisThrusts to (rcsThrust[0] + rcsThrust[1]) / 2.
        local availableAxisAccs to avgAxisThrusts / ship:mass.
        // TODO: load pids from file, if it exists
        
        local pids to pidLib:pidVector(0.776, 0, 0, -1, 1).

        local kiFactor to choose 1 if tuneMode = pidTuneMode:SetpointTracking else 5.
        local kis to kiFactor * 0.01210737 * availableAxisAccs.
        pids:setKis(kis).
        
        return list(pids, minAxisAccs).
    }

    local function translateToPosition {
        parameter targetPosition,                   // () => Vector     returns the target position (RAW)
                  stopCondition,                    // () => Boolean    returns true to abort the loop
                  referencePosition is V(0,0,0),    // Vector           point of reference used to measure the distance (SHIP)
                  speedLimit is 5.                  // Double           lower and upper speed limits
            
        local distanceToTarget to V(1000,1000,1000).    // just a big number
        local currentVelocity to V(0,0,0).
        local pidsInfo to initializePids(pidTuneMode:SetpointTracking).
        local pids to pidsInfo[0].
        local minAxisAccs to pidsInfo[1].
        local factor to min(min(minAxisAccs:X, minAxisAccs:Y), minAxisAccs:Z) / 4.
        
        local function start {
            local velObj to calculusLib:vectorDerivative().
            local currentTime to 0.
            local desiredVelocity to V(0,0,0).
            
            // aliases of library functions to improve performance
            local velObj_calculate to velObj:calculate.
            local pids_update to pids:update.
            local shipCtrl to ship:control.

            pids:setpoint(V(0,0,0)).
            
            // make sure the loop starts on the next tick so it doesn't get interrupted in the middle
            wait 0.
            
            until stopCondition() {
                set currentTime to time:seconds.
                
                set distanceToTarget to targetPosition() - facing*referencePosition.
                set desiredVelocity to distanceToTarget:normalized * min(distanceToTarget:mag * factor, speedLimit).

                // calculate the current velocity as dx/dt
                set currentVelocity to -velObj_calculate(currentTime, distanceToTarget).
                // compare the current velocity to the desired one and make corrections
                set shipCtrl:translation to (-facing) * pids_update(currentTime, currentVelocity - desiredVelocity).
                
                wait 0.
            }.

            set shipCtrl:translation to V(0,0,0).
        }

        local function getDistance {
            return distanceToTarget.
        }
        
        return lexicon(
            "start", start@,
            "getDistance", getDistance@
        ).
    }


    local function cancelVelocityError {
        parameter velocityError,    // () => Vector     returns the velocity error (RAW)
                  stopCondition.    // () => Boolean    returns true to abort the loop

        local pids to initializePids(pidTuneMode:DisturbanceRejection)[0].
        pids:setpoint(V(0,0,0)).

        local pids_update to pids:update.
        local shipCtrl to ship:control.

        until stopCondition() {
            set shipCtrl:translation to (-ship:facing) * pids_update(time:seconds, -velocityError()).
            wait 0.
        }

        set shipCtrl:translation to V(0,0,0).
    }
    
    local function followWaypoints {
        parameter waypointList.     // List<Vector>     list of positions (RAW)
        parameter referencePoint.   // () => Vector     point of reference (RAW) from which the waypoints are measured. IT SHOULD NOT BE THE SHIP
        
        local waypointPosition to V(0,0,0).
        local targetPosition to { return waypointPosition + referencePoint(). }.
        local translateObj to translateToPosition(targetPosition).
        
        // // waypoint could be a more complex object in the future, for now it's just a vector
        // for waypoint in waypointList {
        //     set waypointPosition to waypoint.
        //     // find a better way to inform there's a new target
        //     translateObj:resetDistance().
        //     when translateObj:distance():mag < 1 then {
        //         translateObj:stop().
        //     }
        //     // print "Moving to waypoint " + vectorLib:roundVector(waypoint, 3).
        //     translateObj:start().
        // }
        
        // TODO: kill movement
    }
    
    return lexicon(
        "translate", translate@,
        "translateAsync", translateAsync@,
        "translateToPosition", translateToPosition@,
        "cancelVelocityError", cancelVelocityError@,
        "followWaypoints", followWaypoints@
    ).
}):call().