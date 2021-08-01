@LAZYGLOBAL off.

// #EXTERNAL_IDS nodesLib, utilsLib
// import libraries
runoncepath("/lib/utilsLib").

global nodesLib to ({
    local function pointsToNodes {
        parameter orbitPatch, startTime, endTime, endPos, endVel.

        local fixRotFunc to utilsLib:getFixRotFunctionAuto(endPos).
        local fixRot to R(0,0,0).
        local RAWtoORBIT to -utilsLib:getOrbitRot(startTime).
        local posAt to V(0,0,0).
        local velAt to V(0,0,0).
        local error to V(0,0,0).

        local matchPosNode to node(startTime, 0, 0, 0).
        add matchPosNode.

        until false {
            set fixRot to fixRotFunc(endTime).
            set posAt to fixRot * (positionat(ship, endTime) - body:position).
            set error to RAWtoORBIT * ((posAt - endPos) / (endTime - startTime)).
            if abs(error:mag) > 0.005 {
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
            set velAt to fixRot * velocityat(ship, endTime):orbit.
            set error to RAWtoORBIT * (velAt - endVel).

            if abs(error:mag) > 0.005 {
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

        return lex(
            "setUT", setUT@,
            "getDeltaV", getDeltaV@,
            "setDeltaV", setDeltaV@,
            "getBurnVector", getBurnVector@
        ).
    }

    local function virtualNodeFromNode {
        parameter theNode.
        return virtualNode(theNode:time, V(theNode:radialout, theNode:normal, theNode:prograde)).
    }

    local function nodeFromBurnVector {
        parameter UT, burnVector.
    
        local RAWtoNODE to -utilsLib:getOrbitRot(UT).
        local nodeVector to RAWtoNODE * burnVector.
        return node(UT, nodeVector:X, nodeVector:Y, nodeVector:Z).
    }

    return lex(
        "pointsToNodes", pointsToNodes@,
        "nodeAddDeltaV", nodeAddDeltaV@,
        "nodeSetDeltaV", nodeSetDeltaV@,
        "virtualNode", virtualNode@,
        "virtualNodeFromNode", virtualNodeFromNode@,
        "nodeFromBurnVector", nodeFromBurnVector@
    ).
}):call().