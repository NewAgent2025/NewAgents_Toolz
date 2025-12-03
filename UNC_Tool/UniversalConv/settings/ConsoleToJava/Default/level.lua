function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end
    
--level.dat START
function ConvertLevel(IN)
    local OUT = TagCompound.new()
    
    OUT.Data = OUT:addChild(TagCompound.new("Data"))

    OUT.Data:addChild(TagInt.new("DataVersion", 1631))

    OUT.Data:addChild(TagByte.new("allowCommands", true))
    OUT.Data:addChild(TagByte.new("hardcore", false))
    OUT.Data:addChild(TagByte.new("initialized", true))
    OUT.Data:addChild(TagInt.new("version", 19133))
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

    OUT.Data.Difficulty = OUT.Data:addChild(TagByte.new("Difficulty", 2))
    OUT.Data.DifficultyLocked = OUT.Data:addChild(TagByte.new("DifficultyLocked", false))
    OUT.Data.MapFeatures = OUT.Data:addChild(TagByte.new("MapFeatures", true))
    OUT.Data.raining = OUT.Data:addChild(TagByte.new("raining", false))
    OUT.Data.thundering = OUT.Data:addChild(TagByte.new("thundering", false))
    OUT.Data.clearWeatherTime = OUT.Data:addChild(TagInt.new("clearWeatherTime", 0))
    OUT.Data.GameType = OUT.Data:addChild(TagInt.new("GameType", 1))
    OUT.Data.generatorVersion = OUT.Data:addChild(TagInt.new("generatorVersion", 1))
    OUT.Data.rainTime = OUT.Data:addChild(TagInt.new("rainTime", 32000))
    OUT.Data.SpawnX = OUT.Data:addChild(TagInt.new("SpawnX", 0))
    OUT.Data.SpawnY = OUT.Data:addChild(TagInt.new("SpawnY", 63))
    OUT.Data.SpawnZ = OUT.Data:addChild(TagInt.new("SpawnZ", 0))
    OUT.Data.thunderTime = OUT.Data:addChild(TagInt.new("thunderTime", 65000))
    OUT.Data.DayTime = OUT.Data:addChild(TagLong.new("DayTime", 3000))
    OUT.Data.RandomSeed = OUT.Data:addChild(TagLong.new("RandomSeed", 0))
    OUT.Data.Time = OUT.Data:addChild(TagLong.new("Time", 3000))
    OUT.Data.generatorName = OUT.Data:addChild(TagString.new("generatorName", "default"))

    OUT.Data.DataPacks = OUT.Data:addChild(TagCompound.new("DataPacks"))
    OUT.Data.DataPacks:addChild(TagList.new("Disabled"))
    OUT.Data.DataPacks.Enabled = OUT.Data.DataPacks:addChild(TagList.new("Enabled"))
    OUT.Data.DataPacks.Enabled:addChild(TagString.new("", "vanilla"))

    OUT.Data.Version = OUT.Data:addChild(TagCompound.new("Version"))
    OUT.Data.Version:addChild(TagByte.new("Snapshot", 0))
    OUT.Data.Version:addChild(TagInt.new("Id", 1631))
    OUT.Data.Version:addChild(TagString.new("Name", "1.13.2"))

    OUT.Data.GameRules = OUT.Data:addChild(TagCompound.new("GameRules"))
    OUT.Data.GameRules:addChild(TagString.new("announceAdvancements", "true"))
    OUT.Data.GameRules:addChild(TagString.new("commandBlockOutput", "true"))
    OUT.Data.GameRules:addChild(TagString.new("disableElytraMovementCheck", "false"))
    OUT.Data.GameRules:addChild(TagString.new("doDaylightCycle", "true"))
    OUT.Data.GameRules:addChild(TagString.new("doEntityDrops", "true"))
    OUT.Data.GameRules:addChild(TagString.new("doFireTick", "true"))
    OUT.Data.GameRules:addChild(TagString.new("doLimitedCrafting", "false"))
    OUT.Data.GameRules:addChild(TagString.new("doMobLoot", "true"))
    OUT.Data.GameRules:addChild(TagString.new("doMobSpawning", "true"))
    OUT.Data.GameRules:addChild(TagString.new("doTileDrops", "true"))
    OUT.Data.GameRules:addChild(TagString.new("doWeatherCycle", "true"))
    OUT.Data.GameRules:addChild(TagString.new("keepInventory", "false"))
    OUT.Data.GameRules:addChild(TagString.new("logAdminCommands", "true"))
    OUT.Data.GameRules:addChild(TagString.new("maxCommandChainLength", "65536"))
    OUT.Data.GameRules:addChild(TagString.new("maxEntityCramming", "24"))
    OUT.Data.GameRules:addChild(TagString.new("mobGriefing", "true"))
    OUT.Data.GameRules:addChild(TagString.new("naturalRegeneration", "true"))
    OUT.Data.GameRules:addChild(TagString.new("randomTickSpeed", "3"))
    OUT.Data.GameRules:addChild(TagString.new("reducedDebugInfo", "false"))
    OUT.Data.GameRules:addChild(TagString.new("sendCommandFeedback", "true"))
    OUT.Data.GameRules:addChild(TagString.new("showDeathMessages", "true"))
    OUT.Data.GameRules:addChild(TagString.new("spawnRadius", "10"))
    OUT.Data.GameRules:addChild(TagString.new("spectatorsGenerateChunks", "true"))

    local hasDimData = false

    --iterate through the input level.dat
    if(IN:contains("Data", TYPE.COMPOUND)) then
        IN.Data = IN.lastFound
        
        for i=0, IN.Data.childCount-1 do
            local in_child = IN.Data:child(i)
            local in_child_name = in_child.name
            local in_child_type = in_child.type

            --apply changes to matching tags
            if(in_child_type == TYPE.BYTE)then
                if(in_child_name == "Difficulty") then OUT.Data.Difficulty.value = in_child.value
                elseif(in_child_name == "DifficultyLocked") then OUT.Data.DifficultyLocked.value = in_child.value
                elseif(in_child_name == "MapFeatures") then OUT.Data.MapFeatures.value = in_child.value
                elseif(in_child_name == "raining") then OUT.Data.raining.value = in_child.value
                elseif(in_child_name == "thundering") then OUT.Data.thundering.value = in_child.value
                end
            elseif(in_child_type == TYPE.INT)then
                if(in_child_name == "clearWeatherTime")then OUT.Data.clearWeatherTime.value = in_child.value
                elseif(in_child_name == "GameType")then OUT.Data.GameType.value = in_child.value
                elseif(in_child_name == "generatorVersion")then OUT.Data.generatorVersion.value = in_child.value
                elseif(in_child_name == "rainTime")then OUT.Data.rainTime.value = in_child.value
                elseif(in_child_name == "SpawnX")then OUT.Data.SpawnX.value = in_child.value
                elseif(in_child_name == "SpawnY")then OUT.Data.SpawnY.value = in_child.value
                elseif(in_child_name == "SpawnZ")then OUT.Data.SpawnZ.value = in_child.value
                elseif(in_child_name == "thunderTime")then OUT.Data.thunderTime.value = in_child.value
                end
            elseif(in_child_type == TYPE.LONG)then
                if(in_child_name == "DayTime") then OUT.Data.DayTime.value = in_child.value
                elseif(in_child_name == "RandomSeed") then OUT.Data.RandomSeed.value = in_child.value
                elseif(in_child_name == "Time") then OUT.Data.Time.value = in_child.value
                end
            elseif(in_child_type == TYPE.STRING)then
                if(in_child_name == "generatorName")then
                    OUT.Data.generatorName.value = in_child.value
                    if(in_child.value == "flat") then
                        if(IN.Data:contains("generatorOptions", TYPE.BYTE_ARRAY)) then
                            local genOptions_in = IN.Data.lastFound
                            local genOptions_out = ConvertGeneratorOptions(genOptions_in)
                            if(genOptions_out ~= nil) then OUT.Data:addChild(genOptions_out) end
                        end
                    end
                end
            elseif(in_child_type == TYPE.COMPOUND)then
                if(in_child_name == "DimensionData")then
                    hasDimData = true
                    OUT.Data.DimensionData = OUT.Data:addChild(in_child:clone())

                    if(OUT.Data.DimensionData:contains("The End", TYPE.COMPOUND))then OUT.Data.DimensionData.lastFound.name = "1"
                    elseif(OUT.Data.DimensionData:contains("Overworld", TYPE.COMPOUND))then OUT.Data.DimensionData.lastFound.name = "0"
                    elseif(OUT.Data.DimensionData:contains("Nether", TYPE.COMPOUND))then OUT.Data.DimensionData.lastFound.name = "-1"
                    end
                end
            end
        end
    end

    if(hasDimData == false)then
        OUT.Data:addChild(TagCompound.new("DimensionData"))
    end
    
    return OUT
end


function ConvertGeneratorOptions(IN)
    local OUT = TagCompound.new("generatorOptions")
    OUT.layers = OUT:addChild(TagList.new("layers"))
    OUT.biome = OUT:addChild(TagString.new("biome", "minecraft:plains"))

    local c = 0
    local size = IN:getSize()

    --Unknown if the first byte is a version number.... or something else
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

            local layer = TagCompound.new()
            layer:addChild(TagByte.new("height", layerHeight))
            layer.block = layer:addChild(TagString.new("block", "minecraft:air"))

            if(Settings:dataTableContains("blocks_ids", tostring(layerBlockID)) and layerBlockID ~= 0) then
                local entry = Settings.lastFound

                --TODO Compare version 12 with generatorOptions version for correctness
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > 12) then goto entryContinue end end
                    if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= layerBlockData) then goto entryContinue end end
                    layer.block.value = "minecraft:" .. subEntry[3]
                    ::entryContinue::
                    break
                end
            end

            OUT.layers:addChild(layer)
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
                    OUT.biome.value = "minecraft:" .. subEntry[2]
                end
            end
        end
    else return nil end

    return OUT
end

--level.dat STOP