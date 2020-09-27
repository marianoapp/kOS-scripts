@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/utilsLib").

global nodesLib to ({
    // assumes inverse rotation mode (ie below 100km from the surface)
    local function pointsToNodes {
        parameter orbitPatch, startTime, endTime, endPos, endVel.

        local fixRotFunc to utilsLib:getFixRotFunction().
        local fixRot to R(0,0,0).
        local RAWtoORBIT to -utilsLib:getOrbitRot(startTime).
        local positionError to V(0,0,0).
        local error to V(0,0,0).

        local matchPosNode to node(startTime, 0, 0, 0).
        add matchPosNode.

        until false {
            set fixRot to fixRotFunc(endTime).
            set positionError to (fixRot * (positionat(ship, endTime) - body:position)) - endPos.
            set error to RAWtoORBIT * (positionError / (endTime - startTime)).
            if abs(error:mag) > 0.1 {
                nodeAddDeltaV(matchPosNode, -error).
            }
            else {
                break.
            }
        }

        set RAWtoORBIT to -utilsLib:getOrbitRot(endTime).

        local matchVelNode to node(endTime, 0, 0, 0).
        add matchVelNode.

        until false {
            set fixRot to fixRotFunc(endTime).
            set error to RAWtoORBIT * ((fixRot * velocityat(ship, endTime):surface) - endVel).
            if abs(error:mag) > 0.01 {
                nodeAddDeltaV(matchVelNode, -error).
            }
            else {
                break.
            }
        }
    }

    local function nodeAddDeltaV {
        parameter theNode, deltaV.

        set theNode:radialout to theNode:radialout + deltaV:X.
        set theNode:normal to theNode:normal + deltaV:Y.
        set theNode:prograde to theNode:prograde + deltaV:Z.
    }

    local function nodeSetDeltaV {
        parameter theNode, deltaV.

        set theNode:radialout to deltaV:X.
        set theNode:normal to deltaV:Y.
        set theNode:prograde to deltaV:Z.
    }

    local function virtualNode {
        parameter UT, deltaV.

        local function setUT {
            parameter newUT.
            set UT to newUT.
        }

        local function getDeltaV {
            return deltaV:vec.
        }

        local function setDeltaV {
            parameter newDeltaV.
            set deltaV to newDeltaV.
        }

        local function getBurnVector {
            local ORBITtoRAW to utilsLib:getOrbitRot(UT).
            return ORBITtoRAW * deltaV.
        }

        return lexicon(
            "setUT", setUT@,
            "getDeltaV", getDeltaV@,
            "setDeltaV", setDeltaV@,
            "getBurnVector", getBurnVector@
        ).
    }

    local function virtualNodeFromNode {
        parameter theNode.
        return virtualNode(time:seconds + theNode:eta, V(theNode:radialout, theNode:normal, theNode:prograde)).
    }


    return lexicon(
        "pointsToNodes", pointsToNodes@,
        "nodeAddDeltaV", nodeAddDeltaV@,
        "nodeSetDeltaV", nodeSetDeltaV@,
        "virtualNode", virtualNode@,
        "virtualNodeFromNode", virtualNodeFromNode@
    ).
}):call().