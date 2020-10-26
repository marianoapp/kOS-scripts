@LAZYGLOBAL off.

global pidLib to ({
    local function pidVector {
        parameter kp, ki is 0, kd is 0, minOutput is 0, maxOutput is 0.
        
        local pidX to pidloop(kp, ki, kd, minOutput, maxOutput).
        local pidY to pidloop(kp, ki, kd, minOutput, maxOutput).
        local pidZ to pidloop(kp, ki, kd, minOutput, maxOutput).
            
        local function setpoint {
            parameter value.
            
            set pidX:setpoint to value:X.
            set pidY:setpoint to value:Y.
            set pidZ:setpoint to value:Z.
        }
        
        local function update {
            parameter currentTime, value.
            
            return V(
                pidX:update(currentTime, value:X),
                pidY:update(currentTime, value:Y),
                pidZ:update(currentTime, value:Z)
            ).
        }
        
        local function setBounds {
            parameter minOutput, maxOutput.
            
            set pidX:minoutput to minOutput:X.
            set pidY:minoutput to minOutput:Y.
            set pidZ:minoutput to minOutput:Z.
            set pidX:maxoutput to maxOutput:X.
            set pidY:maxoutput to maxOutput:Y.
            set pidZ:maxoutput to maxOutput:Z.
        }
        
        local function setScalarBounds {
            parameter minOutput, maxOutput.
            
            set pidX:minoutput to minOutput.
            set pidY:minoutput to minOutput.
            set pidZ:minoutput to minOutput.
            set pidX:maxoutput to maxOutput.
            set pidY:maxoutput to maxOutput.
            set pidZ:maxoutput to maxOutput.
        }
        
        local function setKps {
            parameter kps.
            
            set pidX:kp to kps:X.
            set pidY:kp to kps:Y.
            set pidZ:kp to kps:Z.
        }

        local function setKis {
            parameter kis.
            
            set pidX:ki to kis:X.
            set pidY:ki to kis:Y.
            set pidZ:ki to kis:Z.
        }

        local function setKds {
            parameter kds.
            
            set pidX:kd to kds:X.
            set pidY:kd to kds:Y.
            set pidZ:kd to kds:Z.
        }
        
        local function X {
            return pidX.
        }
        
        local function Y {
            return pidY.
        }
        
        local function Z {
            return pidZ.
        }
        
        return lexicon(
            "setpoint", setpoint@,
            "update", update@,
            "setBounds", setBounds@,
            "setScalarBounds", setScalarBounds@,
            "setKps", setKps@,
            "setKis", setKis@,
            "setKds", setKds@,
            "X", X@,
            "Y", Y@,
            "Z", Z@
        ).
    }
    
    local function pidVectorXY {
        parameter kp, ki is 0, kd is 0, minOutput is 0, maxOutput is 0.
        
        local pidX to pidloop(kp, ki, kd, minOutput, maxOutput).
        local pidY to pidloop(kp, ki, kd, minOutput, maxOutput).
            
        local function setpoint {
            parameter value.
            
            set pidX:setpoint to value:X.
            set pidY:setpoint to value:Y.
        }
        
        local function update {
            parameter currentTime, value.
            
            return V(
                pidX:update(currentTime, value:X),
                pidY:update(currentTime, value:Y),
                0
            ).
        }
        
        local function setBounds {
            parameter minOutput, maxOutput.
            
            set pidX:minoutput to minOutput:X.
            set pidY:minoutput to minOutput:Y.
            set pidX:maxoutput to maxOutput:X.
            set pidY:maxoutput to maxOutput:Y.
        }
        
        local function setScalarBounds {
            parameter minOutput, maxOutput.
            
            set pidX:minoutput to minOutput.
            set pidY:minoutput to minOutput.
            set pidX:maxoutput to maxOutput.
            set pidY:maxoutput to maxOutput.
        }
        
        local function setKps {
            parameter kps.
            
            set pidX:kp to kps:X.
            set pidY:kp to kps:Y.
        }

        local function setKis {
            parameter kis.
            
            set pidX:ki to kis:X.
            set pidY:ki to kis:Y.
        }

        local function setKds {
            parameter kds.
            
            set pidX:kd to kds:X.
            set pidY:kd to kds:Y.
        }
        
        local function X {
            return pidX.
        }
        
        local function Y {
            return pidY.
        }
        
        return lexicon(
            "setpoint", setpoint@,
            "update", update@,
            "setBounds", setBounds@,
            "setScalarBounds", setScalarBounds@,
            "setKps", setKps@,
            "setKis", setKis@,
            "setKds", setKds@,
            "X", X@,
            "Y", Y@
        ).
    }
    
    return lexicon(
        "pidVector", pidVector@,
        "pidVectorXY", pidVectorXY@
    ).
}):call().