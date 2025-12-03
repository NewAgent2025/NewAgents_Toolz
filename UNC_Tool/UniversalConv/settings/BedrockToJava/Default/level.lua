Utils = Utils or require("utils")

function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function toBoolString(num)
    if(num == 0) then return "false" end
return "true"
end

function ConvertLevel(IN)
    OUT = TagCompound.new()

    OUT.Data = OUT:addChild(TagCompound.new("Data"))

    OUT.Data:addChild(TagInt.new("DataVersion", 2730))

    OUT.Data:addChild(TagByte.new("DifficultyLocked", false))
    OUT.Data:addChild(TagByte.new("hardcore", false))
    OUT.Data:addChild(TagByte.new("initialized", true))
    OUT.Data:addChild(TagByte.new("MapFeatures", true))
    OUT.Data:addChild(TagInt.new("clearWeatherTime", 0))
    OUT.Data:addChild(TagInt.new("version", 19133))
    OUT.Data:addChild(TagInt.new("WanderingTraderSpawnChance", 25))
    OUT.Data:addChild(TagInt.new("WanderingTraderSpawnDelay", 1200))
    OUT.Data:addChild(TagLong.new("BorderSizeLerpTime", 0))
    OUT.Data:addChild(TagLong.new("LastPlayed", os.time()*1000))
    OUT.Data:addChild(TagLong.new("SizeOnDisk", 0))
    OUT.Data:addChild(TagDouble.new("BorderCenterX", 0))
    OUT.Data:addChild(TagDouble.new("BorderCenterZ", 0))
    OUT.Data:addChild(TagDouble.new("BorderDamagePerBlock", 0.2))
    OUT.Data:addChild(TagDouble.new("BorderSafeZone", 5))
    OUT.Data:addChild(TagDouble.new("BorderSize", 60000000))
    OUT.Data:addChild(TagDouble.new("BorderSizeLerpTarget", 60000000))
    OUT.Data:addChild(TagDouble.new("BorderWarningBlocks", 5))
    OUT.Data:addChild(TagDouble.new("BorderWarningTime", 15))
    OUT.Data:addChild(TagString.new("LevelName", "world"))
    OUT.Data:addChild(TagCompound.new("CustomBossEvents"))
    OUT.Data:addChild(TagCompound.new("DimensionData"))
    OUT.Data:addChild(TagList.new("ScheduledEvents"))

    OUT.Data.allowCommands = OUT.Data:addChild(TagByte.new("allowCommands", true))
    OUT.Data.Difficulty = OUT.Data:addChild(TagByte.new("Difficulty", 2))
    OUT.Data.raining = OUT.Data:addChild(TagByte.new("raining", false))
    OUT.Data.thundering = OUT.Data:addChild(TagByte.new("thundering", false))
    OUT.Data.GameType = OUT.Data:addChild(TagInt.new("GameType", 1))
    --OUT.Data.generatorVersion = OUT.Data:addChild(TagInt.new("generatorVersion", 1))--------------------------
    OUT.Data.rainTime = OUT.Data:addChild(TagInt.new("rainTime", 32000))
    OUT.Data.SpawnX = OUT.Data:addChild(TagInt.new("SpawnX", 0))
    OUT.Data.SpawnY = OUT.Data:addChild(TagInt.new("SpawnY", 63))
    OUT.Data.SpawnZ = OUT.Data:addChild(TagInt.new("SpawnZ", 0))
    OUT.Data.thunderTime = OUT.Data:addChild(TagInt.new("thunderTime", 65000))
    OUT.Data.DayTime = OUT.Data:addChild(TagLong.new("DayTime", 3000))
    --OUT.Data.RandomSeed = OUT.Data:addChild(TagLong.new("RandomSeed", 0))---------------------------------
    OUT.Data.Time = OUT.Data:addChild(TagLong.new("Time", 3000))
    --OUT.Data.generatorName = OUT.Data:addChild(TagString.new("generatorName", "default"))----------------------

    OUT.Data.DataPacks = OUT.Data:addChild(TagCompound.new("DataPacks"))
    OUT.Data.DataPacks:addChild(TagList.new("Disabled"))
    OUT.Data.DataPacks.Enabled = OUT.Data.DataPacks:addChild(TagList.new("Enabled"))
    OUT.Data.DataPacks.Enabled:addChild(TagString.new("", "vanilla"))

    OUT.Data.Version = OUT.Data:addChild(TagCompound.new("Version"))
    OUT.Data.Version:addChild(TagByte.new("Snapshot", 0))
    OUT.Data.Version:addChild(TagInt.new("Id", 2730))
    OUT.Data.Version:addChild(TagString.new("Name", "1.17.1"))

    OUT.Data.GameRules = OUT.Data:addChild(TagCompound.new("GameRules"))

    OUT.Data.GameRules:addChild(TagString.new("announceAdvancements", "true"))
    OUT.Data.GameRules:addChild(TagString.new("disableElytraMovementCheck", "false"))
    OUT.Data.GameRules:addChild(TagString.new("disableRaids", "false"))
    OUT.Data.GameRules:addChild(TagString.new("doLimitedCrafting", "false"))
    OUT.Data.GameRules:addChild(TagString.new("logAdminCommands", "true"))
    OUT.Data.GameRules:addChild(TagString.new("maxEntityCramming", "24"))
    OUT.Data.GameRules:addChild(TagString.new("reducedDebugInfo", "false"))
    OUT.Data.GameRules:addChild(TagString.new("spawnRadius", "10"))
    OUT.Data.GameRules:addChild(TagString.new("spectatorsGenerateChunks", "true"))
    
    OUT.Data.GameRules.commandBlockOutput = OUT.Data.GameRules:addChild(TagString.new("commandBlockOutput", "true"))
    OUT.Data.GameRules.doDaylightCycle = OUT.Data.GameRules:addChild(TagString.new("doDaylightCycle", "true"))
    OUT.Data.GameRules.doEntityDrops = OUT.Data.GameRules:addChild(TagString.new("doEntityDrops", "true"))
    OUT.Data.GameRules.doFireTick = OUT.Data.GameRules:addChild(TagString.new("doFireTick", "true"))
    OUT.Data.GameRules.doMobLoot = OUT.Data.GameRules:addChild(TagString.new("doMobLoot", "true"))
    OUT.Data.GameRules.doMobSpawning = OUT.Data.GameRules:addChild(TagString.new("doMobSpawning", "true"))
    OUT.Data.GameRules.doTileDrops = OUT.Data.GameRules:addChild(TagString.new("doTileDrops", "true"))
    OUT.Data.GameRules.doWeatherCycle = OUT.Data.GameRules:addChild(TagString.new("doWeatherCycle", "true"))
    OUT.Data.GameRules.keepInventory = OUT.Data.GameRules:addChild(TagString.new("keepInventory", "false"))
    OUT.Data.GameRules.maxCommandChainLength = OUT.Data.GameRules:addChild(TagString.new("maxCommandChainLength", "65536"))
    OUT.Data.GameRules.mobGriefing = OUT.Data.GameRules:addChild(TagString.new("mobGriefing", "true"))
    OUT.Data.GameRules.naturalRegeneration = OUT.Data.GameRules:addChild(TagString.new("naturalRegeneration", "true"))
    OUT.Data.GameRules.sendCommandFeedback = OUT.Data.GameRules:addChild(TagString.new("sendCommandFeedback", "true"))
    OUT.Data.GameRules.showDeathMessages = OUT.Data.GameRules:addChild(TagString.new("showDeathMessages", "true"))
    OUT.Data.GameRules.randomTickSpeed = OUT.Data.GameRules:addChild(TagString.new("randomTickSpeed", "3"))

    OUT.Data.WorldGenSettings = OUT.Data:addChild(TagCompound.new("WorldGenSettings"))
    OUT.Data.WorldGenSettings:addChild(TagByte.new("bonus_chest", 0))

    OUT.Data.WorldGenSettings.seed = OUT.Data.WorldGenSettings:addChild(TagLong.new("seed", 0))
    OUT.Data.WorldGenSettings.generate_features = OUT.Data.WorldGenSettings:addChild(TagByte.new("generate_features", 1))

    local dimensions = OUT.Data.WorldGenSettings:addChild(TagCompound.new("dimensions"))

    dimensions.overworld = dimensions:addChild(TagCompound.new("minecraft:overworld"))
    dimensions.overworld:addChild(TagString.new("type", "minecraft:overworld"))
    dimensions.overworld.generator = dimensions.overworld:addChild(TagCompound.new("generator"))
    dimensions.overworld.generator.generatorType = dimensions.overworld.generator:addChild(TagString.new("type", "minecraft:noise"))

    dimensions.the_end = dimensions:addChild(TagCompound.new("minecraft:the_end"))
    dimensions.the_end:addChild(TagString.new("type", "minecraft:the_end"))
    dimensions.the_end.generator = dimensions.the_end:addChild(TagCompound.new("generator"))
    dimensions.the_end.generator:addChild(TagString.new("settings", "minecraft:end"))
    dimensions.the_end.generator:addChild(TagString.new("type", "minecraft:noise"))
    dimensions.the_end.generator.seed = dimensions.the_end.generator:addChild(TagLong.new("seed", 0))
    dimensions.the_end.generator.biome_source = dimensions.the_end.generator:addChild(TagCompound.new("biome_source"))
    dimensions.the_end.generator.biome_source.seed = dimensions.the_end.generator.biome_source:addChild(TagLong.new("seed", 0))
    dimensions.the_end.generator.biome_source:addChild(TagString.new("type", "minecraft:the_end"))

    dimensions.the_nether = dimensions:addChild(TagCompound.new("minecraft:the_nether"))
    dimensions.the_nether:addChild(TagString.new("type", "minecraft:the_nether"))
    dimensions.the_nether.generator = dimensions.the_nether:addChild(TagCompound.new("generator"))
    dimensions.the_nether.generator:addChild(TagString.new("settings", "minecraft:nether"))
    dimensions.the_nether.generator:addChild(TagString.new("type", "minecraft:noise"))
    dimensions.the_nether.generator.seed = dimensions.the_nether.generator:addChild(TagLong.new("seed", 0))
    dimensions.the_nether.generator.biome_source = dimensions.the_nether.generator:addChild(TagCompound.new("biome_source"))
    dimensions.the_nether.generator.biome_source.seed = dimensions.the_nether.generator.biome_source:addChild(TagLong.new("seed", 0))
    dimensions.the_nether.generator.biome_source:addChild(TagString.new("type", "minecraft:multi_noise"))
    dimensions.the_nether.generator.biome_source:addChild(TagString.new("preset", "minecraft:nether"))
    
    Settings:setSettingLong("Time", 0)
    
    --iterate through the input level.dat tags

    local needsFlatSettings = false
    local customFlatSettingsAdded = false
    
    for i=0, IN.childCount-1 do
        local in_child = IN:child(i)
        local in_child_name = in_child.name
        local in_child_type = in_child.type

        if(in_child_type == TYPE.BYTE)then
            if(in_child_name == "commandblockoutput") then OUT.Data.GameRules.commandBlockOutput.value = toBoolString(in_child.value)
            elseif(in_child_name == "commandsEnabled") then OUT.Data.allowCommands.value = in_child.value
            elseif(in_child_name == "dodaylightcycle") then OUT.Data.GameRules.doDaylightCycle.value =  toBoolString(in_child.value)
            elseif(in_child_name == "doentitydrops") then OUT.Data.GameRules.doEntityDrops.value =  toBoolString(in_child.value)
            elseif(in_child_name == "dofiretick") then OUT.Data.GameRules.doFireTick.value =  toBoolString(in_child.value)
            elseif(in_child_name == "domobloot") then OUT.Data.GameRules.doMobLoot.value =  toBoolString(in_child.value)
            elseif(in_child_name == "domobspawning") then OUT.Data.GameRules.doMobSpawning.value =  toBoolString(in_child.value)
            elseif(in_child_name == "dotiledrops") then OUT.Data.GameRules.doTileDrops.value =  toBoolString(in_child.value)
            elseif(in_child_name == "doweathercycle") then OUT.Data.GameRules.doWeatherCycle.value =  toBoolString(in_child.value)
            elseif(in_child_name == "keepinventory") then OUT.Data.GameRules.keepInventory.value =  toBoolString(in_child.value)
            elseif(in_child_name == "mobgriefing") then OUT.Data.GameRules.mobGriefing.value =  toBoolString(in_child.value)
            elseif(in_child_name == "naturalregeneration") then OUT.Data.GameRules.naturalRegeneration.value =  toBoolString(in_child.value)
            elseif(in_child_name == "sendcommandfeedback") then OUT.Data.GameRules.sendCommandFeedback.value =  toBoolString(in_child.value)
            elseif(in_child_name == "showdeathmessages") then OUT.Data.GameRules.showDeathMessages.value =  toBoolString(in_child.value)
            end
        elseif(in_child_type == TYPE.INT)then
            if(in_child_name == "Difficulty") then OUT.Data.Difficulty.value = in_child.value
            elseif(in_child_name == "GameType") then OUT.Data.GameType.value = in_child.value
            elseif(in_child_name == "Generator") then
                if(in_child.value == 2)then
                    dimensions.overworld.generator.generatorType.value = "minecraft:flat"
                    needsFlatSettings = true
                else
                    dimensions.overworld.generator.generatorType.value = "minecraft:noise"
                end
            elseif(in_child_name == "lightningTime") then OUT.Data.thunderTime.value = in_child.value
            elseif(in_child_name == "maxcommandchainlength") then OUT.Data.GameRules.maxCommandChainLength.value = tostring(in_child.value)
            elseif(in_child_name == "rainTime") then OUT.Data.rainTime.value = in_child.value
            elseif(in_child_name == "GameType") then OUT.Data.GameType.value = in_child.value
            elseif(in_child_name == "SpawnX") then OUT.Data.SpawnX.value = in_child.value
            elseif(in_child_name == "SpawnZ") then OUT.Data.SpawnZ.value = in_child.value
            elseif(in_child_name == "randomtickspeed") then OUT.Data.GameRules.randomTickSpeed.value = tostring(in_child.value*3)
            end
        elseif(in_child_type == TYPE.LONG)then
            if(in_child_name == "RandomSeed") then
                OUT.Data.WorldGenSettings.seed.value = in_child.value
                dimensions.the_end.generator.seed.value = in_child.value
                dimensions.the_nether.generator.seed.value = in_child.value
                dimensions.the_end.generator.biome_source.seed.value = in_child.value
                dimensions.the_nether.generator.biome_source.seed.value  = in_child.value
            elseif(in_child_name == "Time") then
                OUT.Data.DayTime.value = in_child.value
            elseif(in_child_name == "currentTick") then
                Settings:setSettingLong("Time", in_child.value)
                OUT.Data.Time.value = in_child.value
            end
        elseif(in_child_type == TYPE.FLOAT)then
            if(in_child_name == "lightningLevel") then OUT.Data.thundering.value = in_child.value ~= 0
            elseif(in_child_name == "rainLevel") then OUT.Data.raining.value = in_child.value ~= 0
            end
        elseif(in_child_type == TYPE.STRING) then 
            if(in_child_name == "FlatWorldLayers") then
                local genOptions_out = ConvertGeneratorOptions(in_child.value)
                if(genOptions_out ~= nil) then
                    dimensions.overworld.generator:addChild(genOptions_out)
                    customFlatSettingsAdded = true
                    OUT.Data.WorldGenSettings.generate_features.value = 0;
                end
            end
        end
    end

    if(needsFlatSettings and not customFlatSettingsAdded) then
        local defaultFlatSettings = TagCompound.new("settings")

        defaultFlatSettings.layers = defaultFlatSettings:addChild(TagList.new("layers"))
        
        for i=0, 2 do
            local layer = TagCompound.new()
            layer.height = layer:addChild(TagInt.new("height", 0))
            layer.block = layer:addChild(TagString.new("block", "minecraft:air"))

            if(i == 0) then
                layer.height.value = 1
                layer.block.value = "minecraft:bedrock"
            elseif(i == 1) then
                layer.height.value = 2
                layer.block.value = "minecraft:dirt"
            elseif(i == 2) then
                layer.height.value = 1
                layer.block.value = "minecraft:grass_block"
            end

            defaultFlatSettings.layers:addChild(layer)
        end

        defaultFlatSettings.biome = defaultFlatSettings:addChild(TagString.new("biome", "minecraft:plains"))
        defaultFlatSettings.structures = defaultFlatSettings:addChild(TagCompound.new("structures"))
        defaultFlatSettings.structures.stronghold = defaultFlatSettings.structures:addChild(TagCompound.new("stronghold"))
        defaultFlatSettings.structures.stronghold:addChild(TagInt.new("count", 128))
        defaultFlatSettings.structures.stronghold:addChild(TagInt.new("distance", 32))
        defaultFlatSettings.structures.stronghold:addChild(TagInt.new("spread", 3))
        defaultFlatSettings.structures.structures = defaultFlatSettings.structures:addChild(TagCompound.new("structures"))
        defaultFlatSettings.structures.structures.minecraft_village = defaultFlatSettings.structures.structures:addChild(TagCompound.new("minecraft:village"))
        defaultFlatSettings.structures.structures.minecraft_village:addChild(TagInt.new("salt", 10387312))
        defaultFlatSettings.structures.structures.minecraft_village:addChild(TagInt.new("separation", 8))
        defaultFlatSettings.structures.structures.minecraft_village:addChild(TagInt.new("spacing", 32))
        defaultFlatSettings:addChild(TagByte.new("features"))
        defaultFlatSettings:addChild(TagByte.new("lakes"))

        dimensions.overworld.generator:addChild(defaultFlatSettings)

        OUT.Data.WorldGenSettings.generate_features.value = 0;

    elseif(not needsFlatSettings) then
        --add default overworld settings
        dimensions.overworld.generator:addChild(TagString.new("settings", "minecraft:overworld"))
        dimensions.overworld.generator.seed = dimensions.overworld.generator:addChild(TagLong.new("seed", OUT.Data.WorldGenSettings.seed.value))
        dimensions.overworld.generator.biome_source = dimensions.overworld.generator:addChild(TagCompound.new("biome_source"))
        dimensions.overworld.generator.biome_source.seed = dimensions.overworld.generator.biome_source:addChild(TagLong.new("seed", OUT.Data.WorldGenSettings.seed.value))
        dimensions.overworld.generator.biome_source:addChild(TagByte.new("large_biomes", 0))
        dimensions.overworld.generator.biome_source:addChild(TagString.new("type", "minecraft:vanilla_layered"))
    end
    
    return OUT
