@LAZYGLOBAL off.

// #EXTERNAL_IDS grapplerDockingLib, translationLib, steeringLib, asyncLib, grapplerLib
// import libraries
runoncepath("/lib/translationLib").
runoncepath("/lib/steeringLib").
runoncepath("/lib/asyncLib").
runoncepath("/lib/grapplerLib").
runoncepath("/lib/schedulingLib").

global grapplerDockingLib to ({
    local function dock
    {
        parameter grappler,        // grappler part
                  targetVessel,    // vessel to grapple
                  targetPosRel,    // position to grapple, in target vessel coordinates
                  topVector is ship:facing:topvector,
                  maxSpeed is 1.
        
        // initialize the grappler
        grapplerLib:arm(grappler).
        grapplerLib:controlfrom(grappler).
        local grabTask to grapplerLib:grabDoneAsync(grappler).
        
        local targetPosRelNorm to targetPosRel:normalized.
        
        // turn the ship in the desired direction
        // TODO: the steering should be normal to the surface of the part (how?)
        local steerTask to steeringLib:steerToDelegateAsync({ return lookdirup(-(targetVessel:facing*targetPosRel), topVector). }).

        // position the vessel above the targetPosition
        local positionOffset to 4.
        local stopFlag to false.
        local targetPositionDel to { return targetVessel:position + targetVessel:facing * (targetPosRel + targetPosRelNorm * positionOffset). }.
        local stopCondition to { return stopFlag or abort. }.
        local referencePosition to -facing * grappler:position.
        
        local tp to translationLib:translateToPosition(targetPositionDel, stopCondition, referencePosition, maxSpeed).

        local sequence to schedulingLib:sequenceScheduler().
        sequence:addEvent({ return tp:getDistance():mag < 0.25. }, { set positionOffset to 0. }).
        sequence:addEvent({ return asyncLib:taskDone(grabTask). }, { set stopFlag to true. }).

        asyncLib:await(steerTask).
        tp:start().

        unlock steering.
    }
    
    return lexicon(
        "dock", dock@
    ).
}):call().