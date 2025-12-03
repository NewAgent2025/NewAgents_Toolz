TileEntity = {}
Entity = Entity or require("entity")
Item = Item or require("item")

function TileEntity:ConvertTileEntity(IN)
    local OUT = TagCompound.new()

    --if id and coords exist, then it's normal
    --if id and coords don't exist and UMC_QueuedTileEntity exists, then it's queued
    --if it's both, assume it's normal and then implementation can read the queue if needed
    --only caveat is an invalid normal tile entity will not revert to a queued one

    --NORMAL
    if(IN:contains("id", TYPE.STRING) and IN:contains("x", TYPE.INT) and IN:contains("y", TYPE.INT) and IN:contains("z", TYPE.INT)) then
        --Grab id and remove 'minecraft:' if found
        local id = ""
        if(IN:contains("id", TYPE.STRING)) then
            id = IN.lastFound.value
            if(id:find("^minecraft:")) then id = id:sub(11) end
        else return nil end

        --Coordinates
        OUT.x = OUT:addChild(TagInt.new("x"))
        OUT.y = OUT:addChild(TagInt.new("y"))
        OUT.z = OUT:addChild(TagInt.new("z"))
        if(IN:contains("x", TYPE.INT)) then OUT.x.value = IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16) else return nil end
        if(IN:contains("y", TYPE.INT)) then OUT.y.value = IN.lastFound.value else return nil end
        if(IN:contains("z", TYPE.INT)) then OUT.z.value = IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16) else return nil end

        local blockX = OUT.x.value
        local blockY = OUT.y.value
        local blockZ = OUT.z.value

        IN.curBlock = Chunk:getBlock(blockX, blockY, blockZ)
        IN.curBlock.save = false

        if(Settings:dataTableContains("tileEntities", id)) then
            local entry = Settings.lastFound
            OUT:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            OUT = TileEntity[entry[1][2]](TileEntity, IN, OUT, true)
        else return nil end

        if(IN.curBlock.save) then Chunk:setBlock(blockX, blockY, blockZ, IN.curBlock) end

    --QUEUE
    elseif(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        --Coordinates
        OUT.x = OUT:addChild(TagInt.new("x"))
        OUT.y = OUT:addChild(TagInt.new("y"))
        OUT.z = OUT:addChild(TagInt.new("z"))
        if(IN.QueuedTE:contains("x", TYPE.INT)) then OUT.x.value = IN.QueuedTE.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16) else return nil end
        if(IN.QueuedTE:contains("y", TYPE.INT)) then OUT.y.value = IN.QueuedTE.lastFound.value else return nil end
        if(IN.QueuedTE:contains("z", TYPE.INT)) then OUT.z.value = IN.QueuedTE.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16) else return nil end

        local blockX = OUT.x.value
        local blockY = OUT.y.value
        local blockZ = OUT.z.value

        IN.curBlock = Chunk:getBlock(blockX, blockY, blockZ)
        IN.curBlock.save = false

        local id = ""

        --Identify queue type
        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_ids") then

                if(IN.QueuedTE:contains("id", TYPE.SHORT)) then
                    local blockId = IN.QueuedTE.lastFound.value

                    --Convert
                    if(blockId == 26) then id = "bed"
                    elseif(blockId == 118) then id = "queued_cauldron"
                    else return nil end

                else return nil end

            elseif(IN.QueuedTE.lastFound.value == "blocks_states") then
                if(IN.QueuedTE:contains("paletteEntry", TYPE.COMPOUND)) then
                    IN.QueuedTE.paletteEntry = IN.QueuedTE.lastFound
                    if(IN.QueuedTE.paletteEntry:contains("Name", TYPE.STRING)) then
                        local blockName = IN.QueuedTE.paletteEntry.lastFound.value
                        if(blockName:find("^minecraft:")) then blockName = blockName:sub(11) end

                        --Convert
                        if(blockName == "cauldron") then id = "queued_cauldron"
                        elseif(blockName:find("^potted_")) then id = "flower_pot"
                        elseif(blockName == "note_block") then id = "noteblock"
                        else return nil end

                    else return nil end
                else return nil end
                
            else return nil end
        else return nil end

        if(id == "") then return nil end

        if(Settings:dataTableContains("tileEntities", id)) then
            local entry = Settings.lastFound
            OUT:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            OUT = TileEntity[entry[1][2]](TileEntity, IN, OUT, true)
        else return nil end

        if(IN.curBlock.save) then Chunk:setBlock(blockX, blockY, blockZ, IN.curBlock) end

    end

return OUT
end

