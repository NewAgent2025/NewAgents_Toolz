function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end
    
    --level.dat START
function ConvertLevel(IN)
    OUT = TagCompound.new()

    OUT.Data = OUT:addChild(TagCompound.new("Data"))

    --create output tags that have no matching input
    OUT.Data:addChild(TagByte.new("allowCommands", false))
    OUT.Data:addChild(TagByte.new("DifficultyLocked", false))
    OUT.Data:addChild(TagByte.new("hardcore", false))
    OUT.Data:addChild(TagByte.new("hasStronghold", false))
    OUT.Data:addChild(TagByte.new("hasStrongholdEndPortal", false))
    OUT.Data:addChild(TagByte.new("initialized", true))
    OUT.Data:addChild(TagByte.new("MapFeatures", true))
    OUT.Data:addChild(TagByte.new("ModernEnd", true))
    OUT.Data:addChild(TagByte.new("newSeaLevel", true))
    OUT.Data:addChild(TagByte.new("spawnBonusChest", false))
    OUT.Data:addChild(TagInt.new("BiomeCentreXChunk", 0))
    OUT.Data:addChild(TagInt.new("BiomeCentreZChunk", 0))
    OUT.Data:addChild(TagInt.new("BiomeScale", 0))
    OUT.Data:addChild(TagInt.new("clearWeatherTime", 0))
    OUT.Data:addChild(TagInt.new("DataVersion", 922))
    OUT.Data:addChild(TagInt.new("HellScale", 3))
    OUT.Data:addChild(TagInt.new("SpawnY", 64))
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
    OUT.Data.hasBeenInCreative = OUT.Data:addChild(TagByte.new("hasBeenInCreative", false))
    OUT.Data.raining = OUT.Data:addChild(TagByte.new("raining", false))
    OUT.Data.thundering = OUT.Data:addChild(TagByte.new("thundering", false))
    OUT.Data.GameType = OUT.Data:addChild(TagInt.new("GameType", 1))
    OUT.Data.generatorVersion = OUT.Data:addChild(TagInt.new("generatorVersion", 1))
    OUT.Data.rainTime = OUT.Data:addChild(TagInt.new("rainTime", 0))
    OUT.Data.SpawnX = OUT.Data:addChild(TagInt.new("SpawnX", 0))
    OUT.Data.SpawnZ = OUT.Data:addChild(TagInt.new("SpawnZ", 0))
    OUT.Data.thunderTime = OUT.Data:addChild(TagInt.new("thunderTime", 0))
    OUT.Data.DayTime = OUT.Data:addChild(TagLong.new("DayTime", 1000))
    OUT.Data.RandomSeed = OUT.Data:addChild(TagLong.new("RandomSeed", 0))
    OUT.Data.Time = OUT.Data:addChild(TagLong.new("Time", 1000))
    OUT.Data.generatorName = OUT.Data:addChild(TagString.new("generatorName", "default")) --TODO set based on generatorVersion

    Settings:setSettingLong("Time", 0)

    --iterate through the input level.dat tags
    for i=0, IN.childCount-1 do
        local in_child = IN:child(i)
        local in_child_name = in_child.name
        local in_child_type = in_child.type


        if(in_child_type == TYPE.BYTE)then
            if(in_child_name == "hasBeenLoadedInCreative") then OUT.Data.hasBeenInCreative.value = in_child.value end
        elseif(in_child_type == TYPE.INT)then
            if(in_child_name == "Difficulty") then OUT.Data.Difficulty.value = in_child.value
            elseif(in_child_name == "GameType") then OUT.Data.GameType.value = in_child.value
            elseif(in_child_name == "Generator") then
                if(in_child.value == 2)then
                    OUT.Data.generatorVersion.value = 0
                    OUT.Data.generatorName.value = "flat"
                else
                    OUT.Data.generatorVersion.value = 1
                    OUT.Data.generatorName.value = "default"
                end
            elseif(in_child_name == "rainTime") then OUT.Data.rainTime.value = in_child.value
            elseif(in_child_name == "lightningTime") then OUT.Data.thunderTime.value = in_child.value
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
        elseif(in_child_type == TYPE.LONG)then
            if(in_child_name == "currentTick") then 
                OUT.Data.Time.value = in_child.value
                Settings:setSettingLong("Time", in_child.value)
            elseif(in_child_name == "RandomSeed") then OUT.Data.RandomSeed.value = in_child.value
            elseif(in_child_name == "Time") then OUT.Data.DayTime.value = in_child.value
            end
        elseif(in_child_type == TYPE.FLOAT)then
            if(in_child_name == "rainLevel") then OUT.Data.raining.value = (in_child.value ~= 0)
            elseif(in_child_name == "lightningLevel") then OUT.Data.thundering.value = (in_child.value ~= 0)
            end
        elseif(in_child_type == TYPE.STRING)then
            if(in_child_name == "FlatWorldLayers") then
                local genOptions_out = ConvertGeneratorOptions(in_child.value)
                if(genOptions_out ~= nil) then OUT.Data:addChild(genOptions_out) end
            end
        end
    end

    return OUT
