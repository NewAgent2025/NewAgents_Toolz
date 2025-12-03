TileEntity = {}
Item = Item or require("item")
Entity = Entity or require("entity")
Utils = Utils or require("utils")

function TileEntity:ConvertTileEntity(IN, required)
    local OUT = TagCompound.new()

    local id = ""
    if(IN:contains("id", TYPE.STRING)) then
        id = IN.lastFound.value
        if(id:find("^minecraft:")) then id = id:sub(11) end
    elseif(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("id", TYPE.SHORT)) then
            local blockId = IN.QueuedTE.lastFound.value

            if(blockId == 26) then id = "bed"
            elseif(blockId == 118) then id = "queued_cauldron"
            elseif(blockId == 33 or blockId == 29) then id = "piston"
            elseif(blockId == 140) then id = "flower_pot"
            elseif(blockId == 154) then id = "hopper"
            elseif(blockId == 23) then id = "dispenser"
            elseif(blockId == 209) then id = "end_gateway"
            elseif(blockId == 25) then id = "noteblock"
            elseif(blockId == 178 or blockId == 151) then id = "daylight_detector"
            elseif(blockId == 177 or blockId == 176) then id = "banner"
            elseif(blockId == 52) then id = "spawner"
            elseif(blockId == 54) then id = "chest"
            elseif(blockId == 144) then id = "trapped_chest"
            elseif(blockId == 61 or blockId == 62) then id = "furnace"
            elseif(blockId == 138) then id = "beacon"
            elseif(blockId == 63 or blockId == 68) then id = "sign"
            elseif(blockId == 117) then id = "brewing_stand"
            elseif(blockId == 130) then id = "ender_chest"
            elseif(blockId == 158) then id = "dropper"
            elseif(blockId == 137 or blockId == 210 or blockId == 211) then id = "command_block"
            else return nil end

        elseif(IN.QueuedTE:contains("id", TYPE.STRING)) then
            local blockId = IN.QueuedTE.lastFound.value

            if(blockId:find("_bed$")) then id = "bed"
            elseif(blockId == "cauldron") then id = "queued_cauldron"
            elseif(blockId == "piston" or blockId == "sticky_piston") then id = "piston"
            elseif(blockId == "flower_pot") then id = "flower_pot"
            elseif(blockId:find("^potted_")) then id = "flower_pot"
            elseif(blockId:find("shulker_box$")) then id = "shulker_box"
            elseif(blockId:find("sign$")) then id = "sign"
            elseif(blockId == "barrel") then id = "barrel"
            elseif(blockId == "bell") then id = "bell"
            elseif(blockId == "hopper") then id = "hopper"
            elseif(blockId:find("_banner$")) then id = "banner"
            elseif(blockId == "blast_furnace") then id = "blast_furnace"
            elseif(blockId == "brewing_stand") then id = "brewing_stand"
            elseif(blockId == "campfire") then id = "campfire"
            elseif(blockId == "chest") then id = "chest"
            elseif(blockId == "conduit") then id = "conduit"
            elseif(blockId == "daylight_detector") then id = "daylight_detector"
            elseif(blockId == "dispenser") then id = "dispenser"
            elseif(blockId == "end_gateway") then id = "end_gateway"
            elseif(blockId == "ender_chest") then id = "ender_chest"
            elseif(blockId == "furnace") then id = "furnace"
            elseif(blockId == "jukebox") then id = "jukebox"
            elseif(blockId == "mob_spawner" or blockId == "spawner") then id = "spawner"
            elseif(blockId == "note_block") then id = "noteblock"
            elseif(blockId == "smoker") then id = "smoker"
            elseif(blockId == "trapped_chest") then id = "trapped_chest"
            elseif(blockId == "dropper") then id = "dropper"
            elseif(blockId == "command_block" or blockId == "chain_command_block" or blockId == "repeating_command_block") then id = "command_block"
            else return nil end

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

    --isMovable
    OUT:addChild(TagByte.new("isMovable", true))

    if(Settings:dataTableContains("tileEntities", id)) then
        local entry = Settings.lastFound
        OUT:addChild(TagString.new("id", entry[1][1]))
        OUT = TileEntity[entry[1][2]](TileEntity, IN, OUT, true)
    else return nil end

    if(IN.curBlock.save) then Chunk:setBlock(blockX, blockY, blockZ, IN.curBlock) end

    return OUT
end

