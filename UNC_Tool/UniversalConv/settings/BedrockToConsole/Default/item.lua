Item = {}
TileEntity = TileEntity or require("tileEntity")

function Item:ConvertItem(IN, slotRequired)
    local OUT = TagCompound.new()

    local ChunkVersion = Settings:getSettingInt("ChunkVersion")

    if(IN:contains("Damage", TYPE.SHORT)) then IN.Damage = IN.lastFound.value else return nil end

    if(IN:contains("Count", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) else return nil end

    if(IN:contains("Slot", TYPE.BYTE) and slotRequired) then OUT:addChild(IN.lastFound:clone()) elseif(slotRequired) then return nil end

    local dataTableName = "items_names"
    if(IN:contains("Name", TYPE.STRING)) then
        IN.id = IN.lastFound.value
        if(IN.id:find("^minecraft:")) then IN.id = IN.id:sub(11) end
    elseif(IN:contains("id", TYPE.SHORT)) then
        IN.id = tostring(IN.lastFound.value)
        dataTableName = "items_ids"
    else return nil end

    if(Settings:dataTableContains(dataTableName, IN.id)) then
        local entry = Settings.lastFound
        for index, _ in ipairs(entry) do
            local subEntry = entry[index]
            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
            if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.Damage) then goto entryContinue end end
            OUT.id = OUT:addChild(TagString.new("id", "minecraft:" .. subEntry[3]))
            if(subEntry[4]:len() > 0) then OUT.Damage = OUT:addChild(TagShort.new("Damage", tonumber(subEntry[4]))) else OUT.Damage = OUT:addChild(TagShort.new("Damage", IN.Damage)) end
            OUT.flags = subEntry[5]
            OUT.tileEntity = subEntry[6]
            break
            ::entryContinue::
        end
        if(OUT.id == nil) then return nil end
    else return nil end

    if(IN:contains("Block", TYPE.COMPOUND)) then
        IN.Block = IN.lastFound
        if(IN.Block:contains("name", TYPE.STRING)) then IN.Block.blockName = IN.Block.lastFound.value end
        if(IN.Block:contains("states", TYPE.COMPOUND)) then IN.Block.states = IN.Block.lastFound end
        if(IN.Block:contains("val", TYPE.SHORT)) then IN.Block.val = IN.Block.lastFound end

        if(IN.Block.blockName ~= nil) then
            if(IN.Block.blockName:find("^minecraft:")) then IN.Block.blockName = IN.Block.blockName:sub(11) end

            if(Settings:dataTableContains("blocks_names", IN.Block.blockName)) then
                local entry = Settings.lastFound
        
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                    if(IN.Block.states ~= nil) then
                        if(subEntry[3]:len() > 0) then if(Item:CompareStates(subEntry[3], IN.Block.states) == false) then goto entryContinue end end
                    elseif(IN.Block.val ~= nil) then
                        if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.Block.val.value) then goto entryContinue end end
                    end

                    OUT.id.value = "minecraft:" .. subEntry[6]
                    if(subEntry[5]:len() ~= 0) then OUT.Damage.value = tonumber(subEntry[5]) end
                    
                    break
                    ::entryContinue::
                end
            end
        end
    end

    if(OUT.tileEntity:len() ~= 0) then
        if(IN:contains("tag", TYPE.COMPOUND)) then
            IN.tag = IN.lastFound
    
            IN.tag.curBlock = TagCompound.new()
            IN.tag.curBlock.itemId = IN.tag.curBlock:addChild(TagString.new("itemId", OUT.id.value))
            IN.tag.curBlock.damage = IN.tag.curBlock:addChild(TagByte.new("damage", OUT.Damage.value))
            IN.tag.curBlock.save = false
    
            local BlockEntityTag_out = TagCompound.new("BlockEntityTag")
    
            if(Settings:dataTableContains("tileEntities", OUT.tileEntity)) then
                local entry = Settings.lastFound
                BlockEntityTag_out = TileEntity[entry[1][2]](TileEntity, IN.tag, BlockEntityTag_out, false)
            end
    
            if(IN.tag.curBlock.save) then
                OUT.id.value = IN.tag.curBlock.itemId.value
                OUT.Damage.value = IN.tag.curBlock.damage.value
            end
    
            if(BlockEntityTag_out ~= nil) then
                if(BlockEntityTag_out.childCount ~= 0) then
                    if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
                    OUT.tag:addChild(BlockEntityTag_out)
                end
            end
    
        end
    end

    OUT = Item:ConvertRepairCost(IN, OUT)

    OUT = Item:ConvertDisplayName(IN, OUT)

    OUT = Item:ConvertUnbreakable(IN, OUT)

    OUT = Item:ConvertEnchantments(IN, OUT)

    if(OUT.flags:len() ~= 0) then
        for flag in OUT.flags:gmatch("([^|]*)|?") do 
            flag = flag:gsub("^%s*(.-)%s*$", "%1")
            
            if(flag == "STORED_ENCH") then OUT = Item:ConvertStoredEnchantments(IN, OUT)
            elseif(flag == "SPAWN_EGG") then OUT = Item:ConvertSpawnEgg(IN, OUT)
            elseif(flag == "COLORED") then OUT = Item:ConvertColor(IN, OUT)
            elseif(flag == "POTION") then OUT = Item:ConvertPotion(IN, OUT)
            --elseif(flag == "BOOK") then OUT = Item:ConvertBook(IN, OUT)
            elseif(flag == "FIREWORK") then OUT = Item:ConvertFirework(IN, OUT)
            elseif(flag == "FIREWORK_CHARGE") then OUT = Item:ConvertFireworkCharge(IN, OUT)
            elseif(flag == "ARROW") then OUT = Item:ConvertArrow(IN, OUT)
            end
        end
    end

    return OUT
