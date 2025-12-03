TileEntity = {}
Item = Item or require("item")
Entity = Entity or require("entity")
Utils = Utils or require("utils")

function TileEntity:ConvertTileEntity(IN, required)
    OUT = TagCompound.new()

    local id = ""
    if(IN:contains("id", TYPE.STRING)) then
        id = IN.lastFound.value
        if(id:find("^minecraft:")) then id = id:sub(11) end
    elseif(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("id", TYPE.SHORT)) then
            local blockId = IN.QueuedTE.lastFound.value

            if(blockId == 119) then id = "end_portal"
            end

        elseif(IN.QueuedTE:contains("id", TYPE.STRING)) then
            local blockId = IN.QueuedTE.lastFound.value

            if(blockId == "end_portal") then id = "end_portal"
            end

        end
    end
    if(id:len() == 0) then return nil end

    if(IN:contains("x", TYPE.INT)) then OUT.x = OUT:addChild(TagInt.new("x", IN.lastFound.value)) else return nil end
    if(IN:contains("y", TYPE.INT)) then OUT.y = OUT:addChild(TagInt.new("y", IN.lastFound.value)) else return nil end
    if(IN:contains("z", TYPE.INT)) then OUT.z = OUT:addChild(TagInt.new("z", IN.lastFound.value)) else return nil end
    local blockX = OUT.x.value
    local blockY = OUT.y.value
    local blockZ = OUT.z.value
    IN.curBlock = Chunk:getBlock(blockX, blockY, blockZ)
    IN.curBlock.save = false

    --keepPacked (unknown use)
    OUT:addChild(TagByte.new("keepPacked", false))

    if(Settings:dataTableContains("tileEntities", id)) then
        local entry = Settings.lastFound
        OUT:addChild(TagString.new("id", entry[1][1]))
        OUT = TileEntity[entry[1][2]](TileEntity, IN, OUT, true)
    else return nil end

    if(IN.curBlock.save) then Chunk:setBlock(blockX, blockY, blockZ, IN.curBlock) end

    return OUT
end

