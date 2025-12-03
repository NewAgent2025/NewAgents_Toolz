Item = {}
TileEntity = TileEntity or require("tileEntity")
Entity = Entity or require("entity")

function Item:ConvertItem(IN, slotRequired)
    local OUT = TagCompound.new()

    local DataVersion = Settings:getSettingInt("DataVersion")

    if(IN:contains("Count", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) else return nil end

    if(IN:contains("Slot", TYPE.BYTE) and slotRequired) then OUT:addChild(IN.lastFound:clone()) elseif(slotRequired) then return nil end

    if(IN:contains("Damage", TYPE.SHORT)) then IN.Damage = IN.lastFound.value end

    --Currently checks for existence of Damage value
    --Might decide to use DataVersion instead?
    local dataTableName = "items_names2"
    if(IN:contains("id", TYPE.STRING)) then
        IN.id = IN.lastFound.value
        if(IN.id:find("^minecraft:")) then IN.id = IN.id:sub(11) end
        if(IN.Damage ~= nil) then dataTableName = "items_names" end
    elseif(IN:contains("id", TYPE.SHORT)) then
        IN.id = tostring(IN.lastFound.value)
        if(IN.Damage == nil) then return nil end
        dataTableName = "items_ids"
    else return nil end

    if(Settings:dataTableContains(dataTableName, IN.id)) then
        local entry = Settings.lastFound

        for index, _ in ipairs(entry) do
            local subEntry = entry[index]
            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end

            if(dataTableName ~= "items_names2") then
                if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.Damage) then goto entryContinue end end
                OUT.id = OUT:addChild(TagString.new("id", "minecraft:" .. subEntry[3]))
                if(subEntry[4]:len() > 0) then OUT.Damage = OUT:addChild(TagShort.new("Damage", tonumber(subEntry[4]))) else OUT.Damage = OUT:addChild(TagShort.new("Damage", IN.Damage)) end
                OUT.flags = subEntry[5]
                OUT.tileEntity = subEntry[6]
            else
                OUT.id = OUT:addChild(TagString.new("id", "minecraft:" .. subEntry[2]))
                if(subEntry[3]:len() > 0) then OUT.Damage = OUT:addChild(TagShort.new("Damage", tonumber(subEntry[3]))) else OUT.Damage = OUT:addChild(TagShort.new("Damage", 0)) end
                OUT.flags = subEntry[4]
                OUT.tileEntity = subEntry[5]
            end
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
                IN.tag.BlockEntityTag.curBlock.itemId = IN.tag.BlockEntityTag.curBlock:addChild(TagString.new("itemId", OUT.id.value))
                IN.tag.BlockEntityTag.curBlock.damage = IN.tag.BlockEntityTag.curBlock:addChild(TagByte.new("damage", OUT.Damage.value))
                IN.tag.BlockEntityTag.curBlock.save = false

                local BlockEntityTag_out = TagCompound.new("BlockEntityTag")
                
                local id = OUT.tileEntity

                if(Settings:dataTableContains("tileEntities", id)) then
                    local entry = Settings.lastFound
                    BlockEntityTag_out = TileEntity[entry[1][2]](TileEntity, IN.tag.BlockEntityTag, BlockEntityTag_out, false)
                end

                if(IN.tag.BlockEntityTag.curBlock.save) then
                    OUT.id.value = IN.tag.BlockEntityTag.curBlock.itemId.value
                    OUT.Damage.value = IN.tag.BlockEntityTag.curBlock.damage.value
                end

                if(BlockEntityTag_out ~= nil) then
                    if(BlockEntityTag_out.childCount ~= 0) then
                        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
                        OUT.tag:addChild(BlockEntityTag_out)
                    end
                end
            end
        end
    end

    OUT = Item:ConvertUnbreakable(IN, OUT)

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
                local Name = IN.tag.display.lastFound.value

                local jsonRoot = JSONValue.new()
                if(jsonRoot:parse(Name).type == JSON_TYPE.OBJECT) then
                    if(jsonRoot:contains("text", JSON_TYPE.STRING)) then
                        OUT.tag.display:addChild(TagString.new("Name", jsonRoot.lastFound:getString()))
                    end
                else
                    OUT.tag.display:addChild(TagString.new("Name", Name))
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