function TileEntity:ConvertBanner(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 176 and IN.curBlock.lastFound.value ~= 177) then return nil end end

    TileEntity:CustomName(IN, OUT, required)

    --check for queued tile entity and turn into Base

    local queueUsed = false

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_states") then
                if(IN.QueuedTE:contains("paletteEntry", TYPE.COMPOUND)) then
                    IN.QueuedTE.paletteEntry = IN.QueuedTE.lastFound

                    if(IN.QueuedTE.paletteEntry:contains("Name", TYPE.STRING)) then
                        local bannerName = IN.QueuedTE.paletteEntry.lastFound.value

                        queueUsed = true

                        OUT.Base = OUT:addChild(TagInt.new("Base"))

                        if(bannerName == "minecraft:white_banner" or bannerName == "minecraft:white_wall_banner") then OUT.Base.value = 15
                        elseif(bannerName == "minecraft:orange_banner" or bannerName == "minecraft:orange_wall_banner") then OUT.Base.value = 14
                        elseif(bannerName == "minecraft:magenta_banner" or bannerName == "minecraft:magenta_wall_banner") then OUT.Base.value = 13
                        elseif(bannerName == "minecraft:light_blue_banner" or bannerName == "minecraft:light_blue_wall_banner") then OUT.Base.value = 12
                        elseif(bannerName == "minecraft:yellow_banner" or bannerName == "minecraft:yellow_wall_banner") then OUT.Base.value = 11
                        elseif(bannerName == "minecraft:lime_banner" or bannerName == "minecraft:lime_wall_banner") then OUT.Base.value = 10
                        elseif(bannerName == "minecraft:pink_banner" or bannerName == "minecraft:pink_wall_banner") then OUT.Base.value = 9
                        elseif(bannerName == "minecraft:gray_banner" or bannerName == "minecraft:gray_wall_banner") then OUT.Base.value = 8
                        elseif(bannerName == "minecraft:light_gray_banner" or bannerName == "minecraft:light_gray_wall_banner") then OUT.Base.value = 7
                        elseif(bannerName == "minecraft:cyan_banner" or bannerName == "minecraft:cyan_wall_banner") then OUT.Base.value = 6
                        elseif(bannerName == "minecraft:purple_banner" or bannerName == "minecraft:purple_wall_banner") then OUT.Base.value = 5
                        elseif(bannerName == "minecraft:blue_banner" or bannerName == "minecraft:blue_wall_banner") then OUT.Base.value = 4
                        elseif(bannerName == "minecraft:brown_banner" or bannerName == "minecraft:brown_wall_banner") then OUT.Base.value = 3
                        elseif(bannerName == "minecraft:green_banner" or bannerName == "minecraft:green_wall_banner") then OUT.Base.value = 2
                        elseif(bannerName == "minecraft:red_banner" or bannerName == "minecraft:red_wall_banner") then OUT.Base.value = 1
                        elseif(bannerName == "minecraft:black_banner" or bannerName == "minecraft:black_wall_banner") then OUT.Base.value = 0
                        end
                    end
                end
            end
        end
    end
    
    if(queueUsed == false and IN:contains("Base", TYPE.INT)) then
        OUT.Base = OUT:addChild(TagInt.new("Base"))
        if(IN.lastFound.value <= 15) then OUT.Base.value = IN.lastFound.value end
    elseif(queueUsed == false and required) then 
        OUT:addChild(TagInt.new("Base"))
    end

    local DataVersion = Settings:getSettingInt("DataVersion")

    if(IN:contains("Patterns", TYPE.LIST)) then
        IN.Patterns = IN.lastFound
        if(IN.Patterns.childCount ~= 0) then
            OUT.Patterns = OUT:addChild(TagList.new("Patterns"))

            for i=0, IN.Patterns.childCount-1 do
                local in_Pattern = IN.Patterns:child(i)
                if(in_Pattern.type ~= TYPE.COMPOUND) then break end

                if(in_Pattern:contains("Color", TYPE.INT)) then in_Pattern.Color = in_Pattern.lastFound else goto patternContinue end
                if(in_Pattern:contains("Pattern", TYPE.STRING)) then in_Pattern.Pattern = in_Pattern.lastFound else goto patternContinue end

                local out_Pattern = OUT.Patterns:addChild(TagCompound.new())
                out_Pattern:addChild(TagString.new("Pattern", in_Pattern.Pattern.value))

                if(in_Pattern.Color.value > 15) then in_Pattern.Color.value = 0 end

                if(DataVersion > 1451) then
                    out_Pattern:addChild(TagInt.new("Color", 15 - in_Pattern.Color.value))
                else
                    out_Pattern:addChild(TagInt.new("Color", in_Pattern.Color.value))
                end

                ::patternContinue::
            end

            if(OUT.Patterns.childCount == 0) then
                OUT:removeChild(OUT.Patterns:getRow())
                OUT.Patterns = nil
            end
        end
    end

    return OUT