end

function Item:ConvertRepairCost(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
        
        if(IN.tag:contains("RepairCost", TYPE.INT)) then OUT.tag:addChild(IN.tag.lastFound:clone()) end

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end
    return OUT
end

function Item:ConvertDisplayName(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
        if(IN.tag:contains("display", TYPE.COMPOUND)) then
            IN.tag.display = IN.tag.lastFound
            if(OUT.tag.display == nil) then OUT.tag.display = OUT.tag:addChild(TagCompound.new("display")) end

            if(IN.tag.display:contains("Name", TYPE.STRING)) then OUT.tag.display:addChild(TagString.new("Name", IN.tag.display.lastFound.value)) end

            if(OUT.tag.display.childCount == 0) then
                OUT.tag:removeChild(OUT.tag.display:getRow())
                OUT.tag.display = nil
            end
        end
        if(IN.tag:contains("RepairCost", TYPE.INT)) then OUT.tag:addChild(IN.tag.lastFound:clone()) end
        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    return OUT
end

function Item:ConvertUnbreakable(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

        if(IN.tag:contains("Unbreakable", TYPE.BYTE)) then OUT.tag:addChild(TagByte.new("Unbreakable", IN.tag.lastFound.value ~= 0)) end

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end
    return OUT
end

function Item:ConvertEnchantments(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
        
        if(IN.tag:contains("ench", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.ench = IN.tag.lastFound
            if(OUT.tag.ench == nil) then OUT.tag.ench = OUT.tag:addChild(TagList.new("ench")) end

            for i=0, IN.tag.ench.childCount-1 do
                local ench_in = IN.tag.ench:child(i)
                local ench_out = TagCompound.new()

                if(ench_in:contains("id", TYPE.SHORT)) then
                    local id = ench_in.lastFound.value

                    if(id == 0) then ench_out:addChild(TagShort.new("id", 0))
                    elseif(id == 1) then ench_out:addChild(TagShort.new("id", 1))
                    elseif(id == 2) then ench_out:addChild(TagShort.new("id", 2))
                    elseif(id == 3) then ench_out:addChild(TagShort.new("id", 3))
                    elseif(id == 4) then ench_out:addChild(TagShort.new("id", 4))
                    elseif(id == 5) then ench_out:addChild(TagShort.new("id", 7))
                    elseif(id == 6) then ench_out:addChild(TagShort.new("id", 5))
                    elseif(id == 7) then ench_out:addChild(TagShort.new("id", 8))
                    elseif(id == 8) then ench_out:addChild(TagShort.new("id", 6))
                    elseif(id == 9) then ench_out:addChild(TagShort.new("id", 16))
                    elseif(id == 10) then ench_out:addChild(TagShort.new("id", 17))
                    elseif(id == 11) then ench_out:addChild(TagShort.new("id", 18))
                    elseif(id == 12) then ench_out:addChild(TagShort.new("id", 19))
                    elseif(id == 13) then ench_out:addChild(TagShort.new("id", 20))
                    elseif(id == 14) then ench_out:addChild(TagShort.new("id", 21))
                    elseif(id == 15) then ench_out:addChild(TagShort.new("id", 32))
                    elseif(id == 16) then ench_out:addChild(TagShort.new("id", 33))
                    elseif(id == 17) then ench_out:addChild(TagShort.new("id", 34))
                    elseif(id == 18) then ench_out:addChild(TagShort.new("id", 35))
                    elseif(id == 19) then ench_out:addChild(TagShort.new("id", 48))
                    elseif(id == 20) then ench_out:addChild(TagShort.new("id", 49))
                    elseif(id == 21) then ench_out:addChild(TagShort.new("id", 50))
                    elseif(id == 22) then ench_out:addChild(TagShort.new("id", 51))
                    elseif(id == 23) then ench_out:addChild(TagShort.new("id", 61))
                    elseif(id == 24) then ench_out:addChild(TagShort.new("id", 62))
                    elseif(id == 25) then ench_out:addChild(TagShort.new("id", 9))
                    elseif(id == 26) then ench_out:addChild(TagShort.new("id", 70))
                    elseif(id == 29) then ench_out:addChild(TagShort.new("id", 66))
                    elseif(id == 30) then ench_out:addChild(TagShort.new("id", 67))
                    elseif(id == 31) then ench_out:addChild(TagShort.new("id", 65))
                    elseif(id == 32) then ench_out:addChild(TagShort.new("id", 68))
                    end
                end

                if(ench_in:contains("lvl", TYPE.SHORT)) then ench_out:addChild(ench_in.lastFound:clone()) else goto enchContinue end
                OUT.tag.ench:addChild(ench_out)
                ::enchContinue::
            end

            if(OUT.tag.ench.childCount == 0) then
                OUT.tag:removeChild(OUT.tag.ench:getRow())
                OUT.tag.ench = nil
            end
        end

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    return OUT
end

function Item:ConvertStoredEnchantments(IN, OUT)
    if(OUT.tag ~= nil) then
        if(OUT.tag.ench ~= nil) then
            OUT.tag.ench.name = "StoredEnchantments"
        end
    end
    return OUT
end

function Item:ConvertColor(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
        if(IN.tag:contains("display", TYPE.COMPOUND)) then
            IN.tag.display = IN.tag.lastFound
            if(OUT.tag.display == nil) then OUT.tag.display = OUT.tag:addChild(TagCompound.new("display")) end

            if(IN.tag.display:contains("color", TYPE.INT)) then OUT.tag.display:addChild(IN.tag.display.lastFound:clone()) end

            if(OUT.tag.display.childCount == 0) then
                OUT.tag:removeChild(OUT.tag.display:getRow())
                OUT.tag.display = nil
            end
        end
        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    return OUT
end

function Item:ConvertSpawnEgg(IN, OUT)
    local validEgg = false
    if(IN:contains("ItemIdentifier", TYPE.STRING)) then
        IN.ItemIdentifier = IN.lastFound.value
        if(IN.ItemIdentifier:find("^minecraft:")) then IN.ItemIdentifier = IN.ItemIdentifier:sub(11) end

        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
    
        if(Settings:dataTableContains("entities_names", IN.ItemIdentifier)) then
            local entry = Settings.lastFound
            OUT.tag.EntityTag = OUT.tag:addChild(TagCompound.new("EntityTag"))
            OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            validEgg = true
        end

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    if(validEgg == false) then return nil end

    return OUT
end

function Item:ConvertPotion(IN, OUT)
    if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
        
    if(Settings:dataTableContains("potions", tostring(IN.Damage))) then
        OUT.tag:addChild(TagString.new("Potion", "minecraft:" .. Settings.lastFound[1][1]))
    end

    if(OUT.tag.childCount == 0) then
        OUT:removeChild(OUT.tag:getRow())
        OUT.tag = nil
    end

    return OUT
end

function Item:ConvertFirework(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

        if(IN.tag:contains("Fireworks", TYPE.COMPOUND)) then
            IN.tag.Fireworks = IN.tag.lastFound
            OUT.tag.Fireworks = OUT.tag:addChild(TagCompound.new("Fireworks"))

            if(IN.tag.Fireworks:contains("Flight", TYPE.BYTE)) then OUT.tag.Fireworks:addChild(IN.tag.Fireworks.lastFound:clone()) else OUT.tag.Fireworks:addChild(TagByte.new("Flight", 1)) end 

            if(IN.tag.Fireworks:contains("Explosions", TYPE.LIST, TYPE.COMPOUND)) then
                IN.tag.Fireworks.Explosions = IN.tag.Fireworks.lastFound
                OUT.tag.Fireworks.Explosions = OUT.tag.Fireworks:addChild(TagList.new("Explosions"))

                for i=0, IN.tag.Fireworks.Explosions.childCount-1 do
                    local explosion_out = Item:ConvertFireworkExplosion(IN.tag.Fireworks.Explosions:child(i))
                    if(explosion_out ~= nil) then OUT.tag.Fireworks.Explosions:addChild(explosion_out) end
                end

                if(OUT.tag.Fireworks.Explosions.childCount == 0) then
                    OUT.tag.Fireworks:removeChild(OUT.tag.Fireworks.Explosions:getRow())
                    OUT.tag.Fireworks.Explosions = nil
                end

            else IN.tag.Fireworks:addChild(TagList.new("Explosions")) end

            if(OUT.tag.Fireworks.childCount == 0) then
                OUT.tag:removeChild(OUT.tag.Fireworks:getRow())
                OUT.tag.Fireworks = nil
            end
        end

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    return OUT
end

function Item:ConvertFireworkCharge(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

        if(IN.tag:contains("FireworksItem", TYPE.COMPOUND)) then
            local explosion_out = Item:ConvertFireworkExplosion(IN.tag.lastFound)
            if(explosion_out ~= nil) then OUT.tag:addChild(explosion_out) end
        end

        --TODO customColor

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    return OUT
end

function Item:ConvertArrow(IN, OUT)
    if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

    if(IN.Damage ~= 0) then
        if(Settings:dataTableContains("potions", tostring(IN.Damage-1))) then
            OUT.tag:addChild(TagString.new("Potion", "minecraft:" .. Settings.lastFound[1][1]))
            OUT.id.value = "minecraft:tipped_arrow"
        end
    end

    if(OUT.tag.childCount == 0) then
        OUT:removeChild(OUT.tag:getRow())
        OUT.tag = nil
    end

    return OUT
end
------------

function Item:ConvertFireworkExplosion(IN)
    local OUT = TagCompound.new("Explosion")

    if(IN:contains("FireworkFlicker", TYPE.BYTE)) then OUT:addChild(TagByte.new("Flicker", IN.lastFound.value ~= 0)) end
    if(IN:contains("FireworkTrail", TYPE.BYTE)) then OUT:addChild(TagByte.new("Trail", IN.lastFound.value ~= 0)) end
    if(IN:contains("FireworkType", TYPE.BYTE)) then OUT:addChild(TagByte.new("Type", IN.lastFound.value ~= 0)) else OUT:addChild(TagByte.new("Type")) end

    --TODO
    --if(IN:contains("Colors", TYPE.INT_ARRAY)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    --if(IN:contains("FadeColors", TYPE.INT_ARRAY)) then OUT:addChild(IN.lastFound:clone()) end

    return OUT
end

function Item:CompareStates(statesString, statesTags)
    for state in statesString:gmatch("([^|]*)|?") do 
        state = state:gsub("^%s*(.-)%s*$", "%1")

        local equalsIndex = state:find("=")
        if(equalsIndex ~= nil) then
            local stateName = state:sub(1, equalsIndex-1)
            local stateValue = state:sub(equalsIndex+1)

            if(stateName:find("^1_")) then
                if(statesTags:contains(stateName:sub(3), TYPE.BYTE)) then
                    if(statesTags.lastFound.value ~= tonumber(stateValue)) then return false end
                else return false end
            elseif(stateName:find("^3_")) then
                if(statesTags:contains(stateName:sub(3), TYPE.INT)) then
                    if(statesTags.lastFound.value ~= tonumber(stateValue)) then return false end
                else return false end
            elseif(stateName:find("^8_")) then
                if(statesTags:contains(stateName:sub(3), TYPE.STRING)) then
                    if(statesTags.lastFound.value ~= stateValue) then return false end
                else return false end
            end
        else return false end
    end
    return true
end

return Item