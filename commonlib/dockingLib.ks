@LAZYGLOBAL off.

// import libraries
runoncepath("commonlib/translationLib").
runoncepath("commonlib/rotationLib").
runoncepath("commonlib/steeringLib").
runoncepath("commonlib/asyncLib").

global dockingLib to ({
    // roll match modes
    // 0- keep current roll
    // 1- align roll to closest 90 degree angle
    // 2- match roll exactly
    local rollMatchModeEnum to lexicon(
        "Current", 0,
        "Closest", 1,
        "Exact", 2
    ).

    local function findDockingPort
    {
        parameter targetVessel.

        local dockTarget to targetVessel.
        local minScore to 10000.
        local portAngle to 0.
        local portDistance to 0.
        local score to 0.
        
        //TODO: compare docking port size
        
        for port in targetVessel:dockingports {
            // TODO: should use the angle between the forevector and the center of the ship instead
            // TODO: check if vang is returning values bigger than 180 and if not then if its returning negative values
            if not port:haspartner {
                set portAngle to vang(-port:portfacing:forevector, targetVessel:direction:forevector).
                set portDistance to port:position:mag.
                set score to portAngle + portDistance.
                if score < minScore {
                    set dockTarget to port.
                    set minScore to score.
                }
            }
        }.
        
        return dockTarget.
    }

    local function getSteeringDelegate {
        parameter targetPort, rollMatchMode.

        local steeringDelegate to {}.
        if rollMatchMode = rollMatchModeEnum:Current {
            set steeringDelegate to { return lookdirup(-targetPort:portfacing:forevector, ship:facing:topvector). }.
        }
        else {
            if rollMatchMode = rollMatchModeEnum:Closest {
                local refVector to (-targetPort:portfacing) * ship:facing:topvector.
                // snap to closest 45 degree angle
                //local dirVector to V(round(refVector:X), round(refVector:Y), 0).
                // snap to closest 90 degree angle
                local dirVector to choose V(round(refVector:X), 0, 0) if abs(refVector:X) > abs(refVector:Y) 
                                     else V(0, round(refVector:Y), 0).
                set steeringDelegate to { return lookdirup(-targetPort:portfacing:forevector, targetPort:portfacing * dirVector). }.
            }
            else {
                set steeringDelegate to { return lookdirup(-targetPort:portfacing:forevector, targetPort:portfacing:topvector). }.
            }
        }

        return steeringDelegate.
    }

    local function dock
    {
        parameter ownPort, targetPort, rollMatchMode is rollMatchModeEnum:Current.
        
        ownPort:controlfrom().
        
        // turn the ship in the desired direction
        local steerTask to steeringLib:steerToDelegateAsync(getSteeringDelegate(targetPort, rollMatchMode)).

        // position the vessel just above the docking port
        local positionOffset to V(0,0,3).
        local targetPosition to { return targetPort:position + targetPort:portfacing*positionOffset. }.
        local translateObj to translationLib:translateToPosition(targetPosition, rotationLib:rawToShip() * ownPort:position).
        // the speed bounds depend on the mass [ y = -2/495*(mass-2) + 1 ]
        local upperSpeedBound to -2/495 * (min(max(ship:mass, 2), 200) - 2) + 1.
        translateObj:setSpeedBounds(upperSpeedBound / 5, upperSpeedBound).
        // when close enough approach and dock
        when translateObj:isDone() then {
            set positionOffset to V(0,0,0.7).
            when ownPort:haspartner then {
                when translateObj:distance():mag < 0.4 then {
                    translateObj:stop().
                }
            }
        }
        asyncLib:await(steerTask).
        translateObj:start().
        
        unlock steering.
    }
    
    return lexicon(
        "rollMatchModeEnum", rollMatchModeEnum,
        "findDockingPort", findDockingPort@,
        "dock", dock@
    ).
}):call().