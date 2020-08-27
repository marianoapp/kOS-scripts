@LAZYGLOBAL off.

// import libraries
runoncepath("commonlib/pidLib").
runoncepath("commonlib/vectorLib").
runoncepath("commonlib/calculusLib").
runoncepath("commonlib/rcsLib").
runoncepath("commonlib/asyncLib").

global translationLib to ({
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
        return asyncLib:newTask(isDone@, whenDone@).
    }
    
    local function initializePids {
        parameter maxAcceleration.
        
        local pids to pidLib:pidVector(0, 0, 0).
        local rcsThrust to rcsLib:getTotalThrustList().
        
        // kp
        local avgThrust to (rcsThrust[0] + rcsThrust[1]) / 2.
        local availableAcceleration to vectorLib:boundScalar(avgThrust / ship:mass, 0, maxAcceleration).
        local kps to 2 * vectorLib:inverse(availableAcceleration).
        pids:setKps(kps).
        
        // limits
        pids:setBounds(
            -vectorLib:boundScalar(maxAcceleration * vectorLib:inverse(rcsThrust[0] / ship:mass), 0, 1),
            vectorLib:boundScalar(maxAcceleration * vectorLib:inverse(rcsThrust[1] / ship:mass), 0, 1)
        ).
        
        return pids.
    }

    local function translateToPosition {
        parameter targetPosition.                   // () => Vector     returns the target position (RAW)
        parameter referencePosition is V(0,0,0).    // Vector           point of reference used to measure the distance (SHIP)
        parameter maxAcceleration is 100.           // Scalar           maximum acceleration in m/s^2 
            
        local stopFlag to false.
        local distanceToTarget to V(10000,10000,10000). // just a big number
        local currentSpeed to V(0,0,0).
        local lowerSpeedBound to 0.2.
        local upperSpeedBound to 3.
        local pids to initializePids(maxAcceleration).
        
        local function start {
            local maxSpeed to V(0,0,0).
            local velObj to calculusLib:vectorDerivative().
            local currentTime to 0.
            local currentPosition to V(0,0,0).
            local currentPath to V(0,0,0).
            local PATHtoRAW to R(0,0,0).
            local RAWtoPATH to R(0,0,0).
            
            set stopFlag to false.
            
            // aliases of library functions to improve performance
            local vectorLib_boundScalar to vectorLib:boundScalar@.
            local vectorLib_absVector to vectorLib:absVector@.
            local vectorLib_bound to vectorLib:bound@.
            local velObj_calculate to velObj:calculate@.
            local pids_setpoint to pids:setpoint@.
            local pids_update to pids:update@.
            local shipCtrl to ship:control.
            local shipFacing to ship:facing.
            
            // make sure the loop starts on the next frame so it doesn't get interrupted in the middle
            wait 0.01.
            
            until stopFlag {
                set currentTime to time:seconds.
                set currentPosition to targetPosition().
                set shipFacing to ship:facing.
                
                // update the path if it diverges too much from the previous one
                if vang(currentPath, currentPosition) > 20 {
                    set currentPath to currentPosition.
                    set PATHtoRAW to lookdirup(currentPosition, shipFacing:topvector).
                    set RAWtoPATH to -PATHtoRAW.
                }
                
                set distanceToTarget to RAWtoPATH * (currentPosition - shipFacing*referencePosition).
                set maxSpeed to vectorLib_boundScalar(vectorLib_absVector(distanceToTarget/5), lowerSpeedBound, upperSpeedBound).
  
                // the desired velocity per axis depends on the distance to the target
                pids_setpoint(vectorLib_bound(distanceToTarget, -maxSpeed, maxSpeed)).
                // compare the current velocity to the desired one and make corrections
                set currentSpeed to -velObj_calculate(currentTime, distanceToTarget).
                // PATHtoSHIP = RAWtoSHIP * PATHtoRAW
                set shipCtrl:translation to (-shipFacing) * PATHtoRAW * pids_update(currentTime, currentSpeed).
                
                wait 0.01.
            }.

            set ship:control:translation to V(0,0,0).
        }
        
        local function stop {
            set stopFlag to true.
        }
        
        local function distance {
            return distanceToTarget.
        }
        
        local function speed {
            return currentSpeed.
        }
        
        local function isDone {
            return distanceToTarget:mag < 0.2 and currentSpeed:mag < 0.1.
        }
        
        local function resetDistance {
            set distanceToTarget to V(10000,10000,10000).   // just a big number
        }
        
        local function setSpeedBounds {
            parameter lowerBound, upperBound.
            set lowerSpeedBound to lowerBound.
            set upperSpeedBound to upperBound.
        }
        
        return lexicon(
            "start", start@,
            "stop", stop@,
            "distance", distance@,
            "isDone", isDone@,
            "speed", speed@,
            "resetDistance", resetDistance@,
            "setSpeedBounds", setSpeedBounds@
        ).
    }
    
    local function followWaypoints {
        parameter waypointList.     // List<Vector>     list of positions (RAW)
        parameter referencePoint.   // () => Vector     point of reference (RAW) from which the waypoints are measured. IT SHOULD NOT BE THE SHIP
        
        local waypointPosition to V(0,0,0).
        local targetPosition to { return waypointPosition + referencePoint(). }.
        local translateObj to translateToPosition(targetPosition).
        
        // waypoint could be a more complex object in the future, for now it's just a vector
        for waypoint in waypointList {
            set waypointPosition to waypoint.
            // find a better way to inform there's a new target
            translateObj:resetDistance().
            when translateObj:distance():mag < 1 then {
                translateObj:stop().
            }
            // print "Moving to waypoint " + vectorLib:roundVector(waypoint, 3).
            translateObj:start().
        }
        
        // TODO: kill movement
    }
        
    return lexicon(
        "translate", translate@,
        "translateAsync", translateAsync@,
        "translateToPosition", translateToPosition@,
        "followWaypoints", followWaypoints@
    ).
}):call().