function Item:ConvertEnchantments(IN, OUT)
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

        --support both ench and Enchantments

        if(IN.tag:contains("Enchantments", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.ench = IN.tag.lastFound
        elseif(IN.tag:contains("ench", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.ench = IN.tag.lastFound
        end

        if(IN.tag.ench ~= nil) then
            if(OUT.tag.ench == nil) then OUT.tag.ench = OUT.tag:addChild(TagList.new("ench")) end

            for i=0, IN.tag.ench.childCount-1 do
                local ench_in = IN.tag.ench:child(i)
                local ench_out = TagCompound.new()

                if(ench_in:contains("id", TYPE.STRING)) then
                    local id = ench_in.lastFound.value
                    if(id:find("^minecraft:")) then id = id:sub(11) end

                    if(id == "protection") then ench_out:addChild(TagShort.new("id", 0))
                    elseif(id == "fire_protection") then ench_out:addChild(TagShort.new("id", 1))
                    elseif(id == "feather_falling") then ench_out:addChild(TagShort.new("id", 2))
                    elseif(id == "blast_protection") then ench_out:addChild(TagShort.new("id", 3))
                    elseif(id == "projectile_protection") then ench_out:addChild(TagShort.new("id", 4))
                    elseif(id == "respiration") then ench_out:addChild(TagShort.new("id", 5))
                    elseif(id == "aqua_affinity") then ench_out:addChild(TagShort.new("id", 6))
                    elseif(id == "thorns") then ench_out:addChild(TagShort.new("id", 7))
                    elseif(id == "depth_strider") then ench_out:addChild(TagShort.new("id", 8))
                    elseif(id == "frost_walker") then ench_out:addChild(TagShort.new("id", 9))
                    elseif(id == "binding_curse") then ench_out:addChild(TagShort.new("id", 10))
                    elseif(id == "sharpness") then ench_out:addChild(TagShort.new("id", 16))
                    elseif(id == "smite") then ench_out:addChild(TagShort.new("id", 17))
                    elseif(id == "bane_of_arthropods") then ench_out:addChild(TagShort.new("id", 18))
                    elseif(id == "knockback") then ench_out:addChild(TagShort.new("id", 19))
                    elseif(id == "fire_aspect") then ench_out:addChild(TagShort.new("id", 20))
                    elseif(id == "looting") then ench_out:addChild(TagShort.new("id", 21))
                    elseif(id == "efficiency") then ench_out:addChild(TagShort.new("id", 32))
                    elseif(id == "silk_touch") then ench_out:addChild(TagShort.new("id", 33))
                    elseif(id == "unbreaking") then ench_out:addChild(TagShort.new("id", 34))
                    elseif(id == "fortune") then ench_out:addChild(TagShort.new("id", 35))
                    elseif(id == "power") then ench_out:addChild(TagShort.new("id", 48))
                    elseif(id == "punch") then ench_out:addChild(TagShort.new("id", 49))
                    elseif(id == "flame") then ench_out:addChild(TagShort.new("id", 50))
                    elseif(id == "infinity") then ench_out:addChild(TagShort.new("id", 51))
                    elseif(id == "luck_of_the_sea") then ench_out:addChild(TagShort.new("id", 61))
                    elseif(id == "lure") then ench_out:addChild(TagShort.new("id", 62))
                    elseif(id == "loyalty") then ench_out:addChild(TagShort.new("id", 65))
                    elseif(id == "impaling") then ench_out:addChild(TagShort.new("id", 66))
                    elseif(id == "riptide") then ench_out:addChild(TagShort.new("id", 67))
                    elseif(id == "channeling") then ench_out:addChild(TagShort.new("id", 68))
                    elseif(id == "mending") then ench_out:addChild(TagShort.new("id", 70))
                    elseif(id == "vanishing_curse") then ench_out:addChild(TagShort.new("id", 71))
                    else goto enchContinue end
                elseif(ench_in:contains("id", TYPE.SHORT)) then
                    local id = ench_in.lastFound.value
                    if(id == 0) then ench_out:addChild(TagShort.new("id", 0))
                    elseif(id == 1) then ench_out:addChild(TagShort.new("id", 1))
                    elseif(id == 2) then ench_out:addChild(TagShort.new("id", 2))
                    elseif(id == 3) then ench_out:addChild(TagShort.new("id", 3))
                    elseif(id == 4) then ench_out:addChild(TagShort.new("id", 4))
                    elseif(id == 5) then ench_out:addChild(TagShort.new("id", 5))
                    elseif(id == 6) then ench_out:addChild(TagShort.new("id", 6))
                    elseif(id == 7) then ench_out:addChild(TagShort.new("id", 7))
                    elseif(id == 8) then ench_out:addChild(TagShort.new("id", 8))
                    elseif(id == 9) then ench_out:addChild(TagShort.new("id", 9))
                    elseif(id == 10) then ench_out:addChild(TagShort.new("id", 10))
                    elseif(id == 16) then ench_out:addChild(TagShort.new("id", 16))
                    elseif(id == 17) then ench_out:addChild(TagShort.new("id", 17))
                    elseif(id == 18) then ench_out:addChild(TagShort.new("id", 18))
                    elseif(id == 19) then ench_out:addChild(TagShort.new("id", 19))
                    elseif(id == 20) then ench_out:addChild(TagShort.new("id", 20))
                    elseif(id == 21) then ench_out:addChild(TagShort.new("id", 21))
                    elseif(id == 32) then ench_out:addChild(TagShort.new("id", 32))
                    elseif(id == 33) then ench_out:addChild(TagShort.new("id", 33))
                    elseif(id == 34) then ench_out:addChild(TagShort.new("id", 34))
                    elseif(id == 35) then ench_out:addChild(TagShort.new("id", 35))
                    elseif(id == 48) then ench_out:addChild(TagShort.new("id", 48))
                    elseif(id == 49) then ench_out:addChild(TagShort.new("id", 49))
                    elseif(id == 50) then ench_out:addChild(TagShort.new("id", 50))
                    elseif(id == 51) then ench_out:addChild(TagShort.new("id", 51))
                    elseif(id == 61) then ench_out:addChild(TagShort.new("id", 61))
                    elseif(id == 62) then ench_out:addChild(TagShort.new("id", 62))
                    elseif(id == 70) then ench_out:addChild(TagShort.new("id", 70))
                    elseif(id == 71) then ench_out:addChild(TagShort.new("id", 71))
                    else goto enchContinue end
                else goto enchContinue end

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
    if(IN:contains("tag", TYPE.COMPOUND)) then
        IN.tag = IN.lastFound
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

        if(IN.tag:contains("StoredEnchantments", TYPE.LIST, TYPE.COMPOUND)) then
            IN.tag.ench = IN.tag.lastFound
        end

        if(IN.tag.ench ~= nil) then
            if(OUT.tag.ench == nil) then OUT.tag.ench = OUT.tag:addChild(TagList.new("StoredEnchantments")) end

            for i=0, IN.tag.ench.childCount-1 do
                local ench_in = IN.tag.ench:child(i)
                local ench_out = TagCompound.new()

                if(ench_in:contains("id", TYPE.STRING)) then
                    local id = ench_in.lastFound.value
                    if(id:find("^minecraft:")) then id = id:sub(11) end

                    if(id == "protection") then ench_out:addChild(TagShort.new("id", 0))
                    elseif(id == "fire_protection") then ench_out:addChild(TagShort.new("id", 1))
                    elseif(id == "feather_falling") then ench_out:addChild(TagShort.new("id", 2))
                    elseif(id == "blast_protection") then ench_out:addChild(TagShort.new("id", 3))
                    elseif(id == "projectile_protection") then ench_out:addChild(TagShort.new("id", 4))
                    elseif(id == "respiration") then ench_out:addChild(TagShort.new("id", 5))
                    elseif(id == "aqua_affinity") then ench_out:addChild(TagShort.new("id", 6))
                    elseif(id == "thorns") then ench_out:addChild(TagShort.new("id", 7))
                    elseif(id == "depth_strider") then ench_out:addChild(TagShort.new("id", 8))
                    elseif(id == "frost_walker") then ench_out:addChild(TagShort.new("id", 9))
                    elseif(id == "binding_curse") then ench_out:addChild(TagShort.new("id", 10))
                    elseif(id == "sharpness") then ench_out:addChild(TagShort.new("id", 16))
                    elseif(id == "smite") then ench_out:addChild(TagShort.new("id", 17))
                    elseif(id == "bane_of_arthropods") then ench_out:addChild(TagShort.new("id", 18))
                    elseif(id == "knockback") then ench_out:addChild(TagShort.new("id", 19))
                    elseif(id == "fire_aspect") then ench_out:addChild(TagShort.new("id", 20))
                    elseif(id == "looting") then ench_out:addChild(TagShort.new("id", 21))
                    elseif(id == "efficiency") then ench_out:addChild(TagShort.new("id", 32))
                    elseif(id == "silk_touch") then ench_out:addChild(TagShort.new("id", 33))
                    elseif(id == "unbreaking") then ench_out:addChild(TagShort.new("id", 34))
                    elseif(id == "fortune") then ench_out:addChild(TagShort.new("id", 35))
                    elseif(id == "power") then ench_out:addChild(TagShort.new("id", 48))
                    elseif(id == "punch") then ench_out:addChild(TagShort.new("id", 49))
                    elseif(id == "flame") then ench_out:addChild(TagShort.new("id", 50))
                    elseif(id == "infinity") then ench_out:addChild(TagShort.new("id", 51))
                    elseif(id == "luck_of_the_sea") then ench_out:addChild(TagShort.new("id", 61))
                    elseif(id == "lure") then ench_out:addChild(TagShort.new("id", 62))
                    elseif(id == "loyalty") then ench_out:addChild(TagShort.new("id", 65))
                    elseif(id == "impaling") then ench_out:addChild(TagShort.new("id", 66))
                    elseif(id == "riptide") then ench_out:addChild(TagShort.new("id", 67))
                    elseif(id == "channeling") then ench_out:addChild(TagShort.new("id", 68))
                    elseif(id == "mending") then ench_out:addChild(TagShort.new("id", 70))
                    elseif(id == "vanishing_curse") then ench_out:addChild(TagShort.new("id", 71))
                    else goto enchContinue end
                elseif(ench_in:contains("id", TYPE.SHORT)) then
                    local id = ench_in.lastFound.value
                    if(id == 0) then ench_out:addChild(TagShort.new("id", 0))
                    elseif(id == 1) then ench_out:addChild(TagShort.new("id", 1))
                    elseif(id == 2) then ench_out:addChild(TagShort.new("id", 2))
                    elseif(id == 3) then ench_out:addChild(TagShort.new("id", 3))
                    elseif(id == 4) then ench_out:addChild(TagShort.new("id", 4))
                    elseif(id == 5) then ench_out:addChild(TagShort.new("id", 5))
                    elseif(id == 6) then ench_out:addChild(TagShort.new("id", 6))
                    elseif(id == 7) then ench_out:addChild(TagShort.new("id", 7))
                    elseif(id == 8) then ench_out:addChild(TagShort.new("id", 8))
                    elseif(id == 9) then ench_out:addChild(TagShort.new("id", 9))
                    elseif(id == 10) then ench_out:addChild(TagShort.new("id", 10))
                    elseif(id == 16) then ench_out:addChild(TagShort.new("id", 16))
                    elseif(id == 17) then ench_out:addChild(TagShort.new("id", 17))
                    elseif(id == 18) then ench_out:addChild(TagShort.new("id", 18))
                    elseif(id == 19) then ench_out:addChild(TagShort.new("id", 19))
                    elseif(id == 20) then ench_out:addChild(TagShort.new("id", 20))
                    elseif(id == 21) then ench_out:addChild(TagShort.new("id", 21))
                    elseif(id == 32) then ench_out:addChild(TagShort.new("id", 32))
                    elseif(id == 33) then ench_out:addChild(TagShort.new("id", 33))
                    elseif(id == 34) then ench_out:addChild(TagShort.new("id", 34))
                    elseif(id == 35) then ench_out:addChild(TagShort.new("id", 35))
                    elseif(id == 48) then ench_out:addChild(TagShort.new("id", 48))
                    elseif(id == 49) then ench_out:addChild(TagShort.new("id", 49))
                    elseif(id == 50) then ench_out:addChild(TagShort.new("id", 50))
                    elseif(id == 51) then ench_out:addChild(TagShort.new("id", 51))
                    elseif(id == 61) then ench_out:addChild(TagShort.new("id", 61))
                    elseif(id == 62) then ench_out:addChild(TagShort.new("id", 62))
                    elseif(id == 70) then ench_out:addChild(TagShort.new("id", 70))
                    elseif(id == 71) then ench_out:addChild(TagShort.new("id", 71))
                    else goto enchContinue end
                else goto enchContinue end

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

                if(attribute_in:contains("AttributeName", TYPE.STRING)) then
                    local attributeName = attribute_in.lastFound.value
                    if(attributeName == "generic.maxHealth") then attribute_out:addChild(TagInt.new("ID", 0))
                    elseif(attributeName == "generic.followRange") then attribute_out:addChild(TagInt.new("ID", 1))
                    elseif(attributeName == "generic.knockbackResistance") then attribute_out:addChild(TagInt.new("ID", 2))
                    elseif(attributeName == "generic.movementSpeed") then attribute_out:addChild(TagInt.new("ID", 3))
                    elseif(attributeName == "generic.attackDamage") then attribute_out:addChild(TagInt.new("ID", 4))
                    elseif(attributeName == "horse.jumpStrength") then attribute_out:addChild(TagInt.new("ID", 5))
                    elseif(attributeName == "zombie.spawnReinforcements") then attribute_out:addChild(TagInt.new("ID", 6))
                    elseif(attributeName == "generic.attackSpeed") then attribute_out:addChild(TagInt.new("ID", 7))
                    elseif(attributeName == "generic.armor") then attribute_out:addChild(TagInt.new("ID", 8))
                    elseif(attributeName == "generic.armorToughness") then attribute_out:addChild(TagInt.new("ID", 9))
                    elseif(attributeName == "generic.luck") then attribute_out:addChild(TagInt.new("ID", 10))
                    else goto attributeContinue end
                else goto attributeContinue end


                if(attribute_in:contains("Operation", TYPE.INT)) then
                    if(attribute_in.lastFound.value >= 0 or attribute_in.lastFound.value <= 2) then attribute_out:addChild(attribute_in.lastFound:clone()) else goto attributeContinue end
                else goto attributeContinue end

                if(attribute_in:contains("Amount", TYPE.DOUBLE)) then
                    attribute_out:addChild(attribute_in.lastFound:clone())
                else goto attributeContinue end

                if(attribute_in:contains("UUIDMost", TYPE.LONG)) then
                    attribute_out:addChild(TagInt.new("UUID", attribute_in.lastFound.value))
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

function Item:ConvertDurability(IN, OUT)
    if(IN.Damage ~= nil) then
        OUT.Damage.value = IN.Damage
    else
        if(IN:contains("tag", TYPE.COMPOUND)) then
            IN.tag = IN.lastFound
            if(IN.tag:contains("Damage", TYPE.INT)) then OUT.Damage.value = IN.tag.lastFound.value end
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
            if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end
    
            if(IN.tag:contains("EntityTag", TYPE.COMPOUND)) then
                IN.tag.EntityTag = IN.tag.lastFound
                OUT.tag.EntityTag = OUT.tag:addChild(TagCompound.new("EntityTag"))
    
                if(IN.tag.EntityTag:contains("id", TYPE.STRING)) then
                    local eggID = IN.tag.EntityTag.lastFound.value
                    if(eggID:find("^minecraft:")) then eggID = eggID:sub(11) end
    
                    if(Settings:dataTableContains("entities", eggID)) then
                        local entry = Settings.lastFound
                        OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
                    end
                end
    
                if(OUT.tag.EntityTag.childCount == 0) then
                    OUT.tag:removeChild(OUT.tag.EntityTag:getRow())
                    OUT.tag.EntityTag = nil
                end
            end
    
            if(OUT.tag.childCount == 0) then
                OUT:removeChild(OUT.tag:getRow())
                OUT.tag = nil
            end
        end
    else
        if(OUT.tag == nil) then OUT.tag = OUT:addChild(TagCompound.new("tag")) end

        OUT.tag.EntityTag = OUT.tag:addChild(TagCompound.new("EntityTag"))

        if(IN.Damage ~= nil) then
            if(IN.Damage ~= 0) then
                if(IN.Damage == 4) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:elder_guardian"))
                elseif(IN.Damage == 5) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:wither_skeleton"))
                elseif(IN.Damage == 6) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:stray"))
                elseif(IN.Damage == 23) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:husk"))
                elseif(IN.Damage == 27) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:zombie_villager"))
                elseif(IN.Damage == 28) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:skeleton_horse"))
                elseif(IN.Damage == 29) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:zombie_horse"))
                elseif(IN.Damage == 31) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:donkey"))
                elseif(IN.Damage == 32) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:mule"))
                elseif(IN.Damage == 34) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:evocation_illager"))
                elseif(IN.Damage == 35) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:vex"))
                elseif(IN.Damage == 36) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:vindication_illager"))
                elseif(IN.Damage == 50) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:creeper"))
                elseif(IN.Damage == 51) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:skeleton"))
                elseif(IN.Damage == 52) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:spider"))
                elseif(IN.Damage == 54) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:zombie"))
                elseif(IN.Damage == 55) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:slime"))
                elseif(IN.Damage == 56) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:ghast"))
                elseif(IN.Damage == 57) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:zombie_pigman"))
                elseif(IN.Damage == 58) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:enderman"))
                elseif(IN.Damage == 59) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:cave_spider"))
                elseif(IN.Damage == 60) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:silverfish"))
                elseif(IN.Damage == 61) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:blaze"))
                elseif(IN.Damage == 62) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:magma_cube"))
                elseif(IN.Damage == 65) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:bat"))
                elseif(IN.Damage == 66) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:witch"))
                elseif(IN.Damage == 67) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:endermite"))
                elseif(IN.Damage == 68) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:guardian"))
                elseif(IN.Damage == 69) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:shulker"))
                elseif(IN.Damage == 90) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:pig"))
                elseif(IN.Damage == 91) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:sheep"))
                elseif(IN.Damage == 92) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:cow"))
                elseif(IN.Damage == 93) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:chicken"))
                elseif(IN.Damage == 94) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:squid"))
                elseif(IN.Damage == 95) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:wolf"))
                elseif(IN.Damage == 96) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:mooshroom"))
                elseif(IN.Damage == 98) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:ocelot"))
                elseif(IN.Damage == 100) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:horse"))
                elseif(IN.Damage == 101) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:rabbit"))
                elseif(IN.Damage == 102) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:polar_bear"))
                elseif(IN.Damage == 103) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:llama"))
                elseif(IN.Damage == 105) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:parrot"))
                elseif(IN.Damage == 120) then OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:villager"))
                end
            end
        else
            local eggID = IN.id:sub(1, IN.id:find("_spawn_egg$")-1)

            if(Settings:dataTableContains("entities", eggID)) then
                local entry = Settings.lastFound
                OUT.tag.EntityTag:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            end
        end

        if(OUT.tag.EntityTag.childCount == 0) then
            OUT.tag:removeChild(OUT.tag.EntityTag:getRow())
            OUT.tag.EntityTag = nil
        end

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

    if(potionAdded == false and IN.Damage ~= nil) then
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

                local jsonRoot = JSONValue.new()
                if(jsonRoot:parse(page).type == JSON_TYPE.OBJECT) then
                    if(jsonRoot:contains("text", JSON_TYPE.STRING)) then
                        page = jsonRoot.lastFound:getString()
                        OUT.tag.pages:addChild(TagString.new("", page))
                    end
                else
                    page = page:gsub('\\n', "\n")
                    page = page:gsub('\\\"', "\"")
                    page = page:gsub('\\\\', "\\")
                    page = UnicodeToUtf8(page)
                    OUT.tag.pages:addChild(TagString.new("", page))
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

--------------- Base Functions

function Item:ConvertFireworkExplosion(IN)
    local OUT = TagCompound.new("Explosion")

    if(IN:contains("Colors", TYPE.INT_ARRAY)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("Flicker", TYPE.BYTE)) then OUT:addChild(TagByte.new("Flicker", IN.lastFound.value ~= 0)) end
    if(IN:contains("Trail", TYPE.BYTE)) then OUT:addChild(TagByte.new("Trail", IN.lastFound.value ~= 0)) end
    if(IN:contains("Type", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) else OUT:addChild(TagByte.new("Type")) end
    if(IN:contains("FadeColors", TYPE.INT_ARRAY)) then OUT:addChild(IN.lastFound:clone()) end

    return OUT
end

function Item:CompareProperties(propsString, propsTags)
    for prop in propsString:gmatch("([^|]*)|?") do 
        prop = prop:gsub("^%s*(.-)%s*$", "%1")
        local equalsIndex = prop:find("=")
        if(equalsIndex ~= nil) then
            local propName = prop:sub(1, equalsIndex-1)
            local propValue = prop:sub(equalsIndex+1)

            if(propsTags:contains(propName, TYPE.STRING)) then
                if(propsTags.lastFound.value ~= propValue) then return false end
            else return false end
        else return false end
    end
    return true
end

return Item