end

function ConvertGeneratorOptions(IN)

    local OUT = TagByteArray.new("generatorOptions");

    local jsonRoot = JSONValue.new()
    if(jsonRoot:parse(IN).type == JSON_TYPE.OBJECT) then

        OUT:appendByte(5)
        OUT:appendShort(12)
        OUT:appendString("Classic Flat")
        OUT:appendByte(0)--turn into layer count

        local layerCount = 0

        local biomeID = 1

        if(jsonRoot:contains("encoding_version", JSON_TYPE.DOUBLE)) then
            local encoding_version = jsonRoot.lastFound:getDouble()
            if(encoding_version == 3 or encoding_version == 4) then

                if(jsonRoot:contains("biome_id", JSON_TYPE.DOUBLE)) then
                    local biomeId = jsonRoot.lastFound:getDouble()
                    if(Settings:dataTableContains("biomes", tostring(biomeId))) then
                        local entry = Settings.lastFound
                        local subEntry = entry[1]
                        biomeID = tonumber(subEntry[1])
                    end
                end


                if(jsonRoot:contains("block_layers", JSON_TYPE.ARRAY)) then
                    local block_layers = jsonRoot.lastFound

                    for i=0, block_layers.childCount-1 do
                        local layerIn = block_layers:child(i)
                        local layerBlockID = 0
                        local layerBlockData = 0
                        local layerHeight = 1

                        if(layerIn:contains("count", JSON_TYPE.DOUBLE)) then
                            layerHeight = layerIn.lastFound:getDouble()
                        end

                        local block_data = 0

                        if(layerIn:contains("block_data", JSON_TYPE.DOUBLE)) then block_data = layerIn.lastFound:getDouble() end

                        layerBlockData = block_data

                        if(encoding_version == 3) then
                            if(layerIn:contains("block_id", JSON_TYPE.DOUBLE)) then
                                local ChunkVersion = Settings:getSettingInt("ChunkVersion")
                                if(Settings:dataTableContains("blocks_ids", tostring(layerIn.lastFound:getDouble()))) then
                                    local entry = Settings.lastFound

                                    for index, _ in ipairs(entry) do
                                        local subEntry = entry[index]
                                        if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                                        if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= layerBlockData) then goto entryContinue end end

                                        layerBlockID = tonumber(subEntry[3])
                                        if(subEntry[4]:len() ~= 0) then layerBlockData = tonumber(subEntry[4]) end
                                        break
                                        ::entryContinue::
                                    end
                                end
                            end
                        elseif(encoding_version == 4) then
                            if(layerIn:contains("block_name", JSON_TYPE.STRING)) then
                                local ChunkVersion = Settings:getSettingInt("ChunkVersion")
                                local blockName = layerIn.lastFound:getString()
                                if(blockName:find("^minecraft:")) then blockName = blockName:sub(11) end
                                if(Settings:dataTableContains("blocks_names", blockName)) then
                                    local entry = Settings.lastFound

                                    for index, _ in ipairs(entry) do
                                        local subEntry = entry[index]
                                        if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                                        if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= layerBlockData) then goto entryContinue end end
                                        layerBlockID = tonumber(subEntry[4])
                                        if(subEntry[5]:len() ~= 0) then layerBlockData = tonumber(subEntry[5]) end
                                        break
                                        ::entryContinue::
                                    end
                                end
                            end
                        end

                        OUT:appendShort(layerBlockID)
                        OUT:appendByte(layerBlockData)
                        OUT:appendByte(layerHeight)

                        layerCount = layerCount + 1

                    end
                end


            end
        end


        OUT:appendByte(1)
        OUT:appendByte(16)
        OUT:appendByte(1)
        OUT:appendByte(0)
        OUT:appendByte(biomeID)

        OUT:setByte(14, layerCount)
    else return nil end

    return OUT
end