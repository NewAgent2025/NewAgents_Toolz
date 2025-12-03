function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

--level.dat START
function ConvertLevel(IN)
    OUT = TagCompound.new()

    --create output tags that have no matching input
    OUT:addChild(TagByte.new("bonusChestEnabled", false))
    OUT:addChild(TagByte.new("bonusChestSpawned", false))
    OUT:addChild(TagByte.new("CenterMapsToOrigin", true))
    OUT:addChild(TagByte.new("commandblockoutput", true))
    OUT:addChild(TagByte.new("commandblocksenabled", true))
    OUT:addChild(TagByte.new("commandsEnabled", true))
    OUT:addChild(TagByte.new("dodaylightcycle", true))
    OUT:addChild(TagByte.new("doentitydrops", true))
    OUT:addChild(TagByte.new("dofiretick", true))
    OUT:addChild(TagByte.new("doinsomnia", true))
    OUT:addChild(TagByte.new("domobloot", true))
    OUT:addChild(TagByte.new("domobspawning", true))
    OUT:addChild(TagByte.new("dotiledrops", true))
    OUT:addChild(TagByte.new("doweathercycle", true))
    OUT:addChild(TagByte.new("drowningdamage", true))
    OUT:addChild(TagByte.new("educationFeaturesEnabled", false))
    OUT:addChild(TagByte.new("eduLevel", false))
    OUT:addChild(TagByte.new("experimentalgameplay", false))
    OUT:addChild(TagByte.new("falldamage", true))
    OUT:addChild(TagByte.new("firedamage", true))
    OUT:addChild(TagByte.new("ForceGameType", false))
    OUT:addChild(TagByte.new("hasLockedBehaviorPack", false))
    OUT:addChild(TagByte.new("hasLockedResourcePack", false))
    OUT:addChild(TagByte.new("immutableWorld", false))
    OUT:addChild(TagByte.new("isFromLockedTemplate", false))
    OUT:addChild(TagByte.new("keepinventory", false))
    OUT:addChild(TagByte.new("LANBroadcast", true))
    OUT:addChild(TagByte.new("mobgriefing", true))
    OUT:addChild(TagByte.new("MultiplayerGame", true))
    OUT:addChild(TagByte.new("naturalregeneration", true))
    OUT:addChild(TagByte.new("PlatformBroadcast", true))
    OUT:addChild(TagByte.new("pvp", true))
    OUT:addChild(TagByte.new("sendcommandfeedback", true))
    OUT:addChild(TagByte.new("showcoordinates", false))
    OUT:addChild(TagByte.new("spawnMobs", true))
    OUT:addChild(TagByte.new("startWithMapEnabled", false))
    OUT:addChild(TagByte.new("texturePacksRequired", false))
    OUT:addChild(TagByte.new("tntexplodes", true))
    OUT:addChild(TagByte.new("useMsaGamertagsOnly", false))
    OUT:addChild(TagByte.new("XBLBroadcast", true))
    OUT:addChild(TagByte.new("XBLBroadcastIntent", true))
    OUT:addChild(TagInt.new("functioncommandlimit", 10000))
    OUT:addChild(TagInt.new("LimitedWorldOriginY", 32767)) --spawny
    OUT:addChild(TagInt.new("maxcommandchainlength", 65535))
    OUT:addChild(TagInt.new("NetherScale", 8))
    OUT:addChild(TagInt.new("NetworkVersion", 291))
    OUT:addChild(TagInt.new("Platform", 2)) --curious
    OUT:addChild(TagInt.new("PlatformBroadcastMode", 3))
    OUT:addChild(TagInt.new("serverChunkTickRange", 10))
    OUT:addChild(TagInt.new("SpawnY", 32767))
    OUT:addChild(TagInt.new("StorageVersion", 8)) --curious
    OUT:addChild(TagInt.new("XBLBroadcastMode", 3))
    OUT:addChild(TagLong.new("worldStartCount", 0))--curous
    OUT:addChild(TagString.new("InventoryVersion", "1.7.1"))
    OUT:addChild(TagString.new("prid", "")) --unknown

    OUT.lastOpenedWithVersion = OUT:addChild(TagList.new("lastOpenedWithVersion"))
    OUT.lastOpenedWithVersion:addChild(TagInt.new("", 1))
    OUT.lastOpenedWithVersion:addChild(TagInt.new("", 7))
    OUT.lastOpenedWithVersion:addChild(TagInt.new("", 1))
    OUT.lastOpenedWithVersion:addChild(TagInt.new("", 0))

    OUT.MinimumCompatibleClientVersion = OUT:addChild(TagList.new("MinimumCompatibleClientVersion"))
    OUT.MinimumCompatibleClientVersion:addChild(TagInt.new("", 1))
    OUT.MinimumCompatibleClientVersion:addChild(TagInt.new("", 7))
    OUT.MinimumCompatibleClientVersion:addChild(TagInt.new("", 1))
    OUT.MinimumCompatibleClientVersion:addChild(TagInt.new("", 0))

    Settings:setSettingInt("LevelVersion", 8)

    --create output tags that do have a matching input
    --store those tags in their own variable
    OUT.Difficulty = OUT:addChild(TagInt.new("Difficulty", 2))
    OUT.GameType = OUT:addChild(TagInt.new("GameType", 1))
    OUT.Generator = OUT:addChild(TagInt.new("Generator", 1))
    OUT.hasBeenLoadedInCreative = OUT:addChild(TagByte.new("hasBeenLoadedInCreative", true))
    OUT.lightningTime = OUT:addChild(TagInt.new("lightningTime", 100000))
    OUT.rainTime = OUT:addChild(TagInt.new("rainTime", 50000))
    OUT.LimitedWorldOriginX = OUT:addChild(TagInt.new("LimitedWorldOriginX", 0)) --spawnx
    OUT.LimitedWorldOriginZ = OUT:addChild(TagInt.new("LimitedWorldOriginZ", 0)) --spawnz
    OUT.SpawnX = OUT:addChild(TagInt.new("SpawnX", 0)) --spawn point
    OUT.SpawnZ = OUT:addChild(TagInt.new("SpawnZ", 0))
    OUT.currentTick = OUT:addChild(TagLong.new("currentTick", 1000)) --curious
    OUT.LastPlayed = OUT:addChild(TagLong.new("LastPlayed", os.time())) --required
    OUT.RandomSeed = OUT:addChild(TagLong.new("RandomSeed", 0))
    OUT.Time = OUT:addChild(TagLong.new("Time", 1000)) --curious
    OUT.lightningLevel = OUT:addChild(TagFloat.new("lightningLevel", 0)) --unknown
    OUT.rainLevel = OUT:addChild(TagFloat.new("rainLevel", 0)) --unknown
    OUT.FlatWorldLayers = OUT:addChild(TagString.new("FlatWorldLayers", "null\n")) --set based on generatorName and generatorOptions maybe?
    OUT.LevelName = OUT:addChild(TagString.new("LevelName", "My Converted World"))

    Settings:setSettingLong("Difficulty", 2)

    --iterate through the input level.dat
    if(IN:contains("Data", TYPE.COMPOUND)) then
        IN.Data = IN.lastFound
        
        for i=0, IN.Data.childCount-1 do
            local in_child = IN.Data:child(i)
            local in_child_name = in_child.name
            local in_child_type = in_child.type

            --apply changes to matching tags
            if(in_child_type == TYPE.BYTE)then
                if(in_child_name == "Difficulty") then
                    if(in_child.value >= 0 and in_child.value <= 3) then
                        OUT.Difficulty.value = in_child.value
                        Settings:setSettingLong("Difficulty", in_child.value)
                    end
                elseif(in_child_name == "raining") then OUT.rainLevel.value = in_child.value
                elseif(in_child_name == "thundering") then OUT.lightningLevel.value = in_child.value
                end
            elseif(in_child_type == TYPE.INT)then
                if(in_child_name == "GameType")then OUT.GameType.value = in_child.value
                elseif(in_child_name == "generatorVersion")then
                    if(in_child.value == 0) then
                        OUT.Generator.value = 2
                    else
                        OUT.Generator.value = 1
                    end
                elseif(in_child_name == "rainTime")then OUT.rainTime.value = in_child.value
                elseif(in_child_name == "SpawnX")then
                    OUT.SpawnX.value = in_child.value
                    OUT.LimitedWorldOriginX.value = in_child.value
                elseif(in_child_name == "SpawnZ")then
                    OUT.SpawnZ.value = in_child.value
                    OUT.LimitedWorldOriginZ.value = in_child.value
                elseif(in_child_name == "thunderTime")then OUT.lightningTime.value = in_child.value
                end
            elseif(in_child_type == TYPE.LONG)then
                if(in_child_name == "DayTime") then OUT.Time.value = in_child.value
                elseif(in_child_name == "LastPlayed") then
                    --OUT.LastPlayed.value = os.time()
                elseif(in_child_name == "RandomSeed") then OUT.RandomSeed.value = in_child.value
                elseif(in_child_name == "Time") then
                    if(in_child.value > 1932735282) then
                        OUT.currentTick.value = 0
                    else
                        OUT.currentTick.value = in_child.value
                    end
                    Settings:setSettingLong("currentTick", OUT.currentTick.value)
                end
            elseif(in_child_type == TYPE.STRING)then
                if(in_child_name == "generatorName")then
                    if(in_child.value == "flat") then
                        if(IN.Data:contains("generatorOptions", TYPE.BYTE_ARRAY)) then
                            local genOptions_in = IN.Data.lastFound
                            local genOptions_out = ConvertGeneratorOptions(genOptions_in)
                            if(genOptions_out ~= nil) then OUT.FlatWorldLayers.value = genOptions_out.value end
                        end
                    end
                end
            end
        end
    end

    return OUT
