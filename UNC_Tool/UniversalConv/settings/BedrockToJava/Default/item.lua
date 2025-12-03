Item = {}
TileEntity = TileEntity or require("tileEntity")
Utils = Utils or require("utils")

function Item:ConvertItem(IN, slotRequired)
    local OUT = TagCompound.new()

    if(IN:contains("Damage", TYPE.SHORT)) then IN.Damage = IN.lastFound.value else return nil end

    if(IN:contains("Count", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) else return nil end

    if(IN:contains("Slot", TYPE.BYTE) and slotRequired) then OUT:addChild(IN.lastFound:clone()) elseif(slotRequired) then return nil end

    if(IN:contains("Name", TYPE.STRING)) then
        IN.id = IN.lastFound
    elseif(IN:contains("id", TYPE.SHORT)) then
        IN.id = IN.lastFound
    else return nil end

    local item = Utils:findItem(IN.id, IN.Damage)
    if(item == nil) then return nil end
    if(item.id == nil) then return nil end
    if(item.id:find("^minecraft:")) then item.id = item.id:sub(11) end

    OUT.id = OUT:addChild(TagString.new("id", "minecraft:" .. item.id))

    if(IN:contains("Block", TYPE.COMPOUND)) then
        IN.Block = IN.lastFound
        if(IN.Block:contains("name", TYPE.STRING)) then IN.Block.id = IN.Block.lastFound.value end
        if(IN.Block:contains("states", TYPE.COMPOUND)) then
            IN.Block.meta = IN.Block.lastFound
            if(IN.Block.meta:contains("mapped_type", TYPE.INT)) then
                IN.Block.meta = IN.Block.meta.lastFound.value
            end
        end
        if(IN.Block:contains("val", TYPE.SHORT)) then IN.Block.meta = IN.Block.lastFound end

        local block = Utils:findBlock(IN.Block.id, IN.Block.meta)
        if(block ~= nil) then
            if(block.id ~= nil) then
                if(block.id ~= "wall_torch") then
                    OUT.id.value = "minecraft:" .. block.id
                end
            end
        end
    end

    if(item.tileEntity:len() ~= 0) then
        if(IN:contains("tag", TYPE.COMPOUND)) then
            IN.tag = IN.lastFound
    
            IN.tag.curBlock = TagCompound.new()
            IN.tag.curBlock.Name = IN.tag.curBlock:addChild(TagString.new("Name", OUT.id.value))
            IN.tag.curBlock.save = false
    
            --local id = OUT.id.value
            --if(id:find("^minecraft:")) then id = id:sub(11) end
    
            local BlockEntityTag_out = TagCompound.new("BlockEntityTag")
    
            if(Settings:dataTableContains("tileEntities", item.tileEntity)) then
                local entry = Settings.lastFound
                BlockEntityTag_out = TileEntity[entry[1][2]](TileEntity, IN.tag, BlockEntityTag_out, false)
            end
    
            if(IN.tag.curBlock.save) then OUT.id.value = IN.tag.curBlock.Name.value end
    
            if(BlockEntityTag_out ~= nil) then
                if(BlockEntityTag_out.childCount ~= 0) then
                    if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
                    OUT.tag:addChild(BlockEntityTag_out)
                end
            end
    
        end
    end

    OUT = Item:ConvertLore(IN, OUT)

    OUT = Item:ConvertRepairCost(IN, OUT)
	
    OUT = Item:ConvertDisplayName(IN, OUT)
	
    OUT = Item:ConvertEnchantments(IN, OUT)

    if(item.flags:len() ~= 0) then
        for flag in item.flags:gmatch("([^|]*)|?") do 
            flag = flag:gsub("^%s*(.-)%s*$", "%1")
            
            if(flag == "DURABILITY") then OUT = Item:ConvertDurability(IN, OUT)
            elseif(flag == "STORED_ENCH") then OUT = Item:ConvertStoredEnchantments(IN, OUT)
            elseif(flag == "SPAWN_EGG") then OUT = Item:ConvertSpawnEgg(IN, OUT)
            elseif(flag == "COLORED") then OUT = Item:ConvertColor(IN, OUT)
            elseif(flag == "POTION") then OUT = Item:ConvertPotion(IN, OUT)
            elseif(flag == "ARROW") then OUT = Item:ConvertArrow(IN, OUT)
            elseif(flag == "BOOK") then OUT = Item:ConvertBook(IN, OUT)
            elseif(flag == "FIREWORK") then OUT = Item:ConvertFirework(IN, OUT)
            elseif(flag == "FIREWORK_CHARGE") then OUT = Item:ConvertFireworkCharge(IN, OUT)
            end

        end
    end
	
    return OUT
end

function Item:ConvertLore(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
        if(IN.tag:contains("display", TYPE.COMPOUND)) then
            IN.tag.display = IN.tag.lastFound
            if(OUT.tag.display == nil) then OUT.tag.display = OUT.tag:addChild(TagCompound.new("display")) end

            if(IN.tag.display:contains("Lore", TYPE.LIST, TYPE.STRING)) then
                local Lore = IN.tag.display.lastFound

                OUT.tag.display.Lore = OUT.tag.display:addChild(TagList.new("Lore"))

                for i=0, Lore.childCount-1 do
                    local currentLore = Lore:child(i).value

                    currentLore = currentLore:gsub("^%s*(.-)%s*$", "%1")

                    currentLore = currentLore:gsub("\\", "\\\\")
                    currentLore = currentLore:gsub("\"", "\\\"")

                    OUT.tag.display.Lore:addChild(TagString.new("", "\"" .. currentLore .. "\""))
                end

                if(OUT.tag.display.Lore.childCount == 0) then
                    OUT.tag.display:removeChild(OUT.tag.display.Lore:getRow())
                    OUT.tag.display.Lore = nil
                end
            end

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

            if(IN.tag.display:contains("Name", TYPE.STRING)) then OUT.tag.display:addChild(TagString.new("Name", "{\"text\":\"" .. IN.tag.display.lastFound.value .. "\"}")) end

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

function Item:ConvertDurability(IN, OUT)
    if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

    local durability = IN.Damage
    
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(IN.tag:contains("Unbreakable", TYPE.BYTE)) then OUT.tag:addChild(TagByte.new("Unbreakable", IN.tag.lastFound.value ~= 0)) end
        if(IN.tag:contains("Damage", TYPE.INT)) then durability = IN.tag.lastFound.value end
    end

    if(OUT.id.value == "minecraft:crossbow") then
        durability = (durability/464)*326;
        durability = durability>=0 and math.floor(durability+0.5) or math.ceil(durability-0.5)
    end

    OUT.tag.Damage = OUT.tag:addChild(TagInt.new("Damage", durability))

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
        elseif(IN.tag:contains("customColor", TYPE.INT)) then
            IN.tag.customColor = IN.tag.lastFound
            if(OUT.tag.display == nil) then OUT.tag.display = OUT.tag:addChild(TagCompound.new("display")) end

            OUT.tag.display:addChild(TagInt.new("color", IN.tag.customColor.value))
        end
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
            if(OUT.tag.ench == nil) then OUT.tag.ench = OUT.tag:addChild(TagList.new("Enchantments")) end

            for i=0, IN.tag.ench.childCount-1 do
                local ench_in = IN.tag.ench:child(i)
                local ench_out = TagCompound.new()
				
				if(ench_in:contains("id", TYPE.SHORT)) then
				
                    local id = ench_in.lastFound.value

                    if(id == 0) then ench_out:addChild(TagString.new("id", "minecraft:protection"))
                    elseif(id == 1) then ench_out:addChild(TagString.new("id", "minecraft:fire_protection"))
                    elseif(id == 2) then ench_out:addChild(TagString.new("id", "minecraft:feather_falling"))
                    elseif(id == 3) then ench_out:addChild(TagString.new("id", "minecraft:blast_protection"))
                    elseif(id == 4) then ench_out:addChild(TagString.new("id", "minecraft:projectile_protection"))
                    elseif(id == 5) then ench_out:addChild(TagString.new("id", "minecraft:thorns"))
                    elseif(id == 6) then ench_out:addChild(TagString.new("id", "minecraft:respiration"))
                    elseif(id == 7) then ench_out:addChild(TagString.new("id", "minecraft:depth_strider"))
                    elseif(id == 8) then ench_out:addChild(TagString.new("id", "minecraft:aqua_affinity"))
                    elseif(id == 9) then ench_out:addChild(TagString.new("id", "minecraft:sharpness"))
                    elseif(id == 10) then ench_out:addChild(TagString.new("id", "minecraft:smite"))
                    elseif(id == 11) then ench_out:addChild(TagString.new("id", "minecraft:bane_of_arthropods"))
                    elseif(id == 12) then ench_out:addChild(TagString.new("id", "minecraft:knockback"))
                    elseif(id == 13) then ench_out:addChild(TagString.new("id", "minecraft:fire_aspect"))
                    elseif(id == 14) then ench_out:addChild(TagString.new("id", "minecraft:looting"))
                    elseif(id == 15) then ench_out:addChild(TagString.new("id", "minecraft:efficiency"))
                    elseif(id == 16) then ench_out:addChild(TagString.new("id", "minecraft:silk_touch"))
                    elseif(id == 17) then ench_out:addChild(TagString.new("id", "minecraft:unbreaking"))
                    elseif(id == 18) then ench_out:addChild(TagString.new("id", "minecraft:fortune"))
                    elseif(id == 19) then ench_out:addChild(TagString.new("id", "minecraft:power"))
                    elseif(id == 20) then ench_out:addChild(TagString.new("id", "minecraft:punch"))
                    elseif(id == 21) then ench_out:addChild(TagString.new("id", "minecraft:flame"))
                    elseif(id == 22) then ench_out:addChild(TagString.new("id", "minecraft:infinity"))
                    elseif(id == 23) then ench_out:addChild(TagString.new("id", "minecraft:luck_of_the_sea"))
                    elseif(id == 24) then ench_out:addChild(TagString.new("id", "minecraft:lure"))
                    elseif(id == 25) then ench_out:addChild(TagString.new("id", "minecraft:frost_walker"))
                    elseif(id == 26) then ench_out:addChild(TagString.new("id", "minecraft:mending"))
                    elseif(id == 29) then ench_out:addChild(TagString.new("id", "minecraft:impaling"))
                    elseif(id == 30) then ench_out:addChild(TagString.new("id", "minecraft:riptide"))
                    elseif(id == 31) then ench_out:addChild(TagString.new("id", "minecraft:loyalty"))
                    elseif(id == 32) then ench_out:addChild(TagString.new("id", "minecraft:channeling"))
                    elseif(id == 33) then ench_out:addChild(TagString.new("id", "minecraft:multishot"))
                    elseif(id == 34) then ench_out:addChild(TagString.new("id", "minecraft:piercing"))
                    elseif(id == 35) then ench_out:addChild(TagString.new("id", "minecraft:quick_charge"))
                    elseif(id == 36) then ench_out:addChild(TagString.new("id", "minecraft:soul_speed"))
					else goto enchContinue end
					
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

function Item:ConvertSpawnEgg(IN, OUT)
    if(IN:contains("ItemIdentifier", TYPE.STRING)) then
        IN.ItemIdentifier = IN.lastFound.value
        if(IN.ItemIdentifier:find("^minecraft:")) then IN.ItemIdentifier = IN.ItemIdentifier:sub(11) end
    
        if(Settings:dataTableContains("entities_names", IN.ItemIdentifier)) then
            local entry = Settings.lastFound

            OUT.id.value = "minecraft:" .. entry[1][1] .. "_spawn_egg"
        end
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

function Item:ConvertBook(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

        if(IN.tag:contains("author", TYPE.STRING)) then OUT.tag:addChild(IN.tag.lastFound:clone()) else OUT.tag:addChild(TagString.new("author")) end
        if(IN.tag:contains("title", TYPE.STRING)) then OUT.tag:addChild(IN.tag.lastFound:clone()) else OUT.tag:addChild(TagString.new("title")) end
        if(IN.tag:contains("generation", TYPE.INT)) then OUT.tag:addChild(IN.tag.lastFound:clone()) else OUT.tag:addChild(TagInt.new("generation")) end

        OUT.tag.pages = OUT.tag:addChild(TagList.new("pages"))

        if(IN.tag:contains("pages", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.pages = IN.tag.lastFound

            for i=0, IN.tag.pages.childCount-1 do
                local page = IN.tag.pages:child(i)

                if(page:contains("text", TYPE.STRING)) then
                    local pageText = page.lastFound.value

                    pageText = pageText:gsub('\\', "\\\\")
                    pageText = pageText:gsub('\n', "\\n")
                    pageText = pageText:gsub('\"', "\\\"")
                    OUT.tag.pages:addChild(TagString.new("", "{\"text\":\"" .. pageText .. "\"}"))
                end
            end
        end

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    return OUT
end

----------------- Base functions

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

return Item