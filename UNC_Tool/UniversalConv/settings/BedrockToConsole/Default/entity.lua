Entity = {}
Item = Item or require("item")

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
            OUT:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            if(tostring(entry[1][3]) == "TRUE") then OUT.Spawnable = true else OUT.Spawnable = false end
            OUT = Entity[entry[1][2]](Entity, IN, OUT, required)
            if(OUT == nil) then return nil end
        else return nil end
    else
        if(Settings:dataTableContains("entities_ids", tostring(id_num))) then
            local entry = Settings.lastFound
            OUT:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            if(tostring(entry[1][3]) == "TRUE") then OUT.Spawnable = true else OUT.Spawnable = false end
            OUT = Entity[entry[1][2]](Entity, IN, OUT, required)
            if(OUT == nil) then return nil end
        else return nil end
    end

    if(IN:contains("LinksTag", TYPE.LIST, TYPE.COMPOUND) and IN.Entities_output_ref ~= nil and IN.Entities_input_ref ~= nil) then
        IN.LinksTag = IN.lastFound

        OUT.Riding = OUT:addChild(TagList.new("Riding"))

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
                        --convert console uuid into uniqueid
                        if(cPassenger:contains("UUID", TYPE.STRING)) then
                            local UUID = cPassenger.lastFound.value
                            if(UUID:find("^ent") and UUID:len() == 35) then
                                if(tonumber("0x" .. UUID:sub(4, 19)) == Link.entityID.value) then
                                    --if it does, then move that base entity into Passengers here, removing from output list, and then continue
                                    OUT.Riding:addChild(cPassenger)
                                    break
                                end
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
                                    OUT.Riding:addChild(passenger)
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
        if(IN.Armor.childCount == 4) then
            OUT.ArmorItems = OUT:addChild(TagList.new("ArmorItems"))

            for i=0, 3 do
                local item = Item:ConvertItem(IN.Armor:child(i), false)
                if(item == nil) then item = TagCompound.new() end
                OUT.ArmorItems:addChild(item)
            end
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

    --TODO disabled slots

    if(IN:contains("Pose", TYPE.COMPOUND)) then
        IN.Pose = IN.lastFound
        OUT.Pose = OUT:addChild(TagCompound.new("Pose"))
        OUT.Pose.LastSignal = OUT.Pose:addChild(TagInt.new("LastSignal"))
        OUT.Pose.PoseIndex = OUT.Pose:addChild(TagInt.new("PoseIndex"))
        if(IN.Pose:contains("LastSignal", TYPE.INT)) then OUT.Pose.LastSignal.value = IN.Pose.lastFound.value end
        if(IN.Pose:contains("PoseIndex", TYPE.INT)) then OUT.Pose.PoseIndex.value = IN.Pose.lastFound.value end
    elseif(required) then
        OUT.Pose = OUT:addChild(TagCompound.new("Pose"))
        OUT.Pose:addChild(TagInt.new("LastSignal"))
        OUT.Pose:addChild(TagInt.new("PoseIndex"))
    end

    return OUT
