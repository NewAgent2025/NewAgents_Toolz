function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end
    
--level.dat START
function ConvertLevel(IN)
    local OUT = TagCompound.new()

    OUT.Data = OUT:addChild(TagCompound.new("Data"))

    --create output tags that have no matching input
    OUT.Data:addChild(TagByte.new("allowCommands", false))
    OUT.Data:addChild(TagByte.new("hardcore", false))
    OUT.Data:addChild(TagByte.new("hasBeenInCreative", false))
    OUT.Data:addChild(TagByte.new("hasStronghold", false))
    OUT.Data:addChild(TagByte.new("hasStrongholdEndPortal", false))
    OUT.Data:addChild(TagByte.new("initialized", true))
    OUT.Data:addChild(TagByte.new("ModernEnd", true))
    OUT.Data:addChild(TagByte.new("newSeaLevel", true))
    OUT.Data:addChild(TagByte.new("spawnBonusChest", false))
    OUT.Data:addChild(TagInt.new("BiomeCentreXChunk", 0))
    OUT.Data:addChild(TagInt.new("BiomeCentreZChunk", 0))
    OUT.Data:addChild(TagInt.new("BiomeScale", 0))
    OUT.Data:addChild(TagInt.new("DataVersion", 922))
    OUT.Data:addChild(TagInt.new("HellScale", 3))
    OUT.Data:addChild(TagInt.new("StrongholdEndPortalX", 0))
    OUT.Data:addChild(TagInt.new("StrongholdEndPortalZ", 0))
    OUT.Data:addChild(TagInt.new("StrongholdX", 0))
    OUT.Data:addChild(TagInt.new("StrongholdY", 0))
    OUT.Data:addChild(TagInt.new("StrongholdZ", 0))
    OUT.Data:addChild(TagInt.new("version", 19132))
    OUT.Data:addChild(TagInt.new("XZSize", 54))
    OUT.Data:addChild(TagLong.new("LastPlayed", 0))
    OUT.Data:addChild(TagLong.new("SizeOnDisk", 0))
    OUT.Data:addChild(TagString.new("LevelName", "world"))

    --create output tags that do have a matching input
    --store those tags in their own variable
    OUT.Data.Difficulty = OUT.Data:addChild(TagByte.new("Difficulty", 0))
    OUT.Data.DifficultyLocked = OUT.Data:addChild(TagByte.new("DifficultyLocked", false))
    OUT.Data.MapFeatures = OUT.Data:addChild(TagByte.new("MapFeatures", true))
    OUT.Data.raining = OUT.Data:addChild(TagByte.new("raining", false))
    OUT.Data.thundering = OUT.Data:addChild(TagByte.new("thundering", false))
    OUT.Data.clearWeatherTime = OUT.Data:addChild(TagInt.new("clearWeatherTime", 0))
    OUT.Data.GameType = OUT.Data:addChild(TagInt.new("GameType", 1))
    OUT.Data.generatorVersion = OUT.Data:addChild(TagInt.new("generatorVersion", 1))
    OUT.Data.rainTime = OUT.Data:addChild(TagInt.new("rainTime", 0))
    OUT.Data.SpawnX = OUT.Data:addChild(TagInt.new("SpawnX", 0))
    OUT.Data.SpawnY = OUT.Data:addChild(TagInt.new("SpawnY", 0))
    OUT.Data.SpawnZ = OUT.Data:addChild(TagInt.new("SpawnZ", 0))
    OUT.Data.thunderTime = OUT.Data:addChild(TagInt.new("thunderTime", 0))
    OUT.Data.DayTime = OUT.Data:addChild(TagLong.new("DayTime", 1000))
    OUT.Data.RandomSeed = OUT.Data:addChild(TagLong.new("RandomSeed", 0))
    OUT.Data.Time = OUT.Data:addChild(TagLong.new("Time", 1000))
    OUT.Data.generatorName = OUT.Data:addChild(TagString.new("generatorName", "default"))

    --iterate through the input level.dat tags
    if(IN:contains("Data", TYPE.COMPOUND)) then
        IN.Data = IN.lastFound

        IN.DataVersion = 0;
        if(IN.Data:contains("DataVersion", TYPE.INT)) then IN.DataVersion = IN.Data.lastFound.value end
        
        for i=0, IN.Data.childCount-1 do
            local in_child = IN.Data:child(i)
            local in_child_name = in_child.name
            local in_child_type = in_child.type

            --apply changes to matching tags
            if(in_child_type == TYPE.BYTE) then
                if(in_child_name == "Difficulty") then OUT.Data.Difficulty.value = in_child.value
                elseif(in_child_name == "DifficultyLocked") then OUT.Data.DifficultyLocked.value = in_child.value
                elseif(in_child_name == "MapFeatures") then OUT.Data.MapFeatures.value = in_child.value
                elseif(in_child_name == "raining") then OUT.Data.raining.value = in_child.value
                elseif(in_child_name == "thundering") then OUT.Data.thundering.value = in_child.value
                end
            elseif(in_child_type == TYPE.INT) then
                if(in_child_name == "clearWeatherTime") then OUT.Data.clearWeatherTime.value = in_child.value
                elseif(in_child_name == "GameType") then OUT.Data.GameType.value = in_child.value
                elseif(in_child_name == "rainTime") then OUT.Data.rainTime.value = in_child.value
                elseif(in_child_name == "SpawnY") then OUT.Data.SpawnY.value = in_child.value
                elseif(in_child_name == "thunderTime") then OUT.Data.thunderTime.value = in_child.value
                elseif(in_child_name == "DayTime") then OUT.Data.DayTime.value = in_child.value
                elseif(in_child_name == "RandomSeed") then OUT.Data.RandomSeed.value = in_child.value
                elseif(in_child_name == "Time") then OUT.Data.Time.value = in_child.value
                elseif(in_child_name == "SpawnX") then
                    local spawnX = in_child.value
                    if(Settings:getSettingBool("center/enabled"))then
                        local chunkOffset = Settings:getSettingInt("center/x")
                        if(Settings:getSettingBool("center/spawnPoint"))then
                            chunkOffset = round(spawnX/16)
                        end
                        spawnX = spawnX - (chunkOffset*16)
                    end
                    if(spawnX < -431 or spawnX > 430) then spawnX = 0 end
                    OUT.Data.SpawnX.value = spawnX
                elseif(in_child_name == "SpawnZ") then
                    local spawnZ = in_child.value
                    if(Settings:getSettingBool("center/enabled"))then
                        local chunkOffset = Settings:getSettingInt("center/z")
                        if(Settings:getSettingBool("center/spawnPoint"))then
                            chunkOffset = round(spawnZ/16)
                        end
                        spawnZ = spawnZ - (chunkOffset*16)
                    end
                    if(spawnZ < -431 or spawnZ > 430) then spawnZ = 0 end
                    OUT.Data.SpawnZ.value = spawnZ
                end
            elseif(in_child_type == TYPE.STRING) then
                if(in_child_name == "generatorName" ) then
                    if(in_child.value == "flat") then
                        OUT.Data.generatorName.value = "flat"
                        OUT.Data.generatorVersion.value = 0

                        --V1   1;7,2*3,2,35:1;1
                        --V2   2;7,2*3,2,35:1;1;
                        --V3   3;minecraft:bedrock,2*minecraft:dirt,minecraft:grass,minecraft:wool:1;1;
                        --V4   NBT
                        
                        if(IN.Data:contains("generatorOptions", TYPE.COMPOUND) and IN.DataVersion ~= nil) then
                            IN.Data.generatorOptions = IN.Data.lastFound
                            OUT.Data.generatorOptions = ConvertGeneratorOptions(IN.Data.generatorOptions, IN.DataVersion)
                        elseif(IN.Data:contains("generatorOptions", TYPE.STRING)) then
                            IN.Data.generatorOptions = IN.Data.lastFound
                            if(IN.Data.generatorOptions.value:len() ~= 0) then
                                OUT.Data.generatorOptions = ConvertGeneratorOptionsLegacy(IN.Data.generatorOptions.value:gsub("%s+", ""), IN.DataVersion)
                            end
                        end

                        if(OUT.Data.generatorOptions == nil) then
                            --TODO check if default superflat generator options is required for console
                        else
                            --TODO check if 1024 byte padding is required
                            OUT.Data:addChild(OUT.Data.generatorOptions)
                        end
                    end
                end
            elseif(in_child_type == TYPE.COMPOUND) then
                if(in_child_name == "WorldGenSettings") then
                    IN.Data.WorldGenSettings = in_child

                    if(IN.Data.WorldGenSettings:contains("seed", TYPE.LONG)) then
                        OUT.Data.RandomSeed.value = IN.Data.WorldGenSettings.lastFound.value
                    end

                    if(IN.Data.WorldGenSettings:contains("dimensions", TYPE.COMPOUND)) then
                        IN.Data.WorldGenSettings.dimensions = IN.Data.WorldGenSettings.lastFound

                        if(IN.Data.WorldGenSettings.dimensions:contains("minecraft:overworld", TYPE.COMPOUND)) then
                            local overworld = IN.Data.WorldGenSettings.dimensions.lastFound

                            if(overworld:contains("generator", TYPE.COMPOUND)) then
                                overworld.generator = overworld.lastFound

                                if(overworld.generator:contains("type", TYPE.STRING)) then
                                    if(overworld.generator.lastFound.value == "minecraft:flat") then

                                        OUT.Data.generatorName.value = "flat"
                                        OUT.Data.generatorVersion.value = 0
                                        if(overworld.generator:contains("settings", TYPE.COMPOUND)) then
                                            OUT.Data.generatorOptions = ConvertGeneratorOptions(overworld.generator.lastFound, IN.DataVersion)
                                        end

                                        if(OUT.Data.generatorOptions == nil) then
                                            --TODO check if default superflat generator options is required for console
                                        else
                                            --TODO check if 1024 byte padding is required
                                            OUT.Data:addChild(OUT.Data.generatorOptions)
                                        end
                                    end
                                end
                            end

                        end
                    end

                end
            end
        end
    end