end

function ConvertGeneratorOptions(IN)

    local jsonRoot = JSONValue.new(JSON_TYPE.OBJECT)

    local jsonBiome = JSONValue.new(JSON_TYPE.DOUBLE)
    jsonBiome:setDouble(1)
    jsonRoot:addChild(jsonBiome, "biome_id")

    local jsonEncodingVersion = JSONValue.new(JSON_TYPE.DOUBLE)
    jsonEncodingVersion:setDouble(4)
    jsonRoot:addChild(jsonEncodingVersion, "encoding_version")

    local jsonStructureOptions = JSONValue.new(JSON_TYPE.NIL)
    jsonRoot:addChild(jsonStructureOptions, "structure_options")

    local jsonLayers = JSONValue.new(JSON_TYPE.ARRAY)

    local c = 0
    local size = IN:getSize()

    --First byte is a version number?
    if(c+1 >= size) then return nil end
    local version = IN:getByte(c)
    c=c+1

    if(version == 5 or version == 255) then
        if(c+2 >= size) then return nil end
        local nameLength = IN:getShort(c)
        c=c+2+nameLength
        
        if(c+1 >= size) then return nil end
        local layerCount = IN:getByte(c)
        c=c+1

        local layerByteSize = 3
        if(version == 5) then
            layerByteSize = 4
        end

        if(c+(layerCount*layerByteSize) >= size) then return nil end
        for i=0, layerCount-1 do
            local layerBlockID = 0
            
            if(version == 255)then
                layerBlockID = IN:getByte(c)
                c=c+1
            elseif(version == 5) then
                layerBlockID = IN:getShort(c)
                c=c+2
            end

            local layerBlockData = IN:getByte(c)
            c=c+1
            local layerHeight = IN:getByte(c)
            c=c+1

            local jsonLayer = JSONValue.new(JSON_TYPE.OBJECT)

            local jsonLayerCount = JSONValue.new(JSON_TYPE.DOUBLE)
            jsonLayerCount:setDouble(layerHeight)

            local jsonLayerBlockName = JSONValue.new(JSON_TYPE.STRING)
            jsonLayerBlockName:setString("minecraft:air")

            local jsonLayerBlockData = JSONValue.new(JSON_TYPE.DOUBLE)
            jsonLayerBlockData:setDouble(0)

            if(Settings:dataTableContains("blocks_ids", tostring(layerBlockID)) and layerBlockID ~= 0) then
                local entry = Settings.lastFound

                --TODO Compare version 12 with generatorOptions version for correctness (I forget what this means when I wrote it)
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > 12) then goto entryContinue end end
                    if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= layerBlockData) then goto entryContinue end end
                    jsonLayerBlockName:setString("minecraft:" .. subEntry[3])
                    jsonLayerBlockData:setDouble(layerBlockData)--copy first
                    if(subEntry[4]:len() ~= 0) then jsonLayerBlockData:setDouble(tonumber(subEntry[4])) end
                    break
                    ::entryContinue::
                end
            end

            jsonLayer:addChild(jsonLayerCount, "count")
            jsonLayer:addChild(jsonLayerBlockName, "block_name")
            jsonLayer:addChild(jsonLayerBlockData, "block_data")

            jsonLayers:addChild(jsonLayer)
        end

        --Extra generator options
        if(c+1 >= size) then return nil end
        local optionsCount = IN:getByte(c)
        c=c+1
        if(c+(optionsCount*4) >= size) then return nil end
        for i=0, optionsCount-1 do
            local optionsID = IN:getByte(c)
            c=c+1

            --TODO identify all option IDs
            if(optionsID == 16) then
                --Biome? unconfirmed!
                local biomeID = IN:getByte(c+2)
                c=c+3
                if(Settings:dataTableContains("biomes", tostring(biomeID))) then
                    local entry = Settings.lastFound
                    local subEntry = entry[1]
                    jsonBiome:setDouble(tonumber(subEntry[1]))
                    jsonRoot:addChild(jsonBiome,"biome_id")
                end
            end
        end
    else return nil end

    jsonRoot:addChild(jsonLayers, "block_layers")

    return TagString.new("", jsonRoot:serialize())
end