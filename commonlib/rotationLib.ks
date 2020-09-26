@LAZYGLOBAL off.

global rotationLib to ({
    local function shipToRaw {
        return facing.
    }
    
    local function rawToShip {
        return -facing.
    }
    
    local function partToRaw {
        parameter part.
        return part:facing.
    }
    
    local function rawToPart {
        parameter part.
        return -part:facing.
    }
    
    local function partToShip {
        parameter part.
        return rawToShip() * partToRaw(part).
    }
    
    local function shipToPart {
        parameter part.
        return rawToPart(part) * shipToRaw().
    }
    
    local function dirToRaw {
        parameter dir.
        return dir.
    }
    
    local function rawToDir {
        parameter dir.
        return dir:inverse.
    }
    
    local function dirToShip {
        parameter dir.
        return rawToShip() * dirToRaw(dir).
    }
    
    local function shipToDir {
        parameter dir.
        return rawToDir(dir) * shipToRaw().
    }
    
    local function shipX {
        return facing:starvector.
    }
    
    local function shipY {
        return facing:topvector.
    }
    
    local function shipZ {
        return facing:forevector.
    }
    
    return lexicon(
        "shipToRaw", shipToRaw@,
        "rawToShip", rawToShip@,
        "partToRaw", partToRaw@,
        "rawToPart", rawToPart@,
        "partToShip", partToShip@,
        "shipToPart", shipToPart@,
        "dirToRaw", dirToRaw @,
        "rawToDir", rawToDir @,
        "dirToShip", dirToShip@,
        "shipToDir", shipToDir@,
        "shipX", shipX@,
        "shipY", shipY@,
        "shipZ", shipZ@
    ).
}):call().