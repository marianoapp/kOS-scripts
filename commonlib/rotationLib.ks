@LAZYGLOBAL off.

global rotationLib to ({
    local function shipToRaw {
        return ship:facing.
    }
    
    local function rawToShip {
        return ship:facing:inverse.
    }
    
    local function partToRaw {
        parameter part.
        return part:facing.
    }
    
    local function rawToPart {
        parameter part.
        return part:facing:inverse.
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
        return shipToRaw() * V(1,0,0).
    }
    
    local function shipY {
        return shipToRaw() * V(0,1,0).
    }
    
    local function shipZ {
        return shipToRaw() * V(0,0,1).
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