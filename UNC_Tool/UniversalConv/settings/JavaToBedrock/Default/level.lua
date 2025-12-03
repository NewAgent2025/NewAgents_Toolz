Utils = Utils or require("utils")

function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function toStringBool(str)
    if(str == "true") then return true else return false end
end
    
function ConvertLevel(IN)
    local OUT = TagCompound.new()

    --create output tags that have no matching input
    OUT:addChild(TagByte.new("bonusChestEnabled", false))
    OUT:addChild(TagByte.new("bonusChestSpawned", false))
    OUT:addChild(TagByte.new("CenterMapsToOrigin", true))
    OUT:addChild(TagByte.new("ConfirmedPlatformLockedContent", false))
    OUT:addChild(TagByte.new("doimmediaterespawn", false))
    OUT:addChild(TagByte.new("doinsomnia", true))
    OUT:addChild(TagByte.new("drowningdamage", true))
    OUT:addChild(TagByte.new("educationFeaturesEnabled", false))
    OUT:addChild(TagByte.new("eduLevel", false))
    OUT:addChild(TagByte.new("experimentalgameplay", false))
    OUT:addChild(TagByte.new("falldamage", true))
    OUT:addChild(TagByte.new("firedamage", true))
    OUT:addChild(TagByte.new("ForceGameType", false))
    OUT:addChild(TagByte.new("hasBeenLoadedInCreative", false))
    OUT:addChild(TagByte.new("hasLockedBehaviorPack", false))
    OUT:addChild(TagByte.new("hasLockedResourcePack", false))
    OUT:addChild(TagByte.new("immutableWorld", false))
    OUT:addChild(TagByte.new("isFromLockedTemplate", false))
    OUT:addChild(TagByte.new("isFromWorldTemplate", false))
    OUT:addChild(TagByte.new("isWorldTemplateOptionLocked", false))
    OUT:addChild(TagByte.new("LANBroadcast", true))
    OUT:addChild(TagByte.new("LANBroadcastIntent", true))
    OUT:addChild(TagByte.new("MultiplayerGame", true))
    OUT:addChild(TagByte.new("MultiplayerGameIntent", true))
    OUT:addChild(TagByte.new("pvp", true))
    OUT:addChild(TagByte.new("requiresCopiedPackRemovalCheck", false))
    OUT:addChild(TagByte.new("showcoordinates", false))
    OUT:addChild(TagByte.new("SpawnV1Villagers", false))
    OUT:addChild(TagByte.new("startWithMapEnabled", false))
    OUT:addChild(TagByte.new("texturePacksRequired", false))
    OUT:addChild(TagByte.new("tntexplodes", true))
    OUT:addChild(TagByte.new("useMsaGamertagsOnly", false))
    OUT:addChild(TagInt.new("functioncommandlimit", 10000))
    OUT:addChild(TagInt.new("LimitedWorldOriginY", 32767)) --spawny
    OUT:addChild(TagInt.new("NetherScale", 8))
    OUT:addChild(TagInt.new("NetworkVersion", 361))
    OUT:addChild(TagInt.new("Platform", 2)) --curious
    OUT:addChild(TagInt.new("PlatformBroadcastIntent", 3))
    OUT:addChild(TagInt.new("serverChunkTickRange", 10))
    OUT:addChild(TagInt.new("SpawnY", 32767))
    OUT:addChild(TagInt.new("StorageVersion", 8)) --curious
    OUT:addChild(TagInt.new("XBLBroadcastIntent", 3))
    OUT:addChild(TagLong.new("worldStartCount", 0))--curous
    OUT:addChild(TagString.new("InventoryVersion", "1.17.0"))--change over time? not required?
    OUT:addChild(TagString.new("prid", "")) --unknown

    OUT.lastOpenedWithVersion = OUT:addChild(TagList.new("lastOpenedWithVersion"))
    OUT.lastOpenedWithVersion:addChild(TagInt.new("", 1))
    OUT.lastOpenedWithVersion:addChild(TagInt.new("", 17))
    OUT.lastOpenedWithVersion:addChild(TagInt.new("", 0))
    OUT.lastOpenedWithVersion:addChild(TagInt.new("", 2))
    OUT.lastOpenedWithVersion:addChild(TagInt.new("", 0))

    OUT.MinimumCompatibleClientVersion = OUT:addChild(TagList.new("MinimumCompatibleClientVersion"))
    OUT.MinimumCompatibleClientVersion:addChild(TagInt.new("", 1))
    OUT.MinimumCompatibleClientVersion:addChild(TagInt.new("", 17))
    OUT.MinimumCompatibleClientVersion:addChild(TagInt.new("", 0))
    OUT.MinimumCompatibleClientVersion:addChild(TagInt.new("", 2))
    OUT.MinimumCompatibleClientVersion:addChild(TagInt.new("", 0))

    Settings:setSettingInt("LevelVersion", 8) --change over time

    --create output tags that do have a matching input
    --store those tags in their own variable
    OUT.commandblockoutput = OUT:addChild(TagByte.new("commandblockoutput", true))
    OUT.commandsenabled = OUT:addChild(TagByte.new("commandsEnabled", true))
    OUT.commandblocksenabled = OUT:addChild(TagByte.new("commandblocksenabled", true))
    OUT.dodaylightcycle = OUT:addChild(TagByte.new("dodaylightcycle", true))
    OUT.doentitydrops = OUT:addChild(TagByte.new("doentitydrops", true))
    OUT.dofiretick = OUT:addChild(TagByte.new("dofiretick", true))
    OUT.domobloot = OUT:addChild(TagByte.new("domobloot", true))
    OUT.domobspawning = OUT:addChild(TagByte.new("domobspawning", true))
    OUT.dotiledrops = OUT:addChild(TagByte.new("dotiledrops", true))
    OUT.doweathercycle = OUT:addChild(TagByte.new("doweathercycle", true))
    OUT.keepinventory = OUT:addChild(TagByte.new("keepinventory", false))
    OUT.mobgriefing = OUT:addChild(TagByte.new("mobgriefing", true))
    OUT.naturalregeneration = OUT:addChild(TagByte.new("naturalregeneration", true))
    OUT.sendcommandfeedback = OUT:addChild(TagByte.new("sendcommandfeedback", true))
    OUT.showdeathmessages = OUT:addChild(TagByte.new("showdeathmessages", true))
    OUT.spawnMobs = OUT:addChild(TagByte.new("spawnMobs", true)) -- maybe?
    OUT.Difficulty = OUT:addChild(TagInt.new("Difficulty", 2))
    OUT.GameType = OUT:addChild(TagInt.new("GameType", 1))
    OUT.Generator = OUT:addChild(TagInt.new("Generator", 1))
    OUT.lightningTime = OUT:addChild(TagInt.new("lightningTime", 100000))
    OUT.rainTime = OUT:addChild(TagInt.new("rainTime", 50000))
    OUT.LimitedWorldOriginX = OUT:addChild(TagInt.new("LimitedWorldOriginX", 0)) --spawnx
    OUT.LimitedWorldOriginZ = OUT:addChild(TagInt.new("LimitedWorldOriginZ", 0)) --spawnz
    OUT.maxcommandchainlength = OUT:addChild(TagInt.new("maxcommandchainlength", 65535))
    OUT.randomtickspeed = OUT:addChild(TagInt.new("randomtickspeed", 1)) -- stay at 1?
    OUT.spawnradius = OUT:addChild(TagInt.new("spawnradius", 5)) --stay at 5?
    OUT.SpawnX = OUT:addChild(TagInt.new("SpawnX", 0)) --spawn point
    OUT.SpawnZ = OUT:addChild(TagInt.new("SpawnZ", 0))
    OUT.currentTick = OUT:addChild(TagLong.new("currentTick", 0))
    OUT.LastPlayed = OUT:addChild(TagLong.new("LastPlayed", os.time())) --required
    OUT.RandomSeed = OUT:addChild(TagLong.new("RandomSeed", 0))
    OUT.Time = OUT:addChild(TagLong.new("Time", 0))
    OUT.lightningLevel = OUT:addChild(TagFloat.new("lightningLevel", 0))
    OUT.rainLevel = OUT:addChild(TagFloat.new("rainLevel", 0))
    OUT.FlatWorldLayers = OUT:addChild(TagString.new("FlatWorldLayers", "null\n")) --set based on generatorName and generatorOptions maybe?
    OUT.LevelName = OUT:addChild(TagString.new("LevelName", "My Converted World"))

    Settings:setSettingLong("currentTick", 0)
    Settings:setSettingLong("Difficulty", 2)

    --iterate through the input level.dat
    if(IN:contains("Data", TYPE.COMPOUND)) then
        IN.Data = IN.lastFound

        IN.DataVersion = 0;
        if(IN.Data:contains("DataVersion", TYPE.INT)) then
            IN.DataVersion = IN.Data.lastFound.value
            Settings:setSettingInt("DataVersion", IN.DataVersion)
        end
        
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
                elseif(in_child_name == "allowCommands") then
                    OUT.commandsenabled.value = in_child.value
                    OUT.commandblocksenabled.value = in_child.value
                end
            elseif(in_child_type == TYPE.INT)then
                if(in_child_name == "GameType")then
                    if(in_child.value >= 0 and in_child.value <= 2) then OUT.GameType.value = in_child.value end
                elseif(in_child_name == "generatorVersion")then
                    --[[
                    if(in_child.value == 0) then
                        OUT.Generator.value = 2
                    else
                        OUT.Generator.value = 1
                    end
                    ]]
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
                    --OUT.LastPlayed.value = round(in_child.value/1000)
                    --uncomment this if you want the input world timestamp to convert
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
                if(in_child_name == "LevelName") then OUT.LevelName.value = in_child.value
                elseif(in_child_name == "generatorName") then
                    if(in_child.value == "flat") then
                        OUT.Generator.value = 2

                        --V1   1;7,2*3,2,35:1;1
                        --V2   2;7,2*3,2,35:1;1;
                        --V3   3;minecraft:bedrock,2*minecraft:dirt,minecraft:grass,minecraft:wool:1;1;
                        --V4   NBT

                        local genOptions_out = TagString.new()

                        if(IN.Data:contains("generatorOptions", TYPE.COMPOUND) and IN.DataVersion ~= nil) then
                            IN.Data.generatorOptions = IN.Data.lastFound
                            genOptions_out = ConvertGeneratorOptions(IN.Data.generatorOptions, IN.DataVersion)
                        elseif(IN.Data:contains("generatorOptions", TYPE.STRING)) then
                            IN.Data.generatorOptions = IN.Data.lastFound
                            if(IN.Data.generatorOptions.value:len() ~= 0) then
                                genOptions_out = ConvertGeneratorOptionsLegacy(IN.Data.generatorOptions.value:gsub("%s+", ""), IN.DataVersion)
                            end
                        end

                        if(genOptions_out ~= nil) then OUT.FlatWorldLayers.value = genOptions_out.value end
                    else
                        OUT.Generator.value = 1
                    end
                end
            elseif(in_child_type == TYPE.COMPOUND)then
                if(in_child_name == "GameRules") then
                    IN.Data.GameRules = in_child
                    for gr=0, IN.Data.GameRules.childCount-1 do
                        local in_GameRules_child = IN.Data.GameRules:child(gr)
                        local in_GameRules_child_name = in_GameRules_child.name
                        local in_GameRules_child_type = in_GameRules_child.type

                        if(in_GameRules_child_type == TYPE.STRING)then
                            if(in_GameRules_child_name == "maxCommandChainLength") then if(tonumber(in_GameRules_child.value) ~= nil) then OUT.maxcommandchainlength.value = tonumber(in_GameRules_child.value) end
                            elseif(in_GameRules_child_name == "randomTickSpeed") then if(tonumber(in_GameRules_child.value) ~= nil) then OUT.randomtickspeed.value = tonumber(in_GameRules_child.value)//3 end
                            elseif(in_GameRules_child_name == "spawnRadius") then if(tonumber(in_GameRules_child.value) ~= nil) then OUT.spawnradius.value = tonumber(in_GameRules_child.value) end
                            elseif(in_GameRules_child_name == "commandBlockOutput") then OUT.commandblockoutput.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "doDaylightCycle") then OUT.dodaylightcycle.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "doEntityDrops") then OUT.doentitydrops.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "doFireTick") then OUT.dofiretick.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "doMobLoot") then OUT.domobloot.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "doMobSpawning") then OUT.domobspawning.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "doTileDrops") then OUT.dotiledrops.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "doWeatherCycle") then OUT.doweathercycle.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "keepInventory") then OUT.keepinventory.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "mobGriefing") then OUT.mobgriefing.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "naturalRegeneration") then OUT.naturalregeneration.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "sendCommandFeedback") then OUT.sendcommandfeedback.value = toStringBool(in_GameRules_child.value)
                            elseif(in_GameRules_child_name == "showDeathMessages") then OUT.showdeathmessages.value = toStringBool(in_GameRules_child.value)
                            end
                        end
                    end
                elseif(in_child_name == "WorldGenSettings") then
                    IN.Data.WorldGenSettings = in_child

                    if(IN.Data.WorldGenSettings:contains("seed", TYPE.LONG)) then
                        OUT.RandomSeed.value = IN.Data.WorldGenSettings.lastFound.value
                    end

                    if(IN.Data.WorldGenSettings:contains("dimensions", TYPE.COMPOUND)) then
                        IN.Data.WorldGenSettings.dimensions = IN.Data.WorldGenSettings.lastFound

                        if(IN.Data.WorldGenSettings.dimensions:contains("minecraft:overworld", TYPE.COMPOUND)) then
                            local overworld = IN.Data.WorldGenSettings.dimensions.lastFound

                            if(overworld:contains("generator", TYPE.COMPOUND)) then
                                overworld.generator = overworld.lastFound

                                if(overworld.generator:contains("type", TYPE.STRING)) then
                                    if(overworld.generator.lastFound.value == "minecraft:flat") then
                                        OUT.Generator.value = 2

                                        if(overworld.generator:contains("settings", TYPE.COMPOUND)) then
                                            local genOptions_out = TagString.new()
                                            genOptions_out = ConvertGeneratorOptions(overworld.generator.lastFound, IN.DataVersion)
                                            if(genOptions_out ~= nil) then OUT.FlatWorldLayers.value = genOptions_out.value end
                                        end
                                    end
                                end
                            end

                        end
                    end
                end
            end
        end

        if(IN.Data:contains("clearWeatherTime", TYPE.INT)) then
            IN.Data.clearWeatherTime = IN.Data.lastFound
            if(IN.Data.clearWeatherTime.value ~= 0) then

                if(OUT.rainLevel.value == 0) then
                    if(OUT.rainTime.value < IN.Data.clearWeatherTime.value) then
                        OUT.rainTime.value = IN.Data.clearWeatherTime.value
                    end
                else
                    OUT.rainLevel.value = 0;
                    OUT.rainTime.value = IN.Data.clearWeatherTime.value
                end
            end
        end
    end

    return OUT
