@LAZYGLOBAL off.

global calculusLib to ({
    local zeroVector to V(0,0,0).

    // start returning meaningful data on the second call
    local function vectorDerivative {
        local lastTime to time:seconds.
        local lastValue to zeroVector.
        local deltaTime to 0.
        
        local function calculate {
            parameter currentTime, currentValue.
            
            set deltaTime to currentTime - lastTime.
            local derivative to zeroVector:vec.
            if deltaTime > 0 {
                set derivative to (currentValue - lastValue) / deltaTime.
            }
            set lastTime to currentTime.
            set lastValue to currentValue:vec.
            
            return derivative.
        }
        
        local function getDeltaTime {
            return deltaTime.
        }
        
        return lexicon(
            "calculate", calculate@,
            "deltaTime", getDeltaTime@
        ).
    }

    // start returning meaningful data on the third call
    local function vectorDoubleDerivative {
        local lastValue to zeroVector.
        local derivativeObj to vectorDerivative().
        
        local function calculate {
            parameter currentTime, currentValue.
            
            local derivative to derivativeObj:calculate(currentTime, currentValue).
            local deltaTime to derivativeObj:deltaTime().
            local doubleDerivative to zeroVector:vec.
            if deltaTime > 0 {
                set doubleDerivative to (derivative - lastValue) / deltaTime.
            }
            set lastValue to derivative.
            
            return doubleDerivative.
        }
        
        return lexicon("calculate", calculate@).
    }
    
    local function vectorErrorDerivative {
        parameter referenceValue.
    
        local lastTime to time:seconds.
        local deltaTime to 0.
        
        local function calculate {
            parameter currentTime, currentValue.
            
            set deltaTime to currentTime - lastTime.
            local derivative to zeroVector:vec.
            if deltaTime > 0 {
                set derivative to (currentValue - referenceValue) / deltaTime.
            }
            set lastTime to currentTime.
            
            return derivative.
        }
        
        return lexicon(
            "calculate", calculate@
        ).
    }
    
    local function scalarDerivative {
        local lastTime to time:seconds.
        local lastValue to 0.
        local deltaTime to 0.
        
        local function calculate {
            parameter currentTime, currentValue.
            
            set deltaTime to currentTime - lastTime.
            local derivative to 0.
            if deltaTime > 0 {
                set derivative to (currentValue - lastValue) / deltaTime.
            }
            set lastTime to currentTime.
            set lastValue to currentValue.
            
            return derivative.
        }
        
        return lexicon(
            "calculate", calculate@
        ).
    }
    
    return lexicon(
        "vectorDerivative", vectorDerivative@,
        "vectorDoubleDerivative", vectorDoubleDerivative@,
        "vectorErrorDerivative", vectorErrorDerivative@,
        "scalarDerivative", scalarDerivative@
    ).
}):call().