return OUT
end
--level.dat STOP


function ConvertGeneratorOptions(IN, DataVersion)

    local OUT = TagByteArray.new("generatorOptions");

    if(IN:contains("layers", TYPE.LIST, TYPE.COMPOUND)) then
        local layers = IN.lastFound

        OUT:appendByte(5)
        OUT:appendShort(12)
        OUT:appendString("Classic Flat")
        OUT:appendByte(layers.childCount)

        for i=0, layers.childCount-1 do
            local layer = layers:child(i)
            local layerBlockID = 0
            local layerBlockData = 0
            local layerHeight = 1
            if(layer:contains("block", TYPE.STRING)) then
                local blockString = layer.lastFound.value
                if(blockString:find("^minecraft:")) then blockString = blockString:sub(11) end

                if(DataVersion >= 1451) then
                    if(Settings:dataTableContains("blocks_states", blockString)) then
                        local entry = Settings.lastFound
                        for index, _ in ipairs(entry) do
                            local subEntry = entry[index]
                            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                            layerBlockID = tonumber(subEntry[3])
                            layerBlockData = tonumber(subEntry[4])
                            break
                            ::entryContinue::
                        end
                    end
                else
                    --TODO Legacy block ids?
                end
            end

            if(layer:contains("height", TYPE.BYTE)) then layerHeight = layer.lastFound.value
            elseif(layer:contains("height", TYPE.INT)) then layerHeight = layer.lastFound.value
            end

            OUT:appendShort(layerBlockID)
            OUT:appendByte(layerBlockData)
            OUT:appendByte(layerHeight)
        end

        OUT:appendByte(1)
        OUT:appendByte(16)
        OUT:appendByte(1)
        OUT:appendByte(0)

        local biomeID = 1

        if(IN:contains("biome", TYPE.STRING)) then 
            local biomeString = IN.lastFound.value
            if(biomeString:find("^minecraft:")) then biomeString = biomeString:sub(11) end
            if(Settings:dataTableContains("biomes_names", biomeString)) then
                local entry = Settings.lastFound
                biomeID = tonumber(entry[1][1])
            end
        end

        OUT:appendByte(biomeID)
    end

    return OUT
