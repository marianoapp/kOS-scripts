@LAZYGLOBAL off.

// import libraries
runoncepath("/commonlib/stringLib").

global dependencyLib to ({
    local function getDependenciesRecursive {
        parameter filePath, visited.

        visited:add(filePath, 0).

        local fileItem to open(filePath).
        if fileItem:typename = "VolumeFile" {
            local searchKeyConst to "runonce" + "path".
            local toVisit to lexicon().
            local fileContent to fileItem:readall:string.
            local matches to stringLib:findAll(fileContent, searchKeyConst).
            
            for index in matches {
                local start to index + 13.
                local count to fileContent:findat(char(34), start) - start.
                local dependencyPath to fileContent:substring(start, count).
                if not visited:haskey(dependencyPath) and not toVisit:haskey(dependencyPath) {
                    toVisit:add(dependencyPath, 0).
                }
            }
            
            for dependencyPath in toVisit:keys {
                if not visited:haskey(dependencyPath) {
                    getDependenciesRecursive(dependencyPath, visited).
                }
            }
        }
    }
    
    local function getDependencies {
        parameter filePath.
        
        local visited to lexicon().
        getDependenciesRecursive(filePath, visited).
        
        return visited:keys.
    }
    
    local function copyFileAndDepsToVolume {
        parameter sourcePath, destinationVolume.
        
        local dependencies to getDependencies(sourcePath).
        local volumePath to path(destinationVolume).
        for filePath in dependencies {
            copypath(filePath, volumePath + filePath).
            // compile filePath to volumePath + filePath.
        }
    }

    return lexicon(
        "getDependencies", getDependencies@,
        "copyFileAndDepsToVolume", copyFileAndDepsToVolume@
    ).
}):call().