end

function TileEntity:ConvertBeacon(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 138) then return nil end end

    if(IN:contains("Levels", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Levels", 0)) end
    if(IN:contains("Primary", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Primary", 0)) end
    if(IN:contains("Secondary", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Secondary", 0)) end
    return OUT
end

function TileEntity:ConvertBed(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 26) then return nil end end

    --check for queued tile entity and turn into color

    local queueUsed = false

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_states") then
                if(IN.QueuedTE:contains("paletteEntry", TYPE.COMPOUND)) then
                    IN.QueuedTE.paletteEntry = IN.QueuedTE.lastFound

                    if(IN.QueuedTE.paletteEntry:contains("Name", TYPE.STRING)) then
                        local bedName = IN.QueuedTE.paletteEntry.lastFound.value

                        queueUsed = true

                        OUT.color = OUT:addChild(TagInt.new("color", 14))

                        if(bedName == "minecraft:white_bed") then OUT.color.value = 0
                        elseif(bedName == "minecraft:orange_bed") then OUT.color.value = 1
                        elseif(bedName == "minecraft:magenta_bed") then OUT.color.value = 2
                        elseif(bedName == "minecraft:light_blue_bed") then OUT.color.value = 3
                        elseif(bedName == "minecraft:yellow_bed") then OUT.color.value = 4
                        elseif(bedName == "minecraft:lime_bed") then OUT.color.value = 5
                        elseif(bedName == "minecraft:pink_bed") then OUT.color.value = 6
                        elseif(bedName == "minecraft:gray_bed") then OUT.color.value = 7
                        elseif(bedName == "minecraft:light_gray_bed") then OUT.color.value = 8
                        elseif(bedName == "minecraft:cyan_bed") then OUT.color.value = 9
                        elseif(bedName == "minecraft:purple_bed") then OUT.color.value = 10
                        elseif(bedName == "minecraft:blue_bed") then OUT.color.value = 11
                        elseif(bedName == "minecraft:brown_bed") then OUT.color.value = 12
                        elseif(bedName == "minecraft:green_bed") then OUT.color.value = 13
                        elseif(bedName == "minecraft:red_bed") then OUT.color.value = 14
                        elseif(bedName == "minecraft:black_bed") then OUT.color.value = 15
                        end
                    end
                end
            end
        end
    end
    
    if(queueUsed == false and IN:contains("color", TYPE.INT)) then
        OUT.color = OUT:addChild(TagInt.new("color", 14))
        if(IN.lastFound.value <= 15) then OUT.color.value = IN.lastFound.value end
    elseif(queueUsed == false and required) then 
        OUT:addChild(TagInt.new("color", 14))
    end

    return OUT
end

function TileEntity:ConvertBrewingStand(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 117) then return nil end end

    TileEntity:CustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("Fuel", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("Fuel", false)) end
    if(IN:contains("BrewTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BrewTime", 0)) end
    return OUT
end

function TileEntity:ConvertCauldron(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 118) then return nil end end

    TileEntity:ConvertItems(IN, OUT, required, true)
    if(required) then OUT:addChild(TagShort.new("PotionType")) end
    if(required) then OUT:addChild(TagString.new("PotionId")) end
    return OUT
end

function TileEntity:ConvertChest(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 54 and IN.curBlock.lastFound.value ~= 146) then return nil end end

    TileEntity:CustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, false)

    if(required) then
        OUT:addChild(TagByte.new("bonus"))
        OUT:addChild(TagByte.new("CScreatedOnHost", true))
        OUT:addChild(TagByte.new("CSnamedByRestricted", false))
        OUT:addChild(TagString.new("CSownerUUID"))
    end

    if(IN:contains("LootTableSeed", TYPE.LONG)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("LootTable", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    return OUT
end

function TileEntity:ConvertComparator(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 149 and IN.curBlock.lastFound.value ~= 150) then return nil end end

    if(IN:contains("OutputSignal", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("OutputSignal", 0)) end
    return OUT
end

function TileEntity:ConvertConduit(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 256) then return nil end end

    if(required) then
        OUT:addChild(TagByte.new("Active", 0))
        OUT:addChild(TagInt.new("Target", -1))
        --TODO identify use of target and add Rotation
    end
    return OUT
end

function TileEntity:ConvertDaylightDetector(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 151 and IN.curBlock.lastFound.value ~= 178) then return nil end end

    return OUT
end

function TileEntity:ConvertDispenser(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 23) then return nil end end

    TileEntity:CustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertDropper(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 158) then return nil end end

    TileEntity:CustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertEnchantmentTable(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 116) then return nil end end

    TileEntity:CustomName(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertEnderChest(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 130) then return nil end end

    return OUT
end

function TileEntity:ConvertEndGateway(IN, OUT, required)

    if(IN:contains("Age", TYPE.LONG)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagLong.new("Age", 0)) end
    if(IN:contains("ExactTeleport", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("ExactTeleport", false)) end

    containsExitPortal = false
    if(IN:contains("ExitPortal", TYPE.COMPOUND)) then
        IN.ExitPortal = IN.lastFound
        if(IN.ExitPortal:contains("X", TYPE.INT) and IN.ExitPortal:contains("Y", TYPE.INT) and IN.ExitPortal:contains("Z", TYPE.INT)) then
            containsExitPortal = true
            OUT.ExitPortal = OUT:addChild(TagCompound.new("ExitPortal"))
            if(IN.ExitPortal:contains("X", TYPE.INT)) then OUT.ExitPortal:addChild(TagInt.new("X", IN.ExitPortal.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) end
            if(IN.ExitPortal:contains("Y", TYPE.INT)) then OUT.ExitPortal:addChild(TagInt.new("Y", IN.ExitPortal.lastFound.value)) end
            if(IN.ExitPortal:contains("Z", TYPE.INT)) then OUT.ExitPortal:addChild(TagInt.new("Z", IN.ExitPortal.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) end
        end
    end

    if((not containsExitPortal) and required) then
        OUT.ExitPortal = OUT:addChild(TagCompound.new("ExitPortal"))
        OUT.ExitPortal:addChild(TagInt.new("X", OUT.x.value))
        OUT.ExitPortal:addChild(TagInt.new("Y", OUT.y.value))
        OUT.ExitPortal:addChild(TagInt.new("Z", OUT.z.value))
    end


    return OUT
end

function TileEntity:ConvertEndPortal(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 119) then return nil end end

    return OUT
end

function TileEntity:ConvertFlowerPot(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 140) then return nil end end

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound
        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_states") then
                if(IN.QueuedTE:contains("paletteEntry", TYPE.COMPOUND)) then
                    IN.QueuedTE.paletteEntry = IN.QueuedTE.lastFound

                    if(IN.QueuedTE.paletteEntry:contains("Name", TYPE.STRING)) then
                        local flowerPotName = IN.QueuedTE.paletteEntry.lastFound.value
                        if(flowerPotName:find("^minecraft:")) then flowerPotName = flowerPotName:sub(11) end
                        if(flowerPotName:find("^potted_")) then flowerPotName = flowerPotName:sub(8) end

                        if(Settings:dataTableContains("blocks_states", flowerPotName) and flowerPotName ~= "air") then
                            local entry = Settings.lastFound
                            local DataVersion = Settings:getSettingInt("DataVersion")
                            for index, _ in ipairs(entry) do
                                local subEntry = entry[index]
                                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                                --if(subEntry[2]:len() > 0 and flowerStatesGoesHere ~= nil) then if(~Item:CompareProperties(subEntry[2], flowerStatesGoesHere)) then goto entryContinue end end
                                OUT.Item = OUT:addChild(TagInt.new("Item", tonumber(subEntry[3])))
                                if(subEntry[4]:len() > 0) then OUT.Data = OUT:addChild(TagInt.new("Data", tonumber(subEntry[4]))) end
                                break
                                ::entryContinue::
                            end
                        end
                    end
                end
            elseif(IN.QueuedTE.lastFound.value == "blocks_ids") then
                IN.Data = 0
                if(IN:contains("Data", TYPE.INT)) then IN.Data = IN.lastFound.value end

                if(IN:contains("Item", TYPE.STRING)) then
                    local flowerName = IN.lastFound.value
                    if(flowerName:find("^minecraft:")) then flowerName = flowerName:sub(11) end
                    if(Settings:dataTableContains("blocks_names", flowerName) and flowerName ~= "air") then
                        local entry = Settings.lastFound
                        local DataVersion = Settings:getSettingInt("DataVersion")
                        for index, _ in ipairs(entry) do
                            local subEntry = entry[index]
                            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                            if(subEntry[2]:len() > 0) then if(subEntry[2] ~= IN.Data) then goto entryContinue end end
                            OUT.Item = OUT:addChild(TagInt.new("Item", tonumber(subEntry[3])))
                            if(subEntry[4]:len() > 0) then OUT.Data = OUT:addChild(TagInt.new("Data", tonumber(subEntry[4]))) end
                            break
                            ::entryContinue::
                        end
                    end
                elseif(IN:contains("Item", TYPE.INT)) then
                    IN.Item = IN.lastFound.value
                    OUT.Item = OUT:addChild(TagInt.new("Item", IN.Item))
                    OUT.Data = OUT:addChild(TagInt.new("Data", IN.Data))
                    if(Settings:dataTableContains("blocks_ids", tostring(IN.Item)) and IN.Item ~= 0) then
                        local entry = Settings.lastFound
                        local DataVersion = Settings:getSettingInt("DataVersion")
                        for index, _ in ipairs(entry) do
                            local subEntry = entry[index]
                            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                            if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.Data) then goto entryContinue end end
                            OUT.Item.value = tonumber(subEntry[3])
                            if(subEntry[4]:len() > 0) then OUT.Data.value = tonumber(subEntry[4]) end
                            break
                            ::entryContinue::
                        end
                    end
                else
                    if(IN.QueuedTE:contains("damage", TYPE.BYTE)) then
                        local potDamage = IN.QueuedTE.lastFound.value
                        IN.Item = 0

                        if(potDamage == 1) then
                            IN.Item = 38
                        elseif(potDamage == 2) then
                            IN.Item = 37
                        elseif(potDamage == 3) then
                            IN.Item = 6
                        elseif(potDamage == 4) then
                            IN.Item = 6
                            IN.Data = 1
                        elseif(potDamage == 5) then
                            IN.Item = 6
                            IN.Data = 2
                        elseif(potDamage == 6) then
                            IN.Item = 6
                            IN.Data = 3
                        elseif(potDamage == 7) then
                            IN.Item = 40
                        elseif(potDamage == 8) then
                            IN.Item = 39
                        elseif(potDamage == 9) then
                            IN.Item = 81
                        elseif(potDamage == 10) then
                            IN.Item = 32
                        elseif(potDamage == 11) then
                            IN.Item = 31
                            IN.Data = 2
                        end

                        OUT.Item = OUT:addChild(TagInt.new("Item", IN.Item))
                        OUT.Data = OUT:addChild(TagInt.new("Data", IN.Data))

                        if(Settings:dataTableContains("blocks_ids", tostring(IN.Item)) and IN.Item ~= 0) then
                            local entry = Settings.lastFound
                            local DataVersion = Settings:getSettingInt("DataVersion")
                            for index, _ in ipairs(entry) do
                                local subEntry = entry[index]
                                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                                if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.Data) then goto entryContinue end end
                                OUT.Item.value = tonumber(subEntry[3])
                                if(subEntry[4]:len() > 0) then OUT.Data.value = tonumber(subEntry[4]) end
                                break
                                ::entryContinue::
                            end
                        end
                    end
                end
            end
        end
    end

    if(OUT.Item == nil and required) then OUT:addChild(TagInt.new("Item")) end
    if(OUT.Data == nil and required) then OUT:addChild(TagInt.new("Data")) end

    return OUT
end

function TileEntity:ConvertFurnace(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 61 and IN.curBlock.lastFound.value ~= 62) then return nil end end

    TileEntity:CustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end
    if(IN:contains("CookTimeTotal", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTimeTotal")) end

    if(required) then 
        OUT.CharcoalUsed = OUT:addChild(TagByte.new("CharcoalUsed"))
        --TODO convert RecipesUsedSize into CharcoalUsed if you can
    end
    return OUT
end

function TileEntity:ConvertHopper(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 154) then return nil end end

    TileEntity:CustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("TransferCooldown", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("TransferCooldown", 0)) end
    return OUT
end

function TileEntity:ConvertJukebox(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 84) then return nil end end

    if(IN:contains("RecordItem", TYPE.COMPOUND)) then
        IN.RecordItem = IN.lastFound
        local item = Item:ConvertItem(IN.RecordItem, false)
        if(item ~= nil) then
            item.name = "RecordItem"
            OUT:addChild(item)
        end
    end
    return OUT
end

function TileEntity:ConvertMobSpawner(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 52) then return nil end end

    if(IN:contains("SpawnCount", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("SpawnCount", 4)) end
    if(IN:contains("SpawnRange", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("SpawnRange", 4)) end
    if(IN:contains("Delay", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Delay", 0)) end
    if(IN:contains("MinSpawnDelay", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("MinSpawnDelay", 200)) end
    if(IN:contains("MaxSpawnDelay", TYPE.SHORT)) then if(IN.lastFound.value > 0) then OUT:addChild(IN.lastFound:clone()) else OUT:addChild(TagShort.new("MaxSpawnDelay", 800)) end elseif(required) then OUT:addChild(TagShort.new("MaxSpawnDelay", 800)) end
    if(IN:contains("MaxNearbyEntities", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("MaxNearbyEntities", 6)) end
    if(IN:contains("RequiredPlayerRange", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("RequiredPlayerRange", 16)) end

    if(IN:contains("SpawnData", TYPE.COMPOUND)) then
        local SpawnData = IN.lastFound
        if(IN:contains("EntityId", TYPE.STRING)) then
            if(not SpawnData:contains("id", TYPE.STRING)) then SpawnData:addChild(TagString.new("id", IN.lastFound.value)) end
        end

        local SpawnData = Entity:ConvertEntity(SpawnData, false)
        if(SpawnData ~= nil) then
            if(SpawnData.Spawnable) then
                SpawnData.name = "SpawnData"
                OUT.SpawnData = OUT:addChild(SpawnData)
            end
        end
    end

    if(IN:contains("SpawnPotentials", TYPE.LIST, TYPE.COMPOUND)) then
        IN.SpawnPotentials = IN.lastFound
        OUT.SpawnPotentials = OUT:addChild(TagList.new("SpawnPotentials"))
        if(OUT.SpawnData == nil) then OUT:addChild(TagCompound.new("SpawnData")) end
        for i=0, IN.SpawnPotentials.childCount-1 do
            local spawnPotential_in = IN.SpawnPotentials:child(i)
            local spawnPotential_out = TagCompound.new()
            if(spawnPotential_in:contains("Weight", TYPE.INT)) then spawnPotential_out:addChild(spawnPotential_in.lastFound:clone()) elseif(required) then spawnPotential_out:addChild(TagInt.new("Weight", 1)) end
            
            if(spawnPotential_in:contains("Entity", TYPE.COMPOUND)) then
                local Entity_out = Entity:ConvertEntity(spawnPotential_in.lastFound, false)
                if(Entity_out ~= nil) then
                    if(Entity_out.Spawnable == false) then goto spawnPotentialContinue end

                    Entity_out.name = "Entity"
                    spawnPotential_out:addChild(Entity_out)
                else goto spawnPotentialContinue end
            elseif(spawnPotential_in:contains("Properties", TYPE.COMPOUND) and spawnPotential_in:contains("Type", TYPE.STRING)) then
                --Legacy
                if(spawnPotential_in:contains("Properties", TYPE.COMPOUND)) then
                    spawnPotential_in.Properties = spawnPotential_in.lastFound
                    if(spawnPotential_in:contains("Type", TYPE.STRING)) then
                        spawnPotential_in.Properties:addChild(TagString.new("id", spawnPotential_in.lastFound.value))
                        local Entity_out = Entity:ConvertEntity(spawnPotential_in.Properties, false)
                        if(Entity_out ~= nil) then
                            Entity_out.name = "Entity"
                            spawnPotential_out:addChild(Entity_out)
                        else goto spawnPotentialContinue end
                    end
                end
            else goto spawnPotentialContinue end
            OUT.SpawnPotentials:addChild(spawnPotential_out)
            ::spawnPotentialContinue::
        end
    elseif(IN:contains("EntityId", TYPE.STRING)) then
        --Transform into SpawnPotentials

        local id = IN.lastFound.value
        if(id:find("^minecraft:")) then id = id:sub(11) end
        if(Settings:dataTableContains("entities", id)) then
            local entry = Settings.lastFound
            OUT.SpawnPotentials = OUT:addChild(TagList.new("SpawnPotentials"))
            local spawnPotential = TagCompound.new()
            spawnPotential:addChild(TagInt.new("Weight", 1))
            spawnPotential.Entity = spawnPotential:addChild(TagCompound.new("Entity"))
            spawnPotential.Entity:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            OUT.SpawnPotentials:addChild(spawnPotential)

            if(OUT.SpawnData == nil) then
                OUT.SpawnData = OUT:addChild(TagCompound.new("SpawnData"))
                OUT.SpawnData:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            end
        end
    end

    return OUT
end

function TileEntity:ConvertNoteBlock(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 25) then return nil end end

    --check for queued tile entity and turn into note and powered
    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_states") then
                if(IN.QueuedTE:contains("paletteEntry", TYPE.COMPOUND)) then
                    IN.QueuedTE.paletteEntry = IN.QueuedTE.lastFound
                    if(IN.QueuedTE.paletteEntry:contains("Properties", TYPE.COMPOUND)) then
                        IN.QueuedTE.paletteEntry.Properties = IN.QueuedTE.paletteEntry.lastFound

                        OUT.note = OUT:addChild(TagByte.new("note"))
                        OUT.powered = OUT:addChild(TagByte.new("powered"))
    
                        if(IN.QueuedTE.paletteEntry.Properties:contains("note", TYPE.STRING)) then OUT.note.value = tonumber(IN.QueuedTE.paletteEntry.Properties.lastFound.value) end
                        if(IN.QueuedTE.paletteEntry.Properties:contains("powered", TYPE.STRING)) then OUT.powered.value = IN.QueuedTE.paletteEntry.Properties.lastFound.value == "true" end
                    end
                end
            end
        end
    else
        if(IN:contains("note", TYPE.BYTE)) then OUT:addChild(TagByte.new("note", IN.lastFound.value)) elseif(required) then OUT:addChild(TagByte.new("note")) end
        if(IN:contains("powered", TYPE.BYTE)) then OUT:addChild(TagByte.new("powered", IN.lastFound.value)) elseif(required) then OUT:addChild(TagByte.new("powered")) end
    end

    return OUT
end

function TileEntity:ConvertPiston(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 34 or IN.curBlock.lastFound.value ~= 36) then return nil end end

    if(IN:contains("progress", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("progress")) end
    if(IN:contains("extending", TYPE.BYTE)) then OUT:addChild(OUT:addChild(TagByte.new("extending", IN.lastFound.value ~= 0))) elseif(required) then OUT:addChild(TagByte.new("extending", true)) end
    if(IN:contains("source", TYPE.BYTE)) then OUT:addChild(OUT:addChild(TagByte.new("source", IN.lastFound.value ~= 0)))
    elseif(required) then
        if(IN.curBlock:contains("id", TYPE.SHORT)) then OUT:addChild(TagByte.new("source", IN.curBlock.lastFound.value == 34)) else return nil end
    end
    if(IN:contains("facing", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("facing")) end

    local blockId = 0
    local blockData = 0

    if(IN:contains("blockState", TYPE.COMPOUND)) then
        IN.blockState = IN.lastFound

        if(IN.blockState:contains("Name", TYPE.STRING)) then
            local Name = IN.blockState.lastFound.value
            if(Name:find("^minecraft:")) then Name = Name:sub(11) end

            if(IN.blockState:contains("Properties", TYPE.COMPOUND)) then IN.blockState.Properties = IN.blockState.lastFound end

            if(Settings:dataTableContains("blocks_states", Name) and Name ~= "air") then
                local entry = Settings.lastFound

                local DataVersion = Settings:getSettingInt("DataVersion")

                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                    if(subEntry[2]:len() > 0 and IN.blockState.Properties ~= nil) then if(Item:CompareProperties(subEntry[2], IN.blockState.Properties) == false) then goto entryContinue end end
                    blockId = tonumber(subEntry[3])
                    if(subEntry[4]:len() > 0) then blockData = tonumber(subEntry[4]) end
                    break
                    ::entryContinue::
                end
            end
        end
    else
        if(IN:contains("blockId", TYPE.INT)) then blockId = IN.lastFound.value else blockId = 0 end
        if(IN:contains("blockData", TYPE.INT)) then blockData = IN.lastFound.value else blockData = 0 end

        if(Settings:dataTableContains("blocks_ids", tostring(blockId)) and blockId ~= 0) then
            local entry = Settings.lastFound

            local DataVersion = Settings:getSettingInt("DataVersion")

            for index, _ in ipairs(entry) do
                local subEntry = entry[index]
                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= blockData) then goto entryContinue end end
                blockId = tonumber(subEntry[3])
                if(subEntry[4]:len() > 0) then blockData = tonumber(subEntry[4]) end
                break
                ::entryContinue::
            end
        end
    end

    if(required) then
        OUT:addChild(TagInt.new("blockId", blockId))
        OUT:addChild(TagInt.new("blockData", blockData))
    end

    return OUT
end

function TileEntity:ConvertShulkerBox(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value < 219 and IN.curBlock.lastFound.value > 234) then return nil end end

    TileEntity:CustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertSign(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 63 and IN.curBlock.lastFound.value ~= 68) then return nil end end

    for i=0, 3 do
        local added = false;
        if(IN:contains("Text" .. tostring(i+1), TYPE.STRING)) then
            local text = IN.lastFound.value
            local jsonRoot = JSONValue.new()
            if(jsonRoot:parse(text).type == JSON_TYPE.OBJECT) then
                if(jsonRoot:contains("text", JSON_TYPE.STRING)) then
                    OUT:addChild(TagString.new("Text" .. tostring(i+1), jsonRoot.lastFound:getString()))
                    added = true
                end
            else

                if(text == "null") then text = "" end

                text = text:gsub("^%s*(.-)%s*$", "%1")

                if(text:find("^\"") and text:find("\"$")) then

                    text = text:sub(2, text:len()-1)

                    text = text:gsub('\\\"', "\"")
                    text = text:gsub('\\\\', "\\")

                    text = UnicodeToUtf8(text)
                end

                if(text:len() > 16) then text = text:sub(1, 16) end
                OUT:addChild(TagString.new("Text" .. tostring(i+1), text))
                added = true;
            end
        end
        if(required and not added) then OUT:addChild(TagString.new("Text" .. tostring(i+1))) end
    end

    if(required) then 
        OUT:addChild(TagByte.new("Verified", true))
        OUT:addChild(TagByte.new("Censored"))
    end
    return OUT
end

function TileEntity:ConvertSkull(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 144) then return nil end end
    
    if(required) then OUT:addChild(TagString.new("ExtraType")) end

    --check for queued tile entity and turn into SkullType and Rot
    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_states") then
                if(IN.QueuedTE:contains("paletteEntry", TYPE.COMPOUND)) then
                    IN.QueuedTE.paletteEntry = IN.QueuedTE.lastFound

                    if(IN.QueuedTE.paletteEntry:contains("Name", TYPE.STRING)) then
                        local skullName = IN.QueuedTE.paletteEntry.lastFound.value

                        OUT.SkullType = OUT:addChild(TagByte.new("SkullType"))
                        OUT.Rot = OUT:addChild(TagByte.new("Rot"))

                        if(skullName == "minecraft:skeleton_skull" or skullName == "minecraft:skeleton_wall_skull") then OUT.SkullType.value = 0
                        elseif(skullName == "minecraft:wither_skeleton_skull" or skullName == "minecraft:wither_skeleton_wall_skull") then OUT.SkullType.value = 1
                        elseif(skullName == "minecraft:zombie_head" or skullName == "minecraft:zombie_wall_head") then OUT.SkullType.value = 2
                        elseif(skullName == "minecraft:player_head" or skullName == "minecraft:player_wall_head") then OUT.SkullType.value = 3
                        elseif(skullName == "minecraft:creeper_head" or skullName == "minecraft:creeper_wall_head") then OUT.SkullType.value = 4
                        elseif(skullName == "minecraft:dragon_head" or skullName == "minecraft:dragon_wall_head") then OUT.SkullType.value = 5
                        end
                    end

                    if(IN.QueuedTE.paletteEntry:contains("Properties", TYPE.COMPOUND)) then
                        IN.QueuedTE.paletteEntry.Properties = IN.QueuedTE.paletteEntry.lastFound
                        if(IN.QueuedTE.paletteEntry.Properties:contains("rotation", TYPE.STRING)) then OUT.Rot.value = tonumber(IN.QueuedTE.paletteEntry.Properties.lastFound.value) end
                    end
                end
            end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("SkullType"))
        OUT:addChild(TagByte.new("Rot"))
    end

    return OUT
end

--------Base functions

function TileEntity:CustomName(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then
        local customName = IN.lastFound.value

        local jsonRoot = JSONValue.new()
        if(jsonRoot:parse(customName).type == JSON_TYPE.OBJECT) then

            local textOut = ""

            if(jsonRoot:contains("text", JSON_TYPE.STRING)) then
                containsText = true
                textOut = jsonRoot.lastFound:getString()
            end

            if(jsonRoot:contains("extra", JSON_TYPE.ARRAY)) then
                local extraArray = jsonRoot.lastFound

                for j=0, extraArray.childCount-1 do
                    local extra = extraArray:child(j)

                    if(extra:contains("text", JSON_TYPE.STRING)) then
                        containsText = true
                        textOut = textOut .. extra.lastFound:getString()
                    end
                end
            end

            OUT:addChild(TagString.new("CustomName", textOut))
        else
            OUT:addChild(IN.lastFound:clone())
        end
    end
end

function TileEntity:ConvertItems(IN, OUT, required, requireItems)
    if(IN:contains("Items", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Items = IN.lastFound
        OUT.Items = OUT:addChild(TagList.new("Items"))
        for i=0, IN.Items.childCount-1 do
            local item = Item:ConvertItem(IN.Items:child(i), true)
            if(item ~= nil) then
                OUT.Items:addChild(item)
            end
        end
    elseif(required and requireItems) then
        OUT:addChild(TagList.new("Items"))
    end
end

return TileEntity