function TileEntity:ConvertBanner(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)

    --check for queued tile entity and turn into Base
    --save curBlock.val for items only

    if(IN:contains("CustomName", TYPE.STRING)) then
        local customName = IN.lastFound.value

        local jsonRoot = JSONValue.new()
        if(jsonRoot:parse(customName).type == JSON_TYPE.OBJECT) then

            if(jsonRoot:contains("translate", JSON_TYPE.STRING)) then
                if(jsonRoot.lastFound:getString() == "block.minecraft.ominous_banner") then
                    OUT:addChild(TagInt.new("Type", 1))
                    OUT:addChild(TagInt.new("Base", 0))

                    return OUT
                end
            end
        end
    end

    local queueUsed = false

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound
        if(IN.QueuedTE:contains("id")) then
            IN.QueuedTE.id = IN.QueuedTE.lastFound
            if(IN.QueuedTE.id.type == TYPE.STRING) then
                local bannerName = IN.QueuedTE.id.value

                if(IN.curBlock:contains("val", TYPE.SHORT)) then
                    IN.curBlock.val = IN.curBlock.lastFound
                    local bannerVal = IN.curBlock.val.value
        
                    queueUsed = true
        
                    if(bannerName == "minecraft:white_banner" or bannerName == "minecraft:white_wall_banner") then bannerVal = 15
                    elseif(bannerName == "minecraft:orange_banner" or bannerName == "minecraft:orange_wall_banner") then bannerVal = 14
                    elseif(bannerName == "minecraft:magenta_banner" or bannerName == "minecraft:magenta_wall_banner") then bannerVal = 13
                    elseif(bannerName == "minecraft:light_blue_banner" or bannerName == "minecraft:light_blue_wall_banner") then bannerVal = 12
                    elseif(bannerName == "minecraft:yellow_banner" or bannerName == "minecraft:yellow_wall_banner") then bannerVal = 11
                    elseif(bannerName == "minecraft:lime_banner" or bannerName == "minecraft:lime_wall_banner") then bannerVal = 10
                    elseif(bannerName == "minecraft:pink_banner" or bannerName == "minecraft:pink_wall_banner") then bannerVal = 9
                    elseif(bannerName == "minecraft:gray_banner" or bannerName == "minecraft:gray_wall_banner") then bannerVal = 8
                    elseif(bannerName == "minecraft:light_gray_banner" or bannerName == "minecraft:light_gray_wall_banner") then bannerVal = 7
                    elseif(bannerName == "minecraft:cyan_banner" or bannerName == "minecraft:cyan_wall_banner") then bannerVal = 6
                    elseif(bannerName == "minecraft:purple_banner" or bannerName == "minecraft:purple_wall_banner") then bannerVal = 5
                    elseif(bannerName == "minecraft:blue_banner" or bannerName == "minecraft:blue_wall_banner") then bannerVal = 4
                    elseif(bannerName == "minecraft:brown_banner" or bannerName == "minecraft:brown_wall_banner") then bannerVal = 3
                    elseif(bannerName == "minecraft:green_banner" or bannerName == "minecraft:green_wall_banner") then bannerVal = 2
                    elseif(bannerName == "minecraft:red_banner" or bannerName == "minecraft:red_wall_banner") then bannerVal = 1
                    elseif(bannerName == "minecraft:black_banner" or bannerName == "minecraft:black_wall_banner") then bannerVal = 0
                    end
        
                    if(IN.curBlock.val.value ~= -1) then
                        IN.curBlock.val.value = bannerVal
                        IN.curBlock.save = true
                    end
        
                    OUT.Base = OUT:addChild(TagInt.new("Base", bannerVal))
                end
            end
        end
     end


    if(queueUsed == false and IN:contains("Base", TYPE.INT)) then
        if(IN.lastFound.value <= 15) then

            if(IN.curBlock.val == nil) then 
                if(IN.curBlock:contains("val", TYPE.SHORT)) then
                    IN.curBlock.val = IN.curBlock.lastFound
                end
            end

            if(IN.curBlock.val ~= nil) then
                IN.curBlock.val.value = 15 - IN.lastFound.value
            end

            OUT.Base = OUT:addChild(TagInt.new("Base", IN.lastFound.value))
            IN.curBlock.save = true
        end
    end

    local DataVersion = Settings:getSettingInt("DataVersion")
    
    if(OUT.Base == nil and required) then OUT:addChild(TagInt.new("Base"))end

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