end

function ConvertGeneratorOptions(IN, DataVersion)

    local jsonRoot = JSONValue.new(JSON_TYPE.OBJECT)

    --[[
    local jsonBiome = JSONValue.new(JSON_TYPE.DOUBLE)
    jsonBiome:setDouble(1)
    jsonRoot:addChild(jsonBiome, "biome_id")
    --]]

    local jsonBiome = JSONValue.new(JSON_TYPE.STRING)
    jsonBiome:setString("minecraft:plains")
    jsonRoot:addChild(jsonBiome, "biome_name")

    local jsonEncodingVersion = JSONValue.new(JSON_TYPE.DOUBLE)
    jsonEncodingVersion:setDouble(4)
    jsonRoot:addChild(jsonEncodingVersion, "encoding_version")

    local jsonStructureOptions = JSONValue.new(JSON_TYPE.NIL)
    jsonRoot:addChild(jsonStructureOptions, "structure_options")

    local jsonLayers = JSONValue.new(JSON_TYPE.ARRAY)

    local totalHeight = 0
    local firstLayerIsAir = true
    if(IN:contains("layers", TYPE.LIST, TYPE.COMPOUND)) then
        local layers = IN.lastFound

        for i=0, layers.childCount-1 do
            local layer = layers:child(i)
            local layerBlockName = "minecraft:air"
            local layerBlockData = 0
            local layerHeight = 1

            if(layer:contains("block", TYPE.STRING)) then
                local blockString = layer.lastFound.value
                if(blockString:find("^minecraft:")) then blockString = blockString:sub(11) end

                if(DataVersion >= 1451) then

                    local layerBlock = Utils:findBlock(blockString)
                    if(layerBlock ~= nil and layerBlock.id ~= nil) then layerBlockName = "minecraft:" .. layerBlock.id end

                    --layer block data is excluded cus whatever
                else
                    --TODO Legacy block ids?
                end
            end

            if(layer:contains("height", TYPE.BYTE)) then layerHeight = layer.lastFound.value
            elseif(layer:contains("height", TYPE.INT)) then layerHeight = layer.lastFound.value
            end

            if(totalHeight == 0 and layerBlockName ~= "minecraft:air") then firstLayerIsAir = false end

            totalHeight = totalHeight + layerHeight

            local jsonLayer = JSONValue.new(JSON_TYPE.OBJECT)

            local jsonLayerCount = JSONValue.new(JSON_TYPE.DOUBLE)
            jsonLayerCount:setDouble(layerHeight)

            local jsonLayerBlockName = JSONValue.new(JSON_TYPE.STRING)
            jsonLayerBlockName:setString(layerBlockName)

            local jsonLayerBlockData = JSONValue.new(JSON_TYPE.DOUBLE)
            jsonLayerBlockData:setDouble(layerBlockData)

            jsonLayer:addChild(jsonLayerCount, "count")
            jsonLayer:addChild(jsonLayerBlockName, "block_name")
            jsonLayer:addChild(jsonLayerBlockData, "block_data")

            jsonLayers:addChild(jsonLayer)
        end

        --[[
        local biomeID = 1

        if(IN:contains("biome", TYPE.STRING)) then 
            local biomeString = IN.lastFound.value
            if(biomeString:find("^minecraft:")) then biomeString = biomeString:sub(11) end
            if(Settings:dataTableContains("biomes_names", biomeString)) then
                local entry = Settings.lastFound
                biomeID = tonumber(entry[1][1])
            end
        end

        jsonBiome:setDouble(biomeID)
        jsonRoot:addChild(jsonBiome,"biome_id")
        --]]

        local biomeName = "minecraft:plains"

        if(IN:contains("biome", TYPE.STRING)) then 
            local biomeString = IN.lastFound.value
            if(biomeString:find("^minecraft:")) then biomeString = biomeString:sub(11) end
            if(Settings:dataTableContains("biomes_names", biomeString)) then
                biomeName = IN.lastFound.value
            end
        end

        jsonBiome:setString(biomeName)
        jsonRoot:addChild(jsonBiome,"biome_name")
    end

    if(totalHeight < 2) then

        local jsonLayer = JSONValue.new(JSON_TYPE.OBJECT)

        local jsonLayerCount = JSONValue.new(JSON_TYPE.DOUBLE)
        jsonLayerCount:setDouble(1)

        local jsonLayerBlockName = JSONValue.new(JSON_TYPE.STRING)
        if(totalHeight == 1 and not firstLayerIsAir) then
            jsonLayerBlockName:setString("minecraft:light_block")
        else
            jsonLayerBlockName:setString("minecraft:air")
        end

        local jsonLayerBlockData = JSONValue.new(JSON_TYPE.DOUBLE)
        jsonLayerBlockData:setDouble(0)

        jsonLayer:addChild(jsonLayerCount, "count")
        jsonLayer:addChild(jsonLayerBlockName, "block_name")
        jsonLayer:addChild(jsonLayerBlockData, "block_data")

        jsonLayers:addChild(jsonLayer)
    end

    jsonRoot:addChild(jsonLayers, "block_layers")

    return TagString.new("", jsonRoot:serialize())
