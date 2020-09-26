@LAZYGLOBAL off.

global estimationLib to ({
    local function forwardLinearInterpolator {
        parameter dataList.

        local dataPointIndex to 1.
        local dataPoint to dataList[0].
        local nextDataPoint to dataList[1].
        local timeDelta to nextDataPoint[0] - dataPoint[0].
        local nextPointTime to nextDataPoint[0].
        local eofFlag to false.

        local function getValue {
            parameter timeValue.

            if not eofFlag {
                // move to the next point
                if nextPointTime < timeValue {
                    until dataPointIndex = dataList:length or dataList[dataPointIndex][0] > timeValue {
                        set dataPointIndex to dataPointIndex + 1.
                    }
                    if dataPointIndex < dataList:length {
                        set dataPoint to nextDataPoint.
                        set nextDataPoint to dataList[dataPointIndex].
                        set timeDelta to nextDataPoint[0] - dataPoint[0].
                        set nextPointTime to nextDataPoint[0].
                    }
                    else {
                        set eofFlag to true.
                        set dataPoint to nextDataPoint.
                        set timeDelta to 1.
                    }
                }
                // interpolation
                local k to (nextPointTime - timeValue) / timeDelta.
                return k*dataPoint[1] + (1-k)*nextDataPoint[1].
            }
            else {
                return dataPoint[1].
            }
        }

        local function EOF {
            return eofFlag.
        }

        return lexicon(
            "getValue", getValue@,
            "EOF", EOF@
        ).
    }

    return lexicon(
        "forwardLinearInterpolator", forwardLinearInterpolator@
    ).
}):call().