Item = {}
TileEntity = TileEntity or require("tileEntity")

function Item:ConvertItem(IN, slotRequired)
    local OUT = TagCompound.new()

    local ChunkVersion = Settings:getSettingInt("ChunkVersion")

    if(IN:contains("Damage", TYPE.SHORT)) then IN.Damage = IN.lastFound.value else return nil end

    if(IN:contains("Count", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) else return nil end

    if(IN:contains("Slot", TYPE.BYTE) and slotRequired) then OUT:addChild(IN.lastFound:clone()) elseif(slotRequired) then return nil end

    local dataTableName = "items_names"
    if(IN:contains("id", TYPE.STRING)) then
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
            OUT.flags = subEntry[4]
            OUT.tileEntity = subEntry[5]
            break
            ::entryContinue::
        end
        if(OUT.id == nil) then return nil end
    else return nil end

    if(OUT.tileEntity:len() ~= 0) then
        if(IN:contains("tag", TYPE.COMPOUND)) then
            IN.tag = IN.lastFound
            if(IN.tag:contains("BlockEntityTag", TYPE.COMPOUND)) then
                IN.tag.BlockEntityTag = IN.tag.lastFound
                IN.tag.BlockEntityTag.curBlock = TagCompound.new()
                IN.tag.BlockEntityTag.curBlock.Name = IN.tag.BlockEntityTag.curBlock:addChild(TagString.new("Name", OUT.id.value))
                IN.tag.BlockEntityTag.curBlock.save = false

                local BlockEntityTag_out = TagCompound.new("BlockEntityTag")
                
                local id = OUT.tileEntity

                if(Settings:dataTableContains("tileEntities", id)) then
                    local entry = Settings.lastFound
                    BlockEntityTag_out = TileEntity[entry[1][2]](TileEntity, IN.tag.BlockEntityTag, BlockEntityTag_out, false)
                end

                if(IN.tag.BlockEntityTag.curBlock.save) then OUT.id.value = IN.tag.BlockEntityTag.curBlock.Name.value end

                if(BlockEntityTag_out ~= nil) then
                    if(BlockEntityTag_out.childCount ~= 0) then
                        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
                        OUT.tag:addChild(BlockEntityTag_out)
                    end
                end
            end
        end
    end

    OUT = Item:ConvertRepairCost(IN, OUT)

    OUT = Item:ConvertDisplayName(IN, OUT)

    OUT = Item:ConvertEnchantments(IN, OUT)

    OUT = Item:ConvertAttributeModifiers(IN, OUT)

    if(OUT.flags:len() ~= 0) then
        for flag in OUT.flags:gmatch("([^|]*)|?") do 
            flag = flag:gsub("^%s*(.-)%s*$", "%1")
            
            if(flag == "DURABILITY") then OUT = Item:ConvertDurability(IN, OUT)
            elseif(flag == "STORED_ENCH") then OUT = Item:ConvertStoredEnchantments(IN, OUT)
            elseif(flag == "SPAWN_EGG") then OUT = Item:ConvertSpawnEgg(IN, OUT)
            elseif(flag == "COLORED") then OUT = Item:ConvertColor(IN, OUT)
            elseif(flag == "POTION") then OUT = Item:ConvertPotion(IN, OUT)
            elseif(flag == "BOOK") then OUT = Item:ConvertBook(IN, OUT)
            elseif(flag == "FIREWORK") then OUT = Item:ConvertFirework(IN, OUT)
            elseif(flag == "FIREWORK_CHARGE") then OUT = Item:ConvertFireworkCharge(IN, OUT)
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

            if(IN.tag.display:contains("Name", TYPE.STRING)) then
                local name = IN.tag.display.lastFound.value
                name = name:gsub('\n', "\\n")
                name = name:gsub('\"', "\\\"")
                name = name:gsub('\\', "\\\\")
                OUT.tag.display:addChild(TagString.new("Name", "{\"text\":\"" .. name .. "\"}"))
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

function Item:ConvertEnchantments(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
        if(IN.tag:contains("ench", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.ench = IN.tag.lastFound
            if(OUT.tag.Enchantments == nil) then OUT.tag.Enchantments = OUT.tag:addChild(TagList.new("Enchantments")) end

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
                    elseif(id == 5) then ench_out:addChild(TagString.new("id", "minecraft:respiration"))
                    elseif(id == 6) then ench_out:addChild(TagString.new("id", "minecraft:aqua_affinity"))
                    elseif(id == 7) then ench_out:addChild(TagString.new("id", "minecraft:thorns"))
                    elseif(id == 8) then ench_out:addChild(TagString.new("id", "minecraft:depth_strider"))
                    elseif(id == 9) then ench_out:addChild(TagString.new("id", "minecraft:frost_walker"))
                    elseif(id == 10) then ench_out:addChild(TagString.new("id", "minecraft:binding_curse"))
                    elseif(id == 16) then ench_out:addChild(TagString.new("id", "minecraft:sharpness"))
                    elseif(id == 17) then ench_out:addChild(TagString.new("id", "minecraft:smite"))
                    elseif(id == 18) then ench_out:addChild(TagString.new("id", "minecraft:bane_of_arthropods"))
                    elseif(id == 19) then ench_out:addChild(TagString.new("id", "minecraft:knockback"))
                    elseif(id == 20) then ench_out:addChild(TagString.new("id", "minecraft:fire_aspect"))
                    elseif(id == 21) then ench_out:addChild(TagString.new("id", "minecraft:looting"))
                    elseif(id == 32) then ench_out:addChild(TagString.new("id", "minecraft:efficiency"))
                    elseif(id == 33) then ench_out:addChild(TagString.new("id", "minecraft:silk_touch"))
                    elseif(id == 34) then ench_out:addChild(TagString.new("id", "minecraft:unbreaking"))
                    elseif(id == 35) then ench_out:addChild(TagString.new("id", "minecraft:fortune"))
                    elseif(id == 48) then ench_out:addChild(TagString.new("id", "minecraft:power"))
                    elseif(id == 49) then ench_out:addChild(TagString.new("id", "minecraft:punch"))
                    elseif(id == 50) then ench_out:addChild(TagString.new("id", "minecraft:flame"))
                    elseif(id == 51) then ench_out:addChild(TagString.new("id", "minecraft:infinity"))
                    elseif(id == 61) then ench_out:addChild(TagString.new("id", "minecraft:luck_of_the_sea"))
                    elseif(id == 62) then ench_out:addChild(TagString.new("id", "minecraft:lure"))
                    elseif(id == 65) then ench_out:addChild(TagString.new("id", "minecraft:loyalty"))
                    elseif(id == 66) then ench_out:addChild(TagString.new("id", "minecraft:impaling"))
                    elseif(id == 67) then ench_out:addChild(TagString.new("id", "minecraft:riptide"))
                    elseif(id == 68) then ench_out:addChild(TagString.new("id", "minecraft:channeling"))
                    elseif(id == 70) then ench_out:addChild(TagString.new("id", "minecraft:mending"))
                    elseif(id == 71) then ench_out:addChild(TagString.new("id", "minecraft:vanishing_curse"))
                    else goto enchContinue
                    end
                else goto enchContinue
                end
                if(ench_in:contains("lvl", TYPE.SHORT)) then ench_out:addChild(ench_in.lastFound:clone()) else goto enchContinue end
                OUT.tag.Enchantments:addChild(ench_out)
                ::enchContinue::
            end

            if(OUT.tag.Enchantments.childCount == 0) then
                OUT.tag:removeChild(OUT.tag.Enchantments:getRow())
                OUT.tag.Enchantments = nil
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
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
        if(IN.tag:contains("StoredEnchantments", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.StoredEnchantments = IN.tag.lastFound
            if(OUT.tag.StoredEnchantments == nil) then OUT.tag.StoredEnchantments = OUT.tag:addChild(TagList.new("StoredEnchantments")) end

            for i=0, IN.tag.StoredEnchantments.childCount-1 do
                local ench_in = IN.tag.StoredEnchantments:child(i)
                local ench_out = TagCompound.new()
                if(ench_in:contains("id", TYPE.SHORT)) then
                    local id = ench_in.lastFound.value
                    if(id == 0) then ench_out:addChild(TagString.new("id", "minecraft:protection"))
                    elseif(id == 1) then ench_out:addChild(TagString.new("id", "minecraft:fire_protection"))
                    elseif(id == 2) then ench_out:addChild(TagString.new("id", "minecraft:feather_falling"))
                    elseif(id == 3) then ench_out:addChild(TagString.new("id", "minecraft:blast_protection"))
                    elseif(id == 4) then ench_out:addChild(TagString.new("id", "minecraft:projectile_protection"))
                    elseif(id == 5) then ench_out:addChild(TagString.new("id", "minecraft:respiration"))
                    elseif(id == 6) then ench_out:addChild(TagString.new("id", "minecraft:aqua_affinity"))
                    elseif(id == 7) then ench_out:addChild(TagString.new("id", "minecraft:thorns"))
                    elseif(id == 8) then ench_out:addChild(TagString.new("id", "minecraft:depth_strider"))
                    elseif(id == 9) then ench_out:addChild(TagString.new("id", "minecraft:frost_walker"))
                    elseif(id == 10) then ench_out:addChild(TagString.new("id", "minecraft:binding_curse"))
                    elseif(id == 16) then ench_out:addChild(TagString.new("id", "minecraft:sharpness"))
                    elseif(id == 17) then ench_out:addChild(TagString.new("id", "minecraft:smite"))
                    elseif(id == 18) then ench_out:addChild(TagString.new("id", "minecraft:bane_of_arthropods"))
                    elseif(id == 19) then ench_out:addChild(TagString.new("id", "minecraft:knockback"))
                    elseif(id == 20) then ench_out:addChild(TagString.new("id", "minecraft:fire_aspect"))
                    elseif(id == 21) then ench_out:addChild(TagString.new("id", "minecraft:looting"))
                    elseif(id == 32) then ench_out:addChild(TagString.new("id", "minecraft:efficiency"))
                    elseif(id == 33) then ench_out:addChild(TagString.new("id", "minecraft:silk_touch"))
                    elseif(id == 34) then ench_out:addChild(TagString.new("id", "minecraft:unbreaking"))
                    elseif(id == 35) then ench_out:addChild(TagString.new("id", "minecraft:fortune"))
                    elseif(id == 48) then ench_out:addChild(TagString.new("id", "minecraft:power"))
                    elseif(id == 49) then ench_out:addChild(TagString.new("id", "minecraft:punch"))
                    elseif(id == 50) then ench_out:addChild(TagString.new("id", "minecraft:flame"))
                    elseif(id == 51) then ench_out:addChild(TagString.new("id", "minecraft:infinity"))
                    elseif(id == 61) then ench_out:addChild(TagString.new("id", "minecraft:luck_of_the_sea"))
                    elseif(id == 62) then ench_out:addChild(TagString.new("id", "minecraft:lure"))
                    elseif(id == 65) then ench_out:addChild(TagString.new("id", "minecraft:loyalty"))
                    elseif(id == 66) then ench_out:addChild(TagString.new("id", "minecraft:impaling"))
                    elseif(id == 67) then ench_out:addChild(TagString.new("id", "minecraft:riptide"))
                    elseif(id == 68) then ench_out:addChild(TagString.new("id", "minecraft:channeling"))
                    elseif(id == 70) then ench_out:addChild(TagString.new("id", "minecraft:mending"))
                    elseif(id == 71) then ench_out:addChild(TagString.new("id", "minecraft:vanishing_curse"))
                    else goto enchContinue
                    end
                else goto enchContinue
                end
                if(ench_in:contains("lvl", TYPE.SHORT)) then ench_out:addChild(ench_in.lastFound:clone()) else goto enchContinue end
                OUT.tag.StoredEnchantments:addChild(ench_out)
                ::enchContinue::
            end

            if(OUT.tag.StoredEnchantments.childCount == 0) then
                OUT.tag:removeChild(OUT.tag.StoredEnchantments:getRow())
                OUT.tag.StoredEnchantments = nil
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
    OUT.tag:addChild(TagInt.new("Damage", IN.Damage))
    
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(IN.tag:contains("Unbreakable", TYPE.BYTE)) then OUT.tag:addChild(TagByte.new("Unbreakable", IN.tag.lastFound.value ~= 0)) end
    end

    return OUT
end

function Item:ConvertSpawnEgg(IN, OUT)

    local hasEntitytag = false
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound

        if(IN.tag:contains("EntityTag", TYPE.COMPOUND)) then
            IN.tag.EntityTag = IN.tag.lastFound

            if(IN.tag.EntityTag:contains("id", TYPE.STRING)) then
                local eggID = IN.tag.EntityTag.lastFound.value
                if(eggID:find("^minecraft:")) then eggID = eggID:sub(11) end

                hasEntitytag = true

                if(Settings:dataTableContains("entities", eggID)) then
                    local entry = Settings.lastFound
                    OUT.id.value = "minecraft:" .. entry[1][1] .. "_spawn_egg"
                end
            end
        end

    end

    if(hasEntitytag == false) then

        local id = ""

        if(IN.Damage == 4) then id = "elder_guardian"
        elseif(IN.Damage == 5) then id= "wither_skeleton"
        elseif(IN.Damage == 6) then id = "stray"
        elseif(IN.Damage == 23) then id = "husk"
        elseif(IN.Damage == 27) then id = "zombie_villager"
        elseif(IN.Damage == 28) then id = "skeleton_horse"
        elseif(IN.Damage == 29) then id = "zombie_horse"
        elseif(IN.Damage == 31) then id = "donkey"
        elseif(IN.Damage == 32) then id = "mule"
        elseif(IN.Damage == 34) then id = "evoker"
        elseif(IN.Damage == 35) then id = "vex"
        elseif(IN.Damage == 36) then id = "vindicator"
        elseif(IN.Damage == 50) then id = "creeper"
        elseif(IN.Damage == 51) then id = "skeleton"
        elseif(IN.Damage == 52) then id = "spider"
        elseif(IN.Damage == 54) then id = "zombie"
        elseif(IN.Damage == 55) then id = "slime"
        elseif(IN.Damage == 56) then id = "ghast"
        elseif(IN.Damage == 57) then id = "zombie_pigman"
        elseif(IN.Damage == 58) then id = "enderman"
        elseif(IN.Damage == 59) then id = "cave_spider"
        elseif(IN.Damage == 60) then id = "silverfish"
        elseif(IN.Damage == 61) then id = "blaze"
        elseif(IN.Damage == 62) then id = "magma_cube"
        elseif(IN.Damage == 65) then id = "bat"
        elseif(IN.Damage == 66) then id = "witch"
        elseif(IN.Damage == 67) then id = "endermite"
        elseif(IN.Damage == 68) then id = "guardian"
        elseif(IN.Damage == 69) then id = "shulker"
        elseif(IN.Damage == 90) then id = "pig"
        elseif(IN.Damage == 91) then id = "sheep"
        elseif(IN.Damage == 92) then id = "cow"
        elseif(IN.Damage == 93) then id = "chicken"
        elseif(IN.Damage == 94) then id = "squid"
        elseif(IN.Damage == 95) then id = "wolf"
        elseif(IN.Damage == 96) then id = "mooshroom"
        elseif(IN.Damage == 98) then id = "ocelot"
        elseif(IN.Damage == 100) then id = "horse"
        elseif(IN.Damage == 101) then id = "rabbit"
        elseif(IN.Damage == 102) then id = "polar_bear"
        elseif(IN.Damage == 103) then id = "llama"
        elseif(IN.Damage == 105) then id = "parrot"
        elseif(IN.Damage == 120) then id = "villager"
        end

        OUT.id.value = "minecraft:" .. id .. "_spawn_egg"
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

function Item:ConvertPotion(IN, OUT)

    local potionAdded = false
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

        if(IN.tag:contains("Potion", TYPE.STRING)) then
            local potionName = IN.tag.lastFound.value
            if(potionName:find("^minecraft:")) then potionName = potionName:sub(11) end

            if(Settings:dataTableContains("potions", potionName)) then
                OUT.tag:addChild(TagString.new("Potion", "minecraft:" .. potionName))
                potionAdded = true
            end
        end

        if(IN.tag:contains("CustomPotionEffects", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.CustomPotionEffects = IN.tag.lastFound
            OUT.tag.CustomPotionEffects = OUT.tag:addChild(TagList.new("CustomPotionEffects"))

            for i=0, IN.tag.CustomPotionEffects.childCount-1 do
                local effect_in = IN.tag.CustomPotionEffects:child(i)
                local effect_out = TagCompound.new()

                if(effect_in:contains("Id", TYPE.BYTE)) then
                    if(effect_in.lastFound.value > 0 and effect_in.lastFound.value <= 30) then effect_out:addChild(effect_in.lastFound:clone()) end
                else goto effectContinue end

                if(effect_in:contains("ShowParticles", TYPE.BYTE)) then effect_out:addChild(TagByte.new("ShowParticles", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("ShowParticles", true)) end
                if(effect_in:contains("Ambient", TYPE.BYTE)) then effect_out:addChild(TagByte.new("Ambient", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("Ambient")) end
                if(effect_in:contains("Amplifier", TYPE.BYTE)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagByte.new("Amplifier")) end
                if(effect_in:contains("Duration", TYPE.INT)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagInt.new("Duration", 1)) end

                OUT.tag.CustomPotionEffects:addChild(effect_out)

                ::effectContinue::
            end

            if(OUT.tag.CustomPotionEffects.childCount == 0) then
                OUT.tag:removeChild(OUT.tag.CustomPotionEffects:getRow())
                OUT.tag.CustomPotionEffects = nil
            else
                potionAdded = true
            end
        end
        
        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    if(potionAdded == false) then
        local potionName = ""
        local potionId = IN.Damage & tonumber("1111",2)
        local potionStrong = IN.Damage & tonumber("100000",2)
        local potionLong = IN.Damage & tonumber("1000000",2)
        local potionSplash = IN.Damage & tonumber("100000000000000", 2)

        if(potionId == 1) then potionName = "regeneration"
        elseif(potionId == 2) then potionName = "swiftness"
        elseif(potionId == 3) then potionName = "fire_resistance"
        elseif(potionId == 4) then potionName = "poison"
        elseif(potionId == 5) then potionName = "healing"
        elseif(potionId == 6) then potionName = "night_vision"
        elseif(potionId == 8) then potionName = "weakness"
        elseif(potionId == 9) then potionName = "strength"
        elseif(potionId == 10) then potionName = "slowness"
        elseif(potionId == 11) then potionName = "leaping"
        elseif(potionId == 12) then potionName = "harming"
        elseif(potionId == 13) then potionName = "water_breathing"
        elseif(potionId == 14) then potionName = "invisibility"
        end

        if(potionName ~= "") then

            local finalPotionName = ""

            if(potionStrong ~= 0) then
                if(Settings:dataTableContains("potions", "strong_" .. potionName)) then
                    finalPotionName = "strong_" .. potionName
                elseif(Settings:dataTableContains("potions", "long_" .. potionName)) then
                    finalPotionName = "long_" .. potionName
                end
            elseif(potionLong ~= 0) then
                if(Settings:dataTableContains("potions", "long_" .. potionName)) then
                    finalPotionName = "long_" .. potionName
                elseif(Settings:dataTableContains("potions", "strong_" .. potionName)) then
                    finalPotionName = "strong_" .. potionName
                end
            end

            if(finalPotionName ~= "") then
                if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
                OUT.tag:addChild(TagString.new("Potion", "minecraft:" .. finalPotionName))

                if(potionSplash ~= 0) then
                    OUT.id.value = "minecraft:splash_potion"
                end
            end
        end
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

        if(IN.tag:contains("pages", TYPE.LIST, TYPE.STRING)) then
            IN.tag.pages = IN.tag.lastFound

            for i=0, IN.tag.pages.childCount-1 do
                local page = IN.tag.pages:child(i).value
                page = page:gsub('\\', "\\\\")
                page = page:gsub('\n', "\\n")
                page = page:gsub('\"', "\\\"")
                OUT.tag.pages:addChild(TagString.new("", "{\"text\":\"" .. page .. "\"}"))
            end
        end

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
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

        if(IN.tag:contains("Explosion", TYPE.COMPOUND)) then
            local explosion_out = Item:ConvertFireworkExplosion(IN.tag.lastFound)
            if(explosion_out ~= nil) then OUT.tag:addChild(explosion_out) end
        end

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    return OUT
end

function Item:ConvertAttributeModifiers(IN, OUT)

    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

        if(IN.tag:contains("AttributeModifiers", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.AttributeModifiers = IN.tag.lastFound
            OUT.tag.AttributeModifiers = OUT.tag:addChild(TagList.new("AttributeModifiers"))

            for i=0, IN.tag.AttributeModifiers.childCount-1 do
                local attribute_in = IN.tag.AttributeModifiers:child(i)
                local attribute_out = TagCompound.new()

                if(attribute_in:contains("ID", TYPE.INT)) then
                    local attributeID = attribute_in.lastFound.value

                    if(attributeID == 0) then attribute_out:addChild(TagString.new("AttributeName", "generic.maxHealth"))
                    elseif(attributeID == 1) then attribute_out:addChild(TagString.new("AttributeName", "generic.followRange"))
                    elseif(attributeID == 2) then attribute_out:addChild(TagString.new("AttributeName", "generic.knockbackResistance"))
                    elseif(attributeID == 3) then attribute_out:addChild(TagString.new("AttributeName", "generic.movementSpeed"))
                    elseif(attributeID == 4) then attribute_out:addChild(TagString.new("AttributeName", "generic.attackDamage"))
                    elseif(attributeID == 5) then attribute_out:addChild(TagString.new("AttributeName", "horse.jumpStrength"))
                    elseif(attributeID == 6) then attribute_out:addChild(TagString.new("AttributeName", "zombie.spawnReinforcements"))
                    elseif(attributeID == 7) then attribute_out:addChild(TagString.new("AttributeName", "generic.attackSpeed"))
                    elseif(attributeID == 8) then attribute_out:addChild(TagString.new("AttributeName", "generic.armor"))
                    elseif(attributeID == 9) then attribute_out:addChild(TagString.new("AttributeName", "generic.armorToughness"))
                    elseif(attributeID == 10) then attribute_out:addChild(TagString.new("AttributeName", "generic.luck"))
                    else goto attributeContinue end
                else goto attributeContinue end

                if(attribute_in:contains("Operation", TYPE.INT)) then
                    if(attribute_in.lastFound.value >= 0 or attribute_in.lastFound.value <= 2) then attribute_out:addChild(attribute_in.lastFound:clone()) else goto attributeContinue end
                else goto attributeContinue end

                if(attribute_in:contains("Amount", TYPE.DOUBLE)) then
                    attribute_out:addChild(attribute_in.lastFound:clone())
                else goto attributeContinue end

                if(attribute_in:contains("UUID", TYPE.INT)) then
                    attribute_out:addChild(TagLong.new("UUIDMost", attribute_in.lastFound.value))
                    attribute_out:addChild(TagLong.new("UUIDLeast"))
                else goto attributeContinue end

                if(attribute_in:contains("Slot", TYPE.STRING)) then
                    local Slot = attribute_in.lastFound.value
                    if(Slot == "mainhand" or Slot == "offhand" or Slot == "feet" or Slot == "legs" or Slot == "chest" or Slot == "head") then attribute_out:addChild(attribute_in.lastFound:clone()) end
                end

                if(attribute_in:contains("Name", TYPE.STRING)) then
                    attribute_out:addChild(attribute_in.lastFound:clone())
                end

                OUT.tag.AttributeModifiers:addChild(attribute_out)

                ::attributeContinue::
            end

            if(OUT.tag.AttributeModifiers.childCount == 0) then
                OUT.tag:removeChild(OUT.tag.AttributeModifiers:getRow())
                OUT.tag.AttributeModifiers = nil
            end
        end

        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    return OUT
end

------------------Base functions

function Item:ConvertFireworkExplosion(IN)
    local OUT = TagCompound.new("Explosion")

    if(IN:contains("Colors", TYPE.INT_ARRAY)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("Flicker", TYPE.BYTE)) then OUT:addChild(TagByte.new("Flicker", IN.lastFound.value ~= 0)) end
    if(IN:contains("Trail", TYPE.BYTE)) then OUT:addChild(TagByte.new("Trail", IN.lastFound.value ~= 0)) end
    if(IN:contains("Type", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) else OUT:addChild(TagByte.new("Type")) end
    if(IN:contains("FadeColors", TYPE.INT_ARRAY)) then OUT:addChild(IN.lastFound:clone()) end

    return OUT
end

function Item:StringToProperties(props)
    if(props:len() == 0) then return nil end

    local OUT = TagCompound.new("Properties")
    for prop in props:gmatch("([^|]*)|?") do 
        prop = prop:gsub("^%s*(.-)%s*$", "%1")
        
        local equalsIndex = prop:find("=")
        if(equalsIndex ~= nil) then
            OUT:addChild(TagString.new(prop:sub(1, equalsIndex-1), prop:sub(equalsIndex+1)))
        end
    end

    return OUT
end

return Item