end
--
function Entity:ConvertArrow(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then
        OUT:addChild(TagByte.new("inGround"))
        OUT:addChild(TagByte.new("crit"))
        OUT:addChild(TagShort.new("life"))
    end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    if(IN:contains("isCreative", TYPE.BYTE)) then 
        if(IN.lastFound.value ~= 0) then
            OUT:addChild(TagByte.new("pickup", 2))
        else
            OUT:addChild(TagByte.new("pickup"))
        end
    elseif(required) then
        OUT:addChild(TagByte.new("pickup"))
    end

    if(IN:contains("auxValue", TYPE.BYTE)) then
        local auxValue = IN.lastFound.value
        if(Settings:dataTableContains("potions", tostring(auxValue))) then
            local entry = Settings.lastFound
            OUT.Potion = OUT:addChild(TagString.new("Potion", "minecraft:" .. entry[1][1]))
        end
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
            if(effect_in:contains("Duration", TYPE.INT)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagInt.new("Duration", 1)) end

            OUT.CustomPotionEffects:addChild(effect_out)

            ::effectContinue::
        end

        if(OUT.CustomPotionEffects.childCount == 0) then
            OUT:removeChild(OUT.CustomPotionEffects:getRow())
            OUT.CustomPotionEffects = nil
        end
    end

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
        if(Variant >= 0 and Variant <= 5) then OUT:addChild(TagByte.new("Type", Variant))
        else OUT:addChild(TagByte.new("Type")) end
    elseif(required) then OUT:addChild(TagByte.new("Type")) end

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

    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

    if(IN:contains("direction", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then OUT.direction = OUT:addChild(IN.lastFound) end
    end

    if(OUT.direction == nil) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
    end

    if(IN:contains("power", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then OUT.power = OUT:addChild(IN.lastFound) end
    end

    if(OUT.power == nil) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
    end

    if(required) then OUT:addChild(TagInt.new("life")) end

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
    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

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
    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

    return OUT
end
--
function Entity:ConvertEnderman(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    --TODO legacy support
    if(IN:contains("carriedBlock", TYPE.COMPOUND)) then
        IN.blockState = IN.lastFound

        if(IN.blockState:contains("name", TYPE.STRING)) then
            local Name = IN.blockState.lastFound.value
            if(Name:find("^minecraft:")) then Name = Name:sub(11) end

            if(IN.blockState:contains("states", TYPE.COMPOUND)) then IN.blockState.states = IN.blockState.lastFound
            elseif(IN.blockState:contains("val", TYPE.SHORT)) then IN.blockState.val = IN.blockState.lastFound
            end
            
            if(Settings:dataTableContains("blocks_names", Name) and Name ~= air) then
                local entry = Settings.lastFound
                local ChunkVersion = Settings:getSettingInt("ChunkVersion")

                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                    if(subEntry[3]:len() ~= 0 and IN.blockState.states ~= nil) then
                        if(Item:CompareStates(subEntry[3], IN.blockState.states) == false) then goto entryContinue end
                    elseif(subEntry[2]:len() ~= 0 and IN.blockState.val ~= nil) then
                        if(tonumber(subEntry[2]) ~= IN.blockState.val) then goto entryContinue end
                    end
                    OUT.carried = OUT:addChild(TagString.new("carried", "minecraft:" .. subEntry[4]))
                    if(subEntry[5]:len() ~= 0) then OUT.carriedData = OUT:addChild(TagShort.new("carriedData", tonumber(subEntry[5]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    end

    if(OUT.carried == nil) then OUT:addChild(TagString.new("carried", "minecraft:air")) end
    if(OUT.carriedData == nil) then OUT:addChild(TagShort.new("carriedData", 0)) end

    return OUT
end
--
function Entity:ConvertEndermite(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagByte.new("PlayerSpawned")) end
    if(IN:contains("Lifetime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Lifetime")) end

    return OUT
end
--
function Entity:ConvertEvoker(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
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

    if(required) then
        OUT:addChild(TagByte.new("DropItem", true))
        OUT:addChild(TagByte.new("HurtEntities", true))
        OUT:addChild(TagInt.new("FallHurtMax", 40))
        OUT:addChild(TagFloat.new("FallHurtAmount", 2.0))
    end

    if(IN:contains("Time", TYPE.BYTE)) then OUT:addChild(TagInt.new("Time", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("Time")) end

    --TODO legacy support
    if(IN:contains("FallingBlock", TYPE.COMPOUND)) then
        IN.blockState = IN.lastFound

        if(IN.blockState:contains("name", TYPE.STRING)) then
            local Name = IN.blockState.lastFound.value
            if(Name:find("^minecraft:")) then Name = Name:sub(11) end

            if(IN.blockState:contains("states", TYPE.COMPOUND)) then IN.blockState.states = IN.blockState.lastFound
            elseif(IN.blockState:contains("val", TYPE.SHORT)) then IN.blockState.val = IN.blockState.lastFound
            end

            if(Settings:dataTableContains("blocks_names", Name) and Name ~= air) then
                local entry = Settings.lastFound
                local ChunkVersion = Settings:getSettingInt("ChunkVersion")

                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                    if(subEntry[3]:len() ~= 0 and IN.blockState.states ~= nil) then
                        if(Item:CompareStates(subEntry[3], IN.blockState.states) == false) then goto entryContinue end
                    elseif(subEntry[2]:len() ~= 0 and IN.blockState.val ~= nil) then
                        if(tonumber(subEntry[2]) ~= IN.blockState.val) then goto entryContinue end
                    end
                    OUT.Block = OUT:addChild(TagString.new("Block", "minecraft:" .. subEntry[4]))
                    if(subEntry[5]:len() ~= 0) then OUT.Data = OUT:addChild(TagByte.new("Data", tonumber(subEntry[5]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    end

    if(OUT.Block == nil) then OUT:addChild(TagString.new("Block", "minecraft:air")) end
    if(OUT.Data == nil) then OUT:addChild(TagByte.new("Data", 0)) end

    --TODO identify use of Variant
    --falling sand has a variant of 2152. bit flag to store damag info? maybe test anvils

    return OUT
end
--
function Entity:ConvertFireball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

    if(IN:contains("direction", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then OUT.direction = OUT:addChild(IN.lastFound) end
    end

    if(OUT.direction == nil) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
    end

    if(IN:contains("power", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then OUT.power = OUT:addChild(IN.lastFound) end
    end

    if(OUT.power == nil) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
    end

    if(required) then
        OUT:addChild(TagInt.new("life"))
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
function Entity:ConvertGhast(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("ExplosionPower", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ExplosionPower", 1)) end

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

    if(IN:contains("Age", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Age")) end
    if(IN:contains("Health", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Health", 5)) end
    if(required) then OUT:addChild(TagShort.new("PickupDelay")) end

    if(IN:contains("Item", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item == nil) then return nil end
        item.name = "Item"
        OUT:addChild(item)
    else return nil end

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
        if(motive == "Kebab") then OUT:addChild(TagString.new("Motive", "Kebab"))
        elseif(motive == "Aztec") then OUT:addChild(TagString.new("Motive", "Aztec"))
        elseif(motive == "Alban") then OUT:addChild(TagString.new("Motive", "Alban"))
        elseif(motive == "Aztec2") then OUT:addChild(TagString.new("Motive", "Aztec2"))
        elseif(motive == "Bomb") then OUT:addChild(TagString.new("Motive", "Bomb"))
        elseif(motive == "Plant") then OUT:addChild(TagString.new("Motive", "Plant"))
        elseif(motive == "Wasteland") then OUT:addChild(TagString.new("Motive", "Wasteland"))
        elseif(motive == "Wanderer") then OUT:addChild(TagString.new("Motive", "Wanderer"))
            height = 2
        elseif(motive == "Graham") then OUT:addChild(TagString.new("Motive", "Graham"))
            height = 2
        elseif(motive == "Pool") then OUT:addChild(TagString.new("Motive", "Pool"))
            width = 2
        elseif(motive == "Courbet") then OUT:addChild(TagString.new("Motive", "Courbet"))
            width = 2
        elseif(motive == "Sunset") then OUT:addChild(TagString.new("Motive", "Sunset"))
            width = 2
        elseif(motive == "Sea") then OUT:addChild(TagString.new("Motive", "Sea"))
            width = 2
        elseif(motive == "Creebet") then OUT:addChild(TagString.new("Motive", "Creebet"))
            width = 2
        elseif(motive == "Match") then OUT:addChild(TagString.new("Motive", "Match"))
            width = 2
            height = 2
        elseif(motive == "Bust") then OUT:addChild(TagString.new("Motive", "Bust"))
            width = 2
            height = 2
        elseif(motive == "Stage") then OUT:addChild(TagString.new("Motive", "Stage"))
            width = 2
            height = 2
        elseif(motive == "Void") then OUT:addChild(TagString.new("Motive", "Void"))
            width = 2
            height = 2
        elseif(motive == "SkullAndRoses") then OUT:addChild(TagString.new("Motive", "SkullAndRoses"))
            width = 2
            height = 2
        elseif(motive == "Wither") then OUT:addChild(TagString.new("Motive", "Wither"))
            width = 2
            height = 2
        elseif(motive == "Fighters") then OUT:addChild(TagString.new("Motive", "Fighters"))
            width = 4
            height = 2
        elseif(motive == "Skeleton") then OUT:addChild(TagString.new("Motive", "Skeleton"))
            width = 4
            height = 3
        elseif(motive == "DonkeyKong") then OUT:addChild(TagString.new("Motive", "DonkeyKong"))
            width = 4
            height = 3
        elseif(motive == "Pointer") then OUT:addChild(TagString.new("Motive", "Pointer"))
            width = 4
            height = 4
        elseif(motive == "Pigscene") then OUT:addChild(TagString.new("Motive", "Pigscene"))
            width = 4
            height = 4
        elseif(motive == "BurningSkull") then OUT:addChild(TagString.new("Motive", "BurningSkull"))
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
    potionItem:addChild(TagShort.new("Damage", 0))
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
    potionItem:addChild(TagShort.new("Damage", 0))
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
        if(Color < 0 or Color > 16) then Color = 16 end
        OUT:addChild(TagByte.new("Color", Color))
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
function Entity:ConvertSmallFireball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

    if(IN:contains("direction", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then OUT.direction = OUT:addChild(IN.lastFound) end
    end

    if(OUT.direction == nil) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
    end

    if(IN:contains("power", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then OUT.power = OUT:addChild(IN.lastFound) end
    end

    if(OUT.power == nil) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
    end

    if(required) then OUT:addChild(TagInt.new("life")) end

    return OUT
end
--
function Entity:ConvertSnowball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end
    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

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
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("isCreative", TYPE.BYTE)) then 
        if(IN.lastFound.value ~= 0) then
            OUT:addChild(TagByte.new("pickup", 2))
        else
            OUT:addChild(TagByte.new("pickup"))
        end
    elseif(required) then
        OUT:addChild(TagByte.new("pickup"))
    end

    if(required) then
        OUT:addChild(TagByte.new("shake"))
        OUT:addChild(TagByte.new("inGround"))
        OUT:addChild(TagByte.new("crit"))
        OUT:addChild(TagShort.new("life"))
        OUT:addChild(TagByte.new("DealtDamage"))
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
        OUT.Trident:addChild(TagShort.new("Damage", 0))
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

                OUT.Offers.Recipes:addChild(trade_out)

                ::tradeContinue::
            end

        end

        --TODO TradeExperienceLevels, might be different for each villager? dont forget about wandering trader's trades
    end

    OUT:addChild(TagInt.new("Riches"))

    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value

        OUT.Profession = OUT:addChild(TagInt.new("Profession"))
        OUT.Career = OUT:addChild(TagInt.new("Career"))
        OUT.CareerLevel = OUT:addChild(TagInt.new("CareerLevel", 1))

        if(Variant == 0) then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(Variant == 1) then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(Variant == 2) then
            OUT.Profession.value = 0
            OUT.Career.value = 1
        elseif(Variant == 3) then
            OUT.Profession.value = 0
            OUT.Career.value = 2
        elseif(Variant == 4) then
            OUT.Profession.value = 0
            OUT.Career.value = 3
        elseif(Variant == 5) then
            OUT.Profession.value = 1
            OUT.Career.value = 0
        elseif(Variant == 6) then
            OUT.Profession.value = 1
            OUT.Career.value = 1
        elseif(Variant == 7) then
            OUT.Profession.value = 2
            OUT.Career.value = 0
        elseif(Variant == 8) then
            OUT.Profession.value = 3
            OUT.Career.value = 0
        elseif(Variant == 9) then
            OUT.Profession.value = 3
            OUT.Career.value = 1
        elseif(Variant == 10) then
            OUT.Profession.value = 3
            OUT.Career.value = 2
        elseif(Variant == 11) then
            OUT.Profession.value = 4
            OUT.Career.value = 0
        elseif(Variant == 12) then
            OUT.Profession.value = 4
            OUT.Career.value = 1
        elseif(Variant == 13) then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(Variant == 14) then
            OUT.Profession.value = 5
            OUT.Career.value = 0
        end
    end

    if(OUT.Profession == nil and required) then OUT:addChild(TagInt.new("Profession")) end
    if(OUT.Career == nil and required) then OUT:addChild(TagInt.new("Career")) end
    if(OUT.CareerLevel == nil and required) then OUT:addChild(TagInt.new("CareerLevel", 1)) end

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

                OUT.Offers.Recipes:addChild(trade_out)

                ::tradeContinue::
            end

        end

        --TODO TradeExperienceLevels, might be different for each villager? dont forget about wandering trader's trades
    end

    OUT:addChild(TagInt.new("Riches"))

    if(IN:contains("PreferredProfession", TYPE.STRING)) then
        local profession = IN.lastFound.value

        OUT.Profession = OUT:addChild(TagInt.new("Profession"))
        OUT.Career = OUT:addChild(TagInt.new("Career"))
        OUT.CareerLevel = OUT:addChild(TagInt.new("CareerLevel", 1))

        if(profession == "none") then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(profession == "farmer") then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(profession == "fisherman") then
            OUT.Profession.value = 0
            OUT.Career.value = 1
        elseif(profession == "shepherd") then
            OUT.Profession.value = 0
            OUT.Career.value = 2
        elseif(profession == "fletcher") then
            OUT.Profession.value = 0
            OUT.Career.value = 3
        elseif(profession == "librarian") then
            OUT.Profession.value = 1
            OUT.Career.value = 0
        elseif(profession == "cartographer") then
            OUT.Profession.value = 1
            OUT.Career.value = 1
        elseif(profession == "cleric") then
            OUT.Profession.value = 2
            OUT.Career.value = 0
        elseif(profession == "armorer") then
            OUT.Profession.value = 3
            OUT.Career.value = 0
        elseif(profession == "weaponsmith") then
            OUT.Profession.value = 3
            OUT.Career.value = 1
        elseif(profession == "toolsmith") then
            OUT.Profession.value = 3
            OUT.Career.value = 2
        elseif(profession == "butcher") then
            OUT.Profession.value = 4
            OUT.Career.value = 0
        elseif(profession == "leatherworker") then
            OUT.Profession.value = 4
            OUT.Career.value = 1
        elseif(profession == "mason") then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(profession == "nitwit") then
            OUT.Profession.value = 5
            OUT.Career.value = 0
        end
    end

    if(OUT.Profession == nil and required) then OUT:addChild(TagInt.new("Profession")) end
    if(OUT.Career == nil and required) then OUT:addChild(TagInt.new("Career")) end
    if(OUT.CareerLevel == nil and required) then OUT:addChild(TagInt.new("CareerLevel", 1)) end

    return OUT
end
--
function Entity:ConvertVindicator(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertWitch(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
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

            if(attr_out:contains("ID", TYPE.INT)) then
                local attrID = attr_out.lastFound.value
                if(attrID == 0) then
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

    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

    if(IN:contains("direction", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then OUT.direction = OUT:addChild(IN.lastFound) end
    end

    if(OUT.direction == nil) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
    end

    if(IN:contains("power", TYPE.LIST, TYPE.FLOAT)) then
        if(IN.lastFound.childCount == 3) then OUT.power = OUT:addChild(IN.lastFound) end
    end

    if(OUT.power == nil) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
    end

    if(required) then OUT:addChild(TagInt.new("life")) end

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
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
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

    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value

        OUT.Profession = OUT:addChild(TagInt.new("Profession"))
        OUT.Career = OUT:addChild(TagInt.new("Career"))
        OUT.CareerLevel = OUT:addChild(TagInt.new("CareerLevel", 1))

        if(Variant == 0) then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(Variant == 1) then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(Variant == 2) then
            OUT.Profession.value = 0
            OUT.Career.value = 1
        elseif(Variant == 3) then
            OUT.Profession.value = 0
            OUT.Career.value = 2
        elseif(Variant == 4) then
            OUT.Profession.value = 0
            OUT.Career.value = 3
        elseif(Variant == 5) then
            OUT.Profession.value = 1
            OUT.Career.value = 0
        elseif(Variant == 6) then
            OUT.Profession.value = 1
            OUT.Career.value = 1
        elseif(Variant == 7) then
            OUT.Profession.value = 2
            OUT.Career.value = 0
        elseif(Variant == 8) then
            OUT.Profession.value = 3
            OUT.Career.value = 0
        elseif(Variant == 9) then
            OUT.Profession.value = 3
            OUT.Career.value = 1
        elseif(Variant == 10) then
            OUT.Profession.value = 3
            OUT.Career.value = 2
        elseif(Variant == 11) then
            OUT.Profession.value = 4
            OUT.Career.value = 0
        elseif(Variant == 12) then
            OUT.Profession.value = 4
            OUT.Career.value = 1
        elseif(Variant == 13) then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(Variant == 14) then
            OUT.Profession.value = 5
            OUT.Career.value = 0
        end
    end

    if(OUT.Profession == nil and required) then OUT:addChild(TagInt.new("Profession")) end
    if(OUT.Career == nil and required) then OUT:addChild(TagInt.new("Career")) end
    if(OUT.CareerLevel == nil and required) then OUT:addChild(TagInt.new("CareerLevel", 1)) end

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

                OUT.Offers.Recipes:addChild(trade_out)

                ::tradeContinue::
            end

        end

        --TODO TradeExperienceLevels, might be different for each villager? dont forget about wandering trader's trades
    end

    OUT:addChild(TagInt.new("Riches"))

    if(IN:contains("PreferredProfession", TYPE.STRING)) then
        local profession = IN.lastFound.value

        OUT.Profession = OUT:addChild(TagInt.new("Profession"))
        OUT.Career = OUT:addChild(TagInt.new("Career"))
        OUT.CareerLevel = OUT:addChild(TagInt.new("CareerLevel", 1))

        if(profession == "none") then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(profession == "farmer") then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(profession == "fisherman") then
            OUT.Profession.value = 0
            OUT.Career.value = 1
        elseif(profession == "shepherd") then
            OUT.Profession.value = 0
            OUT.Career.value = 2
        elseif(profession == "fletcher") then
            OUT.Profession.value = 0
            OUT.Career.value = 3
        elseif(profession == "librarian") then
            OUT.Profession.value = 1
            OUT.Career.value = 0
        elseif(profession == "cartographer") then
            OUT.Profession.value = 1
            OUT.Career.value = 1
        elseif(profession == "cleric") then
            OUT.Profession.value = 2
            OUT.Career.value = 0
        elseif(profession == "armorer") then
            OUT.Profession.value = 3
            OUT.Career.value = 0
        elseif(profession == "weaponsmith") then
            OUT.Profession.value = 3
            OUT.Career.value = 1
        elseif(profession == "toolsmith") then
            OUT.Profession.value = 3
            OUT.Career.value = 2
        elseif(profession == "butcher") then
            OUT.Profession.value = 4
            OUT.Career.value = 0
        elseif(profession == "leatherworker") then
            OUT.Profession.value = 4
            OUT.Career.value = 1
        elseif(profession == "mason") then
            OUT.Profession.value = 0
            OUT.Career.value = 0
        elseif(profession == "nitwit") then
            OUT.Profession.value = 5
            OUT.Career.value = 0
        end
    end

    if(OUT.Profession == nil and required) then OUT:addChild(TagInt.new("Profession")) end
    if(OUT.Career == nil and required) then OUT:addChild(TagInt.new("Career")) end
    if(OUT.CareerLevel == nil and required) then OUT:addChild(TagInt.new("CareerLevel", 1)) end

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
        local UUID_str = "ent" .. string.format("%x", IN.lastFound.value)
        UUID_str = UUID_str .. string.rep("0", 35-UUID_str:len())
        OUT.UniqueID = OUT:addChild(TagString.new("UUID", UUID_str))
    elseif(required) then
        local UUID_str = "ent" .. string.format("%x", math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295)) .. string.format("%x", math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295))
        UUID_str = UUID_str .. string.rep("0", 35-UUID_str:len())
        OUT.UniqueID = OUT:addChild(TagString.new("UUID", UUID_str))
    end
end

function Entity:ConvertBase(IN, OUT, required)

    if(IN:contains("OnGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("OnGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("OnGround", true)) end
    if(IN:contains("Invulnerable", TYPE.BYTE)) then OUT:addChild(TagByte.new("Invulnerable", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Invulnerable")) end
    if(IN:contains("Air", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Air", 300)) end
    if(IN:contains("Fire", TYPE.SHORT)) then
        local Fire = IN.lastFound.value
        if(Fire == 0) then Fire = -1 end
        OUT:addChild(TagShort.new("Fire", Fire))
    elseif(required) then OUT:addChild(TagShort.new("Fire", -1)) end
    if(IN:contains("LastDimensionId", TYPE.INT)) then OUT:addChild(TagInt.new("Dimension", IN.lastFound.value)) elseif(required) then
        local dim = Settings:getSettingInt("Dimension")
        if(dim == 1) then dim = -1 elseif(dim == 2) then dim = 1 end
        OUT:addChild(TagInt.new("Dimension", dim))
    end
    if(IN:contains("PortalCooldown", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("PortalCooldown")) end
    if(IN:contains("FallDistance", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("FallDistance")) end
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("CustomNameVisible", TYPE.BYTE)) then OUT:addChild(TagByte.new("CustomNameVisible", IN.lastFound.value ~= 0)) end

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

    if(IN:contains("Persistent", TYPE.BYTE)) then OUT:addChild(TagByte.new("PersistenceRequired", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("PersistenceRequired")) end
    if(IN:contains("DeathTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("DeathTime")) end
    if(IN:contains("HurtTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("HurtTime")) end

    --TODO Leash

    if(IN:contains("Armor", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Armor = IN.lastFound
        if(IN.Armor.childCount == 4) then
            OUT.ArmorItems = OUT:addChild(TagList.new("ArmorItems"))

            for i=0, 3 do
                local item = Item:ConvertItem(IN.Armor:child(i), false)
                if(item == nil) then item = TagCompound.new() end
                OUT.ArmorItems:addChild(item)
            end
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
                if(Settings:dataTableContains("active_effects", tostring(IN.lastFound.value))) then
                    local entry = Settings.lastFound
                    effect_out:addChild(TagByte.new("Id", tonumber(entry[1][1])))
                else goto effectContinue end
            else goto effectContinue end

            if(effect_in:contains("ShowParticles", TYPE.BYTE)) then effect_out:addChild(TagByte.new("ShowParticles", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("ShowParticles", true)) end
            if(effect_in:contains("Ambient", TYPE.BYTE)) then effect_out:addChild(TagByte.new("Ambient", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("Ambient")) end
            if(effect_in:contains("Amplifier", TYPE.BYTE)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagByte.new("Amplifier")) end
            if(effect_in:contains("Duration", TYPE.INT)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagInt.new("Duration", 1)) end

            OUT.ActiveEffects:addChild(effect_out)

            ::effectContinue::
        end

        if(OUT.ActiveEffects.childCount == 0) then
            OUT:removeChild(OUT.ActiveEffects:getRow())
            OUT.ActiveEffects = nil
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
                    attr_out:addChild(TagInt.new("ID", 0))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Max))
                elseif(attrName == "absorption") then
                    OUT:addChild(TagFloat.new("AbsorptionAmount", attr_in.Current))
                    goto attrContinue
                elseif(attrName == "knockback_resistance") then
                    attr_out:addChild(TagInt.new("ID", 2))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                elseif(attrName == "movement") then
                    attr_out:addChild(TagInt.new("ID", 3))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                    if(true) then goto attrContinue end --skips movement attribute resulting in movement speeds resetting to default. temporary solution
                elseif(attrName == "follow_range") then
                    attr_out:addChild(TagInt.new("ID", 1))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                elseif(attrName == "attack_damage") then
                    attr_out:addChild(TagInt.new("ID", 4))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                elseif(attrName == "horse.jump_strength") then
                    attr_out:addChild(TagInt.new("ID", 5))
                    attr_out:addChild(TagDouble.new("Base", attr_in.Current))
                elseif(attrName == "luck") then
                    attr_out:addChild(TagInt.new("ID", 10))
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

function Entity:ConvertBaseProjectile(IN, OUT, required)

    --TODO identify how tf these can be short tags?
    --if(IN:contains("xTile", TYPE.SHORT)) then OUT:addChild(TagInt.new("xTile", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then OUT:addChild(TagInt.new("xTile", -1)) end
    --if(IN:contains("yTile", TYPE.SHORT)) then OUT:addChild(TagInt.new("xTile", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("yTile", -1)) end
    --if(IN:contains("zTile", TYPE.SHORT)) then OUT:addChild(TagInt.new("zTile", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then OUT:addChild(TagInt.new("zTile", -1)) end

    --TODO legacy projectile support

    --TODO grab block at these coords maybe and generate tile data?
    --[[
    if(required) then 
        OUT:addChild(TagString.new("inTile", "minecraft:air"))
        OUT:addChild(TagShort.new("inData", 0))
    end
    --]]

    return OUT
end

function Entity:ConvertBaseZombie(IN, OUT, required)
    if(IN:contains("IsBaby", TYPE.BYTE)) then OUT:addChild(TagByte.new("IsBaby", IN.lastFound.value ~= 0)) end
    if(required) then OUT:addChild(TagByte.new("CanBreakDoors")) end

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

function Entity:ConvertBaseMinecart(IN, OUT, required)

    if(OUT:contains("Pos", TYPE.LIST, TYPE.DOUBLE)) then
        OUT.Pos = OUT.lastFound
        if(OUT.Pos.childCount == 3) then
            OUT.Pos:child(1).value = OUT.Pos:child(1).value - 0.35

            --detect if minecart is currently shares a block with a rail
            local minecartBlock = Chunk:getBlock(math.floor(OUT.Pos:child(0).value), math.floor(OUT.Pos:child(1).value), math.floor(OUT.Pos:child(2).value))
            if(minecartBlock:contains("id", TYPE.SHORT)) then
                minecartBlock.id = minecartBlock.lastFound.value
                if(minecartBlock.id == 126 or minecartBlock.id == 28 or minecartBlock.id == 27 or  minecartBlock.id == 66) then
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

function Entity:ConvertItems(IN, OUT, required)
    if(IN:contains("Items", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Items = IN.lastFound
        OUT.Items = OUT:addChild(TagList.new("Items"))
        for i=0, IN.Items.childCount-1 do
            local item = Item:ConvertItem(IN.Items:child(i), true)
            if(item ~= nil) then OUT.Items:addChild(item) end
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