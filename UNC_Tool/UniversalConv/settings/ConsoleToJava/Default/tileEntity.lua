TileEntity = {}
Item = Item or require("item")
Entity = Entity or require("entity")

function TileEntity:ConvertTileEntity(IN)
    local OUT = TagCompound.new()

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

        --keepPacked (unknown use)
        OUT:addChild(TagByte.new("keepPacked", false))
        
        --Convert
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
        if(IN.QueuedTE:contains("x", TYPE.INT)) then OUT.x.value = IN.QueuedTE.lastFound.value else return nil end
        if(IN.QueuedTE:contains("y", TYPE.INT)) then OUT.y.value = IN.QueuedTE.lastFound.value else return nil end
        if(IN.QueuedTE:contains("z", TYPE.INT)) then OUT.z.value = IN.QueuedTE.lastFound.value else return nil end

        local blockX = OUT.x.value
        local blockY = OUT.y.value
        local blockZ = OUT.z.value

        IN.curBlock = Chunk:getBlock(blockX, blockY, blockZ)
        IN.curBlock.save = false

        local id = ""

        --keepPacked (unknown use)
        OUT:addChild(TagByte.new("keepPacked", false))

        --Identify queue type
        if(IN.QueuedTE:contains("dataTableName", TYPE.STRING)) then
            if(IN.QueuedTE.lastFound.value == "blocks_ids") then

                if(IN.QueuedTE:contains("id", TYPE.SHORT)) then
                    local blockId = IN.QueuedTE.lastFound.value

                    if(blockId == 23) then id = "dispenser"
                    elseif(blockId == 26) then id = "bed"
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
            OUT:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            OUT = TileEntity[entry[1][2]](TileEntity, IN, OUT, true)
        else return nil end

        if(IN.curBlock.save) then Chunk:setBlock(blockX, blockY, blockZ, IN.curBlock) end
    end

return OUT
end

