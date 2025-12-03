Entity = {}
Item = Item or require("item")
Utils = Utils or require("utils")

function Entity:ConvertEntity(IN, required)
    local OUT = TagCompound.new()

    --check if this entity has already been converted via passengers
    --if it has, skip it
    if(IN:contains("UniqueID", TYPE.LONG) and IN.ConvertedPassengers ~= nil) then
        for j=0, IN.ConvertedPassengers.childCount-1 do
            if(IN.ConvertedPassengers:child(j).value == IN.lastFound.value) then return nil end
        end
    end

    local id_str = ""
    local id_num = 0
    local idIsString = false
    if(IN:contains("identifier", TYPE.STRING)) then id_str = IN.lastFound.value
        if(id_str:find("^minecraft:")) then id_str = id_str:sub(11) end
        idIsString = true
    elseif(IN:contains("id", TYPE.STRING)) then id_str = IN.lastFound.value
        if(id_str:find("^minecraft:")) then id_str = id_str:sub(11) end
        idIsString = true
    elseif(IN:contains("id", TYPE.INT)) then
        id_num = IN.lastFound.value & 255
    else return nil end

    if(IN:contains("Pos", TYPE.LIST, TYPE.FLOAT)) then if(IN.lastFound.childCount == 3) then IN.Pos = IN.lastFound else return nil end end
    if(IN:contains("Motion", TYPE.LIST, TYPE.FLOAT)) then if(IN.lastFound.childCount == 3) then IN.Motion = IN.lastFound else return nil end end
    if(IN:contains("Rotation", TYPE.LIST, TYPE.FLOAT)) then if(IN.lastFound.childCount == 2) then IN.Rotation = IN.lastFound else return nil end end

    if(IN.Pos ~= nil) then 
        OUT.Pos = OUT:addChild(TagList.new("Pos"))
        OUT.Pos:addChild(TagDouble.new("", IN.Pos:child(0).value))
        OUT.Pos:addChild(TagDouble.new("", IN.Pos:child(1).value))
        OUT.Pos:addChild(TagDouble.new("", IN.Pos:child(2).value))
    elseif(required) then
        OUT.Pos = OUT:addChild(TagList.new("Pos"))
        OUT.Pos:addChild(TagDouble.new("", 0))
        OUT.Pos:addChild(TagDouble.new("", 0))
        OUT.Pos:addChild(TagDouble.new("", 0))
    end

    if(IN.Motion ~= nil) then 
        OUT.Motion = OUT:addChild(TagList.new("Motion"))
        OUT.Motion:addChild(TagDouble.new("", IN.Motion:child(0).value))
        OUT.Motion:addChild(TagDouble.new("", IN.Motion:child(1).value))
        OUT.Motion:addChild(TagDouble.new("", IN.Motion:child(2).value))
    elseif(required) then
        OUT.Motion = OUT:addChild(TagList.new("Motion"))
        OUT.Motion:addChild(TagDouble.new("", 0))
        OUT.Motion:addChild(TagDouble.new("", 0))
        OUT.Motion:addChild(TagDouble.new("", 0))
    end

    if(IN.Rotation ~= nil) then 
        OUT.Rotation = OUT:addChild(TagList.new("Rotation"))
        OUT.Rotation:addChild(TagFloat.new("", IN.Rotation:child(0).value))
        OUT.Rotation:addChild(TagFloat.new("", IN.Rotation:child(1).value))
    elseif(required) then
        OUT.Rotation = OUT:addChild(TagList.new("Rotation"))
        OUT.Rotation:addChild(TagFloat.new("", 0))
        OUT.Rotation:addChild(TagFloat.new("", 0))
    end

    if(idIsString) then
        if(Settings:dataTableContains("entities_names", id_str)) then
            local entry = Settings.lastFound
            if(required) then OUT:addChild(TagString.new("id", "minecraft:" .. entry[1][1])) end
            OUT = Entity[entry[1][2]](Entity, IN, OUT, required)
            if(OUT == nil) then return nil end
        else return nil end
    else
        if(Settings:dataTableContains("entities_ids", tostring(id_num))) then
            local entry = Settings.lastFound
            if(required) then OUT:addChild(TagString.new("id", "minecraft:" .. entry[1][1])) end
            OUT = Entity[entry[1][2]](Entity, IN, OUT, required)
            if(OUT == nil) then return nil end
        else return nil end
    end

    if(IN:contains("LinksTag", TYPE.LIST, TYPE.COMPOUND) and IN.Entities_output_ref ~= nil and IN.Entities_input_ref ~= nil) then
        IN.LinksTag = IN.lastFound

        OUT.Passengers = OUT:addChild(TagList.new("Passengers"))

        for i=0, IN.LinksTag.childCount-1 do
            local Link = IN.LinksTag:child(i)

            if(Link:contains("entityID", TYPE.LONG)) then
                Link.entityID = Link.lastFound

                --begin entity search

                --first check if this referenced entity has already been converted
                local alreadyConverted = false
                for j=0, IN.ConvertedPassengers.childCount-1 do
                    if(IN.ConvertedPassengers:child(j).value == Link.entityID.value) then
                        alreadyConverted = true
                        break
                    end
                end

                --if yes, check if exists as a base entity in Entities_output_ref
                if(alreadyConverted) then 
                    for j=0, IN.Entities_output_ref.childCount-1 do
                        local cPassenger = IN.Entities_output_ref:child(j)
                        if(cPassenger:contains("UUIDLeast", TYPE.LONG)) then
                            if(cPassenger.lastFound.value == Link.entityID.value) then
                                --if it does, then move that base entity into Passengers here, removing from output list, and then continue
                                OUT.Passengers:addChild(cPassenger)
                                break
                            end
                        end
                    end

                    --if it doesn't, then this is an invalid link. continue
                else
                    --if no, check if it exists in the input entities list
                    for j=0, IN.Entities_input_ref.childCount-1 do
                        local cPassenger = IN.Entities_input_ref:child(j)
                        if(cPassenger:contains("UniqueID", TYPE.LONG)) then
                            if(cPassenger.lastFound.value == Link.entityID.value) then
                                --if yes, grab that and convert it, mark it as converted

                                cPassenger.TileEntities_output_ref = IN.TileEntities_output_ref
                                cPassenger.Entities_input_ref = IN.Entities_input_ref
                                cPassenger.Entities_output_ref = IN.Entities_output_ref
                                cPassenger.ConvertedPassengers = IN.ConvertedPassengers

                                local passenger = Entity:ConvertEntity(cPassenger, true)
                                if(passenger ~= nil) then
                                    IN.ConvertedPassengers:addChild(TagLong.new("", cPassenger.lastFound.value))
                                    OUT.Passengers:addChild(passenger)
                                end
                                break
                            end
                        end
                    end
                    --if no, invalid link, continue
                end
                
            end
        end
    end

    --this will create duplicate entries, doesn't matter that much
    --a duplicate will be made for every entity that was a passenger and converted before it's host
    if(IN:contains("UniqueID", TYPE.LONG) and IN.ConvertedPassengers ~= nil) then
        IN.ConvertedPassengers:addChild(TagLong.new("", IN.lastFound.value))
    end

    return OUT
end