function TileEntity:ConvertBarrel(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(required) then OUT:addChild(TagByte.new("Findable")) end
    return OUT
end

function TileEntity:ConvertBeacon(IN, OUT, required)

    --TODO convert status effect ids
    if(IN:contains("Primary", TYPE.INT)) then OUT:addChild(TagInt.new("primary", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("primary")) end
    if(IN:contains("Secondary", TYPE.INT)) then OUT:addChild(TagInt.new("secondary", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("secondary")) end
    return OUT
end

function TileEntity:ConvertBeehive(IN, OUT, required)

    if(IN:contains("Bees", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Bees = IN.lastFound

        OUT.Occupants = OUT:addChild(TagList.new("Occupants"))
        
        for i=0, IN.Bees.childCount-1 do
            local bee_in = IN.Bees:child(i)
            local bee_out = TagCompound.new()

            if(bee_in:contains("EntityData", TYPE.COMPOUND)) then
                local beeEntity = Entity:ConvertEntity(bee_in.lastFound, true)
                if(beeEntity == nil) then goto beeContinue end
                beeEntity.name = "SaveData"
                bee_out:addChild(beeEntity)
            else goto beeContinue end
            

            local minTicks = 2400
            if(bee_in:contains("MinOccupationTicks", TYPE.INT)) then  minTicks = bee_in.lastFound.value end

            if(bee_in:contains("TicksInHive", TYPE.INT)) then
                local ticksLeft = minTicks - bee_in.lastFound.value
                if(ticksLeft < 0) then ticksLeft = 0 end
                bee_out:addChild(TagInt.new("TicksLeftToStay", ticksLeft))
            elseif(required) then
                bee_out:addChild(TagInt.new("TicksLeftToStay", 2400))
            end

            bee_out:addChild(TagString.new("ActorIdentifier", "minecraft:bee<>"))

            OUT.Occupants:addChild(bee_out)

            ::beeContinue::
        end

        if(OUT.Occupants.childCount == 0) then
            OUT:removeChild(OUT.Occupants:getRow())
            OUT.Occupants = nil
        end
    end

    return OUT
end

function TileEntity:ConvertBed(IN, OUT, required)

    --check for queued tile entity and turn into color

    local queueUsed = false

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound
        if(IN.QueuedTE:contains("id")) then
            IN.QueuedTE.id = IN.QueuedTE.lastFound

            if(IN.QueuedTE.id.type == TYPE.STRING) then
                local bedName = IN.QueuedTE.id.value
        
                queueUsed = true
        
                OUT.color = OUT:addChild(TagByte.new("color", 14))
        
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

    if(queueUsed == false) then
        if(IN:contains("color", TYPE.INT)) then
            OUT.color = OUT:addChild(TagByte.new("color", 14))
            if(IN.lastFound.value <= 15) then OUT.color.value = IN.lastFound.value end
        elseif(required) then OUT:addChild(TagByte.new("color", 14))
        end
    end

    return OUT
end

function TileEntity:ConvertBell(IN, OUT, required)

    if(required) then
        OUT:addChild(TagByte.new("Ringing"))
        --TODO investigate direction
        OUT:addChild(TagInt.new("Direction"))
        OUT:addChild(TagInt.new("Ticks"))
    end
    return OUT
end

function TileEntity:ConvertBlastFurnace(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end 

    if(required) then
        --TODO identify use of BurnDuration
        OUT:addChild(TagShort.new("BurnDuration"))
        --TODO TileEntity:Convert from RecipesUsedSize if possible
        OUT:addChild(TagShort.new("StoredXP"))
    end

    return OUT
end

function TileEntity:ConvertBrewingStand(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
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

function TileEntity:ConvertCampfire(IN, OUT, required)

    if(IN:contains("Items", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Items = IN.lastFound

        for i=0, IN.Items.childCount-1 do
            local campfireItem = IN.Items:child(i)

            if(campfireItem:contains("Slot", TYPE.BYTE)) then
                campfireItem.Slot = campfireItem.lastFound.value

                if(campfireItem.Slot >= 0 and campfireItem.Slot <= 3) then
                    local newItem = Item:ConvertItem(campfireItem, false)
                    if(newItem ~= nil) then
                        if(campfireItem.Slot == 0 and OUT.Item1 == nil) then
                            newItem.name = "Item1"
                            OUT.Item1 = OUT:addChild(newItem)
                        elseif(campfireItem.Slot == 1 and OUT.Item2 == nil) then
                            newItem.name = "Item2"
                            OUT.Item2 = OUT:addChild(newItem)
                        elseif(campfireItem.Slot == 2 and OUT.Item3 == nil) then
                            newItem.name = "Item3"
                            OUT.Item3 = OUT:addChild(newItem)
                        elseif(campfireItem.Slot == 3 and OUT.Item4 == nil) then
                            newItem.name = "Item4"
                            OUT.Item4 = OUT:addChild(newItem)
                        end
                    end
                end
            end
        end
    end

    if(IN:contains("CookingTimes", TYPE.INT_ARRAY)) then
        IN.CookingTimes = IN.lastFound

        if(IN.CookingTimes.size == 16) then
            OUT.ItemTime1 = OUT:addChild(TagInt.new("ItemTime1", IN.CookingTimes:getInt(0)))
            OUT.ItemTime2 = OUT:addChild(TagInt.new("ItemTime2", IN.CookingTimes:getInt(4)))
            OUT.ItemTime3 = OUT:addChild(TagInt.new("ItemTime3", IN.CookingTimes:getInt(8)))
            OUT.ItemTime4 = OUT:addChild(TagInt.new("ItemTime4", IN.CookingTimes:getInt(12)))
        end
    end

    if(OUT.ItemTime1 == nil and required) then OUT:addChild(TagInt.new("ItemTime1")) end
    if(OUT.ItemTime2 == nil and required) then OUT:addChild(TagInt.new("ItemTime2")) end
    if(OUT.ItemTime3 == nil and required) then OUT:addChild(TagInt.new("ItemTime3")) end
    if(OUT.ItemTime4 == nil and required) then OUT:addChild(TagInt.new("ItemTime4")) end

    return OUT
end

function TileEntity:ConvertCauldron(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(required) then
        OUT:addChild(TagShort.new("PotionType"))
        OUT:addChild(TagShort.new("PotionId", -1))
    end
    return OUT
end

function TileEntity:ConvertChest(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
    if(required) then OUT:addChild(TagByte.new("Findable")) end

    local itemsRequired = true
    --[[
    if(IN:contains("LootTable", TYPE.STRING)) then
        local lootTable = IN.lastFound.value
        if(lootTable:find("^minecraft:chests/")) then
            OUT:addChild(TagString.new("LootTable", lootTable))
            itemsRequired = false
        end
    end
    --]]

    TileEntity:ConvertItems(IN, OUT, required, itemsRequired)

    if(required) then
        local queueUsed = false

        if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
            IN.QueuedTE = IN.lastFound 

            if(IN.QueuedTE:contains("meta")) then
                IN.QueuedTE.meta = IN.QueuedTE.lastFound

                if(IN.QueuedTE.meta.type == TYPE.COMPOUND) then
                    if(IN.QueuedTE.meta:contains("type", TYPE.STRING)) then
                        local chestType = IN.QueuedTE.meta.lastFound
        
                        queueUsed = true
        
                        if(chestType.value == "right") then
                            OUT:addChild(TagByte.new("pairlead", true))
                            OUT.pairx = OUT:addChild(TagInt.new("pairx", OUT.x.value - 1))
                            OUT.pairz = OUT:addChild(TagInt.new("pairz", OUT.z.value))
                            
                            if(IN.QueuedTE.meta:contains("facing", TYPE.STRING)) then 
                                local chestFacing = IN.QueuedTE.meta.lastFound
        
                                if(chestFacing.value == "south") then
                                    OUT.pairx.value = OUT.x.value + 1
                                    OUT.pairz.value = OUT.z.value
                                elseif(chestFacing.value == "west") then
                                    OUT.pairx.value = OUT.x.value
                                    OUT.pairz.value = OUT.z.value + 1
                                elseif(chestFacing.value == "east") then
                                    OUT.pairx.value = OUT.x.value
                                    OUT.pairz.value = OUT.z.value - 1
                                end
                            end
                        end
                    end
                end
            end
        end

        if(queueUsed == false) then 
            if(IN.curBlock:contains("Name", TYPE.STRING)) then
                IN.curBlock.Name = IN.curBlock.lastFound.value
                if(IN.curBlock.Name:find("^minecraft:")) then IN.curBlock.Name = IN.curBlock.Name:sub(11) end

                if(IN.curBlock.Name == "chest" or IN.curBlock.Name == "trapped_chest") then
                    local chestFacing = 2


                    -- 2=north, 3=south, 4=west, 5=east
                    if(IN.curBlock:contains("states", TYPE.COMPOUND)) then
                        IN.curBlock.states = IN.curBlock.lastFound
                        if(IN.curBlock.states:contains("facing_direction", TYPE.INT)) then
                            chestFacing = IN.curBlock.states.lastFound.value
                            if(chestFacing < 2 or chestFacing > 5) then chestFacing = 2 end
                        end
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

                                -- 2=north, 3=south, 4=west, 5=east
                                if(pairBlock:contains("states", TYPE.COMPOUND)) then
                                    pairBlock.states = pairBlock.lastFound
                                    if(pairBlock.states:contains("facing_direction", TYPE.INT)) then
                                        pairFacing = pairBlock.states.lastFound.value
                                        if(pairFacing < 2 or pairFacing > 5) then pairFacing = 2 end
                                    end
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
    end

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

    --TileEntity:ConvertCustomName(IN, OUT, required)

    if(IN:contains("Command", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagString.new("Command")) end

    if(IN:contains("auto", TYPE.BYTE)) then OUT:addChild(TagByte.new("auto", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("auto")) end

    if(IN:contains("conditionMet", TYPE.BYTE)) then OUT:addChild(TagByte.new("conditionMet", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("conditionMet")) end

    if(IN:contains("powered", TYPE.BYTE)) then OUT:addChild(TagByte.new("powered", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("powered")) end

    if(IN:contains("TrackOutput", TYPE.BYTE)) then OUT:addChild(TagByte.new("TrackOutput", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("TrackOutput")) end

    if(IN:contains("SuccessCount", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("SuccessCount")) end

    if(IN:contains("LastOutput", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagString.new("LastOutput")) end

    if(required) then
        OUT:addChild(TagByte.new("ExecuteOnFirstTick"))
        OUT:addChild(TagInt.new("TickDelay"))
        OUT:addChild(TagInt.new("Version", 10))
        OUT:addChild(TagLong.new("LastExecution"))
        OUT:addChild(TagString.new("CustomName"))

        --identify use of LP?
    end

    return OUT
end

function TileEntity:ConvertComparator(IN, OUT, required)
    if(IN:contains("OutputSignal", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("OutputSignal", 0)) end
    return OUT
end

function TileEntity:ConvertConduit(IN, OUT, required)
    if(required) then 
        OUT:addChild(TagByte.new("Active", 0))
        OUT:addChild(TagLong.new("Target", -1))
        --TODO identify use of target and add Rotation
    end
    return OUT
end

function TileEntity:ConvertDaylightDetector(IN, OUT, required)
    return OUT
end

function TileEntity:ConvertDispenser(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    return OUT
end

function TileEntity:ConvertDropper(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
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

    local PlantBlock = TagCompound.new("PlantBlock")

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("id")) then
            IN.QueuedTE.id = IN.QueuedTE.lastFound

            if(IN.QueuedTE:contains("meta")) then IN.QueuedTE.meta = IN.QueuedTE.lastFound end

            if(IN.QueuedTE.id.type == TYPE.SHORT) then
                IN.Data = 0
                if(IN:contains("Data", TYPE.INT)) then IN.Data = IN.lastFound.value end

                if(IN:contains("Item", TYPE.STRING)) then
                    local flowerName = IN.lastFound.value
                    if(flowerName:find("^minecraft:")) then flowerName = flowerName:sub(11) end

                    local flowerBlock = Utils:findBlock(flowerName, IN.Data)

                    if(flowerBlock ~= nil and flowerBlock.id ~= nil) then
                        if(flowerBlock.id:find("^minecraft:")) then flowerBlock.id = flowerBlock.id:sub(11) end
                        PlantBlock.flowerName = PlantBlock:addChild(TagString.new("name", "minecraft:" .. flowerBlock.id))
                        PlantBlock.states = PlantBlock:addChild(Item:StringToStates(flowerBlock.meta))
                    end

                elseif(IN:contains("Item", TYPE.INT)) then
                    IN.Item = IN.lastFound.value

                    local flowerBlock = Utils:findBlock(IN.Item, IN.Data)

                    if(flowerBlock ~= nil and flowerBlock.id ~= nil) then
                        if(flowerBlock.id:find("^minecraft:")) then flowerBlock.id = flowerBlock.id:sub(11) end
                        PlantBlock.flowerName = PlantBlock:addChild(TagString.new("name", "minecraft:" .. flowerBlock.id))
                        PlantBlock.states = PlantBlock:addChild(Item:StringToStates(flowerBlock.meta))
                    end

                    if(Settings:dataTableContains("blocks_ids", tostring(IN.Item)) and IN.Item ~= 0) then
                        local entry = Settings.lastFound
                        local DataVersion = Settings:getSettingInt("DataVersion")
                        for index, _ in ipairs(entry) do
                            local subEntry = entry[index]
                            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                            if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.Data) then goto entryContinue end end
                            PlantBlock.flowerName = PlantBlock:addChild(TagString.new("name", "minecraft:" .. subEntry[3]))
                            PlantBlock.states = PlantBlock:addChild(Item:StringToStates(subEntry[5]))
                            break
                            ::entryContinue::
                        end
                    end
                else
                    if(IN.QueuedTE.meta.type == TYPE.BYTE) then
                        local potDamage = IN.QueuedTE.meta.value
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

                        local flowerBlock = Utils:findBlock(IN.Item, IN.Data)

                        if(flowerBlock ~= nil and flowerBlock.id ~= nil) then
                            if(flowerBlock.id:find("^minecraft:")) then flowerBlock.id = flowerBlock.id:sub(11) end
                            PlantBlock.flowerName = PlantBlock:addChild(TagString.new("name", "minecraft:" .. flowerBlock.id))
                            PlantBlock.states = PlantBlock:addChild(Item:StringToStates(flowerBlock.meta))
                        end
                    end
                end

            elseif(IN.QueuedTE.id.type == TYPE.STRING) then
                local flowerPotName = IN.QueuedTE.id.value

                if(flowerPotName:find("^minecraft:")) then flowerPotName = flowerPotName:sub(11) end
                if(flowerPotName:find("^potted_")) then flowerPotName = flowerPotName:sub(8) end

                local flowerBlock = Utils:findBlock(flowerPotName, IN.QueuedTE.meta)

                if(flowerBlock ~= nil and flowerBlock.id ~= nil) then
                    if(flowerBlock.id:find("^minecraft:")) then flowerBlock.id = flowerBlock.id:sub(11) end
                    PlantBlock.flowerName = PlantBlock:addChild(TagString.new("name", "minecraft:" .. flowerBlock.id))
                    PlantBlock.states = PlantBlock:addChild(Item:StringToStates(flowerBlock.meta))
                end
            end
        end
    end
    
    if(PlantBlock.flowerName ~= nil and PlantBlock.states ~= nil) then
        OUT:addChild(PlantBlock)
    end

    return OUT
end

function TileEntity:ConvertFurnace(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end 

    if(required) then
        --TODO identify use of BurnDuration
        OUT:addChild(TagShort.new("BurnDuration"))
        --TODO TileEntity:Convert from RecipesUsedSize if possible
        OUT:addChild(TagInt.new("StoredXPInt"))
    end

    return OUT
end

function TileEntity:ConvertHopper(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
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
        local SpawnData = IN.lastFound
        if(IN:contains("EntityId", TYPE.STRING)) then
            if(not SpawnData:contains("id", TYPE.STRING)) then SpawnData:addChild(TagString.new("id", IN.lastFound.value)) end
        end

        if(SpawnData:contains("id", TYPE.STRING)) then
            local entityId = SpawnData.lastFound.value
            if(entityId:find("^minecraft:")) then entityId = entityId:sub(11) end

            if(Settings:dataTableContains("entities", entityId)) then
                local entry = Settings.lastFound
                OUT.EntityIdentifier = OUT:addChild(TagString.new("EntityIdentifier", "minecraft:" .. entry[1][1]))
            end
        end
    elseif(IN:contains("EntityId", TYPE.STRING)) then
        local entityId = IN.lastFound.value
        if(entityId:find("^minecraft:")) then entityId = entityId:sub(11) end

        if(Settings:dataTableContains("entities", entityId)) then
            local entry = Settings.lastFound
            OUT.EntityIdentifier = OUT:addChild(TagString.new("EntityIdentifier", "minecraft:" .. entry[1][1]))
        end
    end

    if(OUT.EntityIdentifier == nil and required) then
        OUT:addChild(TagString.new("EntityIdentifier", "minecraft:pig"))
    end

    return OUT
end

function TileEntity:ConvertNoteBlock(IN, OUT, required)

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("meta", TYPE.COMPOUND)) then
            IN.QueuedTE.meta = IN.QueuedTE.lastFound

            OUT.note = OUT:addChild(TagByte.new("note"))

            if(IN.QueuedTE.meta:contains("note", TYPE.STRING)) then OUT.note.value = tonumber(IN.QueuedTE.meta.value) end
        end
    elseif(IN:contains("note", TYPE.BYTE)) then
        OUT.note = OUT:addChild(TagByte.new("note", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagByte.new("note"))
    end

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

        if(IN.QueuedTE:contains("meta")) then
            IN.QueuedTE.meta = IN.QueuedTE.lastFound

            if(IN.QueuedTE.meta.type == TYPE.BYTE) then
                if(IN.QueuedTE.meta.value >= 8) then
                    OUT.isMovable.value = false
                end
            elseif(IN.QueuedTE.meta.type == TYPE.COMPOUND) then
                if(IN.QueuedTE.meta:contains("extended", TYPE.STRING)) then
                    if(IN.QueuedTE.meta.lastFound.value == "true") then
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
        local blockStates = ""


        if(IN:contains("blockState", TYPE.COMPOUND)) then
            IN.blockState = IN.lastFound

            if(IN.blockState:contains("Name", TYPE.STRING)) then IN.blockState.id = IN.blockState.lastFound end
            if(IN.blockState:contains("Properties", TYPE.COMPOUND)) then IN.blockState.meta = IN.blockState.lastFound end

            local block = Utils:findBlock(IN.blockState.id, IN.blockState.meta)
            if(block ~= nil and block.id ~= nil) then
                blockName = "minecraft:" .. block.id
                blockStates = block.meta
            end
        else
            IN.blockId = 0
            IN.blockData = 0
            if(IN:contains("blockId", TYPE.INT)) then IN.blockId = IN.lastFound.value end
            if(IN:contains("blockData", TYPE.INT)) then IN.blockData = IN.lastFound.value end

            local block = Utils:findBlock(IN.blockId, IN.blockData)
            if(block ~= nil and block.id ~= nil) then
                blockName = "minecraft:" .. block.id
                blockStates = block.meta
            end
        end

        OUT.movingBlock = OUT:addChild(TagCompound.new("movingBlock"))

        OUT.movingBlock:addChild(TagString.new("name", blockName))
        if(blockStates:len() ~= 0) then
            local statesTags = Utils:StringToStates(blockStates)
            if(statesTags ~= nil) then OUT.movingBlock:addChild(statesTags) end
        end

        OUT.movingBlockExtra = OUT:addChild(TagCompound.new("movingBlockExtra"))
        OUT.movingBlockExtra:addChild(TagString.new("name", "minecraft:air"))
        OUT.movingBlockExtra:addChild(TagCompound.new("states"))
    end

    return OUT
end

function TileEntity:ConvertLectern(IN, OUT, required)

    if(IN:contains("Book", TYPE.COMPOUND)) then
        IN.Book = IN.lastFound
        local item = Item:ConvertItem(IN.Book, false)
        if(item ~= nil) then
            item.name = "book"
            OUT:addChild(item)
            OUT.hasBook = OUT:addChild(TagByte.new("hasBook", true))
        end
    end

    if(OUT.hasBook == nil and required) then OUT:addChild(TagByte.new("hasBook")) end

    return OUT
end

function TileEntity:ConvertShulkerBox(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    OUT:addChild(TagByte.new("Findable"))

    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        if(IN.QueuedTE:contains("meta")) then
            IN.QueuedTE.meta = IN.QueuedTE.lastFound

            if(IN.QueuedTE.meta.type == TYPE.BYTE) then
                OUT.facing = OUT:addChild(TagByte.new("facing", IN.QueuedTE.meta.value))
            elseif(IN.QueuedTE.meta.type == TYPE.COMPOUND) then
                if(IN.QueuedTE.meta:contains("facing", TYPE.STRING)) then
                    OUT.facing = OUT:addChild(TagByte.new("facing", 0))
                    if(IN.QueuedTE.meta.lastFound.value == "down") then OUT.facing.value = 0
                    elseif(IN.QueuedTE.meta.lastFound.value == "up") then OUT.facing.value = 1
                    elseif(IN.QueuedTE.meta.lastFound.value == "north") then OUT.facing.value = 2
                    elseif(IN.QueuedTE.meta.lastFound.value == "south") then OUT.facing.value = 3
                    elseif(IN.QueuedTE.meta.lastFound.value == "west") then OUT.facing.value = 4
                    elseif(IN.QueuedTE.meta.lastFound.value == "east") then OUT.facing.value = 5
                    end
                end
            end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("facing", 0))
    elseif(IN.curBlock:contains("val", TYPE.SHORT)) then
        IN.curBlock.val = IN.curBlock.lastFound

        if(IN:contains("Color", TYPE.BYTE)) then
            IN.curBlock.val.value = IN.lastFound.value
            IN.curBlock.save = true
        end
    end

    return OUT
end

function TileEntity:ConvertSign(IN, OUT, required)
    local outputText = ""
    containsText = false

    for i=0, 3 do
        if(IN:contains("Text" .. tostring(i+1), TYPE.STRING)) then
            local text = IN.lastFound.value
            local jsonRoot = JSONValue.new()
            if(jsonRoot:parse(text).type == JSON_TYPE.OBJECT) then

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

                if(i == 0) then
                    outputText = textOut
                else
                    outputText = outputText .. "\n" .. textOut
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
                if(i == 0) then
                    outputText = text
                else
                    outputText = outputText .. "\n" .. text
                end

                containsText = true
            end
        end
    end

    if(containsText) then OUT:addChild(TagString.new("Text", outputText))
    elseif(required) then OUT:addChild(TagString.new("Text", outputText))
    end

    return OUT
end

function TileEntity:ConvertSmoker(IN, OUT, required)
    TileEntity:ConvertCustomName(IN, OUT, required)
    TileEntity:ConvertItems(IN, OUT, required, true)
    if(IN:contains("BurnTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("BurnTime")) end
    if(IN:contains("CookTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("CookTime")) end 

    if(required) then
        --TODO identify use of BurnDuration
        OUT:addChild(TagShort.new("BurnDuration"))
        --TODO TileEntity:Convert from RecipesUsedSize if possible
        OUT:addChild(TagShort.new("StoredXP"))
    end

    return OUT
end

function TileEntity:ConvertSkull(IN, OUT, required)

    local rotationFound = false
    --check for queued tile entity and turn into SkullType and Rot
    if(IN:contains("UMC_QueuedTileEntity", TYPE.COMPOUND)) then
        IN.QueuedTE = IN.lastFound

        OUT.SkullType = OUT:addChild(TagByte.new("SkullType"))
        OUT.Rotation = OUT:addChild(TagFloat.new("Rotation"))

        if(IN.QueuedTE:contains("id", TYPE.STRING)) then
            local skullName = IN.QueuedTE.lastFound.value

            if(skullName == "minecraft:skeleton_skull" or skullName == "minecraft:skeleton_wall_skull") then OUT.SkullType.value = 0
            elseif(skullName == "minecraft:wither_skeleton_skull" or skullName == "minecraft:wither_skeleton_wall_skull") then OUT.SkullType.value = 1
            elseif(skullName == "minecraft:zombie_head" or skullName == "minecraft:zombie_wall_head") then OUT.SkullType.value = 2
            elseif(skullName == "minecraft:player_head" or skullName == "minecraft:player_wall_head") then OUT.SkullType.value = 3
            elseif(skullName == "minecraft:creeper_head" or skullName == "minecraft:creeper_wall_head") then OUT.SkullType.value = 4
            elseif(skullName == "minecraft:dragon_head" or skullName == "minecraft:dragon_wall_head") then OUT.SkullType.value = 5
            end

            if(IN.QueuedTE:contains("meta", TYPE.COMPOUND)) then
                IN.QueuedTE.meta = IN.QueuedTE.lastFound

                if(IN.QueuedTE.meta:contains("rotation", TYPE.STRING)) then
                    local rotation = tonumber(IN.QueuedTE.meta.lastFound.value)

                    rotationFound = true

                    if(rotation == 0) then
                        OUT.Rotation.value = 0
                    elseif(rotation == 1) then 
                        OUT.Rotation.value = 22.5
                    elseif(rotation == 2) then 
                        OUT.Rotation.value = 45
                    elseif(rotation == 3) then 
                        OUT.Rotation.value = 67.5
                    elseif(rotation == 4) then 
                        OUT.Rotation.value = 90
                    elseif(rotation == 5) then 
                        OUT.Rotation.value = 112.5
                    elseif(rotation == 6) then 
                        OUT.Rotation.value = 135
                    elseif(rotation == 7) then 
                        OUT.Rotation.value = 157.5
                    elseif(rotation == 8) then 
                        OUT.Rotation.value = 180
                    elseif(rotation == 9) then 
                        OUT.Rotation.value = -157.5
                    elseif(rotation == 10) then 
                        OUT.Rotation.value = -135
                    elseif(rotation == 11) then 
                        OUT.Rotation.value = -112.5
                    elseif(rotation == 12) then 
                        OUT.Rotation.value = -90
                    elseif(rotation == 13) then 
                        OUT.Rotation.value = -67.5
                    elseif(rotation == 14) then 
                        OUT.Rotation.value = -45
                    elseif(rotation == 15) then 
                        OUT.Rotation.value = -22.5
                    end

                end
            end
        end
    end

    if(IN:contains("Rot", TYPE.BYTE) and not rotationFound) then
        local rotation = IN.lastFound.value
        OUT.Rotation = OUT:addChild(TagFloat.new("Rotation"))
        if(rotation == 0) then
            OUT.Rotation.value = 0
        elseif(rotation == 1) then 
            OUT.Rotation.value = 22.5
        elseif(rotation == 2) then 
            OUT.Rotation.value = 45
        elseif(rotation == 3) then 
            OUT.Rotation.value = 67.5
        elseif(rotation == 4) then 
            OUT.Rotation.value = 90
        elseif(rotation == 5) then 
            OUT.Rotation.value = 112.5
        elseif(rotation == 6) then 
            OUT.Rotation.value = 135
        elseif(rotation == 7) then 
            OUT.Rotation.value = 157.5
        elseif(rotation == 8) then 
            OUT.Rotation.value = 180
        elseif(rotation == 9) then 
            OUT.Rotation.value = -157.5
        elseif(rotation == 10) then 
            OUT.Rotation.value = -135
        elseif(rotation == 11) then 
            OUT.Rotation.value = -112.5
        elseif(rotation == 12) then 
            OUT.Rotation.value = -90
        elseif(rotation == 13) then 
            OUT.Rotation.value = -67.5
        elseif(rotation == 14) then 
            OUT.Rotation.value = -45
        elseif(rotation == 15) then 
            OUT.Rotation.value = -22.5
        end
    end

    return OUT
end

-------------Base functions

function TileEntity:ConvertCustomName(IN, OUT, required)
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

    if(IN:contains("LootTable", TYPE.STRING)) then
        local lootTable = IN.lastFound.value
        if(lootTable:find("^minecraft:")) then lootTable = lootTable:sub(11) end
        if(Settings:dataTableContains("loot_tables", lootTable)) then
            local entry = Settings.lastFound
            OUT:addChild(TagString.new("LootTable", "loot_tables/" .. entry[1][1]))

            if(IN:contains("LootTableSeed", TYPE.LONG)) then OUT:addChild(IN.lastFound:clone()) end
        end
    end

end



return TileEntity