end

function ConvertGeneratorOptions(IN)
    local OUT = TagCompound.new("settings")

    local jsonRoot = JSONValue.new()
    if(jsonRoot:parse(IN).type == JSON_TYPE.OBJECT) then
        OUT.layers = OUT:addChild(TagList.new("layers"))
        OUT.biome = OUT:addChild(TagString.new("biome", "minecraft:plains"))
        OUT.structures = OUT:addChild(TagCompound.new("structures"))
        OUT.structures.stronghold = OUT.structures:addChild(TagCompound.new("stronghold"))
        OUT.structures.stronghold:addChild(TagInt.new("count", 128))
        OUT.structures.stronghold:addChild(TagInt.new("distance", 32))
        OUT.structures.stronghold:addChild(TagInt.new("spread", 3))
        OUT.structures.structures = OUT.structures:addChild(TagCompound.new("structures"))
        OUT.structures.structures.minecraft_village = OUT.structures.structures:addChild(TagCompound.new("minecraft:village"))
        OUT.structures.structures.minecraft_village:addChild(TagInt.new("salt", 10387312))
        OUT.structures.structures.minecraft_village:addChild(TagInt.new("separation", 8))
        OUT.structures.structures.minecraft_village:addChild(TagInt.new("spacing", 32))
        OUT:addChild(TagByte.new("features"))
        OUT:addChild(TagByte.new("lakes"))

        if(jsonRoot:contains("encoding_version", JSON_TYPE.DOUBLE)) then
            local encoding_version = jsonRoot.lastFound:getDouble()
            if(encoding_version == 3 or encoding_version == 4) then
                if(jsonRoot:contains("biome_name", JSON_TYPE.STRING)) then
                    local biomeName = jsonRoot.lastFound:getString()
                    if(biomeName:find("^minecraft:")) then biomeName = biomeName:sub(11) end
                    OUT.biome.value = "minecraft:" .. biomeName
                elseif(jsonRoot:contains("biome_id", JSON_TYPE.DOUBLE)) then
                    local biomeId = jsonRoot.lastFound:getDouble()
                    if(Settings:dataTableContains("biomes_ids", tostring(biomeId))) then
                        local entry = Settings.lastFound
                        local subEntry = entry[1]
                        OUT.biome.value = "minecraft:" .. subEntry[2]
                    end
                end

                if(jsonRoot:contains("block_layers", JSON_TYPE.ARRAY)) then
                    local block_layers = jsonRoot.lastFound

                    for i=0, block_layers.childCount-1 do
                        local layerIn = block_layers:child(i)

                        local layer = TagCompound.new()
                        layer.height = layer:addChild(TagInt.new("height", 0))
                        layer.block = layer:addChild(TagString.new("block", "minecraft:air"))

                        if(layerIn:contains("count", JSON_TYPE.DOUBLE)) then
                            layer.height.value = layerIn.lastFound:getDouble()
                        end

                        local block_data = 0
                        if(layerIn:contains("block_data", JSON_TYPE.DOUBLE)) then block_data = layerIn.lastFound:getDouble() end

                        if(encoding_version == 3) then

                            if(layerIn:contains("block_id", JSON_TYPE.DOUBLE)) then
                                local layerBlock = Utils:findBlock(layerIn.lastFound:getDouble(), block_data)
                                if(layerBlock ~= nil and layerBlock.id ~= nil) then layer.block.value = "minecraft:" .. layerBlock.id end
                            end

                        elseif(encoding_version == 4) then
                            if(layerIn:contains("block_name", JSON_TYPE.STRING)) then

                                local layerBlock = Utils:findBlock(layerIn.lastFound:getString(), block_data, -1)
                                if(layerBlock ~= nil and layerBlock.id ~= nil) then layer.block.value = "minecraft:" .. layerBlock.id end
                            end
                        end

                        OUT.layers:addChild(layer)
                    end
                end
                return OUT
            end
        end
    end

    return nil
end