end

function ConvertGeneratorOptionsLegacy(IN, DataVersion)

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

    local firstLayerIsAir = true
    local totalHeight = 0
    local genVersion = 1
    local groupNum = 0
    for group in IN:gmatch("[^;]*") do
        group = group:gsub("^%s*(.-)%s*$", "%1")
        groupNum = groupNum+1

        if(group == nil) then return nil end
        if(group:len() == 0) then return nil end

        if(groupNum == 1 and group:len() > 1) then
            --version number missing
            groupNum = 2
            genVersion = 3
        end

        if(groupNum == 1) then
            --version
            genVersion = tonumber(group)
            if(genVersion < 1 or genVersion > 3) then return nil end
        elseif(groupNum == 2) then
            --layers

            for layer in group:gmatch("[^,]*") do

                local layerBlockName = "minecraft:air"
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

                    local layerBlock = Utils:findBlock(inBlockName)
                    if(layerBlock ~= nil and layerBlock.id ~= nil) then layerBlockName = "minecraft:" .. layerBlock.id end

                    --layer block data is excluded cus whatever

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

                    local layerBlock = Utils:findBlock(inBlockID)
                    if(layerBlock ~= nil and layerBlock.id ~= nil) then layerBlockName = "minecraft:" .. layerBlock.id end

                    --layer block data is excluded cus whatever
                end

                totalHeight = totalHeight + layerHeight

                if(totalHeight == 0 and layerBlockName ~= "minecraft:air") then firstLayerIsAir = false end

                local jsonLayer = JSONValue.new(JSON_TYPE.OBJECT)

                local jsonLayerCount = JSONValue.new(JSON_TYPE.DOUBLE)
                jsonLayerCount:setDouble(layerHeight)

                local jsonLayerBlockName = JSONValue.new(JSON_TYPE.STRING)
                jsonLayerBlockName:setString(layerBlockName)

                local jsonLayerBlockData = JSONValue.new(JSON_TYPE.DOUBLE)
                jsonLayerBlockData:setDouble(layerBlockData)

                jsonLayer:addChild(jsonLayerCount, "count")
                jsonLayer:addChild(jsonLayerBlockName, "block_name")
                jsonLayer:addChild(jsonLayerBlockData, "block_data")

                jsonLayers:addChild(jsonLayer)

            end

        elseif(groupNum == 3) then
            --biome

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
            
            jsonBiome:setDouble(biomeID)
            jsonRoot:addChild(jsonBiome,"biome_id")

            if(genVersion == 1) then break end
        elseif(groupNum == 4) then
            --extra
            break
        end
    end

    if(totalHeight < 2) then

        local jsonLayer = JSONValue.new(JSON_TYPE.OBJECT)

        local jsonLayerCount = JSONValue.new(JSON_TYPE.DOUBLE)
        jsonLayerCount:setDouble(1)

        local jsonLayerBlockName = JSONValue.new(JSON_TYPE.STRING)
        if(totalHeight == 1 and not firstLayerIsAir) then
            jsonLayerBlockName:setString("minecraft:light_block")
        else
            jsonLayerBlockName:setString("minecraft:air")
        end

        local jsonLayerBlockData = JSONValue.new(JSON_TYPE.DOUBLE)
        jsonLayerBlockData:setDouble(0)

        jsonLayer:addChild(jsonLayerCount, "count")
        jsonLayer:addChild(jsonLayerBlockName, "block_name")
        jsonLayer:addChild(jsonLayerBlockData, "block_data")

        jsonLayers:addChild(jsonLayer)
    end

    jsonRoot:addChild(jsonLayers, "block_layers")

    return TagString.new("", jsonRoot:serialize())
end