end

function ConvertGeneratorOptionsLegacy(IN, DataVersion)
    local OUT = TagByteArray.new("generatorOptions");

    OUT:appendByte(5)
    OUT:appendShort(12)
    OUT:appendString("Classic Flat")
    OUT:appendByte(0) --Becomes layer count

    local layerCount = 0
    local genVersion = 1
    local groupNum = 0
    for group in IN:gmatch("[^;]*") do
        group = group:gsub("^%s*(.-)%s*$", "%1")
        groupNum = groupNum+1

        if(group == nil) then return nil end
        if(group:len() == 0) then return nil end

        if(groupNum == 1) then
            --version
            genVersion = tonumber(group)
            if(genVersion < 1 or genVersion > 3) then return nil end
        elseif(groupNum == 2) then
            --layers

            for layer in group:gmatch("[^,]*") do
                layerCount = layerCount + 1

                local layerBlockID = 0
                local layerBlockData = 0
                local layerHeight = 1
                local starIndex = layer:find("*")
                if(starIndex) then
                    layerHeight = tonumber(layer:sub(1, starIndex-1))
                    if(layerHeight < 0 or layerHeight > 255) then return nil end
                    layer = layer:sub(starIndex+1)
                end

                if(genVersion == 3) then
                    --names
                    local inBlockName = "air"
                    local inBlockData = 0

                    if(layer:find("^minecraft:")) then layer = layer:sub(11) end

                    local colonIndex = layer:find(":")
                    if(colonIndex) then
                        inBlockData = tonumber(layer:sub(colonIndex+1))
                        if(inBlockData < 0 or inBlockData > 16) then return nil end
                        layer = layer:sub(colonIndex+1)
                    end

                    inBlockName = layer

                    if(Settings:dataTableContains("blocks_names", inBlockName) and inBlockName ~= "air") then
                        local entry = Settings.lastFound
                        for index, _ in ipairs(entry) do
                            local subEntry = entry[index]
                            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                            if(subEntry[2]:len() > 0) then if(tonumber(subEntry[2]) > inBlockData) then goto entryContinue end end
                            layerBlockID = tonumber(subEntry[3])
                            if(subEntry[4]:len() ~= 0) then layerBlockData = tonumber(subEntry[4]) end
                            break
                            ::entryContinue::
                        end
                    end

                else
                    --ids
                    local inBlockID = 0
                    local inBlockData = 0

                    local colonIndex = layer:find(":")
                    if(colonIndex) then
                        inBlockData = tonumber(layer:sub(colonIndex+1))
                        if(inBlockData < 0 or inBlockData > 16) then return nil end
                        layer = layer:sub(colonIndex+1)
                    end

                    inBlockID = tonumber(layer)

                    if(Settings:dataTableContains("blocks_ids", tostring(inBlockID)) and inBlockID ~= 0) then
                        local entry = Settings.lastFound
                        for index, _ in ipairs(entry) do
                            local subEntry = entry[index]
                            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                            if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) > inBlockData) then goto entryContinue end end
                            layerBlockID = tonumber(subEntry[3])
                            if(subEntry[4]:len() ~= 0) then layerBlockData = tonumber(subEntry[4]) end
                            break
                            ::entryContinue::
                        end
                    end
                end

                OUT:appendShort(layerBlockID)
                OUT:appendByte(layerBlockData)
                OUT:appendByte(layerHeight)
            end

            OUT:setByte(15, layerCount)
        elseif(groupNum == 3) then
            --biome

            OUT:appendByte(1)
            OUT:appendByte(16)
            OUT:appendByte(1)
            OUT:appendByte(0)

            local biomeID = 1
            if(genVersion == 3) then
                if(Settings:dataTableContains("biomes_names", group)) then
                    local entry = Settings.lastFound
                    biomeID = tonumber(entry[1][1])
                end
            else
                if(Settings:dataTableContains("biomes_ids", group)) then
                    local entry = Settings.lastFound
                    biomeID = tonumber(entry[1][1])
                end
            end
            
            OUT:appendByte(biomeID)

            if(genVersion == 1) then break end
        elseif(groupNum == 4) then
            --extra
            break
        end

    end

    return OUT
end