@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/translationLib").
runoncepath("/commonlib/rotationLib").
runoncepath("/commonlib/steeringLib").
runoncepath("/commonlib/asyncLib").
runoncepath("/commonlib/schedulingLib").

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

    local partsMetadata to lexicon(
        "dockingPort2", lexicon(
            "frontOffset", 0.3
        )
    ).

    local function findDockingPort {
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

    local function getPortFrontPosition {
        parameter portPart.

        local frontOffset to 0.
        if partsMetadata:haskey(portPart:name) {
            set frontOffset to partsMetadata[portPart:name]["frontOffset"].
        }

        return portPart:portfacing:forevector:normalized * frontOffset.
    }

    local function dock {
        parameter ownPort, targetPort, rollMatchMode is rollMatchModeEnum:Current, maxSpeed is 2.
        
        ownPort:controlfrom().
        
        // turn the ship in the desired direction
        //local steerTask to steeringLib:steerToDelegateAsync(getSteeringDelegate(targetPort, rollMatchMode)).
        // >> workaround because using the above instruction it's impossible to unlock the steering afterwards
        local steerDelegate to getSteeringDelegate(targetPort, rollMatchMode).
        lock steering to steerDelegate().
        local steerTask to steeringLib:getNewSteeringTask().

        // position the vessel just above the docking port
        local positionOffset to 1.
        local stopFlag to false.
        local targetPosition to { return targetPort:position + targetPort:portfacing:forevector*positionOffset. }.
        local stopCondition to { return stopFlag or abort. }.
        local referencePosition to (-ship:facing) * (ownPort:position + getPortFrontPosition(ownPort)).

        local tp to translationLib:translateToPosition(targetPosition, stopCondition, referencePosition, maxSpeed).
        // when close enough approach and dock
        local sequence to schedulingLib:sequenceScheduler().
        sequence:addEvent({ return tp:getDistance():mag < 0.25. }, { set positionOffset to 0.6. }).
        sequence:addEvent({ return ownPort:haspartner. }, { }).    // do nothing
        sequence:addEvent({ return tp:getDistance():mag < 0.4. }, { set stopFlag to true. }).

        asyncLib:await(steerTask).
        tp:start().
        
        unlock steering.
    }
    
    return lexicon(
        "rollMatchModeEnum", rollMatchModeEnum,
        "findDockingPort", findDockingPort@,
        "dock", dock@
    ).
}):call().