function TileEntity:ConvertBanner(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT.CustomName = OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end

    if(IN:contains("Type", TYPE.INT)) then
        if(IN.lastFound.value ~= 0) then
            OUT.Patterns = OUT:addChild(TagList.new("Patterns"))

            local pat1 = OUT.Patterns:addChild(TagCompound.new())
            pat1:addChild(TagString.new("Pattern", "mr"))
            pat1:addChild(TagInt.new("Color", 9))

            local pat2 = OUT.Patterns:addChild(TagCompound.new())
            pat2:addChild(TagString.new("Pattern", "bs"))
            pat2:addChild(TagInt.new("Color", 8))

            local pat3 = OUT.Patterns:addChild(TagCompound.new())
            pat3:addChild(TagString.new("Pattern", "cs"))
            pat3:addChild(TagInt.new("Color", 7))

            local pat4 = OUT.Patterns:addChild(TagCompound.new())
            pat4:addChild(TagString.new("Pattern", "bo"))
            pat4:addChild(TagInt.new("Color", 8))

            local pat5 = OUT.Patterns:addChild(TagCompound.new())
            pat5:addChild(TagString.new("Pattern", "ms"))
            pat5:addChild(TagInt.new("Color", 15))

            local pat6 = OUT.Patterns:addChild(TagCompound.new())
            pat6:addChild(TagString.new("Pattern", "hh"))
            pat6:addChild(TagInt.new("Color", 8))

            local pat7 = OUT.Patterns:addChild(TagCompound.new())
            pat7:addChild(TagString.new("Pattern", "mc"))
            pat7:addChild(TagInt.new("Color", 8))

            local pat8 = OUT.Patterns:addChild(TagCompound.new())
            pat8:addChild(TagString.new("Pattern", "bo"))
            pat8:addChild(TagInt.new("Color", 15))

            if(OUT.CustomName == nil) then OUT.CustomName = OUT:addChild(TagString.new("CustomName")) end

            OUT.CustomName.value = "{\"color\":\"gold\",\"translate\":\"block.minecraft.ominous_banner\"}"

            return OUT
        end
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
                if(in_Pattern.Color.value >= 0 and in_Pattern.Color.value <= 15) then out_Pattern.Color.value = 15 - in_Pattern.Color.value end
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

function TileEntity:ConvertBarrel(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertBeacon(IN, OUT, required)
    if(IN:contains("primary", TYPE.INT)) then OUT:addChild(TagInt.new("Primary", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("Primary")) end
    if(IN:contains("secondary", TYPE.INT)) then OUT:addChild(TagInt.new("Secondary", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("Secondary")) end
    if(required) then OUT:addChild(TagInt.new("Levels", 1)) end
    return OUT
end

function TileEntity:ConvertBed(IN, OUT, required)

    if(IN.curBlock:contains("Name", TYPE.STRING)) then IN.curBlock.Name = IN.curBlock.lastFound else IN.curBlock.Name = IN.curBlock:addChild(TagString.new("Name", "minecraft:red_bed")) end

    if(IN:contains("color", TYPE.BYTE)) then
        local color = IN.lastFound.value
        if(color < 0 or color > 15) then color = 0 end

        if(color == 0) then IN.curBlock.Name.value = "minecraft:white_bed"
        elseif(color == 1) then IN.curBlock.Name.value = "minecraft:orange_bed"
        elseif(color == 2) then IN.curBlock.Name.value = "minecraft:magenta_bed"
        elseif(color == 3) then IN.curBlock.Name.value = "minecraft:light_blue_bed"
        elseif(color == 4) then IN.curBlock.Name.value = "minecraft:yellow_bed"
        elseif(color == 5) then IN.curBlock.Name.value = "minecraft:lime_bed"
        elseif(color == 6) then IN.curBlock.Name.value = "minecraft:pink_bed"
        elseif(color == 7) then IN.curBlock.Name.value = "minecraft:gray_bed"
        elseif(color == 8) then IN.curBlock.Name.value = "minecraft:light_gray_bed"
        elseif(color == 9) then IN.curBlock.Name.value = "minecraft:cyan_bed"
        elseif(color == 10) then IN.curBlock.Name.value = "minecraft:purple_bed"
        elseif(color == 11) then IN.curBlock.Name.value = "minecraft:blue_bed"
        elseif(color == 12) then IN.curBlock.Name.value = "minecraft:brown_bed"
        elseif(color == 13) then IN.curBlock.Name.value = "minecraft:green_bed"
        elseif(color == 14) then IN.curBlock.Name.value = "minecraft:red_bed"
        elseif(color == 15) then IN.curBlock.Name.value = "minecraft:black_bed"
        end

        IN.curBlock.save = true
    end
    return OUT
end

function TileEntity:ConvertBeehive(IN, OUT, required)

    if(IN:contains("Occupants", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Occupants = IN.lastFound

        OUT.Bees = OUT:addChild(TagList.new("Bees"))

        for i=0, IN.Occupants.childCount-1 do
            local bee_in = IN.Occupants:child(i)
            local bee_out = TagCompound.new()

            if(bee_in:contains("SaveData", TYPE.COMPOUND)) then
                local beeEntity = Entity:ConvertEntity(bee_in.lastFound, true)
                if(beeEntity == nil) then goto beeContinue end
                beeEntity.name = "EntityData"
                bee_out:addChild(beeEntity)
            else goto beeContinue end

            OUT.Bees:addChild(bee_out)

            ::beeContinue::
        end

        if(OUT.Bees.childCount == 0) then
            OUT:removeChild(OUT.Bees:getRow())
            OUT.Bees = nil
        end
    end

    return OUT
end

function TileEntity:ConvertBell(IN, OUT, required)

    --TODO check if java requires tags

    return OUT
end

function TileEntity:ConvertBlastFurnace(IN, OUT, required)

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end 

    if(required) then 
        --TODO identify use of BurnDuration and StoredXP
        OUT:addChild(TagShort.new("CookTimeTotal"))
        OUT:addChild(TagShort.new("RecipesUsedSize"))
    end

    return OUT
end

function TileEntity:ConvertBrewingStand(IN, OUT, required)

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)

    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(TagShort.new("BrewTime", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("BrewTime", 0)) end
    if(IN:contains("FuelAmount", TYPE.SHORT)) then OUT:addChild(TagByte.new("Fuel", IN.lastFound.value)) elseif(required) then OUT:addChild(TagByte.new("Fuel")) end
    return OUT
end

function TileEntity:ConvertCampfire(IN, OUT, required)

    --TileEntity:ConvertItems(IN, OUT, required, true)

    --TODO TileEntity:Convert item times into int arrays

    return OUT
end

function TileEntity:ConvertCauldron(IN, OUT, required)

    return nil
end

function TileEntity:ConvertChest(IN, OUT, required)

    if(required) then 
        if(IN.curBlock:contains("Name", TYPE.STRING)) then
            local blockName = IN.curBlock.lastFound.value
            if(blockName ~= "minecraft:chest" and blockName ~= "minecraft:trapped_chest") then
                return nil
            else
                if(OUT:contains("id", TYPE.STRING)) then OUT.lastFound.value = blockName end
            end
        else
            return nil
        end
    end

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertCommandBlock(IN, OUT, required)

    --TODO add option to let UMC process commands
    --Copy things for now

    --BEDROCK
    --auto byte
    --conditionMet byte
    --ExecuteOnFirstTick byte
    --LPConditionalMode byte
    --LPRedstoneMode byte
    --powered byte
    --TrackOutput byte
    --LPCommandMode int
    --SuccessCount int
    --TickDelay int
    --Version int (10)
    --LastExecution long (timestamp?)
    --Command string
    --CustomName string
    --LastOutput string
    --LastOutputParams list

    --JAVA
    --auto byte
    --conditionMet byte
    --powered byte
    --TrackOutput byte
    --UpdateLastExecution byte
    --SuccessCount int
    --Command string
    --CustomName string (json)


    --AffectedBlocks
    --AffectedEntities
    --AffectedItems
    --QueryResult

    if(IN:contains("CustomName", TYPE.STRING)) then
        if(IN.lastFound.value:len() == 0) then 
            OUT:addChild(TagString.new("CustomName", "{\"text\":\"@\"}"))
        else
            if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
        end
    end

    if(IN:contains("Command", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagString.new("Command")) end

    if(IN:contains("auto", TYPE.BYTE)) then OUT:addChild(TagByte.new("auto", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("auto")) end

    if(IN:contains("conditionMet", TYPE.BYTE)) then OUT:addChild(TagByte.new("conditionMet", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("conditionMet")) end

    if(IN:contains("powered", TYPE.BYTE)) then OUT:addChild(TagByte.new("powered", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("powered")) end

    if(IN:contains("TrackOutput", TYPE.BYTE)) then OUT:addChild(TagByte.new("TrackOutput", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("TrackOutput")) end

    if(IN:contains("SuccessCount", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("SuccessCount")) end

    if(IN:contains("LastOutput", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagString.new("LastOutput")) end


    --store extra command settings for potential conversion back to java?
    --make this a GUI setting


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
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertDropper(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertEnchantmentTable(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertEnderChest(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertEndGateway(IN, OUT, required)

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

function TileEntity:ConvertEndPortal(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertFlowerPot(IN, OUT, required)

    if(IN.curBlock:contains("Name", TYPE.STRING)) then IN.curBlock.Name = IN.curBlock.lastFound else return nil end

    if(IN:contains("PlantBlock", TYPE.COMPOUND)) then
        IN.PlantBlock = IN.lastFound
        if(IN.PlantBlock:contains("name", TYPE.STRING)) then IN.PlantBlock.id = IN.PlantBlock.lastFound.value end

        if(IN.PlantBlock:contains("states", TYPE.COMPOUND)) then IN.PlantBlock.meta = IN.PlantBlock.lastFound
        elseif(IN.PlantBlock:contains("val", TYPE.SHORT)) then IN.PlantBlock.meta = IN.PlantBlock.lastFound end
    else return nil end

    --TODO support old numerical ids

    local flowerBlock = Utils:findBlock(IN.PlantBlock.id, IN.PlantBlock.meta)
    if(flowerBlock == nil) then return nil end
    if(flowerBlock.id == nil) then return nil end

    if(flowerBlock.id:find("^minecraft:")) then flowerBlock.id = flowerBlock.id:sub(11) end

    if(flowerBlock.id == "dandelion") then IN.curBlock.Name.value = "minecraft:potted_dandelion"
    elseif(flowerBlock.id == "poppy") then IN.curBlock.Name.value = "minecraft:potted_poppy"
    elseif(flowerBlock.id == "blue_orchid") then IN.curBlock.Name.value = "minecraft:potted_blue_orchid"
    elseif(flowerBlock.id == "allium") then IN.curBlock.Name.value = "minecraft:potted_allium"
    elseif(flowerBlock.id == "azure_bluet") then IN.curBlock.Name.value = "minecraft:potted_azure_bluet"
    elseif(flowerBlock.id == "red_tulip") then IN.curBlock.Name.value = "minecraft:potted_red_tulip"
    elseif(flowerBlock.id == "orange_tulip") then IN.curBlock.Name.value = "minecraft:potted_orange_tulip"
    elseif(flowerBlock.id == "white_tulip") then IN.curBlock.Name.value = "minecraft:potted_white_tulip"
    elseif(flowerBlock.id == "pink_tulip") then IN.curBlock.Name.value = "minecraft:potted_pink_tulip"
    elseif(flowerBlock.id == "oxeye_daisy") then IN.curBlock.Name.value = "minecraft:potted_oxeye_daisy"
    elseif(flowerBlock.id == "oak_sapling") then IN.curBlock.Name.value = "minecraft:potted_oak_sapling"
    elseif(flowerBlock.id == "spruce_sapling") then IN.curBlock.Name.value = "minecraft:potted_spruce_sapling"
    elseif(flowerBlock.id == "birch_sapling") then IN.curBlock.Name.value = "minecraft:potted_birch_sapling"
    elseif(flowerBlock.id == "jungle_sapling") then IN.curBlock.Name.value = "minecraft:potted_jungle_sapling"
    elseif(flowerBlock.id == "acacia_sapling") then IN.curBlock.Name.value = "minecraft:potted_acacia_sapling"
    elseif(flowerBlock.id == "dark_oak_sapling") then IN.curBlock.Name.value = "minecraft:potted_dark_oak_sapling"
    elseif(flowerBlock.id == "red_mushroom") then IN.curBlock.Name.value = "minecraft:potted_red_mushroom"
    elseif(flowerBlock.id == "brown_mushroom") then IN.curBlock.Name.value = "minecraft:potted_brown_mushroom"
    elseif(flowerBlock.id == "fern") then IN.curBlock.Name.value = "minecraft:potted_fern"
    elseif(flowerBlock.id == "dead_bush") then IN.curBlock.Name.value = "minecraft:potted_dead_bush"
    elseif(flowerBlock.id == "cactus") then IN.curBlock.Name.value = "minecraft:potted_cactus"
    elseif(flowerBlock.id == "wither_rose") then IN.curBlock.Name.value = "minecraft:potted_wither_rose"
    elseif(flowerBlock.id == "cornflower") then IN.curBlock.Name.value = "minecraft:potted_cornflower"
    elseif(flowerBlock.id == "lily_of_the_valley") then IN.curBlock.Name.value = "minecraft:potted_lily_of_the_valley"
    elseif(flowerBlock.id == "warped_roots") then IN.curBlock.Name.value = "minecraft:potted_warped_roots"
    elseif(flowerBlock.id == "warped_fungus") then IN.curBlock.Name.value = "minecraft:potted_warped_fungus"
    elseif(flowerBlock.id == "crimson_roots") then IN.curBlock.Name.value = "minecraft:potted_crimson_roots"
    elseif(flowerBlock.id == "crimson_fungus") then IN.curBlock.Name.value = "minecraft:potted_crimson_fungus"
    else return nil
    end

    IN.curBlock.save = true

    --delete tile entity since it isn't used on Java
    return nil
end

function TileEntity:ConvertFurnace(IN, OUT, required)

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end 

    if(required) then 
        --TODO identify use of BurnDuration and StoredXP
        OUT:addChild(TagShort.new("CookTimeTotal"))
        OUT:addChild(TagShort.new("RecipesUsedSize"))
    end
    return OUT
end

function TileEntity:ConvertHopper(IN, OUT, required)
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("TransferCooldown", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("TransferCooldown", 0)) end
    return OUT
end

function TileEntity:ConvertItemFrame(IN, OUT, required)

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then IN.QueuedTE = IN.lastFound else return nil end

    if(IN.QueuedTE:contains("id")) then IN.QueuedTE.id = IN.QueuedTE.lastFound else return nil end
    if(IN.QueuedTE:contains("meta")) then IN.QueuedTE.meta = IN.QueuedTE.lastFound else return nil end

    --convert to entity

    local EOUT = TagCompound.new()

    local facing = ""
    local isGlow = false

    if(IN.QueuedTE.id.type == TYPE.SHORT) then
        if(IN.QueuedTE.id.value ~= 199) then return nil end

        if(IN.QueuedTE.meta.type == TYPE.BYTE) then
            local val = IN.QueuedTE.meta.value
            if(val == 0 or val == 4) then facing = "east"
            elseif(val == 1 or val == 5) then facing = "west"
            elseif(val == 2 or val == 6) then facing = "south"
            elseif(val == 3 or val == 7) then facing = "north"
            end
        end
    elseif(IN.QueuedTE.id.type == TYPE.STRING) then
        local blockName = IN.QueuedTE.id.value
        if(blockName:find("^minecraft:")) then blockName = blockName:sub(11) end
        if(blockName == "frame") then 
            isGlow = false
        elseif(blockName == "glow_frame") then
            isGlow = true
        else return nil end

        if(IN.QueuedTE.meta.type == TYPE.SHORT) then
            local val = IN.QueuedTE.meta.value

            if(val == 0 or val == 4) then facing = "east"
            elseif(val == 1 or val == 5) then facing = "west"
            elseif(val == 2 or val == 6) then facing = "south"
            elseif(val == 3 or val == 7) then facing = "north"
            end
        elseif(IN.QueuedTE.meta.type == TYPE.COMPOUND) then
            if(IN.QueuedTE.meta:contains("facing_direction", TYPE.INT)) then
                local facing_direction = IN.QueuedTE.meta.lastFound.value

                if(facing_direction == 0) then facing = "down"
                elseif(facing_direction == 1) then facing = "up"
                elseif(facing_direction == 2) then facing = "north"
                elseif(facing_direction == 3) then facing = "south"
                elseif(facing_direction == 4) then facing = "west"
                elseif(facing_direction == 5) then facing = "east"
                end
            else return nil end
        end
    end

    if(facing == "") then return nil end

    if(isGlow) then
        EOUT:addChild(TagString.new("id", "minecraft:glow_item_frame"))
    else
        EOUT:addChild(TagString.new("id", "minecraft:item_frame"))
    end


    if(required) then
        --do position and rotation based on facing
        EOUT.Pos = EOUT:addChild(TagList.new("Pos"))
        EOUT.Pos:addChild(TagDouble.new("", OUT.x.value))
        EOUT.Pos:addChild(TagDouble.new("", OUT.y.value))
        EOUT.Pos:addChild(TagDouble.new("", OUT.z.value))

        EOUT.Rotation = EOUT:addChild(TagList.new("Rotation"))

        if(facing == "south") then
            EOUT.Pos:child(0).value = EOUT.Pos:child(0).value + 0.5
            EOUT.Pos:child(1).value = EOUT.Pos:child(1).value + 0.5
            EOUT.Pos:child(2).value = EOUT.Pos:child(2).value + 0.03125

            EOUT:addChild(TagByte.new("Facing", 3))

            EOUT.Rotation:addChild(TagDouble.new("", 0))
            EOUT.Rotation:addChild(TagDouble.new("", 0))
        elseif(facing == "north") then
            EOUT.Pos:child(0).value = EOUT.Pos:child(0).value + 0.5
            EOUT.Pos:child(1).value = EOUT.Pos:child(1).value + 0.5
            EOUT.Pos:child(2).value = EOUT.Pos:child(2).value + 0.96875

            EOUT:addChild(TagByte.new("Facing", 2))

            EOUT.Rotation:addChild(TagDouble.new("", 180))
            EOUT.Rotation:addChild(TagDouble.new("", 0))
        elseif(facing == "east") then
            EOUT.Pos:child(0).value = EOUT.Pos:child(0).value + 0.03125
            EOUT.Pos:child(1).value = EOUT.Pos:child(1).value + 0.5
            EOUT.Pos:child(2).value = EOUT.Pos:child(2).value + 0.5

            EOUT:addChild(TagByte.new("Facing", 5))

            EOUT.Rotation:addChild(TagDouble.new("", -90))
            EOUT.Rotation:addChild(TagDouble.new("", 0))
        elseif(facing == "west") then
            EOUT.Pos:child(0).value = EOUT.Pos:child(0).value + 0.96875
            EOUT.Pos:child(1).value = EOUT.Pos:child(1).value + 0.5
            EOUT.Pos:child(2).value = EOUT.Pos:child(2).value + 0.5

            EOUT:addChild(TagByte.new("Facing", 4))

            EOUT.Rotation:addChild(TagDouble.new("", 90))
            EOUT.Rotation:addChild(TagDouble.new("", 0))
        elseif(facing == "up") then
            EOUT.Pos:child(0).value = EOUT.Pos:child(0).value + 0.5
            EOUT.Pos:child(1).value = EOUT.Pos:child(1).value + 0.03125
            EOUT.Pos:child(2).value = EOUT.Pos:child(2).value + 0.5

            EOUT:addChild(TagByte.new("Facing", 1))

            EOUT.Rotation:addChild(TagDouble.new("", 0))
            EOUT.Rotation:addChild(TagDouble.new("", -90))
        elseif(facing == "down") then
            EOUT.Pos:child(0).value = EOUT.Pos:child(0).value + 0.5
            EOUT.Pos:child(1).value = EOUT.Pos:child(1).value + 0.96875
            EOUT.Pos:child(2).value = EOUT.Pos:child(2).value + 0.5

            EOUT:addChild(TagByte.new("Facing", 0))

            EOUT.Rotation:addChild(TagDouble.new("", 0))
            EOUT.Rotation:addChild(TagDouble.new("", 90))
        end

        EOUT.Motion = EOUT:addChild(TagList.new("Motion"))
        EOUT.Motion:addChild(TagDouble.new("", 0))
        EOUT.Motion:addChild(TagDouble.new("", 0))
        EOUT.Motion:addChild(TagDouble.new("", 0))

        EOUT:addChild(TagByte.new("Invulnerable"))
        EOUT:addChild(TagByte.new("OnGround"))
        EOUT:addChild(TagShort.new("Air", 300))
        EOUT:addChild(TagShort.new("Fire", -1))


        local dim = Settings:getSettingInt("Dimension")
        if(dim == 0) then EOUT:addChild(TagInt.new("Dimension", 0))
        elseif(dim == 1) then EOUT:addChild(TagInt.new("Dimension", -1))
        elseif(dim == 2) then EOUT:addChild(TagInt.new("Dimension", 1))
        end

        EOUT:addChild(TagInt.new("PortalCooldown"))
        EOUT:addChild(TagFloat.new("FallDistance"))

        EOUT:addChild(TagInt.new("TileX", OUT.x.value))
        EOUT:addChild(TagInt.new("TileY", OUT.y.value))
        EOUT:addChild(TagInt.new("TileZ", OUT.z.value))

        EOUT:addChild(TagLong.new("UUIDMost", math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295)))
        EOUT:addChild(TagLong.new("UUIDLeast", math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295)))
    end

    if(IN:contains("CustomName", TYPE.STRING)) then EOUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end

    if(IN:contains("ItemDropChance", TYPE.FLOAT)) then
        EOUT:addChild(TagFloat.new("ItemDropChance", IN.lastFound.value))
    elseif(required) then 
        EOUT:addChild(TagFloat.new("ItemDropChance", 1))
    end

    if(IN:contains("ItemRotation", TYPE.FLOAT)) then
        EOUT:addChild(TagByte.new("ItemRotation", IN.lastFound.value//45))
    elseif(required) then
        EOUT:addChild(TagByte.new("ItemRotation", 0))
    end

    if(IN:contains("Item", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "Item"
            EOUT:addChild(item)
        end
    end

    if(IN.Entities_output_ref ~= nil) then IN.Entities_output_ref:addChild(EOUT) end

    return nil
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

function TileEntity:ConvertLectern(IN, OUT, required)

    local hasBook = false
    if(IN:contains("book", TYPE.COMPOUND)) then
        IN.book = IN.lastFound
        local item = Item:ConvertItem(IN.book, false)
        if(item ~= nil) then
            item.name = "Book"
            OUT:addChild(item)
            hasBook = true
        end
    end

    if(hasBook) then
        if(IN.curBlock:contains("Properties", TYPE.COMPOUND)) then IN.curBlock.Properties = IN.curBlock.lastFound else IN.curBlock.Properties = IN.curBlock:addChild(TagCompound.new("Properties")) end
        if(IN.curBlock.Properties:contains("has_book", TYPE.STRING)) then IN.curBlock.Properties.lastFound.value = "true" else IN.curBlock.Properties:addChild(TagString.new("has_book", "true")) end
        IN.curBlock.save = true
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

    --TODO get old numerical id format

    if(IN:contains("EntityIdentifier", TYPE.STRING)) then
        local entityId = IN.lastFound.value
        if(entityId:find("^minecraft:")) then entityId = entityId:sub(11) end

        if(Settings:dataTableContains("entities_names", entityId)) then
            local entry = Settings.lastFound
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
    if(IN.curBlock:contains("Name", TYPE.STRING)) then if(IN.curBlock.lastFound.value ~= "minecraft:note_block") then return nil end else return nil end
    if(IN.curBlock:contains("Properties", TYPE.COMPOUND)) then IN.curBlock.Properties = IN.curBlock.lastFound else IN.curBlock.Properties = IN.curBlock:addChild(TagCompound.new("Properties")) end
    if(IN.curBlock.Properties:contains("note", TYPE.STRING)) then IN.curBlock.Properties.note = IN.curBlock.Properties.lastFound else IN.curBlock.Properties.note = IN.curBlock.Properties:addChild(TagString.new("note", "0")) end
    if(IN.curBlock.Properties:contains("powered", TYPE.STRING)) then IN.curBlock.Properties.powered = IN.curBlock.Properties.lastFound else IN.curBlock.Properties.powered = IN.curBlock.Properties:addChild(TagString.new("powered", "false")) end
    if(IN:contains("note", TYPE.BYTE)) then IN.curBlock.Properties.note.value = tostring(IN.lastFound.value) else IN.curBlock.Properties.note.value = "0" end

    IN.curBlock.save = true
    --delete tile entity since it isn't used on Java
    return nil
end

function TileEntity:ConvertPistonArm(IN, OUT, required)

    if(IN.curBlock:contains("Properties", TYPE.COMPOUND)) then IN.curBlock.Properties = IN.curBlock.lastFound else IN.curBlock.Properties = IN.curBlock:addChild(TagCompound.new("Properties")) end
    
    if(IN:contains("NewState", TYPE.BYTE)) then IN.NewState = IN.lastFound.value else IN.NewState = 0 end

    if(IN.curBlock.Properties:contains("extended", TYPE.STRING)) then
        if(IN.NewState == 1 or IN.NewState == 2) then IN.curBlock.Properties.lastFound.value = "true" else IN.curBlock.Properties.lastFound.value = "false" end
    else
        IN.curBlock.Properties:addChild(TagString.new("extended", "false"))
    end
    IN.curBlock.save = true

    if(IN.NewState == 1 or IN.NewState == 3) then

        if(required) then
            OUT.extending = OUT:addChild(TagByte.new("extending", IN.NewState == 1))
            OUT.source = OUT:addChild(TagByte.new("source", true))
            OUT.progress = OUT:addChild(TagFloat.new("progress"))
            OUT.facing = OUT:addChild(TagInt.new("facing"))
            OUT.blockState = OUT:addChild(IN.curBlock:clone())
            OUT.blockState.name = "blockState"
            
            if(IN:contains("Progress", TYPE.FLOAT)) then OUT.progress.value = IN.lastFound.value end

            if(IN.curBlock.Properties:contains("facing", TYPE.STRING)) then
                local facing = IN.curBlock.Properties.lastFound.value
                if(facing == "down") then OUT.facing.value = 0
                elseif(facing == "up") then OUT.facing.value = 1
                elseif(facing == "south") then OUT.facing.value = 2
                elseif(facing == "north") then OUT.facing.value = 3
                elseif(facing == "east") then OUT.facing.value = 4
                elseif(facing == "west") then OUT.facing.value = 5
                end
            end
        end

        if(IN.curBlock:contains("Name", TYPE.STRING)) then IN.curBlock.lastFound.value = "minecraft:moving_piston" else IN.curBlock:addChild(TagString.new("Name","minecraft:moving_piston")) end
        IN.curBlock.Properties:clear()

        IN.curBlock.Properties.pistonType = IN.curBlock.Properties:addChild(TagString.new("type", "normal"))
        if(IN:contains("Sticky", TYPE.BYTE)) then if(IN.lastFound.value == 0) then IN.curBlock.Properties.pistonType.value = "normal" else IN.curBlock.Properties.pistonType.value = "sticky" end end

        IN.curBlock.Properties.facing = IN.curBlock.Properties:addChild(TagString.new("facing", "up"))

        if(OUT.facing.value == 0) then IN.curBlock.Properties.facing.value = "down"
        elseif(OUT.facing.value == 1) then IN.curBlock.Properties.facing.value = "up"
        elseif(OUT.facing.value == 2) then IN.curBlock.Properties.facing.value = "south"
        elseif(OUT.facing.value == 3) then IN.curBlock.Properties.facing.value = "north"
        elseif(OUT.facing.value == 4) then IN.curBlock.Properties.facing.value = "east"
        elseif(OUT.facing.value == 5) then IN.curBlock.Properties.facing.value = "west"
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
        if(IN.movingBlock:contains("name", TYPE.STRING)) then IN.movingBlock.id = IN.movingBlock.lastFound.value end
        if(IN.movingBlock:contains("states", TYPE.COMPOUND)) then IN.movingBlock.meta = IN.movingBlock.lastFound end
        if(IN.movingBlock:contains("val", TYPE.SHORT)) then IN.movingBlock.meta = IN.movingBlock.lastFound end
    else return nil end

    --TODO support old numerical ids

    local movingBlock = Utils:findBlock(IN.movingBlock.id, IN.movingBlock.meta)
    if(movingBlock == nil) then return nil end
    if(movingBlock.id == nil) then return nil end
    if(movingBlock.id:find("^minecraft:")) then movingBlock.id = movingBlock.id:sub(11) end

    OUT.blockState = OUT:addChild(TagCompound.new("blockState"))
    OUT.blockState:addChild(TagString.new("Name", "minecraft:" .. movingBlock.id))
    local props = Utils:StringToProperties(OUT.meta)
    if(props ~= nil) then OUT:addChild(props) end

    return OUT
end

function TileEntity:ConvertShulkerBox(IN, OUT, required)

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)

    if(IN.curBlock:contains("Properties", TYPE.COMPOUND)) then IN.curBlock.Properties = IN.curBlock.lastFound else IN.curBlock.Properties = IN.curBlock:addChild(TagCompound.new("Properties")) end
    if(IN.curBlock.Properties:contains("facing", TYPE.STRING)) then IN.curBlock.Properties.facing = IN.curBlock.Properties.lastFound else IN.curBlock.Properties.facing = IN.curBlock.Properties:addChild(TagString.new("facing", "up")) end
    if(IN:contains("facing", TYPE.BYTE)) then
        local facing = IN.lastFound.value

        if(facing == 0) then IN.curBlock.Properties.facing.value = "down"
        elseif(facing == 1) then IN.curBlock.Properties.facing.value = "up"
        elseif(facing == 2) then IN.curBlock.Properties.facing.value = "north"
        elseif(facing == 3) then IN.curBlock.Properties.facing.value = "south"
        elseif(facing == 4) then IN.curBlock.Properties.facing.value = "west"
        elseif(facing == 5) then IN.curBlock.Properties.facing.value = "east"
        end
    end
    IN.curBlock.save = true
    return OUT
end

function TileEntity:ConvertSign(IN, OUT, required)

    if(required) then OUT:addChild(TagString.new("Color", "black")) end

    if(IN:contains("Text", TYPE.STRING)) then
        OUT.Text1 = OUT:addChild(TagString.new("Text1", "{\"text\":\"\"}"))
        OUT.Text2 = OUT:addChild(TagString.new("Text2", "{\"text\":\"\"}"))
        OUT.Text3 = OUT:addChild(TagString.new("Text3", "{\"text\":\"\"}"))
        OUT.Text4 = OUT:addChild(TagString.new("Text4", "{\"text\":\"\"}"))
        local lineNum = 0
        for line in IN.lastFound.value:gmatch("([^\n]*)\n?") do

            line = line:gsub('\\', "\\\\")

            if(lineNum == 0) then OUT.Text1.value = "{\"text\":\"" .. line .. "\"}"
            elseif(lineNum == 1) then OUT.Text2.value = "{\"text\":\"" .. line .. "\"}"
            elseif(lineNum == 2) then OUT.Text3.value = "{\"text\":\"" .. line .. "\"}"
            elseif(lineNum == 3) then OUT.Text4.value = "{\"text\":\"" .. line .. "\"}"
            else break end
            lineNum = lineNum + 1
        end
    elseif(IN:contains("Text1", TYPE.STRING)) then
        OUT.Text1 = OUT:addChild(TagString.new("Text1", "{\"text\":\"\"}"))
        OUT.Text2 = OUT:addChild(TagString.new("Text2", "{\"text\":\"\"}"))
        OUT.Text3 = OUT:addChild(TagString.new("Text3", "{\"text\":\"\"}"))
        OUT.Text4 = OUT:addChild(TagString.new("Text4", "{\"text\":\"\"}"))

        for i=0, 3 do
            if(IN:contains("Text" .. tostring(i+1), TYPE.STRING)) then
                local text = IN.lastFound.value
                text = text:gsub('\\', "\\\\")

                if(i == 0) then OUT.Text1.value = "{\"text\":\"" .. text .. "\"}"
                elseif(i == 1) then OUT.Text2.value = "{\"text\":\"" .. text .. "\"}"
                elseif(i == 2) then OUT.Text3.value = "{\"text\":\"" .. text .. "\"}"
                elseif(i == 3) then OUT.Text4.value = "{\"text\":\"" .. text .. "\"}"
                end
            end
        end
    elseif(required) then
        OUT:addChild(TagString.new("Text1", "{\"text\":\"\"}"))
        OUT:addChild(TagString.new("Text2", "{\"text\":\"\"}"))
        OUT:addChild(TagString.new("Text3", "{\"text\":\"\"}"))
        OUT:addChild(TagString.new("Text4", "{\"text\":\"\"}"))
    end

    return OUT
end

function TileEntity:ConvertSkull(IN, OUT, required)

    if(IN.curBlock:contains("Name", TYPE.STRING)) then IN.curBlock.Name = IN.curBlock.lastFound else return OUT end

    if(IN.curBlock.Name.value:find("^minecraft:")) then IN.curBlock.Name.value = IN.curBlock.Name.value:sub(11) end
    
    local skullType = 0
    if(IN:contains("SkullType", TYPE.BYTE)) then
        skullType = IN.lastFound.value
        if(skullType > 5 or skullType < 0) then skullType = 0 end
    end

    if(IN.curBlock.Name.value == "skeleton_skull") then
        local rotation = 0
        if(IN:contains("Rotation", TYPE.FLOAT)) then
            local rotationFloat = IN.lastFound.value

            if(rotationFloat > 180) then rotationFloat = rotationFloat - 360 end

            if(rotationFloat == 0) then rotation = 0
            elseif(rotationFloat == 22.5) then rotation = 1
            elseif(rotationFloat == 45) then rotation = 2
            elseif(rotationFloat == 67.5) then rotation = 3
            elseif(rotationFloat == 90) then rotation = 4
            elseif(rotationFloat == 112.5) then rotation = 5
            elseif(rotationFloat == 135) then rotation = 6
            elseif(rotationFloat == 157.5) then rotation = 7
            elseif(rotationFloat == 180) then rotation = 8
            elseif(rotationFloat == -157.5) then rotation = 9
            elseif(rotationFloat == -135) then rotation = 10
            elseif(rotationFloat == -112.5) then rotation = 11
            elseif(rotationFloat == -90) then rotation = 12
            elseif(rotationFloat == -67.5) then rotation = 13
            elseif(rotationFloat == -45) then rotation = 14
            elseif(rotationFloat == -22.5) then rotation = 15
            end

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
    elseif (IN.curBlock.Name.value == "skeleton_wall_skull") then
        if(skullType == 0) then IN.curBlock.Name.value = "minecraft:skeleton_wall_skull"
        elseif (skullType == 1) then IN.curBlock.Name.value = "minecraft:wither_skeleton_wall_skull"
        elseif (skullType == 2) then IN.curBlock.Name.value = "minecraft:zombie_wall_head"
        elseif (skullType == 3) then IN.curBlock.Name.value = "minecraft:player_wall_head"
        elseif (skullType == 4) then IN.curBlock.Name.value = "minecraft:creeper_wall_head"
        elseif (skullType == 5) then IN.curBlock.Name.value = "minecraft:dragon_wall_head"
        end
    end

    if(IN:contains("Rot", TYPE.BYTE)) then
        local rotation = IN.lastFound.value
        if(IN.curBlock:contains("Properties", TYPE.COMPOUND)) then IN.curBlock.Properties = IN.curBlock.lastFound else IN.curBlock.Properties = IN.curBlock:addChild(TagCompound.new("Properties")) end
        if(IN.curBlock.Properties:contains("rotation", TYPE.STRING)) then IN.curBlock.Properties.lastFound.value = tostring(rotation) else IN.curBlock.Properties:addChild(TagString.new("rotation", tostring(rotation))) end
    end

    IN.curBlock.save = true
    return OUT
end

function TileEntity:ConvertSmoker(IN, OUT, required)

    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}")) end
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end 

    if(required) then
        --TODO identify use of BurnDuration and StoredXP
        OUT:addChild(TagShort.new("CookTimeTotal"))
        OUT:addChild(TagShort.new("RecipesUsedSize"))
    end
    return OUT
end
-----------------Base Functions

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