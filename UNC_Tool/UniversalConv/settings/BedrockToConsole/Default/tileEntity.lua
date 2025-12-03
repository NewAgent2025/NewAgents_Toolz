TileEntity = {}
Item = Item or require("item")

function TileEntity:ConvertTileEntity(IN, required)
    local OUT = TagCompound.new()

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
                    --TileEntity:Convert
                    return nil
                else return nil end
            elseif(IN.QueuedTE.lastFound.value == "blocks_names") then
                return nil
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
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 176 and IN.curBlock.lastFound.value ~= 177) then return nil end end

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

                local color = in_Pattern.Color.value
                if(color < 0 or color > 15) then goto patternContinue end
                out_Pattern.Color = out_Pattern:addChild(TagInt.new("Color", color))

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

    if(IN:contains("primary", TYPE.INT)) then OUT:addChild(TagInt.new("Primary", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("Primary")) end
    if(IN:contains("secondary", TYPE.INT)) then OUT:addChild(TagInt.new("Secondary", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("Secondary")) end
    if(required) then OUT:addChild(TagInt.new("Levels")) end
    return OUT
end

function TileEntity:ConvertBed(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 26) then return nil end end

    if(IN:contains("color", TYPE.BYTE)) then OUT:addChild(TagInt.new("color", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("color", 14)) end
    return OUT
end

function TileEntity:ConvertBrewingStand(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 117) then return nil end end

    TileEntity:ConvertItems(IN, OUT, required)
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(TagShort.new("BrewTime", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("BrewTime", 0)) end
    if(IN:contains("FuelAmount", TYPE.SHORT)) then OUT:addChild(TagByte.new("Fuel", IN.lastFound.value)) elseif(required) then OUT:addChild(TagByte.new("Fuel")) end
    return OUT
end

function TileEntity:ConvertCauldron(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 118) then return nil end end

    TileEntity:ConvertItems(IN, OUT, required)
    if(IN:contains("PotionType", TYPE.SHORT)) then OUT:addChild(TagShort.new("PotionType", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("PotionType", 0)) end
    if(IN:contains("PotionId", TYPE.SHORT)) then
        --TODO TileEntity:Convert potion id. check potion type
        OUT:addChild(TagString.new("PotionId"))
    elseif(required) then
        OUT:addChild(TagString.new("PotionId"))
    end
    return OUT
end

function TileEntity:ConvertChest(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 54 and IN.curBlock.lastFound.value ~= 146) then return nil end end

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required)
    if(required) then OUT:addChild(TagByte.new("bonus")) end
    return OUT
end

function TileEntity:ConvertComparator(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 149 and IN.curBlock.lastFound.value ~= 150) then return nil end end

    if(IN:contains("OutputSignal", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("OutputSignal", 0)) end
    return OUT
end

function TileEntity:ConvertConduit(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 256) then return nil end end

    if(IN:contains("Active", TYPE.BYTE)) then OUT:addChild(TagByte.new("Active", IN.lastFound.value)) elseif(required) then OUT:addChild(TagByte.new("Active", 0)) end
    if(IN:contains("Target", TYPE.LONG)) then
        --TODO identify use of Target
        OUT:addChild(TagInt.new("Target", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagInt.new("Target", -1))
    end

    --TODO add Rotation tag

    return OUT
end

function TileEntity:ConvertDaylightDetector(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 151 and IN.curBlock.lastFound.value ~= 178) then return nil end end

    return OUT
end

function TileEntity:ConvertDispenser(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 23) then return nil end end

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertDropper(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 158) then return nil end end

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertEnchantmentTable(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 116) then return nil end end

    return OUT
end

function TileEntity:ConvertEnderChest(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 130) then return nil end end

    return OUT
end

function TileEntity:ConvertEndPortal(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 119) then return nil end end

    return OUT
end

function TileEntity:ConvertEndGateway(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 119) then return nil end end

    if(IN:contains("Age", TYPE.INT)) then OUT:addChild(TagLong.new("Age", IN.lastFound.value)) elseif(required) then OUT:addChild(TagLong.new("Age")) end

    if(IN:contains("ExitPortal", TYPE.LIST)) then
        IN.ExitPortal = IN.lastFound

        if(IN.ExitPortal.childCount == 3) then
            OUT.ExitPortal = OUT:addChild(TagCompound.new("ExitPortal"))
            OUT.ExitPortal:addChild(TagInt.new("X", IN.ExitPortal:child(0).value))
            OUT.ExitPortal:addChild(TagInt.new("Y", IN.ExitPortal:child(1).value))
            OUT.ExitPortal:addChild(TagInt.new("Z", IN.ExitPortal:child(2).value))
        end
    end

    if(OUT.ExitPortal == nil and required) then
        OUT.ExitPortal = OUT:addChild(TagCompound.new("ExitPortal"))
        OUT.ExitPortal:addChild(TagInt.new("X", 0))
        OUT.ExitPortal:addChild(TagInt.new("Y", 64))
        OUT.ExitPortal:addChild(TagInt.new("Z", 0))
    end

    return OUT
end

function TileEntity:ConvertFlowerPot(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 140) then return nil end end

    local flowerItem = TagInt.new("Item")
    local flowerData = TagInt.new("Data")

    --TODO support old numerical ids
    if(IN:contains("PlantBlock", TYPE.COMPOUND)) then
        IN.PlantBlock = IN.lastFound
        if(IN.PlantBlock:contains("name", TYPE.STRING)) then IN.PlantBlock.flowerName = IN.PlantBlock.lastFound.value end
        if(IN.PlantBlock:contains("states", TYPE.COMPOUND)) then IN.PlantBlock.states = IN.PlantBlock.lastFound end
        if(IN.PlantBlock:contains("val", TYPE.SHORT)) then IN.PlantBlock.val = IN.PlantBlock.lastFound end

        if(IN.PlantBlock.flowerName ~= nil) then
            if(IN.PlantBlock.flowerName:find("^minecraft:")) then IN.PlantBlock.flowerName = IN.PlantBlock.flowerName:sub(11) end

            if(Settings:dataTableContains("blocks_names", IN.PlantBlock.flowerName)) then
                local entry = Settings.lastFound
                local ChunkVersion = Settings:getSettingInt("ChunkVersion")

                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                    if(IN.PlantBlock.states ~= nil) then
                        if(subEntry[3]:len() > 0) then if(Item:CompareStates(subEntry[3], IN.PlantBlock.states) == false) then goto entryContinue end end
                    elseif(IN.PlantBlock.val ~= nil) then
                        if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.PlantBlock.val.value) then goto entryContinue end end
                    end
        
                    flowerItem.value = tonumber(subEntry[4])
                    if(subEntry[5]:len() ~= 0) then flowerData.value = tonumber(subEntry[5]) end

                    OUT.Item = OUT:addChild(flowerItem)
                    OUT.Data = OUT:addChild(flowerData)

                    break
                    ::entryContinue::
                end
            end
        end
    end

    if(OUT.Item == nil and required) then OUT:addChild(flowerItem) end
    if(OUT.Data == nil and required) then OUT:addChild(flowerData) end

    return OUT
end

function TileEntity:ConvertFurnace(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 61 and IN.curBlock.lastFound.value ~= 62) then return nil end end

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end 

    if(required) then
        --TODO identify use of BurnDuration
        OUT:addChild(TagShort.new("CookTimeTotal"))
        OUT:addChild(TagByte.new("CharcoalUsed"))
    end
    return OUT
end

function TileEntity:ConvertHopper(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 154) then return nil end end

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required)
    if(IN:contains("TransferCooldown", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("TransferCooldown", 0)) end
    return OUT
end

function TileEntity:ConvertItemFrame(IN, OUT, required)

    
    return nil
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

    --TODO get old numerical id format

    if(IN:contains("EntityIdentifier", TYPE.STRING)) then
        local entityId = IN.lastFound.value
        if(entityId:find("^minecraft:")) then entityId = entityId:sub(11) end

        if(Settings:dataTableContains("entities_names", entityId)) then
            local entry = Settings.lastFound

            if(tostring(entry[1][3]) ~= "TRUE") then return nil end

            local entityIdOut = "minecraft:" .. entry[1][1]

            OUT.SpawnData = OUT:addChild(TagCompound.new("SpawnData"))
            OUT.SpawnData:addChild(TagString.new("id", entityIdOut))

            OUT.SpawnPotentials = OUT:addChild(TagList.new("SpawnPotentials"))
            local spawnPotential = TagCompound.new()
            spawnPotential:addChild(TagInt.new("Weight", 1))
            spawnPotential.Entity = spawnPotential:addChild(TagCompound.new("Entity"))
            spawnPotential.Entity:addChild(TagString.new("id", entityIdOut))
            OUT.SpawnPotentials:addChild(spawnPotential)
        end
    end

    return OUT
end

function TileEntity:ConvertNoteBlock(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 25) then return nil end end

    if(IN:contains("note", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("note")) end
    if(required) then OUT:addChild(TagByte.new("powered")) end
    return OUT
end

function TileEntity:ConvertPistonArm(IN, OUT, required)


    if(IN.curBlock:contains("damage", TYPE.BYTE)) then IN.curBlock.damage = IN.curBlock.lastFound else IN.curBlock.damage = IN.curBlock:addChild(TagByte.new("damage")) end
    
    if(IN:contains("NewState", TYPE.BYTE)) then IN.NewState = IN.lastFound.value else IN.NewState = 0 end

    if(IN.NewState == 1 or IN.NewState == 2) then 
        if(IN.curBlock.damage.value < 8) then IN.curBlock.damage.value = IN.curBlock.damage.value + 8 end
    else
        if(IN.curBlock.damage.value >= 8) then IN.curBlock.damage.value = IN.curBlock.damage.value - 8 end
    end

    IN.curBlock.save = true

    if(IN.NewState == 1 or IN.NewState == 3) then
        if(required) then
            OUT.extending = OUT:addChild(TagByte.new("extending", IN.NewState == 1))
            OUT.source = OUT:addChild(TagByte.new("source", true))
            OUT.progress = OUT:addChild(TagFloat.new("progress"))
            OUT.facing = OUT:addChild(TagInt.new("facing"))
            OUT.blockId = OUT:addChild(TagInt.new("blockId"))
            OUT.blockData = OUT:addChild(TagInt.new("blockData", IN.curBlock.damage.value))
            if(IN.curBlock:contains("id", TYPE.SHORT)) then OUT.blockId.value = IN.curBlock.lastFound.value end
            
            if(IN:contains("Progress", TYPE.FLOAT)) then OUT.progress.value = IN.lastFound.value end

            local facing = IN.curBlock.damage.value
            if(facing > 8) then facing = facing - 8 end
            OUT.facing.value = facing
        end

        if(IN.curBlock:contains("id", TYPE.SHORT)) then IN.curBlock.lastFound.value = 36 else IN.curBlock:addChild(TagShort.new("id", 36)) end
        IN.curBlock.damage.value = 0

        if(IN:contains("Sticky", TYPE.BYTE)) then if(IN.lastFound.value == 0) then IN.curBlock.damage.value = 0 else IN.curBlock.damage.value = 8 end end

        if(OUT.facing.value == 0) then IN.curBlock.damage.value = IN.curBlock.damage.value + 0
        elseif(OUT.facing.value == 1) then IN.curBlock.damage.value = IN.curBlock.damage.value + 1
        elseif(OUT.facing.value == 2) then IN.curBlock.damage.value = IN.curBlock.damage.value + 3
        elseif(OUT.facing.value == 3) then IN.curBlock.damage.value = IN.curBlock.damage.value + 2
        elseif(OUT.facing.value == 4) then IN.curBlock.damage.value = IN.curBlock.damage.value + 5
        elseif(OUT.facing.value == 5) then IN.curBlock.damage.value = IN.curBlock.damage.value + 4
        end

        return OUT
    end

    return nil
end

function TileEntity:ConvertMovingBlock(IN, OUT, required)

    if(required) then
        OUT:addChild(TagByte.new("extending"))
        OUT:addChild(TagFloat.new("progress"))
        OUT:addChild(TagInt.new("facing"))
        OUT:addChild(TagByte.new("source"))
    end

    if(IN:contains("movingBlock", TYPE.COMPOUND)) then
        IN.movingBlock = IN.lastFound
        if(IN.movingBlock:contains("name", TYPE.STRING)) then IN.movingBlock.blockName = IN.movingBlock.lastFound.value end
        if(IN.movingBlock:contains("states", TYPE.COMPOUND)) then IN.movingBlock.states = IN.movingBlock.lastFound end
        if(IN.movingBlock:contains("val", TYPE.SHORT)) then IN.movingBlock.val = IN.movingBlock.lastFound end
    else return nil end

    --TODO support old numerical ids

    if(IN.movingBlock.blockName == nil) then return nil end
    if(IN.movingBlock.blockName:find("^minecraft:")) then IN.movingBlock.blockName = IN.movingBlock.blockName:sub(11) end

    if(Settings:dataTableContains("blocks_names", IN.movingBlock.blockName)) then
        local entry = Settings.lastFound

        local ChunkVersion = Settings:getSettingInt("ChunkVersion")
        for index, _ in ipairs(entry) do
            local subEntry = entry[index]
            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
            if(IN.movingBlock.states ~= nil) then
                if(subEntry[3]:len() > 0) then if(Item:CompareStates(subEntry[3], IN.movingBlock.states) == false) then goto entryContinue end end
            elseif(IN.movingBlock.val ~= nil) then
                if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.movingBlock.val.value) then goto entryContinue end end
            end

            OUT.blockId = OUT:addChild(TagInt.new("blockId", tonumber(subEntry[4])))
            OUT.blockData = OUT:addChild(TagInt.new("blockData", tonumber(subEntry[5])))
            break
            ::entryContinue::
        end
    else return nil end

    if(OUT.blockId == nil and required) then OUT:addChild(TagInt.new("blockId", 0)) end
    if(OUT.blockData == nil and required) then OUT:addChild(TagInt.new("blockData", 0)) end

    return OUT
end

function TileEntity:ConvertShulkerBox(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then
        IN.curBlock.id = IN.curBlock.lastFound
        if(IN.curBlock.id.value < 219 or IN.curBlock.id.value > 234) then return nil end
    end

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required)

    local isDyed = true

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_names") then
                if(IN.QueuedTE:contains("paletteEntry", TYPE.COMPOUND)) then
                    IN.QueuedTE.paletteEntry = IN.QueuedTE.lastFound
                    if(IN.QueuedTE.paletteEntry:contains("name", TYPE.STRING)) then if(IN.QueuedTE.paletteEntry.lastFound.value ~= "minecraft:shulker_box") then isDyed = false end end
                end
            elseif(IN.QueuedTE.lastFound.value == "blocks_ids") then 
                if(IN.QueuedTE:contains("id", TYPE.SHORT)) then if(IN.QueuedTE.lastFound.value ~= 218) then isDyed = false end end
            end
        end
    end

    if(isDyed) then 
        if(IN.curBlock:contains("damage", TYPE.BYTE)) then
            IN.curBlock.damage = IN.curBlock.lastFound
            if(IN:contains("facing", TYPE.BYTE)) then
                IN.curBlock.damage.value = IN.lastFound.value
                IN.curBlock.save = true
            end
        end
    end

    return OUT
end

function TileEntity:ConvertSign(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 63 and IN.curBlock.lastFound.value ~= 68) then return nil end end


    if(required) then
        OUT:addChild(TagByte.new("Verified", true))
        OUT:addChild(TagByte.new("Censored"))
    end

    if(IN:contains("Text", TYPE.STRING)) then
        OUT.Text1 = OUT:addChild(TagString.new("Text1"))
        OUT.Text2 = OUT:addChild(TagString.new("Text2"))
        OUT.Text3 = OUT:addChild(TagString.new("Text3"))
        OUT.Text4 = OUT:addChild(TagString.new("Text4"))
        local lineNum = 0
        for line in IN.lastFound.value:gmatch("([^\n]*)\n?") do
            if(line:len() < 16) then
                if(lineNum == 0) then OUT.Text1.value = line
                elseif(lineNum == 1) then OUT.Text2.value = line
                elseif(lineNum == 2) then OUT.Text3.value = line
                elseif(lineNum == 3) then OUT.Text4.value = line
                else break end
            end
            lineNum = lineNum + 1
        end
    elseif(required) then
        OUT:addChild(TagString.new("Text1"))
        OUT:addChild(TagString.new("Text2"))
        OUT:addChild(TagString.new("Text3"))
        OUT:addChild(TagString.new("Text4"))
    end
    return OUT
end

function TileEntity:ConvertSkull(IN, OUT, required)
    if(IN.curBlock:contains("id", TYPE.SHORT)) then if(IN.curBlock.lastFound.value ~= 144) then return nil end end

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