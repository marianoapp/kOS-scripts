@LAZYGLOBAL off.

global vectorLib to ({
    local function absVector {
        parameter vector.
        
        return V(
            abs(vector:X),
            abs(vector:Y),
            abs(vector:Z)
        ).
    }

    local function roundVector {
        parameter vector, digits is 0.
        
        return V(
            round(vector:X, digits),
            round(vector:Y, digits),
            round(vector:Z, digits)
        ).
    }

    local function bound {
        parameter vector, lowerBound, upperBound.
        
        return V(
            max(min(vector:X, upperBound:X), lowerBound:X),
            max(min(vector:Y, upperBound:Y), lowerBound:Y),
            max(min(vector:Z, upperBound:Z), lowerBound:Z)
        ).
    }

    local function boundScalar {
        parameter vector, lowerBound, upperBound.
        
        return V(
            max(min(vector:X, upperBound), lowerBound),
            max(min(vector:Y, upperBound), lowerBound),
            max(min(vector:Z, upperBound), lowerBound)
        ).
    }

    local function elementWiseProduct {
        parameter vectorA, vectorB.
        
        return V(
            vectorA:X * vectorB:X,
            vectorA:Y * vectorB:Y,
            vectorA:Z * vectorB:Z
        ).
    }

    local function inverse {
        parameter vector.
        
        return V(
            1 / vector:X,
            1 / vector:Y,
            1 / vector:Z
        ).
    }

    local function addScalar {
        parameter vector, scalar.
        
        return V(
            vector:X + scalar,
            vector:Y + scalar,
            vector:Z + scalar
        ).
    }

    local function elementWiseMin {
        parameter vectorA, vectorB.
        
        return V(
            min(vectorA:X, vectorB:X),
            min(vectorA:Y, vectorB:Y),
            min(vectorA:Z, vectorB:Z)
        ).
    }
    
    return lexicon(
        "absVector", absVector@,
        "roundVector", roundVector@,
        "bound", bound@,
        "boundScalar", boundScalar@,
        "elementWiseProduct", elementWiseProduct@,
        "inverse", inverse@,
        "addScalar", addScalar@,
        "elementWiseMin", elementWiseMin@
    ).
}):call().