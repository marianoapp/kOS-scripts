@LAZYGLOBAL off.

global orbitLib to ({
    local function findOrbitAltitudeIntersectionTime {
        parameter orbitPatch, referenceTrueAnomaly, intersectAltitude is 0.

        set intersectAltitude to intersectAltitude + orbitPatch:body:radius.
        
        // only calculate for non hyperbolic orbits with a pe below the intersect altitude
        if orbitPatch:eccentricity <= 1 and (orbitPatch:periapsis + orbitPatch:body:radius) <= intersectAltitude {
            // v = arccos((sma*(1 - ecc^2) - r) / (r*ecc))
            local trueAnomalyAltitude to arccos((orbitPatch:semimajoraxis * (1 - orbitPatch:eccentricity^2) - intersectAltitude) / (orbitPatch:eccentricity * intersectAltitude)).
            // there are two intersection points that are equidistant from the pe, but we're interested in the one before pe
            local trueAnomalyIntersect to 360 - trueAnomalyAltitude.
            // calculate the time between the reference true anomaly and the intersection
            return timeBetweenTrueAnomalies(referenceTrueAnomaly, trueAnomalyIntersect, orbitPatch:eccentricity, orbitPatch:period).
        }
        else {
            return 0.
        }
    }

    local function timeBetweenTrueAnomalies {
        parameter trueAnomalyOne, trueAnomalyTwo, eccentricity, period.

        local meanAnomalyOne to trueAnomalyToMeanAnomaly(trueAnomalyOne, eccentricity).
        local meanAnomalyTwo to trueAnomalyToMeanAnomaly(trueAnomalyTwo, eccentricity).

        return period * (constrainDeg(meanAnomalyTwo - meanAnomalyOne) / 360).
    }

    local function trueAnomalyToMeanAnomaly {
        parameter trueAnomaly, eccentricity.
        local eccentricAnomaly to arctan2(sqrt(1-eccentricity^2) * sin(trueAnomaly), eccentricity + cos(trueAnomaly)).
        return constrainDeg(eccentricAnomaly - eccentricity*sin(eccentricAnomaly)*constant:radtodeg).
    }

    local function constrainDeg {
        parameter value.
        return mod(value + 360, 360).
    }

    return lexicon(
        "findOrbitAltitudeIntersectionTime", findOrbitAltitudeIntersectionTime@
    ).
}):call().