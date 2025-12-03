TileEntity = {}
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
        if(IN:contains("x", TYPE.INT)) then OUT.x.value = IN.lastFound.value else return nil end
        if(IN:contains("y", TYPE.INT)) then OUT.y.value = IN.lastFound.value else return nil end
        if(IN:contains("z", TYPE.INT)) then OUT.z.value = IN.lastFound.value else return nil end

        local blockX = OUT.x.value
        local blockY = OUT.y.value
        local blockZ = OUT.z.value

        IN.curBlock = Chunk:getBlock(blockX, blockY, blockZ)
        IN.curBlock.save = false

        --isMovable
        OUT:addChild(TagByte.new("isMovable", true))
        
        if(Settings:dataTableContains("tileEntities", id)) then
            local entry = Settings.lastFound
            OUT:addChild(TagString.new("id", entry[1][1]))
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
        if(IN.QueuedTE:contains("x", TYPE.INT)) then OUT.x.value = IN.QueuedTE.lastFound.value else return nil end
        if(IN.QueuedTE:contains("y", TYPE.INT)) then OUT.y.value = IN.QueuedTE.lastFound.value else return nil end
        if(IN.QueuedTE:contains("z", TYPE.INT)) then OUT.z.value = IN.QueuedTE.lastFound.value else return nil end

        local blockX = OUT.x.value
        local blockY = OUT.y.value
        local blockZ = OUT.z.value

        IN.curBlock = Chunk:getBlock(blockX, blockY, blockZ)
        IN.curBlock.save = false

        local id = ""

        --isMovable
        OUT:addChild(TagByte.new("isMovable", true))

        --Identify queue type
        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_ids") then

                if(IN.QueuedTE:contains("id", TYPE.SHORT)) then
                    local blockId = IN.QueuedTE.lastFound.value

                    if(blockId == 23) then id = "dispenser"
                    elseif(blockId == 26) then id = "bed"
                    elseif(blockId == 118) then id = "queued_cauldron"
                    elseif(blockId == 33 or blockId == 29) then id = "piston"
                    elseif(blockId == 140) then id = "flower_pot"
                    elseif(blockId == 52) then id = "mob_spawner"
                    elseif(blockId == 54 or blockId == 146) then id = "chest"
                    elseif(blockId == 61 or blockId == 62) then id = "furnace"
                    elseif(blockId == 63 or blockId == 68) then id = "sign"
                    elseif(blockId == 84) then id = "jukebox"
                    elseif(blockId == 117) then id = "brewing_stand"
                    elseif(blockId == 119) then id = "end_portal"
                    elseif(blockId == 130) then id = "ender_Chest"
                    elseif(blockId == 138) then id = "beacon"
                    elseif(blockId == 144) then id = "skull"
                    elseif(blockId == 149 or blockId == 150) then id = "comparator"
                    elseif(blockId == 151 or blockId == 178) then id = "daylight_detector"
                    elseif(blockId == 154) then id = "hopper"
                    elseif(blockId == 158) then id = "dropper"
                    elseif(blockId == 176 or blockId == 177) then id = "banner"
                    elseif(blockId == 209) then id = "end_gateway"
                    elseif(blockId >= 219 and blockId <= 234) then id = "shulker_box"
                    elseif(blockId == 256) then id = "conduit"
                    else return nil end

                else return nil end
            else return nil end
        else return nil end

        if(id == "") then return nil end

        if(Settings:dataTableContains("tileEntities", id)) then
            local entry = Settings.lastFound
            OUT:addChild(TagString.new("id", entry[1][1]))
            OUT = TileEntity[entry[1][2]](TileEntity, IN, OUT, true)
        else return nil end

        if(IN.curBlock.save) then Chunk:setBlock(blockX, blockY, blockZ, IN.curBlock) end
    end

return OUT
end