--
function Entity:ConvertAreaEffectCloud(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end


    if(IN:contains("Duration", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Duration", 600)) end
    if(IN:contains("DurationOnUse", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("DurationOnUse")) end
    if(IN:contains("ReapplicationDelay", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ReapplicationDelay", 20)) end
    if(IN:contains("SpawnTick", TYPE.LONG)) then
        OUT:addChild(TagInt.new("WaitTime", IN.lastFound.value-Settings:getSettingLong("Time")))
    elseif(required) then
        OUT:addChild(TagInt.new("WaitTime", 20))
    end
    if(IN:contains("Radius", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("Radius", 3)) end
    if(IN:contains("RadiusOnUse", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("RadiusOnUse", -0.5)) end
    if(IN:contains("RadiusPerTick", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("RadiusPerTick", -0.005)) end


    if(IN:contains("mobEffects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.mobEffects = IN.lastFound
        OUT.Effects = OUT:addChild(TagList.new("Effects"))

        for i=0, IN.mobEffects.childCount-1 do
            local effect_in = IN.mobEffects:child(i)
            local effect_out = TagCompound.new()

            if(effect_in:contains("Id", TYPE.BYTE)) then
                if(Settings:dataTableContains("active_effects", tostring(IN.lastFound.value))) then
                    local entry = Settings.lastFound
                    effect_out:addChild(TagByte.new("Id", tonumber(entry[1][1])))
                else goto effectContinue end
            else goto effectContinue end

            if(effect_in:contains("ShowParticles", TYPE.BYTE)) then effect_out:addChild(TagByte.new("ShowParticles", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("ShowParticles", true)) end
            if(effect_in:contains("Ambient", TYPE.BYTE)) then effect_out:addChild(TagByte.new("Ambient", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("Ambient")) end
            if(effect_in:contains("Amplifier", TYPE.BYTE)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagByte.new("Amplifier")) end
            if(effect_in:contains("Duration", TYPE.INT)) then effect_out:addChild(TagInt.new("Duration", effect_in.lastFound.value)) else effect_out:addChild(TagInt.new("Duration", 1)) end

            OUT.Effects:addChild(effect_out)

            ::effectContinue::
        end
    end

    if(IN:contains("PotionId", TYPE.SHORT)) then
        if(Settings:dataTableContains("potions", tostring(IN.lastFound.value))) then
            local entry = Settings.lastFound
            OUT:addChild(TagString.new("Potion", "minecraft:" .. entry[1][1]))
        end
    end

    --TODO particle effect

    return OUT
end
--
function Entity:ConvertArmorStand(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Armor", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Armor = IN.lastFound

        OUT.ArmorItems = OUT:addChild(TagList.new("ArmorItems"))

        for i=0, 3 do
            local item = nil
            if(IN.Armor.childCount > 3-i) then
                item = Item:ConvertItem(IN.Armor:child(3-i), false)
            end
            if(item == nil) then item = TagCompound.new() end
            OUT.ArmorItems:addChild(item)
        end
    end
    if(required and OUT.ArmorItems == nil) then
        OUT.ArmorItems = OUT:addChild(TagList.new("ArmorItems"))
        OUT.ArmorItems:addChild(TagCompound.new())
        OUT.ArmorItems:addChild(TagCompound.new())
        OUT.ArmorItems:addChild(TagCompound.new())
        OUT.ArmorItems:addChild(TagCompound.new())
    end

    if(IN:contains("Mainhand", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Mainhand = IN.lastFound
        if(IN.Mainhand.childCount == 1) then
            OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
            local item = Item:ConvertItem(IN.Mainhand:child(0), false)
            if(item ~= nil) then OUT.HandItems:addChild(item) else OUT.HandItems:addChild(TagCompound.new()) end
        end
    end
    if(required and OUT.HandItems == nil) then
        OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
        OUT.HandItems:addChild(TagCompound.new())
    end
    if(IN:contains("Offhand", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Offhand = IN.lastFound
        if(IN.Offhand.childCount == 1) then
            if(OUT.HandItems == nil) then
                OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
                OUT.HandItems:addChild(TagCompound.new())
            end

            local item = Item:ConvertItem(IN.Offhand:child(0), false)
            if(item ~= nil) then OUT.HandItems:addChild(item) else OUT.HandItems:addChild(TagCompound.new()) end
        end
    end
    if(required and OUT.HandItems.childCount == 1) then
        OUT.HandItems:addChild(TagCompound.new())
    end

    if(IN:contains("ActiveEffects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.ActiveEffects = IN.lastFound
        OUT.ActiveEffects = OUT:addChild(TagList.new("ActiveEffects"))

        for i=0, IN.ActiveEffects.childCount-1 do
            local effect_in = IN.ActiveEffects:child(i)
            local effect_out = TagCompound.new()

            if(effect_in:contains("Id", TYPE.BYTE)) then
                if(Settings:dataTableContains("active_effects", tostring(IN.lastFound.value))) then
                    local entry = Settings.lastFound
                    effect_out:addChild(TagByte.new("Id", tonumber(entry[1][1])))
                else goto effectContinue end
            else goto effectContinue end

            if(effect_in:contains("ShowParticles", TYPE.BYTE)) then effect_out:addChild(TagByte.new("ShowParticles", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("ShowParticles", true)) end
            if(effect_in:contains("Ambient", TYPE.BYTE)) then effect_out:addChild(TagByte.new("Ambient", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("Ambient")) end
            if(effect_in:contains("Amplifier", TYPE.BYTE)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagByte.new("Amplifier")) end
            if(effect_in:contains("Duration", TYPE.INT)) then effect_out:addChild(TagInt.new("Duration", effect_in.lastFound.value)) else effect_out:addChild(TagInt.new("Duration", 1)) end

            OUT.ActiveEffects:addChild(effect_out)

            ::effectContinue::
        end
    end

    if(required) then
        OUT:addChild(TagByte.new("ShowArms", true))
        OUT:addChild(TagByte.new("Small"))
        OUT:addChild(TagByte.new("NoBasePlate"))
        OUT:addChild(TagByte.new("Marker"))
        OUT:addChild(TagByte.new("Invisible"))
    end

    return OUT
end
--
function Entity:ConvertArrow(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    local OnGround = false
    if(OUT:contains("OnGround", TYPE.BYTE)) then OnGround = IN.lastFound.value ~= 0 end

    OUT.xTile = OUT:addChild(TagInt.new("xTile", -1))
    OUT.yTile = OUT:addChild(TagInt.new("yTile", -1))
    OUT.zTile = OUT:addChild(TagInt.new("zTile", -1))

    if(IN:contains("StuckToBlockPos", TYPE.LIST, TYPE.INT) and OnGround) then
        if(IN.lastFound.childCount == 3) then
            OUT.xTile.value = IN.lastFound:child(0).value
            OUT.yTile.value = IN.lastFound:child(1).value
            OUT.zTile.value = IN.lastFound:child(2).value
        end
    end

    if(IN:contains("isCreative", TYPE.BYTE)) then 
        if(IN.lastFound.value ~= 0) then
            OUT:addChild(TagByte.new("pickup", 2))
        else
            OUT:addChild(TagByte.new("pickup"))
        end
    elseif(required) then
        OUT:addChild(TagByte.new("pickup"))
    end

    if(IN:contains("mobEffects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.mobEffects = IN.lastFound
        OUT.CustomPotionEffects = OUT:addChild(TagList.new("CustomPotionEffects"))

        for i=0, IN.mobEffects.childCount-1 do
            local effect_in = IN.mobEffects:child(i)
            local effect_out = TagCompound.new()

            if(effect_in:contains("Id", TYPE.BYTE)) then
                if(Settings:dataTableContains("active_effects", tostring(IN.lastFound.value))) then
                    local entry = Settings.lastFound
                    effect_out:addChild(TagByte.new("Id", tonumber(entry[1][1])))
                else goto effectContinue end
            else goto effectContinue end

            if(effect_in:contains("ShowParticles", TYPE.BYTE)) then effect_out:addChild(TagByte.new("ShowParticles", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("ShowParticles", true)) end
            if(effect_in:contains("Ambient", TYPE.BYTE)) then effect_out:addChild(TagByte.new("Ambient", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("Ambient")) end
            if(effect_in:contains("Amplifier", TYPE.BYTE)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagByte.new("Amplifier")) end
            if(effect_in:contains("Duration", TYPE.INT)) then effect_out:addChild(TagInt.new("Duration", effect_in.lastFound.value)) else effect_out:addChild(TagInt.new("Duration", 1)) end

            OUT.CustomPotionEffects:addChild(effect_out)

            ::effectContinue::
        end
    end

    if(IN:contains("auxValue", TYPE.BYTE)) then
        if(Settings:dataTableContains("potions", tostring(IN.lastFound.value))) then
            local entry = Settings.lastFound
            OUT:addChild(TagString.new("Potion", "minecraft:" .. entry[1][1]))
        end
    end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    return OUT
end
--
function Entity:ConvertAxolotl(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    --TODO Parse Variant bitflags

    if(required) then OUT:addChild(TagByte.new("FromBucket")) end

    return OUT
end
--
function Entity:ConvertBat(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("BatFlags", TYPE.BYTE)) then OUT:addChild(TagByte.new("BatFlags", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("BatFlags")) end

    return OUT
end
--
function Entity:ConvertBee(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then
        OUT:addChild(TagByte.new("NoGravity", true))
        OUT:addChild(TagString.new("HurtBy"))
    end

    if(IN:contains("HomePos", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then
            OUT.HivePos = OUT:addChild(TagCompound.new("HivePos"))
            OUT.HivePos:addChild(TagInt.new("X", math.floor(IN.lastFound:child(0).value)))
            OUT.HivePos:addChild(TagInt.new("Y", math.floor(IN.lastFound:child(1).value)))
            OUT.HivePos:addChild(TagInt.new("Z", math.floor(IN.lastFound:child(2).value)))
        end
    end
    if(OUT.HivePos == nil and required) then
        OUT.HivePos = OUT:addChild(TagCompound.new("HivePos"))
        OUT.HivePos:addChild(TagInt.new("X", math.floor(OUT.Pos:child(0).value)))
        OUT.HivePos:addChild(TagInt.new("Y", math.floor(OUT.Pos:child(1).value)))
        OUT.HivePos:addChild(TagInt.new("Z", math.floor(OUT.Pos:child(2).value)))
    end

    if(IN:contains("MarkVariant", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then OUT:addChild(TagByte.new("HasStung", true)) else OUT:addChild(TagByte.new("HasStung")) end
    elseif(required) then
        OUT:addChild(TagByte.new("HasStung"))
    end

    if(Entity:HasDefinition(IN.definitions, "+has_nectar") and required) then
        OUT:addChild(TagByte.new("HasNectar", true))
    elseif(required) then
        OUT:addChild(TagByte.new("HasNectar"))
    end

    if(IN:contains("IsAngry", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then
            OUT:addChild(TagInt.new("Anger", 600))
        else
            OUT:addChild(TagInt.new("Anger"))
        end
    elseif(required) then
        OUT:addChild(TagInt.new("Anger"))
    end

    if(required) then
        OUT:addChild(TagInt.new("CannotEnterHiveTicks"))
        OUT:addChild(TagInt.new("CropsGrownSincePollination"))
        OUT:addChild(TagInt.new("TicksSincePollination"))
    end

    return OUT
end
--
function Entity:ConvertBlaze(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertBoat(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(OUT:contains("Pos", TYPE.LIST, TYPE.DOUBLE)) then
        OUT.Pos = OUT.lastFound
        if(OUT.Pos.childCount == 3) then
            OUT.Pos:child(1).value = OUT.Pos:child(1).value - 0.375
        end
    end

    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value

        if(Variant == 0) then OUT:addChild(TagString.new("Type", "oak"))
        elseif(Variant == 1) then OUT:addChild(TagString.new("Type", "spruce"))
        elseif(Variant == 2) then OUT:addChild(TagString.new("Type", "birch"))
        elseif(Variant == 3) then OUT:addChild(TagString.new("Type", "jungle"))
        elseif(Variant == 4) then OUT:addChild(TagString.new("Type", "acacia"))
        elseif(Variant == 5) then OUT:addChild(TagString.new("Type", "dark_oak"))
        else OUT:addChild(TagString.new("Type", "oak"))
        end
    elseif(required) then
        OUT:addChild(TagString.new("Type", "oak"))
    end

    
    if(OUT:contains("Rotation", TYPE.LIST, TYPE.DOUBLE)) then
        if(OUT.lastFound.childCount == 2) then
            OUT.Rotation = OUT.lastFound

            local rot = OUT.Rotation:child(0).value
            rot = rot - 90
            if(rot < -180) then rot = rot + 360 end
            OUT.Rotation:child(0).value = rot
        end
    end

    return OUT
end
--
function Entity:ConvertBottleOEnchanting(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end


    return OUT
end
--
function Entity:ConvertCat(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value

        if(Variant == 0) then OUT:addChild(TagInt.new("CatType", 8))
        elseif(Variant == 1) then OUT:addChild(TagInt.new("CatType", 1))
        elseif(Variant == 2) then OUT:addChild(TagInt.new("CatType", 2))
        elseif(Variant == 3) then OUT:addChild(TagInt.new("CatType", 3))
        elseif(Variant == 4) then OUT:addChild(TagInt.new("CatType", 4))
        elseif(Variant == 5) then OUT:addChild(TagInt.new("CatType", 5))
        elseif(Variant == 6) then OUT:addChild(TagInt.new("CatType", 6))
        elseif(Variant == 7) then OUT:addChild(TagInt.new("CatType", 7))
        elseif(Variant == 8) then OUT:addChild(TagInt.new("CatType", 0))
        elseif(Variant == 9) then OUT:addChild(TagInt.new("CatType", 10))
        elseif(Variant == 10) then OUT:addChild(TagInt.new("CatType", 9))
        end
    elseif(required) then
        OUT:addChild(TagInt.new("CatType"))
    end

    return OUT
end
--
function Entity:ConvertCaveSpider(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertChicken(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("entries", TYPE.LIST, TYPE.COMPOUND)) then
        local entries = IN.lastFound
        for i=0, entries.childCount-1 do
            local entry = entries:child(i)
            if(entry:contains("SpawnTimer", TYPE.INT)) then 
                OUT.EggLayTime = OUT:addChild(TagInt.new("EggLayTime", entry.lastFound.value))
                break
            end
        end
    end

    if(OUT.EggLayTime == nil and required) then OUT:addChild(TagInt.new("EggLayTime")) end

    if(required) then
        OUT:addChild(TagByte.new("IsChickenJockey"))
    end

    return OUT
end
--
function Entity:ConvertCod(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertCow(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertCreeper(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(Entity:HasDefinition(IN.definitions, "+minecraft:charged_creeper")) then
        OUT:addChild(TagByte.new("powered", true))
    end

    if(IN:contains("Fuse", TYPE.BYTE)) then OUT:addChild(TagShort.new("Fuse", IN.lastFound.value)) end

    if(IN:contains("IsFuseLit", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then OUT:addChild(TagByte.new("ignited", true)) else OUT:addChild(TagByte.new("ignited")) end
    elseif(required) then 
        OUT:addChild(TagByte.new("ignited"))
    end

    if(required) then
        OUT:addChild(TagByte.new("ExplosionRadius", 3))
        OUT:addChild(TagShort.new("Fuse", 30))
    end

    return OUT
end
--
function Entity:ConvertDolphin(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.CanPickUpLoot.value = true

    if(required) then
        OUT:addChild(TagInt.new("TreasurePosX"))
        OUT:addChild(TagInt.new("TreasurePosY"))
        OUT:addChild(TagInt.new("TreasurePosZ"))
        OUT:addChild(TagByte.new("GotFish"))
    end

    if(Entity:HasDefinition(IN.definitions, "+minecraft:dolphin_on_land") and required) then
        if(Entity:HasDefinition(IN.definitions, "+minecraft:dolphin_dried")) then
            OUT:addChild(TagInt.new("Moistness"))
        else
            if(IN:contains("TimeStamp", TYPE.LONG)) then
                OUT:addChild(TagInt.new("Moistness", IN.lastFound.value-Settings:getSettingLong("Time")))
            else
                OUT:addChild(TagInt.new("Moistness", 2399))
            end
        end
    elseif(required) then
        OUT:addChild(TagInt.new("Moistness", 2400))
    end

    return OUT
end
--
function Entity:ConvertDonkey(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertDragonFireball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("direction", TYPE.LIST, TYPE.FLOAT)) then
        IN.direction = IN.lastFound
        if(IN.direction.childCount == 3) then
            OUT.direction = OUT:addChild(TagList.new("direction"))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(0).value))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(1).value))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(2).value))
        end
    end

    if(OUT.direction == nil and required) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new(""))
        OUT.direction:addChild(TagDouble.new(""))
        OUT.direction:addChild(TagDouble.new(""))
    end

    if(IN:contains("power", TYPE.LIST, TYPE.FLOAT)) then
        IN.power = IN.lastFound
        if(IN.power.childCount == 3) then
            OUT.power = OUT:addChild(TagList.new("power"))
            OUT.power:addChild(TagDouble.new("", IN.power:child(0).value))
            OUT.power:addChild(TagDouble.new("", IN.power:child(1).value))
            OUT.power:addChild(TagDouble.new("", IN.power:child(2).value))
        end
    end

    if(OUT.power == nil and required) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new(""))
        OUT.power:addChild(TagDouble.new(""))
        OUT.power:addChild(TagDouble.new(""))
    end

    return OUT
end
--
function Entity:ConvertDrowned(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertEgg(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end


    return OUT
end
--
function Entity:ConvertElderGuardian(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertEnderCrystal(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("ShowBottom", TYPE.BYTE)) then OUT:addChild(TagByte.new("ShowBottom", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("ShowBottom", true)) end

    --TODO beamtarget

    return OUT
end
--
function Entity:ConvertEnderPearl(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end


    return OUT
end
--
function Entity:ConvertEnderman(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    local blockName = "air"
    local blockProps = ""

    --TODO legacy support
    if(IN:contains("carriedBlock", TYPE.COMPOUND)) then
        IN.blockState = IN.lastFound

        if(IN.blockState:contains("name", TYPE.STRING)) then IN.blockState.id = IN.blockState.lastFound end
        if(IN.blockState:contains("states", TYPE.COMPOUND)) then IN.blockState.meta = IN.blockState.lastFound
        elseif(IN.blockState:contains("val", TYPE.SHORT)) then IN.blockState.meta = IN.blockState.lastFound
        end

        local block = Utils:findBlock(IN.blockState.id, IN.blockState.meta)
        if(block ~= nil and block.id ~= nil) then
            blockName = "minecraft:" .. block.id
            blockProps = block.meta
        end
    end

    OUT.carriedBlockState = OUT:addChild(TagCompound.new("carriedBlockState"))

    OUT.carriedBlockState:addChild(TagString.new("Name", blockName))
    if(blockProps:len() ~= 0) then
        local propsTags = Utils:StringToProperties(blockProps)
        if(propsTags ~= nil) then OUT.carriedBlockState:addChild(propsTags) end
    end

    return OUT
end
--
function Entity:ConvertEndermite(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Lifetime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Lifetime")) end

    return OUT
end
--
function Entity:ConvertEvoker(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagInt.new("SpellTicks")) end

    return OUT
end
--
function Entity:ConvertEvokerFangs(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("limitedLife", TYPE.INT)) then
        OUT:addChild(TagInt.new("Warmup", IN.lastFound.value-20))
    elseif(required) then
        OUT:addChild(TagInt.new("Warmup", -20))
    end

    return OUT
end
--
function Entity:ConvertExperienceOrb(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("experience value", TYPE.INT)) then
        OUT:addChild(TagShort.new("Value", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagShort.new("Value", 3))
    end

    if(IN:contains("Age", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Age")) end
    

    return OUT
end
--
function Entity:ConvertEyeOfEnder(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertFallingBlock(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    local blockName = "sand"
    local blockProps = ""

    --TODO legacy support
    if(IN:contains("FallingBlock", TYPE.COMPOUND)) then
        IN.blockState = IN.lastFound

        if(IN.blockState:contains("name", TYPE.STRING)) then IN.blockState.id = IN.blockState.lastFound end
        if(IN.blockState:contains("states", TYPE.COMPOUND)) then IN.blockState.meta = IN.blockState.lastFound
        elseif(IN.blockState:contains("val", TYPE.SHORT)) then IN.blockState.meta = IN.blockState.lastFound
        end

        local block = Utils:findBlock(IN.blockState.id, IN.blockState.meta)
        if(block ~= nil and block.id ~= nil) then
            blockName = "minecraft:" .. block.id
            blockProps = block.meta
        end
    end

    OUT.BlockState = OUT:addChild(TagCompound.new("BlockState"))

    OUT.BlockState:addChild(TagString.new("Name", blockName))
    if(blockProps:len() ~= 0) then
        local propsTags = Utils:StringToProperties(blockProps)
        if(propsTags ~= nil) then OUT.BlockState:addChild(propsTags) end
    end

    if(IN:contains("Time", TYPE.BYTE)) then
        OUT:addChild(TagInt.new("Time", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagInt.new("Time"))
    end

    --TODO identify use of Variant
    --falling sand has a variant of 2152. bit flag to store damag info? maybe test anvils

    if(required) then
        OUT:addChild(TagByte.new("DropItem", true))
        OUT:addChild(TagByte.new("HurtEntities", false))
        OUT:addChild(TagInt.new("FallHurtMax", 40))
        OUT:addChild(TagFloat.new("FallHurtAmount", 2))
    end

    return OUT
end
--
function Entity:ConvertFireball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("direction", TYPE.LIST, TYPE.FLOAT)) then
        IN.direction = IN.lastFound
        if(IN.direction.childCount == 3) then
            OUT.direction = OUT:addChild(TagList.new("direction"))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(0).value))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(1).value))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(2).value))
        end
    end

    if(OUT.direction == nil and required) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new(""))
        OUT.direction:addChild(TagDouble.new(""))
        OUT.direction:addChild(TagDouble.new(""))
    end

    if(IN:contains("power", TYPE.LIST, TYPE.FLOAT)) then
        IN.power = IN.lastFound
        if(IN.power.childCount == 3) then
            OUT.power = OUT:addChild(TagList.new("power"))
            OUT.power:addChild(TagDouble.new("", IN.power:child(0).value))
            OUT.power:addChild(TagDouble.new("", IN.power:child(1).value))
            OUT.power:addChild(TagDouble.new("", IN.power:child(2).value))
        end
    end

    if(OUT.power == nil and required) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new(""))
        OUT.power:addChild(TagDouble.new(""))
        OUT.power:addChild(TagDouble.new(""))
    end

    if(required) then
        OUT:addChild(TagInt.new("ExplosionPower", 1))
    end

    return OUT
end
--
function Entity:ConvertFireworkRocket(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Life", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Life")) end
    if(IN:contains("LifeTime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("LifeTime", 20)) end

    if(required) then
        OUT:addChild(TagByte.new("ShotAtAngle"))
    end

    --TODO generate default firework data?

    --Bedrock doesnt save the firework data? wtf
    --[[
    if(IN:contains("FireworksItem", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "FireworksItem"
            OUT:addChild(item)
        end
    end--]]

    return OUT
end
--
function Entity:ConvertFox(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.CanPickUpLoot.value = true

    if(IN:contains("Sitting", TYPE.BYTE)) then OUT:addChild(TagByte.new("Sitting", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Sitting")) end
    
    if(IN:contains("Variant", TYPE.INT)) then
        if(IN.lastFound.value ~= 0) then
            OUT:addChild(TagString.new("Type", "snow"))
        else
            OUT:addChild(TagString.new("Type", "red"))
        end
    elseif(required) then
        OUT:addChild(TagString.new("Type", "red"))
    end

    if(Entity:HasDefinition(IN.definitions, "+minecraft:fox_ambient_sleep") and required) then
        OUT:addChild(TagByte.new("Sleeping", true))
    elseif(required) then
        OUT:addChild(TagByte.new("Sleeping"))
    end

    if(required) then OUT:addChild(TagByte.new("Crouching")) end

    return OUT
end
--
function Entity:ConvertGhast(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("ExplosionPower", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ExplosionPower", 1)) end

    return OUT
end
--
function Entity:ConvertGlowSquid(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertGoat(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertGuardian(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertHoglin(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(Entity:HasDefinition(IN.definitions, "+huntable_adult") and required) then
        OUT:addChild(TagByte.new("CannotBeHunted", false))
    elseif(required) then
        OUT:addChild(TagByte.new("CannotBeHunted", true))
    end

    return OUT
end
--
function Entity:ConvertHorse(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Variant", TYPE.INT)) then
        IN.baseColor = IN.lastFound.value
        if(IN.baseColor > 6) then IN.baseColor = 0 end
    end

    if(IN:contains("MarkVariant", TYPE.INT)) then
        IN.markings = IN.lastFound.value
        if(IN.markings > 4) then IN.markings = 0 end
    end

    if(IN.baseColor ~= nil or IN.markings ~= nil or required) then
        if(IN.baseColor == nil) then IN.baseColor = 0 end
        if(IN.markings == nil) then IN.markings = 0 end

        OUT:addChild(TagInt.new("Variant", IN.baseColor + (IN.markings << 8)))
    end

    return OUT
end
--
function Entity:ConvertHusk(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertIronGolem(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    
    if(Entity:HasDefinition(IN.definitions, "+minecraft:player_created") and required) then
        OUT:addChild(TagByte.new("PlayerCreated", true))
    elseif(required) then 
        OUT:addChild(TagByte.new("PlayerCreated"))
    end

    return OUT
end
--
function Entity:ConvertItemDrop(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Item", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item == nil) then return nil end
        item.name = "Item"
        OUT:addChild(item)
    else return nil end

    if(IN:contains("Age", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Age")) end
    if(IN:contains("Health", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Health", 5)) end
    if(required) then OUT:addChild(TagShort.new("PickupDelay")) end

    return OUT
end
--
function Entity:ConvertLlama(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Strength", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Strength")) end

    if(IN:contains("Variant", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Variant")) end


    return OUT
end
--
function Entity:ConvertMagmaCube(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Size", TYPE.BYTE)) then
        local Size = IN.lastFound.value
        if(Size < 1) then Size = 1 end
        if(Size > 3) then Size = 3 end
        OUT:addChild(TagInt.new("Size", Size-1))
    elseif(IN:contains("Variant", TYPE.INT)) then 
        local Size = IN.lastFound.value
        if(Size < 1) then Size = 1 end
        if(Size > 3) then Size = 3 end
        OUT:addChild(TagInt.new("Size", Size-1))
    elseif(required) then 
        OUT:addChild(TagInt.new("Size", 1))
    end

    return OUT
end
--
function Entity:ConvertMinecart(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertMinecartChest(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("ChestItems", TYPE.LIST, TYPE.COMPOUND)) then IN.lastFound.name = "Items" end

    Entity:ConvertItems(IN, OUT, required)

    return OUT
end
--
function Entity:ConvertMinecartCommandBlock(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("LastExecution", TYPE.LONG)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("TrackOutput", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("Command", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("SuccessCont", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) end
    if(OUT:contains("CustomName", TYPE.STRING)) then
        local jsonRoot = JSONValue.new()
        if(jsonRoot:parse(OUT.lastFound.value).type == JSON_TYPE.OBJECT) then
            if(jsonRoot:contains("text", JSON_TYPE.STRING)) then
                if(jsonRoot.lastFound:getString() == "") then
                    local jsonText= JSONValue.new(JSON_TYPE.STRING)
                    jsonText:setString("@")
                    jsonRoot:addChild(jsonText, "text")
                end
            end
        end
        OUT.lastFound.value = jsonRoot:serialize()
    elseif(required) then
        OUT:addChild(TagString.new("CustomName", "{\"text\":\"@\"}"))
    end

    return OUT
end
--
function Entity:ConvertMinecartHopper(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("ChestItems", TYPE.LIST, TYPE.COMPOUND)) then IN.lastFound.name = "Items" end

    Entity:ConvertItems(IN, OUT, required)

    if(Entity:HasDefinition(IN.definitions, "+minecart:hopper_active") and required) then
        OUT:addChild(TagByte.new("Enabled", true))
    elseif(Entity:HasDefinition(IN.definitions, "+minecart:hopper_inactive") and required) then
        OUT:addChild(TagByte.new("Enabled"))
    elseif(required) then
        OUT:addChild(TagByte.new("Enabled", true))
    end

    return OUT
end
--
function Entity:ConvertMinecartTNT(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("IsFuseLit", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then
            if(IN:contains("Fuse", TYPE.BYTE)) then
                OUT:addChild(TagInt.new("TNTFuse", IN.lastFound.value))
            else
                OUT:addChild(TagInt.new("TNTFuse", -1))
            end
        else
            OUT:addChild(TagInt.new("TNTFuse", -1))
        end
    elseif(required) then
        OUT:addChild(TagInt.new("TNTFuse", -1))
    end

    return OUT
end
--
function Entity:ConvertMooshroom(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(Entity:HasDefinition(IN.definitions, "+minecraft:mooshroom_red") and required) then
        OUT:addChild(TagString.new("Type", "red"))
    elseif(Entity:HasDefinition(IN.definitions, "+minecraft:mooshroom_brown") and required) then
        OUT:addChild(TagString.new("Type", "brown"))
    elseif(required) then
        OUT:addChild(TagString.new("Type", "red"))
    end

    return OUT
end
--
function Entity:ConvertMule(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertOcelot(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertPainting(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Direction", TYPE.BYTE)) then
        local Direction = IN.lastFound.value
        if(Direction < 0 or Direction > 3) then return nil end 
        OUT.Facing = OUT:addChild(TagByte.new("Facing", Direction))
    elseif(required) then return nil end

    local width = 1
    local height = 1

    if(IN:contains("Motive", TYPE.STRING)) then
        local motive = IN.lastFound.value
        if(motive:find("^minecraft:")) then motive = motive:sub(11) end
        if(motive == "Kebab") then OUT:addChild(TagString.new("Motive", "kebab"))
        elseif(motive == "Aztec") then OUT:addChild(TagString.new("Motive", "aztec"))
        elseif(motive == "Alban") then OUT:addChild(TagString.new("Motive", "alban"))
        elseif(motive == "Aztec2") then OUT:addChild(TagString.new("Motive", "aztec2"))
        elseif(motive == "Bomb") then OUT:addChild(TagString.new("Motive", "bomb"))
        elseif(motive == "Plant") then OUT:addChild(TagString.new("Motive", "plant"))
        elseif(motive == "Wasteland") then OUT:addChild(TagString.new("Motive", "wasteland"))
        elseif(motive == "Wanderer") then OUT:addChild(TagString.new("Motive", "wanderer"))
            height = 2
        elseif(motive == "Graham") then OUT:addChild(TagString.new("Motive", "graham"))
            height = 2
        elseif(motive == "Pool") then OUT:addChild(TagString.new("Motive", "pool"))
            width = 2
        elseif(motive == "Courbet") then OUT:addChild(TagString.new("Motive", "courbet"))
            width = 2
        elseif(motive == "Sunset") then OUT:addChild(TagString.new("Motive", "sunset"))
            width = 2
        elseif(motive == "Sea") then OUT:addChild(TagString.new("Motive", "sea"))
            width = 2
        elseif(motive == "Creebet") then OUT:addChild(TagString.new("Motive", "creebet"))
            width = 2
        elseif(motive == "Match") then OUT:addChild(TagString.new("Motive", "match"))
            width = 2
            height = 2
        elseif(motive == "Bust") then OUT:addChild(TagString.new("Motive", "bust"))
            width = 2
            height = 2
        elseif(motive == "Stage") then OUT:addChild(TagString.new("Motive", "stage"))
            width = 2
            height = 2
        elseif(motive == "Void") then OUT:addChild(TagString.new("Motive", "void"))
            width = 2
            height = 2
        elseif(motive == "SkullAndRoses") then OUT:addChild(TagString.new("Motive", "skull_and_roses"))
            width = 2
            height = 2
        elseif(motive == "Wither") then OUT:addChild(TagString.new("Motive", "wither"))
            width = 2
            height = 2
        elseif(motive == "Fighters") then OUT:addChild(TagString.new("Motive", "fighters"))
            width = 4
            height = 2
        elseif(motive == "Skeleton") then OUT:addChild(TagString.new("Motive", "skeleton"))
            width = 4
            height = 3
        elseif(motive == "DonkeyKong") then OUT:addChild(TagString.new("Motive", "donkey_kong"))
            width = 4
            height = 3
        elseif(motive == "Pointer") then OUT:addChild(TagString.new("Motive", "pointer"))
            width = 4
            height = 4
        elseif(motive == "Pigscene") then OUT:addChild(TagString.new("Motive", "pigscene"))
            width = 4
            height = 4
        elseif(motive == "BurningSkull") then OUT:addChild(TagString.new("Motive", "burning_skull"))
            width = 4
            height = 4
        else return nil end
    else return nil end

    OUT.Pos:child(1).value = OUT.Pos:child(1).value - ((height%2)/2)

    local TileX = math.floor(OUT.Pos:child(0).value)
    local TileY = math.floor(OUT.Pos:child(1).value)
    local TileZ = math.floor(OUT.Pos:child(2).value)

    TileY = TileY - (1-(height%2))

    if(OUT.Facing.value == 0) then --south
        TileX = TileX - (1-(width%2))
    elseif(OUT.Facing.value == 1) then --west
        TileZ = TileZ - (1-(width%2))
    end

    if(required) then
        OUT:addChild(TagInt.new("TileX", TileX))
        OUT:addChild(TagInt.new("TileY", TileY))
        OUT:addChild(TagInt.new("TileZ", TileZ))
    end


    return OUT
end
--
function Entity:ConvertPanda(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.CanPickUpLoot.value = true

    local mainGene = "normal"
    local hiddenGene = "normal"

    if(IN:contains("GeneArray", TYPE.LIST, TYPE.COMPOUND)) then
        if(IN.lastFound.childCount > 0) then
            local Genes = IN.lastFound:child(0)

            if(Genes:contains("MainAllele", TYPE.INT)) then
                local gene = Genes.lastFound.value

                if(gene == 0) then mainGene = "lazy"
                elseif(gene == 1) then mainGene = "worried"
                elseif(gene == 2) then mainGene = "playful"
                elseif(gene == 3) then mainGene = "aggressive"
                elseif(gene == 4) then mainGene = "weak"
                elseif(gene == 5) then mainGene = "weak"
                elseif(gene == 6) then mainGene = "weak"
                elseif(gene == 7) then mainGene = "weak"
                elseif(gene == 8) then mainGene = "brown"
                elseif(gene == 9) then mainGene = "brown"
                elseif(gene == 10) then mainGene = "normal"
                elseif(gene == 11) then mainGene = "normal"
                elseif(gene == 12) then mainGene = "normal"
                elseif(gene == 13) then mainGene = "normal"
                elseif(gene == 14) then mainGene = "normal"
                end
            end

            if(Genes:contains("HiddenAllele", TYPE.INT)) then
                local gene = Genes.lastFound.value

                if(gene == 0) then hiddenGene = "lazy"
                elseif(gene == 1) then hiddenGene = "worried"
                elseif(gene == 2) then hiddenGene = "playful"
                elseif(gene == 3) then hiddenGene = "aggressive"
                elseif(gene == 4) then hiddenGene = "weak"
                elseif(gene == 5) then hiddenGene = "weak"
                elseif(gene == 6) then hiddenGene = "weak"
                elseif(gene == 7) then hiddenGene = "weak"
                elseif(gene == 8) then hiddenGene = "brown"
                elseif(gene == 9) then hiddenGene = "brown"
                elseif(gene == 10) then hiddenGene = "normal"
                elseif(gene == 11) then hiddenGene = "normal"
                elseif(gene == 12) then hiddenGene = "normal"
                elseif(gene == 13) then hiddenGene = "normal"
                elseif(gene == 14) then hiddenGene = "normal"
                end
            end
        end
    end

    if(required) then
        OUT:addChild(TagString.new("MainGene", mainGene))
        OUT:addChild(TagString.new("HiddenGene", hiddenGene))
    end

    return OUT
end
--
function Entity:ConvertParrot(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value
        if(Variant < 0 or Variant > 4) then Variant = 0 end
        OUT:addChild(TagInt.new("Variant", Variant))
    elseif(required) then
        OUT:addChild(TagInt.new("Variant"))
    end

    return OUT
end 
--
function Entity:ConvertPhantom(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then
        OUT:addChild(TagInt.new("Size"))
        OUT:addChild(TagInt.new("AX", math.floor(OUT.Pos:child(0).value)))
        OUT:addChild(TagInt.new("AY", math.floor(OUT.Pos:child(1).value)))
        OUT:addChild(TagInt.new("AZ", math.floor(OUT.Pos:child(2).value)))
    end

    return OUT
end
--
function Entity:ConvertPig(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Saddled", TYPE.BYTE)) then OUT:addChild(TagByte.new("Saddle", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Saddle")) end

    return OUT
end
--
function Entity:ConvertPiglin(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("ChestItems", TYPE.LIST, TYPE.COMPOUND)) then
        IN.ChestItems = IN.lastFound
        OUT.Inventory = OUT:addChild(TagList.new("Inventory"))
        for i=0, IN.ChestItems.childCount-1 do
            local item = Item:ConvertItem(IN.ChestItems:child(i), true)
            if(item ~= nil) then
                OUT.Inventory:addChild(item)
            end
        end
    elseif(required) then
        OUT:addChild(TagList.new("Inventory"))
    end

    if(Entity:HasDefinition(IN.definitions, "+hunter") and required) then
        OUT:addChild(TagByte.new("CannotHunt", false))
    elseif(required) then
        OUT:addChild(TagByte.new("CannotHunt", true))
    end

    return OUT
end
--
function Entity:ConvertPillager(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertPolarBear(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertPotionLingering(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    local potionItem = TagCompound.new("Potion")
    potionItem:addChild(TagString.new("id", "minecraft:lingering_potion"))
    potionItem:addChild(TagByte.new("Count", 1))

    if(IN:contains("PotionId", TYPE.SHORT)) then
        if(Settings:dataTableContains("potions", tostring(IN.lastFound.value))) then
            local entry = Settings.lastFound
            potionItem.tag = potionItem:addChild(TagCompound.new("tag"))
            potionItem.tag:addChild(TagString.new("Potion", "minecraft:" .. entry[1][1]))
        end
    end

    return OUT
end
--
function Entity:ConvertPotionSplash(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    local potionItem = TagCompound.new("Potion")
    potionItem:addChild(TagString.new("id", "minecraft:splash_potion"))
    potionItem:addChild(TagByte.new("Count", 1))

    if(IN:contains("PotionId", TYPE.SHORT)) then
        if(Settings:dataTableContains("potions", tostring(IN.lastFound.value))) then
            local entry = Settings.lastFound
            potionItem.tag = potionItem:addChild(TagCompound.new("tag"))
            potionItem.tag:addChild(TagString.new("Potion", "minecraft:" .. entry[1][1]))
        end
    end

    return OUT
end
--
function Entity:ConvertPufferfish(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(Entity:HasDefinition(IN.definitions, "+minecraft:normal_puff") and required) then
        OUT:addChild(TagInt.new("PuffState"))
    elseif(Entity:HasDefinition(IN.definitions, "+minecraft:deflate_sensor") and required) then
        OUT:addChild(TagInt.new("PuffState", 1))
    elseif(required) then
        OUT:addChild(TagInt.new("PuffState"))
    end

    if(required) then OUT:addChild(TagByte.new("FromBucket")) end

    return OUT
end
--
function Entity:ConvertRabbit(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Variant", TYPE.INT)) then
        local RabbitType = IN.lastFound.value
        if(RabbitType < 0 or RabbitType > 5) then RabbitType = 0 end
        OUT:addChild(TagInt.new("RabbitType", RabbitType))
    elseif(required) then 
        OUT:addChild(TagInt.new("RabbitType"))
    end

    if(IN:contains("MoreCarrotTicks", TYPE.INT)) then
        OUT:addChild(IN.lastFound:clone())
    elseif(required) then
        OUT:addChild(TagInt.new("MoreCarrotTicks"))
    end

    return OUT
end
--
function Entity:ConvertRavager(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
    if(OUT == nil) then return nil end

    local TimeStamp = 0
    if(IN:contains("TimeStamp", TYPE.LONG)) then TimeStamp = IN.lastFound.value end

    if(Entity:HasDefinition(IN.definitions, "-minecraft:hostile") and required) then
        if(Entity:HasDefinition(IN.definitions, "+stunned")) then
            OUT.StunTick = OUT:addChild(TagInt.new("StunTick", TimeStamp-Settings:getSettingLong("Time")))
            OUT.RoarTick = OUT:addChild(TagInt.new("RoarTick"))
        elseif(Entity:HasDefinition(IN.definitions, "+roaring")) then
            OUT.RoarTick = OUT:addChild(TagInt.new("RoarTick", TimeStamp-Settings:getSettingLong("Time")))
            OUT.StunTick = OUT:addChild(TagInt.new("StunTick"))
        end
    end

    if(OUT.StunTick == nil and required) then OUT:addChild(TagInt.new("StunTick")) end
    if(OUT.RoarTick == nil and required) then OUT:addChild(TagInt.new("RoarTick")) end

    return OUT
end
--
function Entity:ConvertSalmon(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertSheep(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Sheared", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("Sheared", IN.lastFound.value ~= 0))
    elseif(required) then
        OUT:addChild(TagByte.new("Sheared"))
    end

    if(IN:contains("Color", TYPE.BYTE)) then
        local Color = IN.lastFound.value
        if(Color < 0 or Color > 15) then Color = 0 end
        OUT:addChild(TagByte.new("Color", Color))
    elseif(required) then 
        OUT:addChild(TagByte.new("Color"))
    end

    return OUT
end
--
function Entity:ConvertShulker(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Variant", TYPE.INT)) then
        local Color = IN.lastFound.value
        if(Color < 0 or Color > 16) then
            OUT:addChild(TagByte.new("Color", 16))
        else
            OUT:addChild(TagByte.new("Color", 15-Color))
        end
    elseif(required) then
        OUT:addChild(TagByte.new("Color", 16))
    end

    return OUT
end
--
function Entity:ConvertSilverfish(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertSkeleton(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertSkeletonHorse(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    --TODO skeleton horse trap

    return OUT
end
--
function Entity:ConvertSlime(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Size", TYPE.BYTE)) then
        local Size = IN.lastFound.value
        if(Size < 1) then Size = 1 end
        if(Size > 3) then Size = 3 end
        OUT:addChild(TagInt.new("Size", Size-1))
    elseif(IN:contains("Variant", TYPE.INT)) then 
        local Size = IN.lastFound.value
        if(Size < 1) then Size = 1 end
        if(Size > 3) then Size = 3 end
        OUT:addChild(TagInt.new("Size", Size-1))
    elseif(required) then 
        OUT:addChild(TagInt.new("Size", 1))
    end

    return OUT
end
--
function Entity:ConvertSnowball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    return OUT
end
--
function Entity:ConvertSnowman(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Sheared", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("Pumpkin", IN.lastFound.value == 0))
    elseif(required) then
        OUT:addChild(TagByte.new("Pumpkin", true))
    end

    return OUT
end
--
function Entity:ConvertSmallFireball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("direction", TYPE.LIST, TYPE.FLOAT)) then
        IN.direction = IN.lastFound
        if(IN.direction.childCount == 3) then
            OUT.direction = OUT:addChild(TagList.new("direction"))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(0).value))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(1).value))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(2).value))
        end
    end

    if(OUT.direction == nil and required) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new(""))
        OUT.direction:addChild(TagDouble.new(""))
        OUT.direction:addChild(TagDouble.new(""))
    end

    if(IN:contains("power", TYPE.LIST, TYPE.FLOAT)) then
        IN.power = IN.lastFound
        if(IN.power.childCount == 3) then
            OUT.power = OUT:addChild(TagList.new("power"))
            OUT.power:addChild(TagDouble.new("", IN.power:child(0).value))
            OUT.power:addChild(TagDouble.new("", IN.power:child(1).value))
            OUT.power:addChild(TagDouble.new("", IN.power:child(2).value))
        end
    end

    if(OUT.power == nil and required) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new(""))
        OUT.power:addChild(TagDouble.new(""))
        OUT.power:addChild(TagDouble.new(""))
    end

    return OUT
end
--
function Entity:ConvertSpider(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertStray(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertStrider(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Saddled", TYPE.BYTE)) then OUT:addChild(TagByte.new("Saddle", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Saddle")) end

    return OUT
end
--
function Entity:ConvertSquid(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertTNT(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Fuse", TYPE.BYTE)) then
        OUT:addChild(TagShort.new("Fuse", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagShort.new("Fuse", -1))
    end

    return OUT
end
--
function Entity:ConvertTrident(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    local OnGround = false
    if(OUT:contains("OnGround", TYPE.BYTE)) then OnGround = IN.lastFound.value ~= 0 end

    OUT.xTile = OUT:addChild(TagInt.new("xTile", -1))
    OUT.yTile = OUT:addChild(TagInt.new("yTile", -1))
    OUT.zTile = OUT:addChild(TagInt.new("zTile", -1))

    if(IN:contains("StuckToBlockPos", TYPE.LIST, TYPE.INT) and OnGround) then
        if(IN.lastFound.childCount == 3) then
            OUT.xTile.value = IN.lastFound:child(0).value
            OUT.yTile.value = IN.lastFound:child(1).value
            OUT.zTile.value = IN.lastFound:child(2).value
        end
    end

    if(required) then
        OUT:addChild(TagByte.new("shake"))
        OUT:addChild(TagByte.new("inGround"))
        OUT:addChild(TagByte.new("crit"))
        OUT:addChild(TagShort.new("life"))
        OUT:addChild(TagByte.new("DealtDamage"))
    end

    if(IN:contains("isCreative", TYPE.BYTE)) then 
        if(IN.lastFound.value ~= 0) then
            OUT:addChild(TagByte.new("pickup", 2))
        else
            OUT:addChild(TagByte.new("pickup"))
        end
    elseif(required) then
        OUT:addChild(TagByte.new("pickup"))
    end

    if(IN:contains("Trident", TYPE.COMPOUND)) then
        local tridentItem = Item:ConvertItem(IN.lastFound, false)

        if(tridentItem ~= nil) then
            tridentItem.name = "Trident"
            OUT.Trident = OUT:addChild(tridentItem)
        end
    end

    if(OUT.Trident == nil and required) then
        OUT.Trident = OUT:addChild(TagCompound.new("Trident"))
        OUT.Trident:addChild(TagString.new("id", "minecraft:trident"))
        OUT.Trident:addChild(TagByte.new("Count", 1))
    end

    return OUT
end
--
function Entity:ConvertTropicalFish(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    --TODO Parse Variant bitflags

    if(required) then OUT:addChild(TagByte.new("FromBucket")) end

    return OUT
end
--
function Entity:ConvertTurtle(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("HomePos", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then
            IN.HomePos = IN.lastFound

            OUT.HomePosX = OUT:addChild(TagInt.new("HomePosX", math.floor(IN.HomePos:child(0).value)))
            OUT.HomePosY = OUT:addChild(TagInt.new("HomePosY", math.floor(IN.HomePos:child(1).value)))
            OUT.HomePosZ = OUT:addChild(TagInt.new("HomePosZ", math.floor(IN.HomePos:child(2).value)))
        end
    end

    if(OUT.HomePosX == nil and required) then OUT:addChild(TagInt.new("HomePosX", math.floor(OUT.Pos:child(0).value))) end
    if(OUT.HomePosY == nil and required) then OUT:addChild(TagInt.new("HomePosY", math.floor(OUT.Pos:child(1).value))) end
    if(OUT.HomePosZ == nil and required) then OUT:addChild(TagInt.new("HomePosZ", math.floor(OUT.Pos:child(2).value))) end

    if(IN:contains("IsPregnant", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("HasEgg", IN.lastFound.value ~= 0))
    elseif(required) then 
        OUT:addChild(TagByte.new("HasEgg"))
    end

    return OUT
end
--
function Entity:ConvertVex(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then
        OUT:addChild(TagInt.new("LifeTicks", 1200))
        OUT:addChild(TagInt.new("BoundX", math.floor(OUT.Pos:child(0).value)))
        OUT:addChild(TagInt.new("BoundY", math.floor(OUT.Pos:child(1).value)))
        OUT:addChild(TagInt.new("BoundZ", math.floor(OUT.Pos:child(2).value)))
    end

    return OUT
end
--TODO villager data has a level tag. include it
function Entity:ConvertVillager(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.CanPickUpLoot.value = true

    if(IN:contains("ChestItems", TYPE.LIST, TYPE.COMPOUND)) then
        IN.ChestItems = IN.lastFound
        OUT.Inventory = OUT:addChild(TagList.new("Inventory"))
        for i=0, IN.ChestItems.childCount-1 do
            local item = Item:ConvertItem(IN.ChestItems:child(i), true)
            if(item ~= nil) then
                OUT.Inventory:addChild(item)
            end
        end
    elseif(required) then
        OUT:addChild(TagList.new("Inventory"))
    end

    if(IN:contains("Willing", TYPE.BYTE)) then OUT:addChild(TagByte.new("Willing", IN.lastFound.value ~=0)) elseif(required) then OUT:addChild(TagByte.new("Willing")) end


    if(IN:contains("Offers", TYPE.COMPOUND)) then
        IN.Offers = IN.lastFound
        OUT.Offers = OUT:addChild(TagCompound.new("Offers"))

        if(IN.Offers:contains("Recipes", TYPE.LIST, TYPE.COMPOUND)) then
            IN.Offers.Recipes = IN.Offers.lastFound
            OUT.Offers.Recipes = OUT.Offers:addChild(TagList.new("Recipes"))

            for i=0, IN.Offers.Recipes.childCount-1 do
                local trade_in = IN.Offers.Recipes:child(i)
                local trade_out = TagCompound.new()


                if(trade_in:contains("buyA", TYPE.COMPOUND)) then
                    local buyA = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyA == nil) then goto tradeContinue end
                    buyA.name = "buy"
                    trade_out:addChild(buyA)
                else goto tradeContinue end

                if(trade_in:contains("buyB", TYPE.COMPOUND)) then
                    local buyB = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyB ~= nil) then
                        buyB.name = "buyB"
                        trade_out:addChild(buyB)
                    end
                end

                if(trade_in:contains("sell", TYPE.COMPOUND)) then
                    local sell = Item:ConvertItem(trade_in.lastFound, false)
                    if(sell == nil) then goto tradeContinue end
                    sell.name = "sell"
                    trade_out:addChild(sell)
                else goto tradeContinue end

                if(trade_in:contains("rewardExp", TYPE.BYTE)) then
                    trade_out:addChild(TagByte.new("rewardExp", trade_in.lastFound.value ~= 0))
                else trade_out:addChild(TagByte.new("rewardExp", true)) end

                if(trade_in:contains("maxUses", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("maxUses", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("maxUses", 6)) end

                if(trade_in:contains("uses", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("uses", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("uses")) end

                if(trade_in:contains("priceMultiplierA", TYPE.FLOAT)) then
                    trade_out:addChild(TagFloat.new("priceMultiplier", trade_in.lastFound.value))
                else trade_out:addChild(TagFloat.new("priceMultiplier", 0)) end
                
                if(trade_in:contains("demand", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("demand", (trade_in.lastFound.value+32)*-1))
                else trade_out:addChild(TagInt.new("demand")) end

                if(trade_in:contains("traderExp", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("xp", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("xp", 1)) end

                OUT.Offers.Recipes:addChild(trade_out)

                ::tradeContinue::
            end

        end

        --TODO TradeExperienceLevels, might be different for each villager? dont forget about wandering trader's trades
    end

    OUT.VillagerData = OUT:addChild(TagCompound.new("VillagerData"))

    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value

        if(Variant == 0) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:none"))
        elseif(Variant == 1) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
        elseif(Variant == 2) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:fisherman"))
        elseif(Variant == 3) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:shepherd"))
        elseif(Variant == 4) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:fletcher"))
        elseif(Variant == 5) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:librarian"))
        elseif(Variant == 6) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:cartographer"))
        elseif(Variant == 7) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:cleric"))
        elseif(Variant == 8) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:armorer"))
        elseif(Variant == 9) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:weaponsmith"))
        elseif(Variant == 10) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:toolsmith"))
        elseif(Variant == 11) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:butcher"))
        elseif(Variant == 12) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:leatherworker"))
        elseif(Variant == 13) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:mason"))
        elseif(Variant == 14) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:nitwit"))
        else
            OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
        end
    elseif(required) then 
        OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
    end

    OUT.VillagerData:addChild(TagString.new("type", "minecraft:plains"))

    if(OUT.VillagerData.childCount < 2) then
        OUT:removeChild(OUT.VillagerData:getRow())
        OUT.VillagerData = nil
    end

    return OUT
end
--
function Entity:ConvertVillagerV2(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.CanPickUpLoot.value = true

    if(IN:contains("ChestItems", TYPE.LIST, TYPE.COMPOUND)) then
        IN.ChestItems = IN.lastFound
        OUT.Inventory = OUT:addChild(TagList.new("Inventory"))
        for i=0, IN.ChestItems.childCount-1 do
            local item = Item:ConvertItem(IN.ChestItems:child(i), true)
            if(item ~= nil) then
                OUT.Inventory:addChild(item)
            end
        end
    elseif(required) then
        OUT:addChild(TagList.new("Inventory"))
    end

    if(IN:contains("Willing", TYPE.BYTE)) then OUT:addChild(TagByte.new("Willing", IN.lastFound.value ~=0)) elseif(required) then OUT:addChild(TagByte.new("Willing")) end


    if(IN:contains("Offers", TYPE.COMPOUND)) then
        IN.Offers = IN.lastFound
        OUT.Offers = OUT:addChild(TagCompound.new("Offers"))

        if(IN.Offers:contains("Recipes", TYPE.LIST, TYPE.COMPOUND)) then
            IN.Offers.Recipes = IN.Offers.lastFound
            OUT.Offers.Recipes = OUT.Offers:addChild(TagList.new("Recipes"))

            for i=0, IN.Offers.Recipes.childCount-1 do
                local trade_in = IN.Offers.Recipes:child(i)
                local trade_out = TagCompound.new()


                if(trade_in:contains("buyA", TYPE.COMPOUND)) then
                    local buyA = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyA == nil) then goto tradeContinue end
                    buyA.name = "buy"
                    trade_out:addChild(buyA)
                else goto tradeContinue end

                if(trade_in:contains("buyB", TYPE.COMPOUND)) then
                    local buyB = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyB ~= nil) then
                        buyB.name = "buyB"
                        trade_out:addChild(buyB)
                    end
                end

                if(trade_in:contains("sell", TYPE.COMPOUND)) then
                    local sell = Item:ConvertItem(trade_in.lastFound, false)
                    if(sell == nil) then goto tradeContinue end
                    sell.name = "sell"
                    trade_out:addChild(sell)
                else goto tradeContinue end

                if(trade_in:contains("rewardExp", TYPE.BYTE)) then
                    trade_out:addChild(TagByte.new("rewardExp", trade_in.lastFound.value ~= 0))
                else trade_out:addChild(TagByte.new("rewardExp", true)) end

                if(trade_in:contains("maxUses", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("maxUses", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("maxUses", 6)) end

                if(trade_in:contains("uses", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("uses", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("uses")) end

                if(trade_in:contains("priceMultiplierA", TYPE.FLOAT)) then
                    trade_out:addChild(TagFloat.new("priceMultiplier", trade_in.lastFound.value))
                else trade_out:addChild(TagFloat.new("priceMultiplier", 0)) end
                
                if(trade_in:contains("demand", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("demand", (trade_in.lastFound.value+32)*-1))
                else trade_out:addChild(TagInt.new("demand")) end

                if(trade_in:contains("traderExp", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("xp", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("xp", 1)) end

                OUT.Offers.Recipes:addChild(trade_out)

                ::tradeContinue::
            end

        end

        --TODO TradeExperienceLevels, might be different for each villager? dont forget about wandering trader's trades
    end

    OUT.VillagerData = OUT:addChild(TagCompound.new("VillagerData"))

    if(IN:contains("PreferredProfession", TYPE.STRING)) then
        local profession = IN.lastFound.value

        if(profession == "none") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "farmer") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "fisherman") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "shepherd") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "fletcher") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "librarian") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "cartographer") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "cleric") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "armorer") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "weaponsmith") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "toolsmith") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "butcher") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "leatherworker") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "mason") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "nitwit") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        else
            OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
        end
    elseif(required) then 
        OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
    end

    if(IN:contains("MarkVariant", TYPE.INT)) then
        local MarkVariant = IN.lastFound.value

        if(MarkVariant == 0) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:plains"))
        elseif(MarkVariant == 1) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:desert"))
        elseif(MarkVariant == 2) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:jungle"))
        elseif(MarkVariant == 3) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:savanna"))
        elseif(MarkVariant == 4) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:snow"))
        elseif(MarkVariant == 5) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:swamp"))
        elseif(MarkVariant == 6) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:taiga"))
        else
            OUT.VillagerData:addChild(TagString.new("type", "minecraft:plains"))
        end
    elseif(required) then
        OUT.VillagerData:addChild(TagString.new("type", "minecraft:plains"))
    end

    if(IN:contains("TradeTier", TYPE.INT)) then
        OUT.VillagerData:addChild(TagInt.new("level", IN.lastFound.value))
    elseif(required) then
        OUT.VillagerData:addChild(TagInt.new("level"))
    end

    if(IN:contains("TradeExperience", TYPE.INT)) then
        OUT:addChild(TagInt.new("Xp", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagInt.new("Xp"))
    end

    if(OUT.VillagerData.childCount < 2) then
        OUT:removeChild(OUT.VillagerData:getRow())
        OUT.VillagerData = nil
    end

    return OUT
end
--
function Entity:ConvertVindicator(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertWanderingTrader(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Offers", TYPE.COMPOUND)) then
        IN.Offers = IN.lastFound
        OUT.Offers = OUT:addChild(TagCompound.new("Offers"))

        if(IN.Offers:contains("Recipes", TYPE.LIST, TYPE.COMPOUND)) then
            IN.Offers.Recipes = IN.Offers.lastFound
            OUT.Offers.Recipes = OUT.Offers:addChild(TagList.new("Recipes"))

            for i=0, IN.Offers.Recipes.childCount-1 do
                local trade_in = IN.Offers.Recipes:child(i)
                local trade_out = TagCompound.new()


                if(trade_in:contains("buyA", TYPE.COMPOUND)) then
                    local buyA = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyA == nil) then goto tradeContinue end
                    buyA.name = "buy"
                    trade_out:addChild(buyA)
                else goto tradeContinue end

                if(trade_in:contains("buyB", TYPE.COMPOUND)) then
                    local buyB = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyB ~= nil) then
                        buyB.name = "buyB"
                        trade_out:addChild(buyB)
                    end
                end

                if(trade_in:contains("sell", TYPE.COMPOUND)) then
                    local sell = Item:ConvertItem(trade_in.lastFound, false)
                    if(sell == nil) then goto tradeContinue end
                    sell.name = "sell"
                    trade_out:addChild(sell)
                else goto tradeContinue end

                if(trade_in:contains("rewardExp", TYPE.BYTE)) then
                    trade_out:addChild(TagByte.new("rewardExp", trade_in.lastFound.value ~= 0))
                else trade_out:addChild(TagByte.new("rewardExp", true)) end

                if(trade_in:contains("maxUses", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("maxUses", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("maxUses", 6)) end

                if(trade_in:contains("uses", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("uses", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("uses")) end

                if(trade_in:contains("priceMultiplierA", TYPE.FLOAT)) then
                    trade_out:addChild(TagFloat.new("priceMultiplier", trade_in.lastFound.value))
                else trade_out:addChild(TagFloat.new("priceMultiplier", 0)) end
                
                if(trade_in:contains("demand", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("demand", (trade_in.lastFound.value+32)*-1))
                else trade_out:addChild(TagInt.new("demand")) end

                if(trade_in:contains("traderExp", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("xp", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("xp", 1)) end

                OUT.Offers.Recipes:addChild(trade_out)

                ::tradeContinue::
            end

        end

        --TODO TradeExperienceLevels, might be different for each villager? dont forget about wandering trader's trades
    end

    return OUT
end
--
function Entity:ConvertWitch(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertWither(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Invul", TYPE.INT)) then
        OUT:addChild(IN.lastFound:clone())
    elseif(required) then
        OUT:addChild(TagInt.new("Invul"))
    end

    if(OUT.Attributes ~= nil) then
        for i=0, OUT.Attributes.childCount-1 do
            local attr_out = OUT.Attributes:child(i)
            if(attr_out:contains("Name", TYPE.STRING)) then
                local attrName = attr_out.lastFound.value
                if(attrName == "generic.maxHealth") then
                    if(attr_out:contains("Base", TYPE.DOUBLE)) then
                        attr_out.Base = attr_out.lastFound

                        if(OUT:contains("Health", TYPE.FLOAT)) then
                            OUT.Health = OUT.lastFound
                            if(attr_out.Base.value == 450) then
                                attr_out.Base.value = 300
                                OUT.Health.value = (OUT.Health.value * 2)/3
                            elseif(attr_out.Base.value == 600) then
                                attr_out.Base.value = 300
                                OUT.Health.value = OUT.Health.value/2
                            end
                        end
                    end
                end
            end
        end
    end

    return OUT
end
--
function Entity:ConvertWitherSkeleton(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertWitherSkull(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("direction", TYPE.LIST, TYPE.FLOAT)) then
        IN.direction = IN.lastFound
        if(IN.direction.childCount == 3) then
            OUT.direction = OUT:addChild(TagList.new("direction"))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(0).value))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(1).value))
            OUT.direction:addChild(TagDouble.new("", IN.direction:child(2).value))
        end
    end

    if(OUT.direction == nil and required) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new(""))
        OUT.direction:addChild(TagDouble.new(""))
        OUT.direction:addChild(TagDouble.new(""))
    end

    if(IN:contains("power", TYPE.LIST, TYPE.FLOAT)) then
        IN.power = IN.lastFound
        if(IN.power.childCount == 3) then
            OUT.power = OUT:addChild(TagList.new("power"))
            OUT.power:addChild(TagDouble.new("", IN.power:child(0).value))
            OUT.power:addChild(TagDouble.new("", IN.power:child(1).value))
            OUT.power:addChild(TagDouble.new("", IN.power:child(2).value))
        end
    end

    if(OUT.power == nil and required) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new(""))
        OUT.power:addChild(TagDouble.new(""))
        OUT.power:addChild(TagDouble.new(""))
    end

    return OUT
end
--
function Entity:ConvertWolf(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertZoglin(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertZombie(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertZombieHorse(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertZombiePigman(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("IsAngry", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then OUT:addChild(TagShort.new("Anger", 300)) end
    end

    return OUT
end
--
function Entity:ConvertZombieVillager(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.VillagerData = OUT:addChild(TagCompound.new("VillagerData"))

    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value

        if(Variant == 0) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:none"))
        elseif(Variant == 1) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
        elseif(Variant == 2) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:fisherman"))
        elseif(Variant == 3) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:shepherd"))
        elseif(Variant == 4) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:fletcher"))
        elseif(Variant == 5) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:librarian"))
        elseif(Variant == 6) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:cartographer"))
        elseif(Variant == 7) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:cleric"))
        elseif(Variant == 8) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:armorer"))
        elseif(Variant == 9) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:weaponsmith"))
        elseif(Variant == 10) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:toolsmith"))
        elseif(Variant == 11) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:butcher"))
        elseif(Variant == 12) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:leatherworker"))
        elseif(Variant == 13) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:mason"))
        elseif(Variant == 14) then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:nitwit"))
        else
            OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
        end
    elseif(required) then 
        OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
    end

    OUT.VillagerData:addChild(TagString.new("type", "minecraft:plains"))

    if(OUT.VillagerData.childCount < 2) then
        OUT:removeChild(OUT.VillagerData:getRow())
        OUT.VillagerData = nil
    end

    return OUT
end
--
function Entity:ConvertZombieVillagerV2(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("IsBaby", TYPE.BYTE)) then OUT:addChild(TagByte.new("IsBaby", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("IsBaby")) end

    if(IN:contains("Offers", TYPE.COMPOUND)) then
        IN.Offers = IN.lastFound
        OUT.Offers = OUT:addChild(TagCompound.new("Offers"))

        if(IN.Offers:contains("Recipes", TYPE.LIST, TYPE.COMPOUND)) then
            IN.Offers.Recipes = IN.Offers.lastFound
            OUT.Offers.Recipes = OUT.Offers:addChild(TagList.new("Recipes"))

            for i=0, IN.Offers.Recipes.childCount-1 do
                local trade_in = IN.Offers.Recipes:child(i)
                local trade_out = TagCompound.new()


                if(trade_in:contains("buyA", TYPE.COMPOUND)) then
                    local buyA = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyA == nil) then goto tradeContinue end
                    buyA.name = "buy"
                    trade_out:addChild(buyA)
                else goto tradeContinue end

                if(trade_in:contains("buyB", TYPE.COMPOUND)) then
                    local buyB = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyB ~= nil) then
                        buyB.name = "buyB"
                        trade_out:addChild(buyB)
                    end
                end

                if(trade_in:contains("sell", TYPE.COMPOUND)) then
                    local sell = Item:ConvertItem(trade_in.lastFound, false)
                    if(sell == nil) then goto tradeContinue end
                    sell.name = "sell"
                    trade_out:addChild(sell)
                else goto tradeContinue end

                if(trade_in:contains("rewardExp", TYPE.BYTE)) then
                    trade_out:addChild(TagByte.new("rewardExp", trade_in.lastFound.value ~= 0))
                else trade_out:addChild(TagByte.new("rewardExp", true)) end

                if(trade_in:contains("maxUses", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("maxUses", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("maxUses", 6)) end

                if(trade_in:contains("uses", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("uses", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("uses")) end

                if(trade_in:contains("priceMultiplierA", TYPE.FLOAT)) then
                    trade_out:addChild(TagFloat.new("priceMultiplier", trade_in.lastFound.value))
                else trade_out:addChild(TagFloat.new("priceMultiplier", 0)) end
                
                if(trade_in:contains("demand", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("demand", (trade_in.lastFound.value+32)*-1))
                else trade_out:addChild(TagInt.new("demand")) end

                if(trade_in:contains("traderExp", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("xp", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("xp", 1)) end

                OUT.Offers.Recipes:addChild(trade_out)

                ::tradeContinue::
            end

        end

        --TODO TradeExperienceLevels, might be different for each villager? dont forget about wandering trader's trades
    end

    OUT.VillagerData = OUT:addChild(TagCompound.new("VillagerData"))

    if(IN:contains("PreferredProfession", TYPE.STRING)) then
        local profession = IN.lastFound.value

        if(profession == "none") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "farmer") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "fisherman") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "shepherd") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "fletcher") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "librarian") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "cartographer") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "cleric") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "armorer") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "weaponsmith") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "toolsmith") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "butcher") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "leatherworker") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "mason") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        elseif(profession == "nitwit") then OUT.VillagerData:addChild(TagString.new("profession", "minecraft:" .. profession))
        else
            OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
        end
    elseif(required) then 
        OUT.VillagerData:addChild(TagString.new("profession", "minecraft:farmer"))
    end

    if(IN:contains("MarkVariant", TYPE.INT)) then
        local MarkVariant = IN.lastFound.value

        if(MarkVariant == 0) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:plains"))
        elseif(MarkVariant == 1) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:desert"))
        elseif(MarkVariant == 2) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:jungle"))
        elseif(MarkVariant == 3) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:savanna"))
        elseif(MarkVariant == 4) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:snow"))
        elseif(MarkVariant == 5) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:swamp"))
        elseif(MarkVariant == 6) then OUT.VillagerData:addChild(TagString.new("type", "minecraft:taiga"))
        else
            OUT.VillagerData:addChild(TagString.new("type", "minecraft:plains"))
        end
    elseif(required) then
        OUT.VillagerData:addChild(TagString.new("type", "minecraft:plains"))
    end

    if(OUT.VillagerData.childCount < 2) then
        OUT:removeChild(OUT.VillagerData:getRow())
        OUT.VillagerData = nil
    end

    if(Entity:HasDefinition(IN.definitions, "+to_villager") and required) then
        OUT:addChild(TagInt.new("ConversionTime", 2400))
    elseif(required) then
        OUT:addChild(TagInt.new("ConversionTime", -1))
    end

    return OUT
end

----------------- Base functions

function Entity:ConvertUUID(IN, OUT, required)
    if(IN:contains("UniqueID", TYPE.LONG)) then
        OUT.UUID = OUT:addChild(TagIntArray.new("UUID"))
        OUT.UUID:appendLong(IN.lastFound.value)
        OUT.UUID:appendLong(IN.lastFound.value)
    elseif(required) then
        OUT.UUID = OUT:addChild(TagIntArray.new("UUID"))
        OUT.UUID:appendLong(math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295))
        OUT.UUID:appendLong(math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295))
    end
end

function Entity:ConvertBase(IN, OUT, required)

    if(IN:contains("OnGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("OnGround", IN.lastFound.value ~= 0)) end
    if(IN:contains("Invulnerable", TYPE.BYTE)) then OUT:addChild(TagByte.new("Invulnerable", IN.lastFound.value ~= 0)) end
    if(IN:contains("Air", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Air", 300)) end
    if(IN:contains("Fire", TYPE.SHORT)) then
        local Fire = IN.lastFound.value
        if(Fire == 0) then Fire = -1 end
        OUT:addChild(TagShort.new("Fire", Fire))
    end
    if(IN:contains("LastDimensionId", TYPE.INT)) then OUT:addChild(TagInt.new("Dimension", IN.lastFound.value)) elseif(required) then
        local dim = Settings:getSettingInt("Dimension")
        if(dim == 1) then dim = -1 elseif(dim == 2) then dim = 1 end
        OUT:addChild(TagInt.new("Dimension", dim))
    end
    if(IN:contains("PortalCooldown", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("PortalCooldown")) end
    if(IN:contains("FallDistance", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("FallDistance")) end
    if(IN:contains("CustomName", TYPE.STRING)) then
        OUT:addChild(TagString.new("CustomName", "{\"text\": \"" .. IN.lastFound.value .. "\"}"))
        if(required) then OUT:addChild(TagByte.new("CustomNameVisible")) end
    end

    Entity:ConvertUUID(IN, OUT, required)

    --load definitions for easier access
    if(IN:contains("definitions", TYPE.LIST, TYPE.STRING)) then IN.definitions = IN.lastFound else IN.definitions = TagList.new("definitions") end

    return OUT
end

function Entity:ConvertBaseLiving(IN, OUT, required)

    if(required) then
        OUT.CanPickUpLoot = OUT:addChild(TagByte.new("CanPickUpLoot"))
        OUT:addChild(TagByte.new("FallFlying"))
        OUT:addChild(TagByte.new("LeftHanded"))
        OUT:addChild(TagShort.new("HurtByTimestamp"))
    end

    if(IN:contains("Persistent", TYPE.BYTE)) then OUT:addChild(TagByte.new("PersistenceRequired", IN.lastFound.value ~= 0)) end
    if(IN:contains("DeathTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("HurtTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) end

    if(IN:contains("Armor", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Armor = IN.lastFound

        OUT.ArmorItems = OUT:addChild(TagList.new("ArmorItems"))

        for i=0, 3 do
            local item = nil
            if(IN.Armor.childCount > 3-i) then
                item = Item:ConvertItem(IN.Armor:child(3-i), false)
            end
            if(item == nil) then item = TagCompound.new() end
            OUT.ArmorItems:addChild(item)
        end
    end
    if(required and OUT.ArmorItems == nil) then
        OUT.ArmorItems = OUT:addChild(TagList.new("ArmorItems"))
        OUT.ArmorItems:addChild(TagCompound.new())
        OUT.ArmorItems:addChild(TagCompound.new())
        OUT.ArmorItems:addChild(TagCompound.new())
        OUT.ArmorItems:addChild(TagCompound.new())
    end
    if(required) then
        OUT.ArmorDropChances = OUT:addChild(TagList.new("ArmorDropChances"))
        OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
        OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
        OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
        OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
    end

    if(IN:contains("Mainhand", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Mainhand = IN.lastFound
        if(IN.Mainhand.childCount == 1) then
            OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
            local item = Item:ConvertItem(IN.Mainhand:child(0), false)
            if(item ~= nil) then OUT.HandItems:addChild(item) else OUT.HandItems:addChild(TagCompound.new()) end
        end
    end
    if(required and OUT.HandItems == nil) then
        OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
        OUT.HandItems:addChild(TagCompound.new())
    end
    if(IN:contains("Offhand", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Offhand = IN.lastFound
        if(IN.Offhand.childCount == 1) then
            if(OUT.HandItems == nil) then
                OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
                OUT.HandItems:addChild(TagCompound.new())
            end

            local item = Item:ConvertItem(IN.Offhand:child(0), false)
            if(item ~= nil) then OUT.HandItems:addChild(item) else OUT.HandItems:addChild(TagCompound.new()) end
        end
    end
    if(required and OUT.HandItems.childCount == 1) then
        OUT.HandItems:addChild(TagCompound.new())
    end
    if(required) then
        OUT.HandDropChances = OUT:addChild(TagList.new("HandDropChances"))
        OUT.HandDropChances:addChild(TagFloat.new("", 0.085))
        OUT.HandDropChances:addChild(TagFloat.new("", 0.085))
    end

    if(IN:contains("ActiveEffects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.ActiveEffects = IN.lastFound
        OUT.ActiveEffects = OUT:addChild(TagList.new("ActiveEffects"))

        for i=0, IN.ActiveEffects.childCount-1 do
            local effect_in = IN.ActiveEffects:child(i)
            local effect_out = TagCompound.new()

            if(effect_in:contains("Id", TYPE.BYTE)) then
                if(Settings:dataTableContains("active_effects", tostring(effect_in.lastFound.value))) then
                    local entry = Settings.lastFound
                    effect_out:addChild(TagByte.new("Id", tonumber(entry[1][1])))
                else goto effectContinue end
            else goto effectContinue end

            if(effect_in:contains("ShowParticles", TYPE.BYTE)) then effect_out:addChild(TagByte.new("ShowParticles", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("ShowParticles", true)) end
            if(effect_in:contains("Ambient", TYPE.BYTE)) then effect_out:addChild(TagByte.new("Ambient", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("Ambient")) end
            if(effect_in:contains("Amplifier", TYPE.BYTE)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagByte.new("Amplifier")) end
            if(effect_in:contains("Duration", TYPE.INT)) then effect_out:addChild(TagInt.new("Duration", effect_in.lastFound.value)) else effect_out:addChild(TagInt.new("Duration", 1)) end

            OUT.ActiveEffects:addChild(effect_out)

            ::effectContinue::
        end
    end

    if(IN:contains("Attributes", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Attributes = IN.lastFound
        OUT.Attributes = OUT:addChild(TagList.new("Attributes"))

        for i=0, IN.Attributes.childCount-1 do
            local attr_in = IN.Attributes:child(i)
            local attr_out = TagCompound.new()

            if(attr_in:contains("Max", TYPE.FLOAT)) then attr_in.Max = attr_in.lastFound.value else goto attrContinue end
            if(attr_in:contains("Current", TYPE.FLOAT)) then attr_in.Current = attr_in.lastFound.value else goto attrContinue end

            if(attr_in:contains("Name", TYPE.STRING)) then
                local attrName = attr_in.lastFound.value
                if(attrName:find("^minecraft:")) then attrName = attrName:sub(11) end

                if(attrName == "health") then
                    OUT:addChild(TagFloat.new("Health", attr_in.Current))
                    attr_out:addChild(TagString.new("Name", "minecraft:generic.max_health"))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Max))
                elseif(attrName == "absorption") then
                    OUT:addChild(TagFloat.new("AbsorptionAmount", attr_in.Current))
                    goto attrContinue
                elseif(attrName == "knockback_resistance") then
                    attr_out:addChild(TagString.new("Name", "minecraft:generic.knockback_resistance"))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                elseif(attrName == "movement") then
                    attr_out:addChild(TagString.new("Name", "minecraft:generic.movement_speed"))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                    if(true) then goto attrContinue end --skips movement attribute resulting in movement speeds resetting to default. temporary solution
                elseif(attrName == "follow_range") then
                    attr_out:addChild(TagString.new("Name", "minecraft:generic.follow_range"))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                elseif(attrName == "attack_damage") then
                    attr_out:addChild(TagString.new("Name", "minecraft:generic.attack_damage"))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                elseif(attrName == "horse.jump_strength") then
                    attr_out:addChild(TagString.new("Name", "minecraft:horse.jump_strength"))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                elseif(attrName == "flying_speed") then
                    attr_out:addChild(TagInt.new("ID", 11))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                else goto attrContinue end
            else goto attrContinue end

            OUT.Attributes:addChild(attr_out)

            ::attrContinue::
        end
    end

    return OUT
end

function Entity:ConvertBaseBreedable(IN, OUT, required)
    if(IN:contains("InLove", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("InLove")) end

    if(IN:contains("Age", TYPE.INT)) then
        OUT.Age = OUT:addChild(TagInt.new("Age", IN.lastFound.value))
    elseif(required) then
        OUT.Age =  OUT:addChild(TagInt.new("Age"))
    end

    if(IN:contains("BreedCooldown", TYPE.INT)) then
        if(IN.lastFound.value > 0) then
            if(OUT.Age == nil) then OUT:addChild(TagInt.new("Age", IN.lastFound.value)) else OUT.Age.value = IN.lastFound.value end
        end
    end

    return OUT
end

function Entity:ConvertBaseZombie(IN, OUT, required)

    if(Entity:HasDefinition(IN.definitions, "+minecraft:start_drowned_transformation") and required) then
        if(IN:contains("TimeStamp", TYPE.LONG)) then
            OUT:addChild(TagInt.new("InWaterTime", IN.lastFound.value-Settings:getSettingLong("Time")))
            OUT:addChild(TagInt.new("DrownedConversionTime", -1))
        elseif(IN:contains("CountTime", TYPE.INT)) then
            local CountTime = IN.lastFound.value
            if(IN.lastFound.value == 0) then CountTime = -1 end
            OUT:addChild(TagInt.new("InWaterTime", CountTime))
        else
            OUT:addChild(TagInt.new("InWaterTime", -1))
            OUT:addChild(TagInt.new("DrownedConversionTIme", -1))
        end
    elseif(Entity:HasDefinition(IN.definitions, "+minecraft:convert_to_drowned") and required) then
        OUT:addChild(TagInt.new("InWaterTime", -1))
        OUT:addChild(TagInt.new("DrownedConversionTIme", 300))
    end

    if(IN:contains("IsBaby", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then OUT:addChild(TagByte.new("IsBaby", true)) end
    end

    return OUT
end

function Entity:ConvertBaseRaiding(IN, OUT, required)

    --TODO all raid spawning

    --JAVA
    --CanJoinRaid byte
    --PatrolLeader byte
    --Patrolling byte
    --Wave int

    return OUT
end

function Entity:ConvertBaseMinecart(IN, OUT, required)

    if(OUT:contains("Pos", TYPE.LIST, TYPE.DOUBLE)) then
        OUT.Pos = OUT.lastFound
        if(OUT.Pos.childCount == 3) then
            OUT.Pos:child(1).value = OUT.Pos:child(1).value - 0.35

            --detect if minecart is currently shares a block with a rail
            local minecartBlock = Chunk:getBlock(math.floor(OUT.Pos:child(0).value), math.floor(OUT.Pos:child(1).value), math.floor(OUT.Pos:child(2).value))
            if(minecartBlock:contains("name", TYPE.STRING)) then
                minecartBlock.Name = minecartBlock.lastFound.value
                if(minecartBlock.Name == "minecraft:activator_rail" or minecartBlock.Name == "minecraft:detector_rail" or minecartBlock.Name == "minecraft:powered_rail" or  minecartBlock.Name == "minecraft:rail") then
                    OUT.Pos:child(1).value = OUT.Pos:child(1).value - 0.0875
                end
            end
        end
    end

    return OUT
end

function Entity:ConvertBaseHorse(IN, OUT, required)

    if(required) then
        OUT:addChild(TagByte.new("EatingHaystack"))
        OUT:addChild(TagByte.new("Bred"))
        OUT:addChild(TagByte.new("Tame"))
        OUT:addChild(TagInt.new("Temper"))
    end

    return OUT
end

function Entity:ConvertBaseProjectile(IN, OUT, required)

    local inGround = false
    if(IN:contains("inGround", TYPE.BYTE)) then
        inGround = true
        OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0))
    elseif(required) then
        OUT:addChild(TagByte.new("inGround"))
    end

    OUT.xTile = OUT:addChild(TagInt.new("xTile", -1))
    OUT.yTile = OUT:addChild(TagInt.new("yTile", -1))
    OUT.zTile = OUT:addChild(TagInt.new("zTile", -1))

    if(IN:contains("StuckToBlockPos", TYPE.LIST, TYPE.INT) and inGround) then
        if(IN.lastFound.childCount == 3) then
            OUT.xTile.value = IN.lastFound:child(0).value
            OUT.yTile.value = IN.lastFound:child(1).value
            OUT.zTile.value = IN.lastFound:child(2).value
        end
    end

    --TODO inBlockState

    return OUT
end

function Entity:ConvertItems(IN, OUT, required)
    if(IN:contains("Items", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Items = IN.lastFound
        OUT.Items = OUT:addChild(TagList.new("Items"))
        for i=0, IN.Items.childCount-1 do
            local item = Item:ConvertItem(IN.Items:child(i), true)
            if(item ~= nil) then
                OUT.Items:addChild(item)
            end
        end
    elseif(required) then
        OUT:addChild(TagList.new("Items"))
    end
end

function Entity:HasDefinition(definitions, name)
    for i=0, definitions.childCount-1 do
        if(definitions:child(i).value == name) then return true end
    end

    return false
end

return Entity