function TileEntity:ConvertBanner(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end

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

    if(IN:contains("Base", TYPE.INT)) then
        local BaseNum = IN.lastFound.value
        if(BaseNum >= 0 and BaseNum <= 15) then
            if(IN.curBlock:contains("Name", TYPE.STRING)) then
                IN.curBlock.Name = IN.curBlock.lastFound

                local wallString = ""
                if(IN.curBlock.Name.value:find("wall_banner$")) then wallString = "_wall" end

                if(BaseNum == 15) then IN.curBlock.Name.value = "minecraft:white" .. wallString .. "_banner"
                elseif(BaseNum == 14) then IN.curBlock.Name.value = "minecraft:orange" .. wallString .. "_banner"
                elseif(BaseNum == 13) then IN.curBlock.Name.value = "minecraft:magenta" .. wallString .. "_banner"
                elseif(BaseNum == 12) then IN.curBlock.Name.value = "minecraft:light_blue" .. wallString .. "_banner"
                elseif(BaseNum == 11) then IN.curBlock.Name.value = "minecraft:yellow" .. wallString .. "_banner"
                elseif(BaseNum == 10) then IN.curBlock.Name.value = "minecraft:lime" .. wallString .. "_banner"
                elseif(BaseNum == 9) then IN.curBlock.Name.value = "minecraft:pink" .. wallString .. "_banner"
                elseif(BaseNum == 8) then IN.curBlock.Name.value = "minecraft:gray" .. wallString .. "_banner"
                elseif(BaseNum == 7) then IN.curBlock.Name.value = "minecraft:light_gray" .. wallString .. "_banner"
                elseif(BaseNum == 6) then IN.curBlock.Name.value = "minecraft:cyan" .. wallString .. "_banner"
                elseif(BaseNum == 5) then IN.curBlock.Name.value = "minecraft:purple" .. wallString .. "_banner"
                elseif(BaseNum == 4) then IN.curBlock.Name.value = "minecraft:blue" .. wallString .. "_banner"
                elseif(BaseNum == 3) then IN.curBlock.Name.value = "minecraft:brown" .. wallString .. "_banner"
                elseif(BaseNum == 2) then IN.curBlock.Name.value = "minecraft:green" .. wallString .. "_banner"
                elseif(BaseNum == 1) then IN.curBlock.Name.value = "minecraft:red" .. wallString .. "_banner"
                elseif(BaseNum == 0) then IN.curBlock.Name.value = "minecraft:black" .. wallString .. "_banner"
                end

                IN.curBlock.save = true
            end
        end
    end

    return OUT
end

function TileEntity:ConvertBeacon(IN, OUT, required)
    if(IN:contains("Levels", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Levels", 0)) end
    if(IN:contains("Primary", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Primary", 0)) end
    if(IN:contains("Secondary", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Secondary", 0)) end
    return OUT
end

function TileEntity:ConvertBed(IN, OUT, required)
    if(IN:contains("color", TYPE.INT)) then
        local colorNum = IN.lastFound.value
        if(colorNum >= 0 and colorNum <= 15) then
            if(IN.curBlock:contains("Name", TYPE.STRING)) then
                IN.curBlock.Name = IN.curBlock.lastFound

                if(colorNum == 0) then IN.curBlock.Name.value = "minecraft:white_bed"
                elseif(colorNum == 1) then IN.curBlock.Name.value = "minecraft:orange_bed"
                elseif(colorNum == 2) then IN.curBlock.Name.value = "minecraft:magenta_bed"
                elseif(colorNum == 3) then IN.curBlock.Name.value = "minecraft:light_blue_bed"
                elseif(colorNum == 4) then IN.curBlock.Name.value = "minecraft:yellow_bed"
                elseif(colorNum == 5) then IN.curBlock.Name.value = "minecraft:lime_bed"
                elseif(colorNum == 6) then IN.curBlock.Name.value = "minecraft:pink_bed"
                elseif(colorNum == 7) then IN.curBlock.Name.value = "minecraft:gray_bed"
                elseif(colorNum == 8) then IN.curBlock.Name.value = "minecraft:light_gray_bed"
                elseif(colorNum == 9) then IN.curBlock.Name.value = "minecraft:cyan_bed"
                elseif(colorNum == 10) then IN.curBlock.Name.value = "minecraft:purple_bed"
                elseif(colorNum == 11) then IN.curBlock.Name.value = "minecraft:blue_bed"
                elseif(colorNum == 12) then IN.curBlock.Name.value = "minecraft:brown_bed"
                elseif(colorNum == 13) then IN.curBlock.Name.value = "minecraft:green_bed"
                elseif(colorNum == 14) then IN.curBlock.Name.value = "minecraft:red_bed"
                elseif(colorNum == 15) then IN.curBlock.Name.value = "minecraft:black_bed"
                end

                IN.curBlock.save = true
            end
        end
    end

    return OUT
end

function TileEntity:ConvertBrewingStand(IN, OUT, required)
    if(required) then OUT:addChild(TagString.new("Lock")) end
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("Fuel", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("Fuel", false)) end
    if(IN:contains("BrewTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BrewTime", 0)) end
    return OUT
end

function TileEntity:ConvertChest(IN, OUT, required)
    if(IN.curBlock:contains("Name", TYPE.STRING)) then
        local blockName = IN.curBlock.lastFound.value
        if(blockName ~= "minecraft:chest" and blockName ~= "minecraft:trapped_chest") then
            return nil
        else
            if(OUT:contains("id", TYPE.STRING)) then
                OUT.lastFound.value = blockName
            elseif(required) then
                OUT:addChild(TagString.new("id", blockName))
            end
        end
    else
        return nil
    end

    if(required) then OUT:addChild(TagString.new("Lock")) end
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, false)
    if(IN:contains("LootTableSeed", TYPE.LONG)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("LootTable", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    return OUT
end

function TileEntity:ConvertComparator(IN, OUT, required)
    if(IN:contains("OutputSignal", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("OutputSignal", 0)) end
    return OUT
end

function TileEntity:ConvertConduit(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertDaylightDetector(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertDispenser(IN, OUT, required)
    if(required) then OUT:addChild(TagString.new("Lock")) end
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertDropper(IN, OUT, required)
    if(required) then OUT:addChild(TagString.new("Lock")) end
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertEnchantmentTable(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    return OUT
end

function TileEntity:ConvertEnderChest(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertEndGateway(IN, OUT, required)
    if(IN:contains("Age", TYPE.LONG)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagLong.new("Age", 0)) end
    if(IN:contains("ExactTeleport", TYPE.BYTE)) then OUT:addChild(TagByte.new("ExactTeleport", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("ExactTeleport", false)) end

    containsExitPortal = false
    if(IN:contains("ExitPortal", TYPE.COMPOUND)) then
        IN.ExitPortal = IN.lastFound
        if(IN.ExitPortal:contains("X", TYPE.INT) and IN.ExitPortal:contains("Y", TYPE.INT) and IN.ExitPortal:contains("Z", TYPE.INT)) then
            containsExitPortal = true
            OUT.ExitPortal = OUT:addChild(TagCompound.new("ExitPortal"))
            if(IN.ExitPortal:contains("X", TYPE.INT)) then OUT.ExitPortal:addChild(TagInt.new("X", IN.ExitPortal.lastFound.value)) end
            if(IN.ExitPortal:contains("Y", TYPE.INT)) then OUT.ExitPortal:addChild(TagInt.new("Y", IN.ExitPortal.lastFound.value)) end
            if(IN.ExitPortal:contains("Z", TYPE.INT)) then OUT.ExitPortal:addChild(TagInt.new("Z", IN.ExitPortal.lastFound.value)) end
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
    return OUT
end

function TileEntity:ConvertFlowerPot(IN, OUT, required)
    if(IN.curBlock:contains("Name", TYPE.STRING)) then IN.curBlock.Name = IN.curBlock.lastFound else return nil end
    local itemId = ""
    local itemData = ""
    if(IN:contains("Item", TYPE.INT)) then
        itemId = tostring(IN.lastFound.value)
    end
    if(IN:contains("Data", TYPE.INT)) then itemData = tostring(IN.lastFound.value) end

    local ChunkVersion = Settings:getSettingInt("ChunkVersion")

    if(Settings:dataTableContains("blocks_ids", itemId)) then
        local entry = Settings.lastFound

        local flowerName = ""
        for index, _ in ipairs(entry) do
            local subEntry = entry[index]
            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
            if(subEntry[2]:len() ~= 0) then if(subEntry[2] ~= itemData) then goto entryContinue end end
            flowerName = entry[index][3]
            break
            ::entryContinue::
        end

        if(flowerName:len() == 0) then return nil end

        if(flowerName == "dandelion") then IN.curBlock.Name = "minecraft:potted_dandelion"
        elseif(flowerName == "poppy") then IN.curBlock.Name = "minecraft:potted_poppy"
        elseif(flowerName == "blue_orchid") then IN.curBlock.Name = "minecraft:potted_blue_orchid"
        elseif(flowerName == "allium") then IN.curBlock.Name = "minecraft:potted_allium"
        elseif(flowerName == "azure_bluet") then IN.curBlock.Name = "minecraft:potted_azure_bluet"
        elseif(flowerName == "red_tulip") then IN.curBlock.Name = "minecraft:potted_red_tulip"
        elseif(flowerName == "orange_tulip") then IN.curBlock.Name = "minecraft:potted_orange_tulip"
        elseif(flowerName == "white_tulip") then IN.curBlock.Name = "minecraft:potted_white_tulip"
        elseif(flowerName == "pink_tulip") then IN.curBlock.Name = "minecraft:potted_pink_tulip"
        elseif(flowerName == "oxeye_daisy") then IN.curBlock.Name = "minecraft:potted_oxeye_daisy"
        elseif(flowerName == "oak_sapling") then IN.curBlock.Name = "minecraft:potted_oak_sapling"
        elseif(flowerName == "spruce_sapling") then IN.curBlock.Name = "minecraft:potted_spruce_sapling"
        elseif(flowerName == "birch_sapling") then IN.curBlock.Name = "minecraft:potted_birch_sapling"
        elseif(flowerName == "jungle_sapling") then IN.curBlock.Name = "minecraft:potted_jungle_sapling"
        elseif(flowerName == "acacia_sapling") then IN.curBlock.Name = "minecraft:potted_acacia_sapling"
        elseif(flowerName == "dark_oak_sapling") then IN.curBlock.Name = "minecraft:potted_dark_oak_sapling"
        elseif(flowerName == "red_mushroom") then IN.curBlock.Name = "minecraft:potted_red_mushroom"
        elseif(flowerName == "brown_mushroom") then IN.curBlock.Name = "minecraft:potted_brown_mushroom"
        elseif(flowerName == "fern") then IN.curBlock.Name = "minecraft:potted_fern"
        elseif(flowerName == "dead_bush") then IN.curBlock.Name = "minecraft:potted_dead_bush"
        elseif(flowerName == "cactus") then IN.curBlock.Name = "minecraft:potted_cactus"
        else return nil
        end

        IN.curBlock.save = true
    end

    --delete tile entity since it isn't used on Java
    return nil
end

function TileEntity:ConvertFurnace(IN, OUT, required)
    if(required) then OUT:addChild(TagString.new("Lock")) end
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end
    if(IN:contains("CookTimeTotal", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTimeTotal")) end

    if(required) then 
        OUT.RecipesUsedSize = OUT:addChild(TagShort.new("RecipesUsedSize"))
        --TODO convert CharcoalUsed into RecipesUsedSize if you can
    end
    return OUT
end

function TileEntity:ConvertHopper(IN, OUT, required)
    if(required) then OUT:addChild(TagString.new("Lock")) end
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

    if(IN:contains("SpawnData", TYPE.COMPOUND)) then
        local SpawnData = Entity:ConvertEntity(IN.lastFound, false)
        if(SpawnData ~= nil) then
            SpawnData.name = "SpawnData"
            OUT.SpawnData = OUT:addChild(SpawnData)
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
            --old java format was never used on console
            if(spawnPotential_in:contains("Entity", TYPE.COMPOUND)) then
                local Entity_out = Entity:ConvertEntity(spawnPotential_in.lastFound, false)
                if(Entity_out ~= nil) then
                    Entity_out.name = "Entity"
                    spawnPotential_out:addChild(Entity_out)
                else goto spawnPotentialContinue end
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

function TileEntity:ConvertPiston(IN, OUT, required)

    if(IN:contains("progress", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("progress")) end
    if(IN:contains("extending", TYPE.BYTE)) then OUT:addChild(OUT:addChild(TagByte.new("extending", IN.lastFound.value ~= 0))) elseif(required) then OUT:addChild(TagByte.new("extending", true)) end
    if(IN:contains("source", TYPE.BYTE)) then OUT:addChild(OUT:addChild(TagByte.new("source", IN.lastFound.value ~= 0)))
    elseif(required) then
        if(IN.curBlock:contains("Name", TYPE.STRING)) then OUT:addChild(TagByte.new("source", IN.curBlock.lastFound.value == "minecraft:piston_head")) else return nil end
    end
    if(IN:contains("facing", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("facing")) end

    if(IN:contains("blockId", TYPE.INT)) then IN.blockId = IN.lastFound.value else IN.blockId = 0 end
    if(IN:contains("blockData", TYPE.INT)) then IN.blockData = IN.lastFound.value else IN.blockData = 0 end

    local ChunkVersion = Settings:getSettingInt("ChunkVersion")

    local Name = "air"
    OUT.blockState = OUT:addChild(TagCompound.new("blockState"))

    if(Settings:dataTableContains("blocks_ids", tostring(IN.blockId)) and IN.blockId ~= 0) then
        local entry = Settings.lastFound

        local contains = false
        for index, _ in ipairs(entry) do
            local subEntry = entry[index]
            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
            if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.blockData) then goto entryContinue end end
            contains = true
            Name = subEntry[3]
            local Properties = Item:StringToProperties(subEntry[4])
            if(Properties ~= nil) then OUT.blockState:addChild(Properties) end
            break
            ::entryContinue::
        end
        if(not contains) then return nil end
    else return nil end

    OUT.blockState:addChild(TagString.new("Name", "minecraft:" .. Name))

    return OUT
end

function TileEntity:ConvertNoteBlock(IN, OUT, required)
    if(IN.curBlock:contains("Name", TYPE.STRING)) then if(IN.curBlock.lastFound.value ~= "minecraft:note_block") then return nil end else return nil end
    if(IN.curBlock:contains("Properties", TYPE.COMPOUND)) then IN.curBlock.Properties = IN.curBlock.lastFound else IN.curBlock.Properties = IN.curBlock:addChild(TagCompound.new("Properties")) end
    if(IN.curBlock.Properties:contains("note", TYPE.STRING)) then IN.curBlock.Properties.note = IN.curBlock.Properties.lastFound else IN.curBlock.Properties.note = IN.curBlock.Properties:addChild(TagString.new("note", "0")) end
    if(IN.curBlock.Properties:contains("powered", TYPE.STRING)) then IN.curBlock.Properties.powered = IN.curBlock.Properties.lastFound else IN.curBlock.Properties.powered = IN.curBlock.Properties:addChild(TagString.new("powered", "false")) end
    if(IN:contains("note", TYPE.BYTE)) then IN.curBlock.Properties.note.value = tostring(IN.lastFound.value) else IN.curBlock.Properties.note.value = "0" end
    if(IN:contains("powered", TYPE.BYTE)) then IN.curBlock.Properties.powered.value = tostring(IN.lastFound.value) else IN.curBlock.Properties.powered.value = "false" end

    IN.curBlock.save = true
    --delete tile entity since it isn't used on Java
    return nil
end

function TileEntity:ConvertShulkerBox(IN, OUT, required)
    if(required) then OUT:addChild(TagString.new("Lock")) end
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertSign(IN, OUT, required)
    if(IN:contains("Text1", TYPE.STRING)) then
        local text = IN.lastFound.value
        text = text:gsub('\\', "\\\\")
        text = text:gsub('\n', "\\n")
        text = text:gsub('\"', "\\\"")
        OUT:addChild(TagString.new("Text1", "{\"text\":\"" .. text .. "\"}"))
    elseif(required) then OUT:addChild(TagString.new("Text1")) end
    if(IN:contains("Text2", TYPE.STRING)) then
        local text = IN.lastFound.value
        text = text:gsub('\\', "\\\\")
        text = text:gsub('\n', "\\n")
        text = text:gsub('\"', "\\\"")
        OUT:addChild(TagString.new("Text2", "{\"text\":\"" .. text .. "\"}"))
    elseif(required) then OUT:addChild(TagString.new("Text2")) end
    if(IN:contains("Text3", TYPE.STRING)) then
        local text = IN.lastFound.value
        text = text:gsub('\\', "\\\\")
        text = text:gsub('\n', "\\n")
        text = text:gsub('\"', "\\\"")
        OUT:addChild(TagString.new("Text3", "{\"text\":\"" .. text .. "\"}"))
    elseif(required) then OUT:addChild(TagString.new("Text3")) end
    if(IN:contains("Text4", TYPE.STRING)) then
        local text = IN.lastFound.value
        text = text:gsub('\\', "\\\\")
        text = text:gsub('\n', "\\n")
        text = text:gsub('\"', "\\\"")
        OUT:addChild(TagString.new("Text4", "{\"text\":\"" .. text .. "\"}"))
    elseif(required) then OUT:addChild(TagString.new("Text4")) end
    return OUT
end

function TileEntity:ConvertSkull(IN, OUT, required)

    if(IN.curBlock:contains("Name", TYPE.STRING)) then IN.curBlock.Name = IN.curBlock.lastFound else return OUT end
    
    local skullType = 0
    if(IN:contains("SkullType", TYPE.BYTE)) then
        skullType = IN.lastFound.value
        if(skullType > 5 or skullType < 0) then skullType = 0 end
    end

    local skullName = IN.curBlock.Name.value
    if(skullName:find("^minecraft:")) then skullName = skullName:sub(11) end

    if(skullName == "skeleton_skull") then
        local rotation = 0
        if(IN:contains("Rot", TYPE.BYTE)) then
            rotation = IN.lastFound.value
            if(rotation > 15) then rotation = 0 end
        end
        if(IN.curBlock:contains("Properties", TYPE.COMPOUND)) then IN.curBlock.Properties = IN.curBlock.lastFound else IN.curBlock.Properties = IN.curBlock:addChild(TagCompound.new("Properties")) end
        if(IN.curBlock.Properties:contains("rotation", TYPE.STRING)) then IN.curBlock.Properties.lastFound.value = tostring(rotation) else IN.curBlock.Properties:addChild(TagString.new("rotation", tostring(rotation))) end
    
        if(skullType == 0) then IN.curBlock.Name.value = "minecraft:skeleton_skull"
        elseif (skullType == 1) then IN.curBlock.Name.value = "minecraft:wither_skeleton_skull"
        elseif (skullType == 2) then IN.curBlock.Name.value = "minecraft:zombie_head"
        elseif (skullType == 3) then IN.curBlock.Name.value = "minecraft:player_head"
        elseif (skullType == 4) then IN.curBlock.Name.value = "minecraft:creeper_head"
        elseif (skullType == 5) then IN.curBlock.Name.value = "minecraft:dragon_head"
        end
    elseif (skullName == "skeleton_wall_skull") then
        if(skullType == 0) then IN.curBlock.Name.value = "minecraft:skeleton_wall_skull"
        elseif (skullType == 1) then IN.curBlock.Name.value = "minecraft:wither_skeleton_wall_skull"
        elseif (skullType == 2) then IN.curBlock.Name.value = "minecraft:zombie_wall_head"
        elseif (skullType == 3) then IN.curBlock.Name.value = "minecraft:player_wall_head"
        elseif (skullType == 4) then IN.curBlock.Name.value = "minecraft:creeper_wall_head"
        elseif (skullType == 5) then IN.curBlock.Name.value = "minecraft:dragon_wall_head"
        end
    else return OUT end

    IN.curBlock.save = true
    return OUT
end

--------------------------------Base Functions

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