function TileEntity:ConvertBanner(IN, OUT, required)

    if(IN:contains("Base", TYPE.INT)) then
        OUT.Base = OUT:addChild(TagInt.new("Base"))
        if(IN.lastFound.value <= 15) then OUT.Base.value = IN.lastFound.value end
    elseif(required) then
        OUT:addChild(TagInt.new("Base"))
    end

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

                out_Pattern.Color = out_Pattern:addChild(TagInt.new("Color"))
                local color = in_Pattern.Color.value
                if(color == 0) then out_Pattern.Color.value = 15
                elseif(color == 1) then out_Pattern.Color.value = 14
                elseif(color == 2) then out_Pattern.Color.value = 13
                elseif(color == 3) then out_Pattern.Color.value = 12
                elseif(color == 4) then out_Pattern.Color.value = 11
                elseif(color == 5) then out_Pattern.Color.value = 10
                elseif(color == 6) then out_Pattern.Color.value = 9
                elseif(color == 7) then out_Pattern.Color.value = 8
                elseif(color == 8) then out_Pattern.Color.value = 7
                elseif(color == 9) then out_Pattern.Color.value = 6
                elseif(color == 10) then out_Pattern.Color.value = 5
                elseif(color == 11) then out_Pattern.Color.value = 4
                elseif(color == 12) then out_Pattern.Color.value = 3
                elseif(color == 13) then out_Pattern.Color.value = 2
                elseif(color == 14) then out_Pattern.Color.value = 1
                elseif(color == 15) then out_Pattern.Color.value = 0
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

    --TODO convert status effect ids
    if(IN:contains("Primary", TYPE.INT)) then OUT:addChild(TagInt.new("primary", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("primary")) end
    if(IN:contains("Secondary", TYPE.INT)) then OUT:addChild(TagInt.new("secondary", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("secondary")) end
    return OUT
end

function TileEntity:ConvertBed(IN, OUT, required)
    if(IN:contains("color", TYPE.INT)) then OUT:addChild(TagByte.new("color", IN.lastFound.value)) elseif(required) then OUT:addChild(TagByte.new("color", 14)) end
    return OUT
end

function TileEntity:ConvertBrewingStand(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BrewTime", TYPE.SHORT)) then OUT:addChild(TagShort.new("CookTime", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("CookTime", 0)) end
    if(IN:contains("Fuel", TYPE.BYTE)) then
        OUT:addChild(TagShort.new("FuelAmount", IN.lastFound.value))
        OUT:addChild(TagShort.new("FuelTotal", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagShort.new("FuelAmount", 0))
        OUT:addChild(TagShort.new("FuelTotal", 0))
    end
    return OUT
end

function TileEntity:ConvertCauldron(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("PotionType", TYPE.SHORT)) then OUT:addChild(TagShort.new("PotionType", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("PotionType", 0)) end
    if(IN:contains("PotionId", TYPE.STRING)) then
        --TODO TileEntity:Convert potion id. check potion type
        OUT:addChild(TagShort.new("PotionId", -1))
    elseif(required) then
        OUT:addChild(TagShort.new("PotionId", -1))
    end

    --TODO customColor

    return OUT
end

function TileEntity:ConvertChest(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, false)
    if(required) then OUT:addChild(TagByte.new("Findable")) end

    if(required) then 
        if(IN.curBlock:contains("Name", TYPE.STRING)) then
            IN.curBlock.Name = IN.curBlock.lastFound.value
            if(IN.curBlock.Name:find("^minecraft:")) then IN.curBlock.Name = IN.curBlock.Name:sub(11) end

            if(IN.curBlock.Name == "chest" or IN.curBlock.Name == "trapped_chest") then
                local chestFacing = 2

                if(IN.curBlock:contains("val", TYPE.SHORT)) then
                    IN.curBlock.val = IN.curBlock.lastFound.value

                    chestFacing = IN.curBlock.val
                    if(chestFacing < 2 or chestFacing > 5) then chestFacing = 2 end
                end
        
                local mainX = OUT.x.value%16
                local mainZ = OUT.z.value%16
                local pairX = mainX
                local pairZ = mainZ
                local pairXGlobal = OUT.x.value
                local pairZGlobal = OUT.z.value

                local withinChunk = false

                if(chestFacing == 2 or chestFacing == 3) then
                    pairX = pairX + 1
                    pairXGlobal = pairXGlobal + 1
                    if(mainX < 15) then withinChunk = true end
                elseif(chestFacing == 4 or chestFacing == 5) then
                    pairZ = pairZ + 1
                    pairZGlobal = pairZGlobal + 1
                    if(mainZ < 15) then withinChunk = true end
                end

                if(withinChunk) then
                    local pairBlock = Chunk:getBlock(pairX, OUT.y.value, pairZ)

                    if(pairBlock:contains("Name", TYPE.STRING)) then
                        pairBlock.Name = pairBlock.lastFound.value
                        if(pairBlock.Name:find("^minecraft:")) then pairBlock.Name = pairBlock.Name:sub(11) end
                        if(pairBlock.Name == IN.curBlock.Name) then

                            local pairFacing = 2

                            if(pairBlock:contains("val", TYPE.SHORT)) then
                                pairBlock.val = pairBlock.lastFound.value

                                pairFacing = pairBlock.val
                                if(pairFacing < 2 or pairFacing > 5) then pairFacing = 2 end
                            end

                            if(pairFacing == chestFacing) then
                                OUT:addChild(TagByte.new("pairlead", true))
                                OUT.pairx = OUT:addChild(TagInt.new("pairx", pairXGlobal))
                                OUT.pairz = OUT:addChild(TagInt.new("pairz", pairZGlobal))
                            end
                        end
                    end
                else
                    OUT:addChild(TagByte.new("pairlead", true))
                    OUT.pairx = OUT:addChild(TagInt.new("pairx", pairXGlobal))
                    OUT.pairz = OUT:addChild(TagInt.new("pairz", pairZGlobal))
                end
            end
        end
    end

    return OUT
end

function TileEntity:ConvertComparator(IN, OUT, required)
    if(IN:contains("OutputSignal", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("OutputSignal", 0)) end
    return OUT
end

function TileEntity:ConvertConduit(IN, OUT, required)
    if(IN:contains("Active", TYPE.BYTE)) then OUT:addChild(TagByte.new("Active", IN.lastFound.value)) elseif(required) then OUT:addChild(TagByte.new("Active", 0)) end
    if(IN:contains("Target", TYPE.INT)) then
        --TODO identify use of Target
        OUT:addChild(TagLong.new("Target", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagLong.new("Target", -1))
    end

    return OUT
end

function TileEntity:ConvertDaylightDetector(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertDispenser(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertDropper(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertEnchantmentTable(IN, OUT, required)
    if(required) then OUT:addChild(TagFloat.new("rott")) end
    return OUT
end

function TileEntity:ConvertEnderChest(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertEndGateway(IN, OUT, required)

    if(IN:contains("Age", TYPE.LONG)) then OUT:addChild(TagInt.new("Age", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("Age")) end

    if(IN:contains("ExitPortal", TYPE.COMPOUND)) then
        IN.ExitPortal = IN.lastFound
        OUT.ExitPortal = OUT:addChild(TagList.new("ExitPortal"))
        if(IN.ExitPortal:contains("X", TYPE.INT)) then OUT.ExitPortal:addChild(TagInt.new("", IN.ExitPortal.lastFound.value)) else OUT.ExitPortal:addChild(TagInt.new("")) end
        if(IN.ExitPortal:contains("Y", TYPE.INT)) then OUT.ExitPortal:addChild(TagInt.new("", IN.ExitPortal.lastFound.value)) else OUT.ExitPortal:addChild(TagInt.new("", 64)) end
        if(IN.ExitPortal:contains("Z", TYPE.INT)) then OUT.ExitPortal:addChild(TagInt.new("", IN.ExitPortal.lastFound.value)) else OUT.ExitPortal:addChild(TagInt.new("")) end
    end

    if(OUT.ExitPortal == nil and required) then
        OUT.ExitPortal = OUT:addChild(TagList.new("ExitPortal"))
        OUT.ExitPortal:addChild(TagInt.new(""))
        OUT.ExitPortal:addChild(TagInt.new("", 64))
        OUT.ExitPortal:addChild(TagInt.new(""))
    end

    return OUT
end

function TileEntity:ConvertEndPortal(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertFlowerPot(IN, OUT, required)

    local itemId = "0"
    local itemData = "0"
    if(IN:contains("Item", TYPE.INT)) then
        itemId = tostring(IN.lastFound.value)
    end
    if(IN:contains("Data", TYPE.INT)) then itemData = tostring(IN.lastFound.value) end

    local ChunkVersion = Settings:getSettingInt("ChunkVersion")

    if(Settings:dataTableContains("blocks_ids", itemId)) then
        local entry = Settings.lastFound
        for index, _ in ipairs(entry) do
            local subEntry = entry[index]
            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
            if(subEntry[2]:len() ~= 0) then if(subEntry[2] ~= itemData) then goto entryContinue end end
            OUT.PlantBlock = OUT:addChild(TagCompound.new("PlantBlock"))
            OUT.PlantBlock:addChild(TagString.new("name", "minecraft:" .. subEntry[3]))
            OUT.PlantBlock.val = OUT.PlantBlock:addChild(TagShort.new("val", tonumber(itemData)))
            if(subEntry[4]:len() > 0) then OUT.PlantBlock.val.value = tonumber(subEntry[4]) end
            break
            ::entryContinue::
        end
    end

    if(OUT.PlantBlock == nil) then

        if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
            IN.QueuedTE = IN.lastFound
            if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
                if(IN.QueuedTE.lastFound.value == "blocks_ids") then
                    IN.Data = 0

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

                        if(Settings:dataTableContains("blocks_ids", tostring(IN.Item)) and IN.Item ~= 0) then
                            local entry = Settings.lastFound
                            for index, _ in ipairs(entry) do
                                local subEntry = entry[index]
                                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                                if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.Data) then goto entryContinue end end

                                OUT.PlantBlock = OUT:addChild(TagCompound.new("PlantBlock"))
                                OUT.PlantBlock.flowerName = OUT.PlantBlock:addChild(TagString.new("name", "minecraft:" .. subEntry[3]))
                                OUT.PlantBlock.val = OUT.PlantBlock:addChild(TagShort.new("val", tonumber(itemData)))
                                if(subEntry[4]:len() > 0) then OUT.PlantBlock.val.value = tonumber(subEntry[4]) end
                                break
                                ::entryContinue::
                            end
                        end
                    end
                end
            end
        end
    end

    return OUT
end

function TileEntity:ConvertFurnace(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end 

    if(required) then 
        --TODO identify use of BurnDuration
        OUT:addChild(TagShort.new("BurnDuration"))
    end
    return OUT
end

function TileEntity:ConvertHopper(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("TransferCooldown", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("TransferCooldown", 0)) end
    return OUT
end

function TileEntity:ConvertJukebox(IN, OUT, required)
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

    if(IN:contains("SpawnCount", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("SpawnCount", 4)) end
    if(IN:contains("SpawnRange", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("SpawnRange", 4)) end
    if(IN:contains("Delay", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Delay", 0)) end
    if(IN:contains("MinSpawnDelay", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("MinSpawnDelay", 200)) end
    if(IN:contains("MaxSpawnDelay", TYPE.SHORT)) then if(IN.lastFound.value > 0) then OUT:addChild(IN.lastFound:clone()) else OUT:addChild(TagShort.new("MaxSpawnDelay", 800)) end elseif(required) then OUT:addChild(TagShort.new("MaxSpawnDelay", 800)) end
    if(IN:contains("MaxNearbyEntities", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("MaxNearbyEntities", 6)) end
    if(IN:contains("RequiredPlayerRange", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("RequiredPlayerRange", 16)) end

    local id = ""

    if(IN:contains("SpawnData", TYPE.COMPOUND)) then
        IN.SpawnData = IN.lastFound
        if(IN.SpawnData:contains("id", TYPE.STRING)) then
            id = IN.SpawnData.lastFound.value
        end
    end

    if(id:len() == 0) then if(IN:contains("EntityId", TYPE.STRING)) then id = IN.lastFound.value end end

    if(id:find("^minecraft:")) then id = id:sub(11) end
    if(Settings:dataTableContains("entities", id)) then
        local entry = Settings.lastFound
        if(entry[1][2]:len() > 0) then OUT.EntityId = OUT:addChild(TagInt.new("EntityId", tonumber(entry[1][2]))) end
    end

    if(OUT.EntityId == nil) then OUT:addChild(TagInt.new("EntityId", 1)) end

    return OUT
end

function TileEntity:ConvertNoteBlock(IN, OUT, required)
    if(IN:contains("note", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("note")) end
    return OUT
end

function TileEntity:ConvertPiston(IN, OUT, required)

    
    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        --PistonArm
        IN.QueuedTE = IN.lastFound

        if(OUT:contains("isMovable", TYPE.BYTE)) then
            OUT.isMovable = OUT.lastFound
        else
            OUT.isMovable = OUT:addChild(TagByte.new("isMovable", true))
        end

        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_ids") then
                if(IN.QueuedTE:contains("damage", TYPE.BYTE)) then
                    if(IN.QueuedTE.lastFound.value >= 8) then
                        OUT.isMovable.value = false
                    end
                end
            end
        end

        if(IN.curBlock:contains("Name", TYPE.STRING)) then
            OUT:addChild(TagByte.new("Sticky", IN.curBlock.lastFound.value == "minecraft:sticky_piston"))
        elseif(required) then
            OUT:addChild(TagByte.new("Sticky", false))
        end

        if(OUT.isMovable.value == 1) then
            OUT:addChild(TagFloat.new("Progress", 0))
            OUT:addChild(TagFloat.new("LastProgress", 0))
            OUT:addChild(TagByte.new("State", 0))
            OUT:addChild(TagByte.new("NewState", 0))
        else
            OUT:addChild(TagFloat.new("Progress", 1))
            OUT:addChild(TagFloat.new("LastProgress", 1))
            OUT:addChild(TagByte.new("State", 2))
            OUT:addChild(TagByte.new("NewState", 2))
        end

    else
        --MovingBlock

        if(OUT:contains("id", TYPE.STRING)) then
            OUT.lastFound.value = "MovingBlock"
        end

        local blockName = "minecraft:air"
        local blockVal = 0

        IN.blockId = 0
        IN.blockData = 0
        if(IN:contains("blockId", TYPE.INT)) then IN.blockId = IN.lastFound.value end
        if(IN:contains("blockData", TYPE.INT)) then IN.blockData = IN.lastFound.value end
        blockVal = IN.blockData

        if(Settings:dataTableContains("blocks_ids", tostring(IN.blockId)) and IN.blockId ~= 0) then
            local entry = Settings.lastFound

            local DataVersion = Settings:getSettingInt("DataVersion")

            for index, _ in ipairs(entry) do
                local subEntry = entry[index]
                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.blockData) then goto entryContinue end end
                blockName = "minecraft:" .. subEntry[3]
                if(subEntry[4]:len() > 0) then blockVal = tonumber(subEntry[4]) end
                break
                ::entryContinue::
            end
        end

        OUT.movingBlock = OUT:addChild(TagCompound.new("movingBlock"))

        OUT.movingBlock:addChild(TagString.new("name", blockName))
        OUT.movingBlock:addChild(TagShort.new("val", blockVal))

        OUT.movingBlockExtra = OUT:addChild(TagCompound.new("movingBlockExtra"))
        OUT.movingBlockExtra:addChild(TagString.new("name", "minecraft:air"))
        OUT.movingBlockExtra:addChild(TagShort.new("val"))
    end

    return OUT
end

function TileEntity:ConvertShulkerBox(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    
    if(required) then OUT:addChild(TagByte.new("Findable")) end

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound
        OUT.facing = OUT:addChild(TagByte.new("facing", 0))

        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_ids") then
                if(IN.QueuedTE:contains("damage", TYPE.BYTE)) then OUT.facing = IN.QueuedTE.lastFound.value end
            end
        end
    end

    return OUT
end

function TileEntity:ConvertSign(IN, OUT, required)
    local outputText = ""
    containsText = false
    if(IN:contains("Text1", TYPE.STRING)) then
        outputText = IN.lastFound.value
        containsText = true
    end
    if(IN:contains("Text2", TYPE.STRING)) then
        outputText = outputText .. "\n" .. IN.lastFound.value
        containsText = true
    else outputText = outputText .. "\n" end
    if(IN:contains("Text3", TYPE.STRING)) then
        outputText = outputText .. "\n" .. IN.lastFound.value 
        containsText = true
    else outputText = outputText .. "\n" end
    if(IN:contains("Text4", TYPE.STRING)) then
        outputText = outputText .. "\n" .. IN.lastFound.value 
        containsText = true
    end

    if(containsText) then OUT:addChild(TagString.new("Text", outputText))
    elseif(required) then OUT:addChild(TagString.new("Text", outputText))
    end
    
    return OUT
end

function TileEntity:ConvertSkull(IN, OUT, required)
    if(IN:contains("SkullType", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("SkullType")) end
    if(IN:contains("Rot", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("Rot")) end
    --TODO check if mouth moving exists on console
    return OUT
end

-------------Base functions

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