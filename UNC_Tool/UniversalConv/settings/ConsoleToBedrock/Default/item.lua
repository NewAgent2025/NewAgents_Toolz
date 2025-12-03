Item = {}

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
            OUT.id = OUT:addChild(TagString.new("Name", "minecraft:" .. subEntry[3]))
            if(subEntry[4]:len() == 0) then OUT.Damage = OUT:addChild(TagShort.new("Damage", IN.Damage)) else OUT.Damage = OUT:addChild(TagShort.new("Damage", tonumber(subEntry[4]))) end
            OUT.flags = subEntry[5]
            OUT.tileEntity = subEntry[6]
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
                IN.tag.BlockEntityTag.curBlock.val = IN.tag.BlockEntityTag.curBlock:addChild(TagShort.new("val", OUT.Damage.value))
                IN.tag.BlockEntityTag.curBlock.save = false

                local BlockEntityTag_out = TagCompound.new("BlockEntityTag")
                
                if(Settings:dataTableContains("tileEntities", OUT.tileEntity)) then
                    local entry = Settings.lastFound
                    BlockEntityTag_out = TileEntity[entry[1][2]](TileEntity, IN.tag.BlockEntityTag, BlockEntityTag_out, false)
                end

                if(IN.tag.BlockEntityTag.curBlock.save) then
                    OUT.id.value = IN.tag.BlockEntityTag.curBlock.Name.value
                    OUT.Damage.value = IN.tag.BlockEntityTag.curBlock.val.value
                end

                if(BlockEntityTag_out ~= nil) then
                    if(BlockEntityTag_out.childCount ~= 0) then
                        BlockEntityTag_out.name = "tag"
                        OUT.tag = OUT:addChild(BlockEntityTag_out)
                    end
                end
            end
        end
    end

    OUT = Item:ConvertRepairCost(IN, OUT)

    OUT = Item:ConvertDisplayName(IN, OUT)

    OUT = Item:ConvertEnchantments(IN, OUT)

    if(OUT.flags:len() ~= 0) then
        for flag in OUT.flags:gmatch("([^|]*)|?") do 
            flag = flag:gsub("^%s*(.-)%s*$", "%1")
            
            if(flag == "SPAWN_EGG") then OUT = Item:ConvertSpawnEgg(IN, OUT)
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

            if(IN.tag.display:contains("Name", TYPE.STRING)) then OUT.tag.display:addChild(IN.tag.display.lastFound:clone()) end

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
        elseif(IN.tag:contains("StoredEnchantments", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.ench = IN.tag.lastFound
        end

        if(IN.tag.ench ~= nil) then
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
                    elseif(id == 5) then ench_out:addChild(TagShort.new("id", 6))
                    elseif(id == 6) then ench_out:addChild(TagShort.new("id", 8))
                    elseif(id == 7) then ench_out:addChild(TagShort.new("id", 5))
                    elseif(id == 8) then ench_out:addChild(TagShort.new("id", 7))
                    elseif(id == 9) then ench_out:addChild(TagShort.new("id", 25))
                    elseif(id == 16) then ench_out:addChild(TagShort.new("id", 9))
                    elseif(id == 17) then ench_out:addChild(TagShort.new("id", 10))
                    elseif(id == 18) then ench_out:addChild(TagShort.new("id", 11))
                    elseif(id == 19) then ench_out:addChild(TagShort.new("id", 12))
                    elseif(id == 20) then ench_out:addChild(TagShort.new("id", 13))
                    elseif(id == 21) then ench_out:addChild(TagShort.new("id", 14))
                    elseif(id == 32) then ench_out:addChild(TagShort.new("id", 15))
                    elseif(id == 33) then ench_out:addChild(TagShort.new("id", 16))
                    elseif(id == 34) then ench_out:addChild(TagShort.new("id", 17))
                    elseif(id == 35) then ench_out:addChild(TagShort.new("id", 18))
                    elseif(id == 48) then ench_out:addChild(TagShort.new("id", 19))
                    elseif(id == 49) then ench_out:addChild(TagShort.new("id", 20))
                    elseif(id == 50) then ench_out:addChild(TagShort.new("id", 21))
                    elseif(id == 51) then ench_out:addChild(TagShort.new("id", 22))
                    elseif(id == 61) then ench_out:addChild(TagShort.new("id", 23))
                    elseif(id == 62) then ench_out:addChild(TagShort.new("id", 24))
                    elseif(id == 65) then ench_out:addChild(TagShort.new("id", 31))
                    elseif(id == 66) then ench_out:addChild(TagShort.new("id", 29))
                    elseif(id == 67) then ench_out:addChild(TagShort.new("id", 30))
                    elseif(id == 68) then ench_out:addChild(TagShort.new("id", 32))
                    elseif(id == 70) then ench_out:addChild(TagShort.new("id", 26))
                    else goto enchContinue
                    end

                else goto enchContinue
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

function Item:ConvertPotion(IN, OUT)

    local potionAdded = false
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(IN.tag:contains("Potion", TYPE.STRING)) then
            local potionName = IN.tag.lastFound.value
            if(potionName:find("^minecraft:")) then potionName = potionName:sub(11) end

            if(Settings:dataTableContains("potions", potionName)) then
                local entry = Settings.lastFound

                if(OUT.id.value == "minecraft:arrow") then 
                    OUT.Damage.value = tonumber(entry[1][1])+1
                else
                    OUT.Damage.value = tonumber(entry[1][1])
                end
                
                potionAdded = true
            end
        end
    end

    if(potionAdded == false) then
        local potionName = ""
        local potionId = IN.Damage & tonumber("1111",2)
        local potionStrong = IN.Damage & tonumber("100000",2)
        local potionLong = IN.Damage & tonumber("1000000",2)
        local potionSplash = IN.Damage & tonumber("100000000000000",2)

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
                if(Settings:dataTableContains("potions", finalPotionName)) then
                    local entry = Settings.lastFound
                    OUT.Damage.value = tonumber(entry[1][1])
    
                    if(potionSplash ~= 0) then
                        OUT.id.value = "minecraft:splash_potion"
                    end
                end
            end
        end
    end

    return OUT
end

function Item:ConvertSpawnEgg(IN, OUT)

    local hasEntityTag = false
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(IN.tag:contains("EntityTag", TYPE.COMPOUND)) then
            hasEntityTag = true
        end
    end

    if(hasEntityTag) then
        if(IN:contains("tag", TYPE.COMPOUND)) then
            IN.tag = IN.lastFound
            if(IN.tag:contains("EntityTag", TYPE.COMPOUND)) then
                IN.tag.EntityTag = IN.tag.lastFound
                if(IN.tag.EntityTag:contains("id", TYPE.STRING)) then
                    local eggID = IN.tag.EntityTag.lastFound.value
                    if(eggID:find("^minecraft:")) then eggID = eggID:sub(11) end
    
                    if(Settings:dataTableContains("entities", eggID)) then
                        local entry = Settings.lastFound
                        if(entry[1][2]:len() > 0) then OUT.Damage.value = tonumber(entry[1][2]) end
                    end
                end
            end
        end
    else
        --convert console damage to bedrock damage
        if(IN.Damage ~= 0) then
            if(IN.Damage == 4) then OUT.Damage.value = 50
            elseif(IN.Damage == 4) then OUT.Damage.value = 48
            elseif(IN.Damage == 6) then OUT.Damage.value = 46
            elseif(IN.Damage == 23) then OUT.Damage.value = 47
            elseif(IN.Damage == 27) then OUT.Damage.value = 44
            elseif(IN.Damage == 28) then OUT.Damage.value = 26
            elseif(IN.Damage == 29) then OUT.Damage.value = 27
            elseif(IN.Damage == 31) then OUT.Damage.value = 24
            elseif(IN.Damage == 32) then OUT.Damage.value = 25
            elseif(IN.Damage == 34) then OUT.Damage.value = 104
            elseif(IN.Damage == 35) then OUT.Damage.value = 105
            elseif(IN.Damage == 36) then OUT.Damage.value = 57
            elseif(IN.Damage == 50) then OUT.Damage.value = 33
            elseif(IN.Damage == 51) then OUT.Damage.value = 34
            elseif(IN.Damage == 52) then OUT.Damage.value = 35
            elseif(IN.Damage == 54) then OUT.Damage.value = 32
            elseif(IN.Damage == 55) then OUT.Damage.value = 37
            elseif(IN.Damage == 56) then OUT.Damage.value = 41
            elseif(IN.Damage == 57) then OUT.Damage.value = 36
            elseif(IN.Damage == 58) then OUT.Damage.value = 38
            elseif(IN.Damage == 59) then OUT.Damage.value = 40
            elseif(IN.Damage == 60) then OUT.Damage.value = 39
            elseif(IN.Damage == 61) then OUT.Damage.value = 43
            elseif(IN.Damage == 62) then OUT.Damage.value = 42
            elseif(IN.Damage == 65) then OUT.Damage.value = 19
            elseif(IN.Damage == 66) then OUT.Damage.value = 45
            elseif(IN.Damage == 67) then OUT.Damage.value = 55
            elseif(IN.Damage == 68) then OUT.Damage.value = 49
            elseif(IN.Damage == 69) then OUT.Damage.value = 54
            elseif(IN.Damage == 90) then OUT.Damage.value = 12
            elseif(IN.Damage == 91) then OUT.Damage.value = 13
            elseif(IN.Damage == 92) then OUT.Damage.value = 11
            elseif(IN.Damage == 93) then OUT.Damage.value = 10
            elseif(IN.Damage == 94) then OUT.Damage.value = 17
            elseif(IN.Damage == 95) then OUT.Damage.value = 14
            elseif(IN.Damage == 96) then OUT.Damage.value = 16
            elseif(IN.Damage == 98) then OUT.Damage.value = 22
            elseif(IN.Damage == 100) then OUT.Damage.value = 23
            elseif(IN.Damage == 101) then OUT.Damage.value = 18
            elseif(IN.Damage == 102) then OUT.Damage.value = 28
            elseif(IN.Damage == 103) then OUT.Damage.value = 29
            elseif(IN.Damage == 120) then OUT.Damage.value = 15
            else OUT.Damage.value = 0
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
                local pageCompound = TagCompound.new()
                pageCompound:addChild(TagString.new("text", page))
                pageCompound:addChild(TagString.new("photoname"))
                OUT.tag.pages:addChild(pageCompound)
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

function Item:ConvertColor(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
        if(IN.tag:contains("display", TYPE.COMPOUND)) then
            IN.tag.display = IN.tag.lastFound

            if(IN.tag.display:contains("color", TYPE.INT)) then
                OUT.tag:addChild(TagInt.new("customColor", 0xff000000 + IN.tag.display.lastFound.value))
            end
        end
        if(OUT.tag.childCount == 0) then
            OUT:removeChild(OUT.tag:getRow())
            OUT.tag = nil
        end
    end

    return OUT
end

--[[
function Item:ConvertBanner(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(IN.tag:contains("BlockEntityTag", TYPE.COMPOUND)) then
            IN.tag.BlockEntityTag = IN.tag.lastFound
            if(IN.tag.BlockEntityTag:contains("Base", TYPE.INT)) then
                local BaseNum = IN.tag.BlockEntityTag.lastFound.value
                if(BaseNum >= 0 and BaseNum <= 15) then
                    if(BaseNum == 0) then OUT.Damage.value = 15
                    elseif(BaseNum == 1) then OUT.Damage.value = 14
                    elseif(BaseNum == 2) then OUT.Damage.value = 13
                    elseif(BaseNum == 3) then OUT.Damage.value = 12
                    elseif(BaseNum == 4) then OUT.Damage.value = 11
                    elseif(BaseNum == 5) then OUT.Damage.value = 10
                    elseif(BaseNum == 6) then OUT.Damage.value = 9
                    elseif(BaseNum == 7) then OUT.Damage.value = 8
                    elseif(BaseNum == 8) then OUT.Damage.value = 7
                    elseif(BaseNum == 9) then OUT.Damage.value = 6
                    elseif(BaseNum == 10) then OUT.Damage.value = 5
                    elseif(BaseNum == 11) then OUT.Damage.value = 4
                    elseif(BaseNum == 12) then OUT.Damage.value = 3
                    elseif(BaseNum == 13) then OUT.Damage.value = 2
                    elseif(BaseNum == 14) then OUT.Damage.value = 1
                    elseif(BaseNum == 15) then OUT.Damage.value = 0
                    end
                end
            end
        end
    end
    return OUT
end
--]]

------------- Base functions

function Item:ConvertFireworkExplosion(IN)
    local OUT = TagCompound.new("Explosion")

    if(IN:contains("Flicker", TYPE.BYTE)) then OUT:addChild(TagByte.new("FireworkFlicker", IN.lastFound.value ~= 0)) end
    if(IN:contains("Trail", TYPE.BYTE)) then OUT:addChild(TagByte.new("FireworkTrail", IN.lastFound.value ~= 0)) end
    if(IN:contains("Type", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) else OUT:addChild(TagByte.new("FireworkType")) end

    --TODO
    --if(IN:contains("Colors", TYPE.INT_ARRAY)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    --if(IN:contains("FadeColors", TYPE.INT_ARRAY)) then OUT:addChild(IN.lastFound:clone()) end

    return OUT
end

function Item:BlankItem()
    local OUT = TagCompound.new()
    OUT:addChild(TagString.new("Name"))
    OUT:addChild(TagShort.new("Damage"))
    OUT:addChild(TagByte.new("Count"))
    return OUT
end

return Item