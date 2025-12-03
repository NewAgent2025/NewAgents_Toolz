Entity = {}

FLOAT_MAX = 3.40282e+38

function Entity:ConvertEntity(IN, required)
    local OUT = TagCompound.new()

    --requires id, Pos, Rotation, Motion
    local id = ""
    if(IN:contains("id", TYPE.STRING)) then id = IN.lastFound.value
        if(id:find("^minecraft:")) then id = id:sub(11) end
    else return nil end
    if(IN:contains("Pos", TYPE.LIST, TYPE.DOUBLE)) then  if(IN.lastFound.childCount == 3) then IN.Pos = IN.lastFound else return nil end elseif(required) then return nil end
    if(IN:contains("Motion", TYPE.LIST, TYPE.DOUBLE)) then  if(IN.lastFound.childCount == 3) then IN.Motion = IN.lastFound else return nil end elseif(required) then return nil end
    if(IN:contains("Rotation", TYPE.LIST, TYPE.FLOAT)) then  if(IN.lastFound.childCount == 2) then IN.Rotation = IN.lastFound else return nil end elseif(required) then return nil end

    if(IN.Motion ~= nil) then
        OUT.Motion = OUT:addChild(TagList.new("Motion"))
        OUT.Motion:addChild(TagFloat.new("", IN.Motion:child(0).value))
        OUT.Motion:addChild(TagFloat.new("", IN.Motion:child(1).value))
        OUT.Motion:addChild(TagFloat.new("", IN.Motion:child(2).value))
    end

    if(IN.Rotation ~= nil) then
        OUT.Rotation = OUT:addChild(TagList.new("Rotation"))
        OUT.Rotation:addChild(TagFloat.new("", IN.Rotation:child(0).value))
        OUT.Rotation:addChild(TagFloat.new("", IN.Rotation:child(1).value))
    end

    if(IN.Pos ~= nil) then
        OUT.Pos = OUT:addChild(TagList.new("Pos"))
        OUT.Pos:addChild(TagFloat.new("", IN.Pos:child(0).value))
        OUT.Pos:addChild(TagFloat.new("", IN.Pos:child(1).value))
        OUT.Pos:addChild(TagFloat.new("", IN.Pos:child(2).value))
    end

    --TODO
    --ender dragon, illusioner, llama spit, shulker bullet

    if(Settings:dataTableContains("entities", id)) then
        local entry = Settings.lastFound
        OUT:addChild(TagString.new("identifier", "minecraft:" .. entry[1][1]))
        OUT = Entity[entry[1][3]](Entity, IN, OUT, required)
        if(OUT == nil) then return nil end
    else return nil end

    if(OUT.UniqueID ~= nil) then
        if(IN:contains("Riding", TYPE.COMPOUND)) then
            --Legacy
            IN.Riding = IN.lastFound
    
            --the entity in Riding is the entity that should reference this one
            IN.Riding.Entities_output_ref = IN.Entities_output_ref
            IN.Riding.TileEntities_output_ref = IN.TileEntities_output_ref
    
            local ridingEntity = Entity:ConvertEntity(IN.Riding, true)
            if(ridingEntity ~= nil) then
                ridingEntity.LinksTag = ridingEntity:addChild(TagList.new("LinksTag"))
                ridingEntity.LinksTag.Link = TagCompound.new()

                ridingEntity.LinksTag.Link:addChild(TagInt.new("linkID"))
                ridingEntity.LinksTag.Link:addChild(TagLong.new("entityID", OUT.UniqueID.value))

                if(IN.Entities_output_ref ~= nil) then IN.Entities_output_ref:addChild(ridingEntity) end
            end
        elseif(IN:contains("Riding", TYPE.LIST, TYPE.COMPOUND)) then
            --Normal
            IN.Passengers = IN.lastFound
    
            --the entities in passengers are the entities this one should reference
            OUT.LinksTag = OUT:addChild(TagList.new("LinksTag"))

            for i=0, IN.Passengers.childCount-1 do
                local passenger_in = IN.Passengers:child(i)
                passenger_in.Entities_output_ref = IN.Entities_output_ref
                passenger_in.TileEntities_output_ref = IN.TileEntities_output_ref
                local passenger_out = Entity:ConvertEntity(passenger_in, true)
                if(passenger_out ~= nil) then
                    if(passenger_out.UniqueID ~= nil) then
                        local Link = TagCompound.new()
                        Link:addChild(TagInt.new("linkID", OUT.LinksTag.childCount))
                        Link:addChild(TagLong.new("entityID", passenger_out.UniqueID.value))
                        OUT.LinksTag:addChild(Link)
                    end
                    if(IN.Entities_output_ref ~= nil) then IN.Entities_output_ref:addChild(passenger_out) end
                end
            end

            if(OUT.LinksTag.childCount == 0) then
                OUT:removeChild(OUT.LinksTag:getRow())
                OUT.LinksTag = nil
            end

        end
    end

    return OUT
end

--
function Entity:ConvertAreaEffectCloud(IN, OUT, required)
    OUT.def_base = "area_effect_cloud"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))

    if(IN:contains("Duration", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Duration", 600)) end
    if(IN:contains("DurationOnUse", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("DurationOnUse")) end
    if(IN:contains("ReapplicationDelay", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ReapplicationDelay", 20)) end
    if(IN:contains("WaitTime", TYPE.INT)) then
        OUT:addChild(TagLong.new("SpawnTick", Settings:getSettingLong("currentTick")+IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagLong.new("SpawnTick", Settings:getSettingLong("currentTick")+20))
    end
    if(IN:contains("Radius", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("Radius", 3)) end
    if(IN:contains("RadiusOnUse", TYPE.FLOAT)) then
        OUT:addChild(IN.lastFound:clone())
        OUT:addChild(TagFloat.new("RadiusChangeOnPickup", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagFloat.new("RadiusOnUse", -0.5))
        OUT:addChild(TagFloat.new("RadiusChangeOnPickup", -0.5))
    end
    if(IN:contains("RadiusPerTick", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("RadiusPerTick", -0.005)) end

    OUT.mobEffects = OUT:addChild(TagList.new("mobEffects"))
    if(IN:contains("Effects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Effects = IN.lastFound

        for i=0, IN.Effects.childCount-1 do
            local effect_in = IN.Effects:child(i)
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
            if(effect_in:contains("Duration", TYPE.INT)) then
                effect_out:addChild(TagInt.new("Duration", effect_in.lastFound.value))
                effect_out:addChild(TagInt.new("DurationEasy", effect_in.lastFound.value))
                effect_out:addChild(TagInt.new("DurationNormal", effect_in.lastFound.value))
                effect_out:addChild(TagInt.new("DurationHard", effect_in.lastFound.value))
            else
                effect_out:addChild(TagInt.new("Duration", 1))
                effect_out:addChild(TagInt.new("DurationEasy", 1))
                effect_out:addChild(TagInt.new("DurationNormal", 1))
                effect_out:addChild(TagInt.new("DurationHard", 1))
            end

            effect_out:addChild(TagByte.new("DisplayOnScreenTextureAnimation"))

            OUT.mobEffects:addChild(effect_out)

            ::effectContinue::
        end
    end

    if(IN:contains("Potion", TYPE.STRING)) then
        local potionName = IN.lastFound.value
        if(potionName:find("^minecraft:")) then potionName = potionName:sub(11) end

        if(Settings:dataTableContains("potions", potionName)) then
            local entry = Settings.lastFound
            local PotionId = tonumber(entry[1][1])
            local effectId = tonumber(entry[1][2])
            local effectDuration = tonumber(entry[1][3])
            local effectAmplifier = tonumber(entry[1][4])
            OUT:addChild(TagShort.new("PotionId", PotionId))

            --make an exception for turtle master
            if(PotionId == 37 or PotionId == 38 or PotionId == 39) then

                local effect_out1 = TagCompound.new()

                local duration1 = 100
                local duration2 = 100
                local amp1 = 3
                local amp2 = 2

                if(PotionId == 38) then
                    duration1 = 200
                    duration2 = 200
                elseif(PotionId == 39) then
                    amp1 = 5
                    amp2 = 3
                end

                effect_out1:addChild(TagByte.new("Id", 2))
                effect_out1:addChild(TagByte.new("ShowParticles", true))
                effect_out1:addChild(TagByte.new("Ambient"))
                effect_out1:addChild(TagByte.new("DisplayOnScreenTextureAnimation"))
                effect_out1:addChild(TagByte.new("Amplifier", amp1))
                effect_out1:addChild(TagInt.new("Duration", duration1))
                effect_out1:addChild(TagInt.new("DurationEasy", duration1))
                effect_out1:addChild(TagInt.new("DurationNormal", duration1))
                effect_out1:addChild(TagInt.new("DurationHard", duration1))

                effect_out2:addChild(TagByte.new("Id", 11))
                effect_out2:addChild(TagByte.new("ShowParticles", true))
                effect_out2:addChild(TagByte.new("Ambient"))
                effect_out2:addChild(TagByte.new("DisplayOnScreenTextureAnimation"))
                effect_out2:addChild(TagByte.new("Amplifier", amp2))
                effect_out2:addChild(TagInt.new("Duration", duration2))
                effect_out2:addChild(TagInt.new("DurationEasy", duration2))
                effect_out2:addChild(TagInt.new("DurationNormal", duration2))
                effect_out2:addChild(TagInt.new("DurationHard", duration2))

                OUT.mobEffects:addChild(effect_out1)
                OUT.mobEffects:addChild(effect_out2)

            else
                if(effectId ~= 0) then
                    local effect_out = TagCompound.new()

                    effect_out:addChild(TagByte.new("Id", effectId))
                    effect_out:addChild(TagByte.new("ShowParticles", true))
                    effect_out:addChild(TagByte.new("Ambient"))
                    effect_out:addChild(TagByte.new("DisplayOnScreenTextureAnimation"))
                    effect_out:addChild(TagByte.new("Amplifier", effectAmplifier))
                    effect_out:addChild(TagInt.new("Duration", effectDuration))
                    effect_out:addChild(TagInt.new("DurationEasy", effectDuration))
                    effect_out:addChild(TagInt.new("DurationNormal", effectDuration))
                    effect_out:addChild(TagInt.new("DurationHard", effectDuration))

                    OUT.mobEffects:addChild(effect_out)
                end
            end
        end
    end

    --if(OUT.mobEffects.childCount == 0) then return nil end

    --TODO particle effect

    return OUT
end
--
function Entity:ConvertArmorStand(IN, OUT, required)
    OUT.def_base = "armor_stand"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

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

function Entity:ConvertArrow(IN, OUT, required)
    OUT.def_base = "arrow"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))

    --TODO enchantFlame, enchantInfinity, enchantPower, enchantPower

    --TODO projectile information

    if(IN:contains("pickup", TYPE.BYTE)) then
        local pickup = IN.lastFound.value
        if(pickup < 0 or pickup > 2) then pickup = 1 end

        if(pickup == 0) then
            OUT:addChild(TagByte.new("player"))
        elseif(pickup == 1) then
            OUT:addChild(TagByte.new("player", true))
            OUT:addChild(TagByte.new("isCreative", true))
        elseif(pickup == 2) then
            OUT:addChild(TagByte.new("player"))
            OUT:addChild(TagByte.new("isCreative", true))
        end
    elseif(required) then OUT:addChild(TagByte.new("player")) end

    OUT.mobEffects = OUT:addChild(TagList.new("mobEffects"))
    if(IN:contains("Effects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Effects = IN.lastFound

        for i=0, IN.Effects.childCount-1 do
            local effect_in = IN.Effects:child(i)
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
            if(effect_in:contains("Duration", TYPE.INT)) then
                effect_out:addChild(TagInt.new("Duration", effect_in.lastFound.value))
                effect_out:addChild(TagInt.new("DurationEasy", effect_in.lastFound.value))
                effect_out:addChild(TagInt.new("DurationNormal", effect_in.lastFound.value))
                effect_out:addChild(TagInt.new("DurationHard", effect_in.lastFound.value))
            else
                effect_out:addChild(TagInt.new("Duration", 1))
                effect_out:addChild(TagInt.new("DurationEasy", 1))
                effect_out:addChild(TagInt.new("DurationNormal", 1))
                effect_out:addChild(TagInt.new("DurationHard", 1))
            end

            effect_out:addChild(TagByte.new("DisplayOnScreenTextureAnimation"))

            OUT.mobEffects:addChild(effect_out)

            ::effectContinue::
        end
    end

    if(IN:contains("Potion", TYPE.STRING)) then
        local potionName = IN.lastFound.value
        if(potionName:find("^minecraft:")) then potionName = potionName:sub(11) end

        if(Settings:dataTableContains("potions", potionName)) then
            local entry = Settings.lastFound
            local PotionId = tonumber(entry[1][1])
            local effectId = tonumber(entry[1][2])
            local effectDuration = tonumber(entry[1][3])
            local effectAmplifier = tonumber(entry[1][4])
            OUT.auxValue = OUT:addChild(TagByte.new("auxValue", PotionId))

            --make an exception for turtle master
            if(PotionId == 37 or PotionId == 38 or PotionId == 39) then

                local effect_out1 = TagCompound.new()

                local duration1 = 100
                local duration2 = 100
                local amp1 = 3
                local amp2 = 2

                if(PotionId == 38) then
                    duration1 = 200
                    duration2 = 200
                elseif(PotionId == 39) then
                    amp1 = 5
                    amp2 = 3
                end

                effect_out1:addChild(TagByte.new("Id", 2))
                effect_out1:addChild(TagByte.new("ShowParticles", true))
                effect_out1:addChild(TagByte.new("Ambient"))
                effect_out1:addChild(TagByte.new("DisplayOnScreenTextureAnimation"))
                effect_out1:addChild(TagByte.new("Amplifier", amp1))
                effect_out1:addChild(TagInt.new("Duration", duration1))
                effect_out1:addChild(TagInt.new("DurationEasy", duration1))
                effect_out1:addChild(TagInt.new("DurationNormal", duration1))
                effect_out1:addChild(TagInt.new("DurationHard", duration1))

                effect_out2:addChild(TagByte.new("Id", 11))
                effect_out2:addChild(TagByte.new("ShowParticles", true))
                effect_out2:addChild(TagByte.new("Ambient"))
                effect_out2:addChild(TagByte.new("DisplayOnScreenTextureAnimation"))
                effect_out2:addChild(TagByte.new("Amplifier", amp2))
                effect_out2:addChild(TagInt.new("Duration", duration2))
                effect_out2:addChild(TagInt.new("DurationEasy", duration2))
                effect_out2:addChild(TagInt.new("DurationNormal", duration2))
                effect_out2:addChild(TagInt.new("DurationHard", duration2))

                OUT.mobEffects:addChild(effect_out1)
                OUT.mobEffects:addChild(effect_out2)

            else
                if(effectId ~= 0) then
                    local effect_out = TagCompound.new()

                    effect_out:addChild(TagByte.new("Id", effectId))
                    effect_out:addChild(TagByte.new("ShowParticles", true))
                    effect_out:addChild(TagByte.new("Ambient"))
                    effect_out:addChild(TagByte.new("DisplayOnScreenTextureAnimation"))
                    effect_out:addChild(TagByte.new("Amplifier", effectAmplifier))
                    effect_out:addChild(TagInt.new("Duration", effectDuration))
                    effect_out:addChild(TagInt.new("DurationEasy", effectDuration))
                    effect_out:addChild(TagInt.new("DurationNormal", effectDuration))
                    effect_out:addChild(TagInt.new("DurationHard", effectDuration))

                    OUT.mobEffects:addChild(effect_out)
                end
            end
        end
    end

    if(OUT.auxValue == nil and required) then OUT:addChild(TagByte.new("auxValue")) end

    return OUT
end
--
function Entity:ConvertBat(IN, OUT, required)
    OUT.def_base = "bat"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 6, 6, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.6 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.1, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("BatFlags", TYPE.BYTE)) then OUT:addChild(TagByte.new("BatFlags", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("BatFlags")) end

    return OUT
end
--
function Entity:ConvertBlaze(IN, OUT, required)
    OUT.def_base = "blaze"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 6, 6, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 48, 48, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.13 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.1, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertBoat(IN, OUT, required)
    OUT.def_base = "boat"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))

    if(OUT:contains("Pos", TYPE.LIST, TYPE.FLOAT)) then
        OUT.Pos = OUT.lastFound
        if(OUT.Pos.childCount == 3) then
            OUT.Pos:child(1).value = OUT.Pos:child(1).value + 0.375
        end
    end

    if(IN:contains("Type", TYPE.BYTE)) then
        local Type = IN.lastFound.value
        if(Type >= 0 and Type <= 5) then OUT:addChild(TagInt.new("Variant", Type))
        else OUT:addChild(TagInt.new("Variant")) end
    elseif(required) then OUT:addChild(TagInt.new("Variant")) end

    if(OUT:contains("Rotation", TYPE.LIST, TYPE.FLOAT)) then
        if(OUT.lastFound.childCount == 2) then
            OUT.Rotation = OUT.lastFound

            local rot = OUT.Rotation:child(0).value
            rot = rot + 90
            if(rot > 180) then rot = rot - 360 end
            OUT.Rotation:child(0).value = rot
        end
    end

    return OUT
end
--
function Entity:ConvertBottleOEnchanting(IN, OUT, required)
    OUT.def_base = "xp_bottle"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagByte.new("IsGlobal", true)) end
    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    return OUT
end
--
function Entity:ConvertCaveSpider(IN, OUT, required)
    OUT.def_base = "cave_spider"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 2, 2, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 12, 12, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertChicken(IN, OUT, required)
    OUT.def_base = "chicken"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 4, 4, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("EggLayTime", TYPE.INT)) then 
        local entry = TagCompound.new()
        entry:addChild(TagInt.new("SpawnTimer", IN.lastFound.value))
        OUT.entries = OUT:addChild(TagList.new("entries"))
        OUT.entries:addChild(entry)
    end

    return OUT
end
--
function Entity:ConvertCod(IN, OUT, required)
    OUT.def_base = "cod"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 6, 6, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.6 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.1, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.1, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertCow(IN, OUT, required)
    OUT.def_base = "cow"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 10, 10, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.05 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertCreeper(IN, OUT, required)
    OUT.def_base = "creeper"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.05 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.2, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    local isCharged = false
    if(IN:contains("powered", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then
            isCharged = true
            OUT.definitions:addChild(TagString.new("", "+minecraft:charged_creeper"))
        end
    end

    if(IN:contains("Fuse", TYPE.SHORT)) then OUT:addChild(TagByte.new("Fuse", IN.lastFound.value)) end

    local isIgnited = false
    if(IN:contains("ignited", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("IsFuseLit", IN.lastFound.value ~= 0))

        if(IN.lastFound.value ~= 0) then
            isIgnited = true
            if(isCharged) then OUT.definitions:addChild(TagString.new("", "+minecraft:charged_exploding"))
            else OUT.definitions:addChild(TagString.new("", "+minecraft:exploding")) end
        end
    end

    if(isIgnited == false) then OUT.definitions:addChild(TagString.new("", "-minecraft:exploding")) end
    return OUT
end
--
function Entity:ConvertDolphin(IN, OUT, required)
    OUT.def_base = "dolphin"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 10, 10, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 48, 48, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed + 1.1 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.1, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.15, FLOAT_MAX)

    if(IN:contains("Moistness", TYPE.INT)) then
        local Moistness = IN.lastFound.value
        if(Moistness == 0) then 
            OUT.definitions:addChild(TagString.new("", "+minecraft:dolphin_dried"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:dolphin_on_land"))
            OUT.definitions:addChild(TagString.new("", "-minecraft:dolphin_swimming_navigation"))
        elseif(Moistness < 2400 ) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:dolphin_on_land"))
            OUT.definitions:addChild(TagString.new("", "-minecraft:dolphin_swimming_navigation"))

            --TODO identify 1.7.1 version of moistness time
            --OUT:addChild(TagLong.new("TimeStamp", Settings:getSettingLong("currentTick")+2400-Moistness))
        else
            OUT.definitions:addChild(TagString.new("", "-minecraft:dolphin_dried"))
            OUT.definitions:addChild(TagString.new("", "-minecraft:dolphin_on_land"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:dolphin_swimming_navigation"))
        end
    else
        OUT.definitions:addChild(TagString.new("", "-minecraft:dolphin_dried"))
        OUT.definitions:addChild(TagString.new("", "-minecraft:dolphin_on_land"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:dolphin_swimming_navigation"))
    end

    return OUT
end
--
function Entity:ConvertDonkey(IN, OUT, required)
    OUT.def_base = "donkey"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_wild"))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 19, 19, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.175, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)
    OUT = Entity:AddAttribute(OUT, "minecraft:horse.jump_strength", 0.5, FLOAT_MAX, IN.Attributes.horse_jumpStrength)

    return OUT
end
--
function Entity:ConvertDragonFireball(IN, OUT, required)
    OUT.def_base = "dragon_fireball"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("direction", TYPE.LIST, TYPE.DOUBLE)) then
        IN.direction = IN.lastFound
        if(IN.direction.childCount == 3) then
            OUT.direction = OUT:addChild(TagList.new("direction"))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(0).value))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(1).value))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(2).value))
        end
    end

    if(OUT.direction == nil and required) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagFloat.new(""))
        OUT.direction:addChild(TagFloat.new(""))
        OUT.direction:addChild(TagFloat.new(""))
    end

    if(IN:contains("power", TYPE.LIST, TYPE.DOUBLE)) then
        IN.power = IN.lastFound
        if(IN.power.childCount == 3) then
            OUT.power = OUT:addChild(TagList.new("power"))
            OUT.power:addChild(TagFloat.new("", IN.power:child(0).value))
            OUT.power:addChild(TagFloat.new("", IN.power:child(1).value))
            OUT.power:addChild(TagFloat.new("", IN.power:child(2).value))
        end
    end

    if(OUT.power == nil and required) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagFloat.new(""))
        OUT.power:addChild(TagFloat.new(""))
        OUT.power:addChild(TagFloat.new(""))
    end

    return OUT
end
--
function Entity:ConvertDrowned(IN, OUT, required)
    OUT.def_base = "drowned"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("IsBaby", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("IsBaby", IN.lastFound.value ~= 0))

        if(IN.lastFound.value ~= 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:baby_" .. OUT.def_base))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:adult_" .. OUT.def_base))
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby", false))
        OUT.definitions:addChild(TagString.new("", "+minecraft:adult_" .. OUT.def_base))
    end

    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.23, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.06, FLOAT_MAX)

    local holdingTrident = false
    if(OUT:contains("Mainhand", TYPE.LIST, TYPE.COMPOUND)) then
        OUT.Mainhand = OUT.lastFound
        if(OUT.Mainhand.childCount == 1) then
            local item = OUT.Mainhand:child(0)

            if(item:contains("Name", TYPE.STRING)) then
                local itemName = item.lastFound.value
                if(itemName:find("^minecraft:")) then itemName = itemName:sub(11) end

                if(itemName == "trident") then holdingTrident = true end
            end
        end
    end

    if(holdingTrident) then
        OUT.definitions:addChild(TagString.new("", "+minecraft:ranged_mode"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:mode_switcher"))
    else
        OUT.definitions:addChild(TagString.new("", "+minecraft:melee_mode"))
    end

    return OUT
end
--
function Entity:ConvertEgg(IN, OUT, required)
    OUT.def_base = "egg"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagByte.new("IsGlobal", true)) end
    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    return OUT
end
--
function Entity:ConvertElderGuardian(IN, OUT, required)
    OUT.def_base = "elder_guardian"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 5, 5, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 80, 80, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.3, FLOAT_MAX)
    
    return OUT
end
--
function Entity:ConvertEnderCrystal(IN, OUT, required)
    OUT.def_base = "ender_crystal"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))

    if(IN:contains("ShowBottom", TYPE.BYTE)) then OUT:addChild(TagByte.new("ShowBottom", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("ShowBottom", true)) end

    return OUT
end
--
function Entity:ConvertEnderPearl(IN, OUT, required)
    OUT.def_base = "ender_pearl"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:no_spawn"))

    if(required) then OUT:addChild(TagByte.new("IsGlobal", true)) end
    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end


    return OUT
end
--
function Entity:ConvertEnderman(IN, OUT, required)
    OUT.def_base = "enderman"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.definitions:addChild(TagString.new("", "+minecraft:enderman_calm"))
    
    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 7, 7, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 40, 40, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 32, 32, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed + 0.15 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.45, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("carried", TYPE.SHORT)) then IN.carried = IN.lastFound.value else IN.carried = 0 end
    if(IN:contains("carriedData", TYPE.SHORT)) then IN.carriedData = IN.lastFound.value else IN.carriedData = 0 end

    local ChunkVersion = Settings:getSettingInt("ChunkVersion")

    if(Settings:dataTableContains("blocks_ids", tostring(IN.carried)) and IN.carried ~= 0) then
        local entry = Settings.lastFound
        for index, _ in ipairs(entry) do
            local subEntry = entry[index]
            if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
            if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.carriedData) then goto entryContinue end end
            OUT.carriedBlock = OUT:addChild(TagCompound.new("carriedBlock"))
            OUT.carriedBlock:addChild(TagString.new("name", "minecraft:" .. subEntry[3]))
            if(subEntry[4]:len() > 0) then OUT.carriedBlock:addChild(TagShort.new("val", tonumber(subEntry[4]))) else OUT.carriedBlock:addChild(TagShort.new("val")) end
            break
            ::entryContinue::
        end
    end

    return OUT
end
--
function Entity:ConvertEndermite(IN, OUT, required)
    OUT.def_base = "endermite"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 2, 2, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 8, 8, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.23 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.02, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Lifetime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Lifetime")) end

    return OUT
end
--
function Entity:ConvertEvoker(IN, OUT, required)
    OUT.def_base = "evocation_illager"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 24, 24, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 64, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.5, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertEvokerFangs(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:containds("Warmup", TYPE.INT)) then OUT:addChild(TagInt.new("limitedLife", IN.lastFound.value + 20)) elseif(required) then OUT:addChild(TagInt.new("limitedLife", 20)) end

    return OUT
end
--
function Entity:ConvertExperienceOrb(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Value", TYPE.SHORT)) then
        OUT:addChild(TagInt.new("experience value", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagInt.new("experience value", 3))
    end

    if(IN:contains("Age", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Age")) end
    
    return OUT
end
--
function Entity:ConvertEyeOfEnder(IN, OUT, required)
    OUT.def_base = "eye_of_ender_signal"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))


    if(required) then OUT:addChild(TagByte.new("IsGlobal", true)) end

    return OUT
end
--
function Entity:ConvertFallingBlock(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Time", TYPE.INT)) then OUT:addChild(TagByte.new("Time", IN.lastFound.value)) elseif(required) then OUT:addChild(TagByte.new("Time")) end

    --TODO Variant

    if(IN:contains("Block", TYPE.STRING)) then
        IN.Block = IN.lastFound.value
        if(IN.Block:find("^minecraft:")) then IN.Block = IN.Block:sub(11) end
        if(IN:contains("Data", TYPE.BYTE)) then IN.Data = IN.lastFound.value else IN.Data = 0 end

        if(Settings:dataTableContains("blocks_names", IN.Block)) then
            local entry = Settings.lastFound
            local ChunkVersion = Settings:getSettingInt("ChunkVersion")
            
            for index, _ in ipairs(entry) do
                local subEntry = entry[index]
                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.Data) then goto entryContinue end end
                OUT.FallingBlock = OUT:addChild(TagCompound.new("FallingBlock"))
                OUT.FallingBlock:addChild(TagString.new("name", "minecraft:" .. subEntry[3]))
                if(subEntry[4]:len() > 0) then OUT.FallingBlock:addChild(TagShort.new("val", tonumber(subEntry[4]))) else OUT.FallingBlock:addChild(TagShort.new("val")) end
                break
                ::entryContinue::
            end
        end
    elseif(IN:contains("TileID", TYPE.INT)) then
        IN.TileID = IN.lastFound.value
        if(IN:contains("Data", TYPE.BYTE)) then IN.Data = IN.lastFound.value else IN.Data = 0 end

        local ChunkVersion = Settings:getSettingInt("ChunkVersion")

        if(Settings:dataTableContains("blocks_ids", tostring(IN.TileID)) and IN.TileID ~= 0) then
            local entry = Settings.lastFound
            
            for index, _ in ipairs(entry) do
                local subEntry = entry[index]
                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                if(subEntry[2]:len() ~= 0) then if(tonumber(subEntry[2]) ~= IN.Data) then goto entryContinue end end
                OUT.FallingBlock = OUT:addChild(TagCompound.new("FallingBlock"))
                OUT.FallingBlock:addChild(TagString.new("name", "minecraft:" .. subEntry[3]))
                if(subEntry[4]:len() > 0) then OUT.FallingBlock:addChild(TagShort.new("val", tonumber(subEntry[4]))) else OUT.FallingBlock:addChild(TagShort.new("val")) end
                break
                ::entryContinue::
            end
        end


    else return nil end

    return OUT
end
--
function Entity:ConvertFireball(IN, OUT, required)
    OUT.def_base = "fireball"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("direction", TYPE.LIST, TYPE.DOUBLE)) then
        IN.direction = IN.lastFound
        if(IN.direction.childCount == 3) then
            OUT.direction = OUT:addChild(TagList.new("direction"))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(0).value))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(1).value))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(2).value))
        end
    end

    if(OUT.direction == nil and required) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagFloat.new(""))
        OUT.direction:addChild(TagFloat.new(""))
        OUT.direction:addChild(TagFloat.new(""))
    end

    if(IN:contains("power", TYPE.LIST, TYPE.DOUBLE)) then
        IN.power = IN.lastFound
        if(IN.power.childCount == 3) then
            OUT.power = OUT:addChild(TagList.new("power"))
            OUT.power:addChild(TagFloat.new("", IN.power:child(0).value))
            OUT.power:addChild(TagFloat.new("", IN.power:child(1).value))
            OUT.power:addChild(TagFloat.new("", IN.power:child(2).value))
        end
    end

    if(OUT.power == nil and required) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagFloat.new(""))
        OUT.power:addChild(TagFloat.new(""))
        OUT.power:addChild(TagFloat.new(""))
    end

    return OUT
end
--
function Entity:ConvertFireworkRocket(IN, OUT, required)
    OUT.def_base = "fireworks_rocket"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))

    --JAVA
    --ShotAtAngle byte true or false
    --no use for conversion

    if(IN:contains("Life", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Life")) end
    if(IN:contains("LifeTime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("LifeTime", 20)) end

    --Bedrock doesnt save the firework data? wtf
    --[[
    if(IN:contains("FireworksItem", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "FireworksItem"
            OUT:addChild(item)
        end
    end--]]

    if(required) then OUT:addChild(TagByte.new("IsGlobal", true)) end
    return OUT
end
--
function Entity:ConvertGhast(IN, OUT, required)
    OUT.def_base = "ghast"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 10, 10, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 64, 64, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.67 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.03, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("ExplosionPower", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ExplosionPower", 1)) end

    return OUT
end
--
function Entity:ConvertGuardian(IN, OUT, required)
    OUT.def_base = "guardian"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 5, 5, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 30, 30, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 16, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.38 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.12, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.12, FLOAT_MAX)

    if(required) then OUT:addChild(TagByte.new("Elder")) end

    return OUT
end
--
function Entity:ConvertHorse(IN, OUT, required)
    OUT.def_base = "horse"

    --legacy horse type
    if(IN:contains("Type", TYPE.INT)) then
        if(IN.lastFound.value == 1) then
            OUT.def_base = "donkey"
            if(OUT:contains("identifier", TYPE.STRING)) then OUT.lastFound.value = "minecraft:donkey" end
        elseif(IN.lastFound.value == 2) then
            OUT.def_base = "mule"
            if(OUT:contains("identifier", TYPE.STRING)) then OUT.lastFound.value = "minecraft:mule" end
        elseif(IN.lastFound.value == 3) then
            OUT.def_base = "zombie_horse"
            if(OUT:contains("identifier", TYPE.STRING)) then OUT.lastFound.value = "minecraft:zombie_horse" end
        elseif(IN.lastFound.value == 4) then
            OUT.def_base = "skeleton_horse"
            if(OUT:contains("identifier", TYPE.STRING)) then OUT.lastFound.value = "minecraft:skeleton_horse" end
        end
    end

    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_wild"))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 30, 30, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.1, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)
    OUT = Entity:AddAttribute(OUT, "minecraft:horse.jump_strength", 0.5, FLOAT_MAX, IN.Attributes.horse_jumpStrength)

    --TODO variant
    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value

        local baseColor = Variant & 255
        local markings = (Variant >> 8) & 255
        if(baseColor > 6) then baseColor = 0 end 
        if(markings > 4) then markings = 0 end

        if(baseColor == 0) then OUT.definitions:addChild(TagString.new("", "+minecraft:base_white"))
        elseif(baseColor == 1) then OUT.definitions:addChild(TagString.new("", "+minecraft:base_creamy"))
        elseif(baseColor == 2) then OUT.definitions:addChild(TagString.new("", "+minecraft:base_chestnut"))
        elseif(baseColor == 3) then OUT.definitions:addChild(TagString.new("", "+minecraft:base_brown"))
        elseif(baseColor == 4) then OUT.definitions:addChild(TagString.new("", "+minecraft:base_black"))
        elseif(baseColor == 5) then OUT.definitions:addChild(TagString.new("", "+minecraft:base_gray"))
        elseif(baseColor == 6) then OUT.definitions:addChild(TagString.new("", "+minecraft:base_dark_brown"))
        end

        OUT:addChild(TagInt.new("Variant", baseColor))

        if(markings == 0) then OUT.definitions:addChild(TagString.new("", "+minecraft:markings_none"))
        elseif(markings == 1) then OUT.definitions:addChild(TagString.new("", "+minecraft:markings_white_details"))
        elseif(markings == 2) then OUT.definitions:addChild(TagString.new("", "+minecraft:markings_white_field"))
        elseif(markings == 3) then OUT.definitions:addChild(TagString.new("", "+minecraft:markings_white_dots"))
        elseif(markings == 4) then OUT.definitions:addChild(TagString.new("", "+minecraft:markings_black_dots"))
        end

        OUT:addChild(TagInt.new("MarkVariant", markings))
    end

    return OUT
end
--
function Entity:ConvertHusk(IN, OUT, required)
    OUT.def_base = "husk"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("IsBaby", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("IsBaby", IN.lastFound.value ~= 0))

        if(IN.lastFound.value ~= 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:zombie_" .. OUT.def_base .. "_baby"))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:zombie_" .. OUT.def_base .. "_adult"))
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby", false))
        OUT.definitions:addChild(TagString.new("", "+minecraft:zombie_" .. OUT.def_base .. "_adult"))
    end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.23, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.2, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertIronGolem(IN, OUT, required)
    OUT.def_base = "iron_golem"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 7, 7, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 100, 100, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 1, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("PlayerCreated", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then OUT.definitions:addChild(TagString.new("", "+minecraft:player_created")) end
    end

    return OUT
end
--
function Entity:ConvertItemDrop(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Age", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Age")) end
    if(IN:contains("Health", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Health", 5)) end

    if(IN:contains("Item", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "Item"
            OUT:addChild(item)
        else
            item = Item:BlankItem()
            item.name = "Item"
            OUT:addChild(item)
        end
    else
        item = Item:BlankItem()
        item.name = "Item"
        OUT:addChild(item)
    end

    return OUT
end
--
function Entity:ConvertItemFrame(IN, OUT, required)
    --convert to tile entity
    local TOUT = TagCompound.new()
    TOUT:addChild(TagString.new("id", "ItemFrame"))
    TOUT.x = TOUT:addChild(TagInt.new("x", math.floor(OUT.Pos:child(0).value)))
    TOUT.y = TOUT:addChild(TagInt.new("y", math.floor(OUT.Pos:child(1).value)))
    TOUT.z = TOUT:addChild(TagInt.new("z", math.floor(OUT.Pos:child(2).value)))
    TOUT:addChild(TagByte.new("IsMovable", true))

    local blockToSet = TagCompound.new()
    blockToSet:addChild(TagString.new("Name", "minecraft:frame"))
    --TODO set facing state based on input
    --states are 3_facing_direction and 1_item_frame_map_bit


    --if(val == 0 or val == 4) then facing = "east"
    --elseif(val == 1 or val == 5) then facing = "west"
    --elseif(val == 2 or val == 6) then facing = "south"
    --elseif(val == 3 or val == 7) then facing = "north"
    --end

    local facing_direction = 0
    if(IN:contains("Facing", TYPE.BYTE)) then
        local Facing = IN.lastFound.value

        if(Facing == 0) then facing_direction = 2
        elseif(Facing == 1) then facing_direction = 1
        elseif(Facing == 2) then facing_direction = 3
        elseif(Facing == 3) then facing_direction = 0
        else return nil end
    elseif(IN:contains("Direction", TYPE.BYTE)) then

        --0 north
        local Direction = IN.lastFound.value
        if(Direction == 0) then facing_direction = 2
        elseif(Direction == 1) then facing_direction = 1
        elseif(Direction == 2) then facing_direction = 3
        elseif(Direction == 3) then facing_direction = 0
        else return nil end
    else return nil end

    local isMap = 0
    if(IN:contains("Item", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "Item"
            if(item:contains("Name", TYPE.STRING)) then
                local itemName = item.lastFound.value
                if(itemName:find("^minecraft:")) then itemName = itemName:sub(11) end

                if(itemName == "map") then isMap = 1 end
            end
            TOUT:addChild(item)
        end
    end

    blockToSet:addChild(TagShort.new("val", facing_direction + (isMap*4)))

    Chunk:setBlock(TOUT.x.value, TOUT.y.value, TOUT.z.value, blockToSet)

    if(IN:contains("ItemRotation", TYPE.BYTE)) then
        TOUT:addChild(TagFloat.new("ItemRotation", IN.lastFound.value*45))
    elseif(required) then TOUT:addChild(TagFloat.new("ItemRotation")) end

    if(IN:contains("ItemDropChance", TYPE.FLOAT)) then TOUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("ItemDropChance", 1.0)) end

    if(IN.TileEntities_output_ref ~= nil) then IN.TileEntities_output_ref:addChild(TOUT) end

    return nil
end
--
function Entity:ConvertLlama(IN, OUT, required)
    OUT.def_base = "llama"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_wild"))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 28, 28, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 40, 40, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed + 0.075 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Strength", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Strength")) end
    if(required) then OUT:addChild(TagInt.new("StrengthMax", 5)) end

    if(IN:contains("DecorItem", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            --TODO put decorItem on items list
            --Find out how java does this
        end
    end

    if(IN:contains("Variant", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Variant")) end

    return OUT
end
--
function Entity:ConvertLlamaSpit(IN, OUT, required)
    OUT.def_base = "llama_spit"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertMagmaCube(IN, OUT, required)
    OUT.def_base = "magma_cube"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 4, 4, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed + 0.36 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.66, FLOAT_MAX, IN.Attributes.movementSpeed6)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Size", TYPE.INT)) then
        local Size = IN.lastFound.value
        if(Size > 1) then Size = 2 end
        if(Size < 0) then Size = 0 end

        OUT:addChild(TagByte.new("Size", Size + 1))
        OUT:addChild(TagInt.new("Variant", Size + 1))

        if(Size == 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:slime_small"))
            OUT = Entity:AddAttribute(OUT, "minecraft:health", 1, 1, IN.Health, IN.Attributes.maxHealth)
        elseif(Size == 1) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:slime_medium")) 
            OUT = Entity:AddAttribute(OUT, "minecraft:health", 4, 4, IN.Health, IN.Attributes.maxHealth)
        elseif(Size == 2) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:slime_large"))
            OUT = Entity:AddAttribute(OUT, "minecraft:health", 16, 16, IN.Health, IN.Attributes.maxHealth)
        end

    elseif(required) then 
        OUT:addChild(TagByte.new("Size", 2))
        OUT:addChild(TagInt.new("Variant", 2))
        OUT.definitions:addChild(TagString.new("", "+minecraft:slime_medium"))
        OUT = Entity:AddAttribute(OUT, "minecraft:health", 4, 4)
    end

    return OUT
end
--
function Entity:ConvertMinecart(IN, OUT, required)
    OUT.def_base = "minecart"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end
--
function Entity:ConvertMinecartChest(IN, OUT, required)
    OUT.def_base = "chest_minecart"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    Entity:ConvertItems(IN, OUT, required)

    if(OUT:contains("Items", TYPE.LIST, TYPE.COMPOUND)) then OUT.lastFound.name = "ChestItems" end

    --InventoryVersion required???

    return OUT
end
--
function Entity:ConvertMinecartHopper(IN, OUT, required)
    OUT.def_base = "hopper_minecart"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    Entity:ConvertItems(IN, OUT, required)

    if(OUT:contains("Items", TYPE.LIST, TYPE.COMPOUND)) then OUT.lastFound.name = "ChestItems" end

    if(IN:contains("Enabled", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:hopper_active"))
        else
            OUT.definitions:addChild(TagString.new("", "-minecraft:hopper_active"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:hopper_inactive"))
        end
    else
        OUT.definitions:addChild(TagString.new("", "+minecraft:hopper_active"))
    end

    return OUT
end
--
function Entity:ConvertMinecartTNT(IN, OUT, required)
    OUT.def_base = "tnt_minecart"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("TNTFuse", TYPE.INT)) then
        if(IN.lastFound.value ~= -1) then
            OUT:addChild(TagByte.new("IsFuseLit", true))
            OUT:addChild(TagByte.new("Fuse", IN.lastFound.value))
            OUT.definitions:addChild(TagString.new("", "-minecraft:inactive"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:primed_tnt"))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:inactive"))
            OUT:addChild(TagByte.new("IsFuseLit"))
        end
    else
        OUT.definitions:addChild(TagString.new("", "+minecraft:inactive"))
        OUT:addChild(TagByte.new("IsFuseLit"))
    end

    if(required) then OUT:addChild(TagByte.new("AllowUnderwater", true)) end

    return OUT
end
--
function Entity:ConvertMooshroom(IN, OUT, required)
    OUT.def_base = "cow"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:mooshroom"))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 10, 10, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.05 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("InLove", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("InLove")) end
    
    if(IN:contains("Age", TYPE.INT)) then
        local Age = IN.lastFound.value
        if(Age < 0) then
            OUT:addChild(TagInt.new("Age", Age))
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+minecraft:cow_baby"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:cow_adult"))
            if(Age < 0) then OUT:addChild(TagInt.new("BreedCooldown", Age)) end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:cow_adult"))
    end

    OUT.definitions:addChild(TagString.new("", "+minecraft:mooshroom_red")) 

    return OUT
end
--
function Entity:ConvertMule(IN, OUT, required)
    OUT.def_base = "mule"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_wild"))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 27, 27, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.175, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)
    OUT = Entity:AddAttribute(OUT, "minecraft:horse.jump_strength", 0.5, FLOAT_MAX, IN.Attributes.horse_jumpStrength)

    return OUT
end
--
function Entity:ConvertOcelot(IN, OUT, required)
    OUT.def_base = "ocelot"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_wild"))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 4, FLOAT_MAX, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 10, 10, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertParrot(IN, OUT, required)
    OUT.def_base = "parrot"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_wild"))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 6, 6, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.2 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.4, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value
        if(Variant < 0 or Variant > 4) then Variant = 0 end
        OUT:addChild(TagInt.new("Variant", Variant))

        if(Variant == 0) then OUT.definitions:addChild(TagString.new("", "+minecraft:parrot_red"))
        elseif(Variant == 1) then OUT.definitions:addChild(TagString.new("", "+minecraft:parrot_blue"))
        elseif(Variant == 2) then OUT.definitions:addChild(TagString.new("", "+minecraft:parrot_green"))
        elseif(Variant == 3) then OUT.definitions:addChild(TagString.new("", "+minecraft:parrot_cyan"))
        elseif(Variant == 4) then OUT.definitions:addChild(TagString.new("", "+minecraft:parrot_silver"))
        end

    elseif(required) then
        OUT:addChild(TagInt.new("Variant"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:parrot_red"))
    end

    return OUT
end 
--
function Entity:ConvertPainting(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    --verify these values
    --CONSOLE TU73
    --south 0
    --west 1
    --north 2
    --east 3

    --BEDROCK 1.14
    --south 0
    --west 1
    --north 2
    --east 3

    local facingUsed = false

    if(IN:contains("Facing", TYPE.BYTE)) then
        facingUsed = true
        local Facing = IN.lastFound.value
        if(Facing < 0 or Facing > 3) then return nil end 
        OUT.Direction = OUT:addChild(TagByte.new("Direction", Facing))
    elseif(IN:contains("Direction", TYPE.BYTE)) then
        local Direction = IN.lastFound.value
        if(Direction < 0 or Direction > 3) then return nil end 
        OUT.Direction = OUT:addChild(TagByte.new("Direction", Direction))
    elseif(required) then return nil end

    local width = 1
    local height = 1

    if(IN:contains("Motive", TYPE.STRING)) then
        local motive = IN.lastFound.value
        if(motive == "Kebab") then
            OUT:addChild(TagString.new("Motive", "Kebab"))
        elseif(motive == "Aztec") then
            OUT:addChild(TagString.new("Motive", "Aztec"))
        elseif(motive == "Alban") then
            OUT:addChild(TagString.new("Motive", "Alban"))
        elseif(motive == "Aztec2") then
            OUT:addChild(TagString.new("Motive", "Aztec2"))
        elseif(motive == "Bomb") then
            OUT:addChild(TagString.new("Motive", "Bomb"))
        elseif(motive == "Plant") then
            OUT:addChild(TagString.new("Motive", "Plant"))
        elseif(motive == "Wasteland") then
            OUT:addChild(TagString.new("Motive", "Wasteland"))
        elseif(motive == "Wanderer") then
            OUT:addChild(TagString.new("Motive", "Wanderer"))
            height = 2
        elseif(motive == "Graham") then
            OUT:addChild(TagString.new("Motive", "Graham"))
            height = 2
        elseif(motive == "Pool") then
            OUT:addChild(TagString.new("Motive", "Pool"))
            width = 2
        elseif(motive == "Courbet") then
            OUT:addChild(TagString.new("Motive", "Courbet"))
            width = 2
        elseif(motive == "Sunset") then
            OUT:addChild(TagString.new("Motive", "Sunset"))
            width = 2
        elseif(motive == "Sea") then
            OUT:addChild(TagString.new("Motive", "Sea"))
            width = 2
        elseif(motive == "Creebet") then
            OUT:addChild(TagString.new("Motive", "Creebet"))
            width = 2
        elseif(motive == "Match") then
            OUT:addChild(TagString.new("Motive", "Match"))
            width = 2
            height = 2
        elseif(motive == "Bust") then
            OUT:addChild(TagString.new("Motive", "Bust"))
            width = 2
            height = 2
        elseif(motive == "Stage") then
            OUT:addChild(TagString.new("Motive", "Stage"))
            width = 2
            height = 2
        elseif(motive == "Void") then
            OUT:addChild(TagString.new("Motive", "Void"))
            width = 2
            height = 2
        elseif(motive == "SkullAndRoses") then
            OUT:addChild(TagString.new("Motive", "SkullAndRoses"))
            width = 2
            height = 2
        elseif(motive == "Wither") then
            OUT:addChild(TagString.new("Motive", "Wither"))
            width = 2
            height = 2
        elseif(motive == "Fighters") then
            OUT:addChild(TagString.new("Motive", "Fighters"))
            width = 4
            height = 2
        elseif(motive == "Skeleton") then
            OUT:addChild(TagString.new("Motive", "Skeleton"))
            width = 4
            height = 3
        elseif(motive == "DonkeyKong") then
            OUT:addChild(TagString.new("Motive", "DonkeyKong"))
            width = 4
            height = 3
        elseif(motive == "Pointer") then
            OUT:addChild(TagString.new("Motive", "Pointer"))
            width = 4
            height = 4
        elseif(motive == "Pigscene") then
            OUT:addChild(TagString.new("Motive", "Pigscene"))
            width = 4
            height = 4
        elseif(motive == "BurningSkull") then
            OUT:addChild(TagString.new("Motive", "BurningSkull"))
            width = 4
            height = 4
        else return nil end
    else return nil end

    if(OUT:contains("Pos", TYPE.LIST, TYPE.FLOAT)) then
        OUT.Pos = OUT.lastFound

        local posX = math.floor(OUT.Pos:child(0).value)
        local posY = math.floor(OUT.Pos:child(1).value)
        local posZ = math.floor(OUT.Pos:child(2).value)

        posY = posY + ((height%2)/2)

        if(facingUsed) then
            if(OUT.Direction.value == 0) then --south
                posZ = posZ + 0.03125
                if(width%2~=0) then posX = posX + 0.5 end
            elseif(OUT.Direction.value == 1) then --west
                posX = posX + 0.96875
                if(width%2~=0) then posZ = posZ + 0.5 end
            elseif(OUT.Direction.value == 2) then --north
                posZ = posZ + 0.96875
                if(width%2~=0) then posX = posX + 0.5 end
            elseif(OUT.Direction.value == 3) then --east
                posX = posX + 0.03125
                if(width%2~=0) then posZ = posZ + 0.5 end
            end
        end

        OUT.Pos:child(0).value = posX
        OUT.Pos:child(1).value = posY
        OUT.Pos:child(2).value = posZ
    end

    return OUT
end
--
function Entity:ConvertPhantom(IN, OUT, required)
    OUT.def_base = "phantom"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 6, 6, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 64, 64, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed + 1.1 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 1.8, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertPig(IN, OUT, required)
    OUT.def_base = "pig"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 10, 10, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Saddle", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("Saddled", IN.lastFound.value ~= 0))
        if(IN.lastFound.value ~= 0) then
            OUT.definitions:addChild(TagString.new("", "-minecraft:" .. OUT.def_base .. "_unsaddled"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_saddled"))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_unsaddled"))
        end
    else
        OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_unsaddled"))
        if(required) then OUT:addChild(TagByte.new("Saddled")) end
    end

    return OUT
end
--
function Entity:ConvertPolarBear(IN, OUT, required)
    OUT.def_base = "polar_bear"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 6, 6, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 30, 30, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 48, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("InLove", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("InLove")) end
    
    if(IN:contains("Age", TYPE.INT)) then
        local Age = IN.lastFound.value
        if(Age < 0) then
            OUT:addChild(TagInt.new("Age", Age))
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+minecraft:baby"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:baby_wild"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:adult"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:adult_wild"))
            if(Age < 0) then OUT:addChild(TagInt.new("BreedCooldown", Age)) end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:adult"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:adult_wild"))
    end


    return OUT
end
--
function Entity:ConvertPotion(IN, OUT, required)
    OUT.def_base = "splash_potion"

    if(IN:contains("Potion", TYPE.COMPOUND)) then
        IN.Potion = IN.lastFound
        local potionItem = Item:ConvertItem(IN.Potion, false)
        if(potionItem == nil) then return nil end

        if(potionItem:contains("Name", TYPE.STRING)) then
            potionItem.Name = potionItem.lastFound.value

            if(potionItem.Name:find("^minecraft:")) then potionItem.Name = potionItem.Name:sub(11) end

            if(potionItem.Name == "lingering_potion") then
                OUT.def_base = "lingering_potion"
                if(OUT:contains("identifier", TYPE.STRING)) then OUT.lastFound.value = "minecraft:lingering_potion" end
            elseif(potionItem.Name ~= "splash_potion") then return nil end
        end

        if(potionItem:contains("Damage", TYPE.SHORT)) then
            potionItem.Damage = potionItem.lastFound
            OUT.PotionId = OUT:addChild(TagShort.new("PotionId", potionItem.lastFound.value))
        end
    else return nil end

    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagByte.new("IsGlobal", true)) end
    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    return OUT
end
--
function Entity:ConvertPufferfish(IN, OUT, required)
    OUT.def_base = "pufferfish"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 6, 6, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.57 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.13, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.13, FLOAT_MAX)

    if(IN:contains("PuffState", TYPE.INT)) then
        if(IN.lastFound.value == 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:normal_puff"))
        elseif(IN.lastFound.value == 1) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:half_puff_inflate"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:full_puff"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:deflate_sensor"))

            OUT:addChild(TagInt.new("Variant", 2))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:normal_puff"))
        end
    elseif(required) then 
        OUT.definitions:addChild(TagString.new("", "+minecraft:normal_puff"))
    end

    return OUT
end
--
function Entity:ConvertRabbit(IN, OUT, required)
    OUT.def_base = "rabbit"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 3, 3, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("InLove", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("InLove")) end
    
    if(IN:contains("Age", TYPE.INT)) then
        local Age = IN.lastFound.value
        if(Age < 0) then
            OUT:addChild(TagInt.new("Age", Age))
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+baby"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+adult"))
            if(Age < 0) then OUT:addChild(TagInt.new("BreedCooldown", Age)) end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+adult"))
    end

    if(IN:contains("RabbitType", TYPE.INT)) then
        local RabbitType = IN.lastFound.value
        if(RabbitType < 0 or RabbitType > 5) then RabbitType = 0 end
        OUT:addChild(TagInt.new("Variant", RabbitType))

        if(RabbitType == 0) then OUT.definitions:addChild(TagString.new("", "+coat_brown"))
        elseif(RabbitType == 1) then OUT.definitions:addChild(TagString.new("", "+coat_white"))
        elseif(RabbitType == 2) then OUT.definitions:addChild(TagString.new("", "+coat_black"))
        elseif(RabbitType == 3) then OUT.definitions:addChild(TagString.new("", "+coat_black_and_white"))--might be wrong
        elseif(RabbitType == 4) then OUT.definitions:addChild(TagString.new("", "+coat_gold"))--might be wrong
        elseif(RabbitType == 5) then OUT.definitions:addChild(TagString.new("", "+coat_salt"))
        end
    else
        OUT.definitions:addChild(TagString.new("", "+coat_brown"))
        if(required) then OUT:addChild(TagInt.new("Variant")) end
    end

    if(required) then OUT:addChild(TagInt.new("CarrotsEaten")) end

    if(IN:contains("MoreCarrotTicks", TYPE.INT)) then
        OUT:addChild(IN.lastFound:clone())
    elseif(required) then
        OUT:addChild(TagInt.new("MoreCarrotTicks"))
    end

    return OUT
end
--
function Entity:ConvertSalmon(IN, OUT, required)
    OUT.def_base = "salmon"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 6, 6, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.58 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.12, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.12, FLOAT_MAX)

    OUT.definitions:addChild(TagString.new("", "+scale_normal"))
    --sometimes is scale_large?

    return OUT
end
--
function Entity:ConvertSheep(IN, OUT, required)
    OUT.def_base = "sheep"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 8, 8, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed +0.02 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    OUT.definitions:addChild(TagString.new("", "+minecraft:sheep_white"))

    local isBaby = false
    if(OUT:contains("IsBaby", TYPE.BYTE)) then if(OUT.lastFound.value ~= 0) then isBaby = true end end

    if(IN:contains("Sheared", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then
            OUT.definitions:addChild(TagString.new("", "-minecraft:sheep_dyeable"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:sheep_sheared"))
            OUT:addChild(TagByte.new("Sheared", true))

            OUT.definitions:addChild(TagString.new("", "+minecraft:rideable_sheared"))
            if(isBaby == false) then 
                OUT.definitions:addChild(TagString.new("", "+minecraft:loot_sheared"))
            end
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:sheep_dyeable"))
            OUT.definitions:addChild(TagString.new("", "-minecraft:sheep_sheared"))
            OUT:addChild(TagByte.new("Sheared"))

            if(isBaby) then
                OUT.definitions:addChild(TagString.new("", "+minecraft:rideable_sheared"))
            else
                OUT.definitions:addChild(TagString.new("", "+minecraft:rideable_wooly"))
                OUT.definitions:addChild(TagString.new("", "+minecraft:loot_wooly"))
            end
        end
    elseif(required) then
        OUT.definitions:addChild(TagString.new("", "+minecraft:sheep_dyeable"))
        OUT.definitions:addChild(TagString.new("", "-minecraft:sheep_sheared"))
        OUT:addChild(TagByte.new("Sheared"))

        if(isBaby) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:rideable_sheared"))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:rideable_wooly"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:loot_wooly"))
        end
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
    OUT.def_base = "shulker"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 30, 30, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.7 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Color", TYPE.BYTE)) then
        local Color = IN.lastFound.value
        if(Color < 0 or Color > 16) then Color = 16 end
        OUT:addChild(TagInt.new("Variant", Color))

        if(Color == 16) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_undyed")) end
    elseif(required) then
        OUT:addChild(TagInt.new("Variant", 16))
        OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_undyed"))
    end

    return OUT
end
--
function Entity:ConvertShulkerBullet(IN, OUT, required)
    OUT.def_base = "shulker_bullet"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))

    --TODO projectile coords

    return OUT
end
--
function Entity:ConvertSilverfish(IN, OUT, required)
    OUT.def_base = "silverfish"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 1, 1, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 8, 8, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertSkeleton(IN, OUT, required)
    OUT.def_base = "skeleton"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.definitions:addChild(TagString.new("", "+minecraft:ranged_attack"))

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertSkeletonHorse(IN, OUT, required)
    OUT.def_base = "skeleton_horse"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 2, 2, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 15, 15, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.2, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.08, FLOAT_MAX)
    OUT = Entity:AddAttribute(OUT, "minecraft:horse.jump_strength", 0.5, FLOAT_MAX, IN.Attributes.horse_jumpStrength)

    --every skeleton horse is tamed?
    if(required) then OUT:addChild(TagByte.new("IsTamed", true)) end
    --convert tamed info if needed

    --TODO skeleton horse trap
    if(IN:contains("SkeletonTrap", TYPE.BYTE)) then
    end

    return OUT
end
--
function Entity:ConvertSlime(IN, OUT, required)
    OUT.def_base = "slime"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 0, 0, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Size", TYPE.INT)) then
        local Size = IN.lastFound.value
        if(Size > 1) then Size = 2 end
        if(Size < 0) then Size = 0 end

        OUT:addChild(TagByte.new("Size", Size + 1))
        OUT:addChild(TagInt.new("Variant", Size + 1))

        if(Size == 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:slime_small"))
            OUT = Entity:AddAttribute(OUT, "minecraft:health", 1, 1, IN.Health, IN.Attributes.maxHealth)
        elseif(Size == 1) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:slime_medium")) 
            OUT = Entity:AddAttribute(OUT, "minecraft:health", 4, 4, IN.Health, IN.Attributes.maxHealth)
        elseif(Size == 2) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:slime_large"))
            OUT = Entity:AddAttribute(OUT, "minecraft:health", 16, 16, IN.Health, IN.Attributes.maxHealth)
        end

    elseif(required) then 
        OUT:addChild(TagByte.new("Size", 2))
        OUT:addChild(TagInt.new("Variant", 2))
        OUT.definitions:addChild(TagString.new("", "+minecraft:slime_medium"))
        OUT = Entity:AddAttribute(OUT, "minecraft:health", 4, 4)
    end

    return OUT
end
--
function Entity:ConvertSnowball(IN, OUT, required)
    OUT.def_base = "snowball"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagByte.new("IsGlobal", true)) end
    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    return OUT
end
--
function Entity:ConvertSnowman(IN, OUT, required)
    OUT.def_base = "snow_golem"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 2, 2, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 4, 4, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.2, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Pumpkin", TYPE.BYTE)) then
        if(IN.lastFound.value == 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:snowman_sheared"))
            OUT.Sheared = OUT:addChild(TagByte.new("Sheared", true))
        end
    end

    if(OUT.Sheared == nil and required) then
        OUT:addChild(TagByte.new("Sheared", false))
    end
    return OUT
end
--
function Entity:ConvertSmallFireball(IN, OUT, required)
    OUT.def_base = "small_fireball"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end


    if(IN:contains("direction", TYPE.LIST, TYPE.DOUBLE)) then
        IN.direction = IN.lastFound
        if(IN.direction.childCount == 3) then
            OUT.direction = OUT:addChild(TagList.new("direction"))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(0).value))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(1).value))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(2).value))
        end
    end

    if(OUT.direction == nil and required) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagFloat.new(""))
        OUT.direction:addChild(TagFloat.new(""))
        OUT.direction:addChild(TagFloat.new(""))
    end

    if(IN:contains("power", TYPE.LIST, TYPE.DOUBLE)) then
        IN.power = IN.lastFound
        if(IN.power.childCount == 3) then
            OUT.power = OUT:addChild(TagList.new("power"))
            OUT.power:addChild(TagFloat.new("", IN.power:child(0).value))
            OUT.power:addChild(TagFloat.new("", IN.power:child(1).value))
            OUT.power:addChild(TagFloat.new("", IN.power:child(2).value))
        end
    end

    if(OUT.power == nil and required) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagFloat.new(""))
        OUT.power:addChild(TagFloat.new(""))
        OUT.power:addChild(TagFloat.new(""))
    end

    return OUT
end
--
function Entity:ConvertSpider(IN, OUT, required)
    OUT.def_base = "spider"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 16, 16, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertStray(IN, OUT, required)
    OUT.def_base = "stray"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.definitions:addChild(TagString.new("", "+minecraft:ranged_attack"))

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertSquid(IN, OUT, required)
    OUT.def_base = "squid"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 10, 10, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.5 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.2, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertTNT(IN, OUT, required)
    OUT.def_base = "tnt"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))

    if(IN:contains("Fuse", TYPE.SHORT)) then
        if(IN.lastFound.value ~= -1) then
            OUT.IsFuseList = OUT:addChild(TagByte.new("IsFuseLit", true))
            OUT:addChild(TagByte.new("Fuse", IN.lastFound.value))
        end
    end

    if(OUT.IsFuseList == nil and required) then OUT:addChild(TagByte.new("IsFuseLit")) end

    return OUT
end
--
function Entity:ConvertTrident(IN, OUT, required)
    OUT.def_base = "thrown_trident"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))

    if(IN:contains("pickup", TYPE.BYTE)) then
        local pickup = IN.lastFound.value
        if(pickup < 0 or pickup > 2) then pickup = 1 end

        if(pickup == 0) then
            OUT:addChild(TagByte.new("player"))
        elseif(pickup == 1) then
            OUT:addChild(TagByte.new("player", true))
            OUT:addChild(TagByte.new("isCreative", true))
        elseif(pickup == 2) then
            OUT:addChild(TagByte.new("player"))
            OUT:addChild(TagByte.new("isCreative", true))
        end
    elseif(required) then OUT:addChild(TagByte.new("player")) end

    if(IN:contains("Trident", TYPE.COMPOUND)) then
        local tridentItem = Item:ConvertItem(IN.lastFound, false)

        if(tridentItem ~= nil) then
            tridentItem.name = "Trident"
            OUT.Trident = OUT:addChild(tridentItem)
        end
    end

    if(OUT.Trident == nil and required) then
        OUT.Trident = OUT:addChild(TagCompound.new("Trident"))
        OUT.Trident:addChild(TagString.new("Name", "minecraft:trident"))
        OUT.Trident:addChild(TagByte.new("Count", 1))
        OUT.Trident:addChild(TagShort.new("Damage", 0))
    end

    return OUT
end
--
function Entity:ConvertTropicalFish(IN, OUT, required)
    OUT.def_base = "tropicalfish"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 6, 6, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.58 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.12, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.12, FLOAT_MAX)

    --TODO Parse Variant bitflags

    return OUT
end
--
function Entity:ConvertTurtle(IN, OUT, required)
    OUT.def_base = "turtle"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 30, 30, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.15 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.1, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.12, FLOAT_MAX)

    if(IN:contains("InLove", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("InLove")) end
    
    if(IN:contains("Age", TYPE.INT)) then
        local Age = IN.lastFound.value
        if(Age < 0) then
            OUT:addChild(TagInt.new("Age", Age))
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+minecraft:baby"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:adult"))
            if(Age < 0) then OUT:addChild(TagInt.new("BreedCooldown", Age)) end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:adult"))
    end

    OUT.HomePos = OUT:addChild(TagList.new("HomePos"))

    if(IN:contains("HomePosX", TYPE.INT)) then OUT.HomePos:addChild(TagFloat.new("", IN.lastFound.value))
    elseif(required) then OUT.HomePos:addChild(TagFloat.new("")) end

    if(IN:contains("HomePosY", TYPE.INT)) then OUT.HomePos:addChild(TagFloat.new("", IN.lastFound.value))
    elseif(required) then OUT.HomePos:addChild(TagFloat.new("")) end

    if(IN:contains("HomePosZ", TYPE.INT)) then OUT.HomePos:addChild(TagFloat.new("", IN.lastFound.value))
    elseif(required) then OUT.HomePos:addChild(TagFloat.new("")) end

    if(OUT.HomePos.childCount == 0) then 
        OUT:removeChild(OUT.HomePos:getRow())
        OUT.HomePos = nil
    end

    if(IN:contains("HasEgg", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("IsPregnant", IN.lastFound.value ~= 0))
        if(IN.lastFound.value ~= 0) then OUT.definitions:addChild(TagString.new("", "+minecraft:pregnant")) end
    elseif(required) then 
        OUT:addChild(TagByte.new("IsPregnant"))
    end

    return OUT
end
--
function Entity:ConvertVex(IN, OUT, required)
    OUT.def_base = "vex"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 14, 14, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 1, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    --bound coords arent used on bedrock. wtf?
    --timers isnt used either

    return OUT
end
--
function Entity:ConvertVillager(IN, OUT, required)
    OUT.def_base = "villager"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 128, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.5, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("InLove", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("InLove")) end
    
    if(IN:contains("Age", TYPE.INT)) then
        local Age = IN.lastFound.value
        if(Age < 0) then
            OUT:addChild(TagInt.new("Age", Age))
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+baby"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+adult"))
            if(Age < 0) then OUT:addChild(TagInt.new("BreedCooldown", Age)) end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+adult"))
    end

    if(IN:contains("Inventory", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Inventory = IN.lastFound
        OUT.ChestItems = OUT:addChild(TagList.new("ChestItems"))
        for i=0, IN.Inventory.childCount-1 do
            local item = Item:ConvertItem(IN.Inventory:child(i), true)
            if(item ~= nil) then
                OUT.ChestItems:addChild(item)
            end
        end
    elseif(required) then
        OUT:addChild(TagList.new("ChestItems"))
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

                if(trade_in:contains("buy", TYPE.COMPOUND)) then
                    local buy = Item:ConvertItem(trade_in.lastFound, false)
                    if(buy == nil) then goto tradeContinue end
                    buy.name = "buyA"
                    trade_out:addChild(buy)
                else goto tradeContinue end

                if(trade_in:contains("buyB", TYPE.COMPOUND)) then
                    local buyB = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyB ~= nil) then
                        buyB.name = "buyB"
                        trade_out:addChild(buyB)
                        if(buyB:contains("Count", TYPE.BYTE)) then
                            trade_out.buyCountB = trade_out:addChild(TagInt.new("buyCountB", buyB.lastFound.value)) 
                        end
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

    if(IN:contains("Riches", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Riches")) end
        
    local Profession = 0
    if(IN:contains("Profession", TYPE.INT)) then
        Profession = IN.lastFound.value
        if(Profession < 0 or Profession > 5) then Profession = 0 end
    end

    local Career = 1
    if(IN:contains("Career", TYPE.INT)) then
        Career = IN.lastFound.value
    end

    if(Profession == 0) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+farmer"))
            OUT:addChild(TagInt.new("Variant", 1))
        elseif(Career == 2) then
            OUT.definitions:addChild(TagString.new("", "+fisherman"))
            OUT:addChild(TagInt.new("Variant", 2))
        elseif(Career == 3) then
            OUT.definitions:addChild(TagString.new("", "+shepherd"))
            OUT:addChild(TagInt.new("Variant", 2))
        elseif(Career == 4) then
            OUT.definitions:addChild(TagString.new("", "+fletcher"))
            OUT:addChild(TagInt.new("Variant", 3))
        end
    elseif(Profession == 1) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+librarian"))
            OUT:addChild(TagInt.new("Variant", 5))
        elseif(Career == 2) then
            OUT.definitions:addChild(TagString.new("", "+cartographer"))
            OUT:addChild(TagInt.new("Variant", 6))
        end
    elseif(Profession == 2) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+cleric"))
            OUT:addChild(TagInt.new("Variant", 7))
        end
    elseif(Profession == 3) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+armorer"))
            OUT:addChild(TagInt.new("Variant", 8))
        elseif(Career == 2) then
            OUT.definitions:addChild(TagString.new("", "+weaponsmith"))
            OUT:addChild(TagInt.new("Variant", 9))
        elseif(Career == 3) then
            OUT.definitions:addChild(TagString.new("", "+toolsmith"))
            OUT:addChild(TagInt.new("Variant", 10))
        end
    elseif(Profession == 4) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+butcher"))
            OUT:addChild(TagInt.new("Variant", 11))
        elseif(Career == 2) then
            OUT.definitions:addChild(TagString.new("", "+leatherworker"))
            OUT:addChild(TagInt.new("Variant", 12))
        end
    elseif(Profession == 5) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+nitwit"))
            OUT:addChild(TagInt.new("Variant", 14))
        end
    end
    
    if(required) then
        OUT:addChild(TagInt.new("MarkVariant")) 
    end

    return OUT
end
--
function Entity:ConvertVindicator(IN, OUT, required)
    OUT.def_base = "vindicator"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.definitions:addChild(TagString.new("", "+minecraft:default_targeting"))

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 8, 8, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 24, 24, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.35, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertWitch(IN, OUT, required)
    OUT.def_base = "witch"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 26, 26, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 64, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertWither(IN, OUT, required)
    OUT.def_base = "wither"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    local Difficulty = Settings:getSettingLong("Difficulty")
    local baseHealth = 300
    if(Difficulty == 2) then
        baseHealth = 450
        if(IN.Health ~= nil) then IN.Health = IN.Health * 1.5 end
        if(IN.Attributes.maxHealth ~= nil) then IN.Attributes.maxHealth = IN.Attributes.maxHealth * 1.5 end
    elseif(Difficulty == 3) then
        baseHealth = 600
        if(IN.Health ~= nil) then IN.Health = IN.Health * 2 end
        if(IN.Attributes.maxHealth ~= nil) then IN.Attributes.maxHealth = IN.Attributes.maxHealth * 2 end
    end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", baseHealth, baseHealth, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 70, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.6, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)




    local beingCreated = false
    if(IN:contains("Invul", TYPE.INT)) then
        OUT:addChild(IN.lastFound:clone())
        OUT:addChild(TagInt.new("SpawningFrames", IN.lastFound.value))

        if(IN.lastFound.value > 0) then beingCreated = true end
    elseif(required) then
        OUT:addChild(TagInt.new("Invul"))
        OUT:addChild(TagInt.new("SpawningFrames"))
    end

    if(required) then
        if(beingCreated) then
            OUT:addChild(TagInt.new("ShieldHealth"))
        else
            OUT:addChild(TagInt.new("ShieldHealth", 40))

            OUT.Phase = OUT:addChild(TagInt.new("Phase", 1))
            OUT.AirAttack = OUT:addChild(TagByte.new("AirAttack", true))

            if(IN.Health ~= nil) then
                if(IN.Health < baseHealth/2) then
                    OUT.Phase.value = 0
                    OUT.AirAttack.value = false
                end
            end
        end

        OUT:addChild(TagInt.new("firerate", 20))
        OUT:addChild(TagInt.new("dyingFrames"))
        OUT:addChild(TagInt.new("maxHealth", baseHealth))
    end

    return OUT
end
--
function Entity:ConvertWitherSkeleton(IN, OUT, required)
    OUT.def_base = "wither_skeleton"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 4, 4, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertWitherSkull(IN, OUT, required)
    OUT.def_base = "wither_skull"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end


    if(IN:contains("direction", TYPE.LIST, TYPE.DOUBLE)) then
        IN.direction = IN.lastFound
        if(IN.direction.childCount == 3) then
            OUT.direction = OUT:addChild(TagList.new("direction"))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(0).value))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(1).value))
            OUT.direction:addChild(TagFloat.new("", IN.direction:child(2).value))
        end
    end

    if(OUT.direction == nil and required) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagFloat.new(""))
        OUT.direction:addChild(TagFloat.new(""))
        OUT.direction:addChild(TagFloat.new(""))
    end

    if(IN:contains("power", TYPE.LIST, TYPE.DOUBLE)) then
        IN.power = IN.lastFound
        if(IN.power.childCount == 3) then
            OUT.power = OUT:addChild(TagList.new("power"))
            OUT.power:addChild(TagFloat.new("", IN.power:child(0).value))
            OUT.power:addChild(TagFloat.new("", IN.power:child(1).value))
            OUT.power:addChild(TagFloat.new("", IN.power:child(2).value))
        end
    end

    if(OUT.power == nil and required) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagFloat.new(""))
        OUT.power:addChild(TagFloat.new(""))
        OUT.power:addChild(TagFloat.new(""))
    end

    return OUT
end
--
function Entity:ConvertWolf(IN, OUT, required)
    OUT.def_base = "wolf"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_wild"))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 8, 8, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    return OUT
end
--
function Entity:ConvertZombie(IN, OUT, required)
    OUT.def_base = "zombie"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.definitions:addChild(TagString.new("", "+minecraft:can_have_equipment"))

    if(IN:contains("IsBaby", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("IsBaby", IN.lastFound.value ~= 0))

        if(IN.lastFound.value ~= 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_baby"))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_adult"))
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby", false))
        OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_adult"))
    end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.23, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)
    
    --TODO Legacy zombie villager

    return OUT
end
--
function Entity:ConvertZombieHorse(IN, OUT, required)
    OUT.def_base = "zombie_horse"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 2, 2, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 15, 15, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.2, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)
    OUT = Entity:AddAttribute(OUT, "minecraft:horse.jump_strength", 0.5, FLOAT_MAX, IN.Attributes.horse_jumpStrength)

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

    OUT.def_base = "zombie_pigman"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 5, 5, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.23, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Age", TYPE.INT)) then
        local Age = IN.lastFound.value
        if(Age < 0) then
            OUT:addChild(TagInt.new("Age", Age))
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+minecraft:pig_zombie_baby"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:pig_zombie_adult"))
            if(Age < 0) then OUT:addChild(TagInt.new("BreedCooldown", Age)) end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:pig_zombie_adult"))
    end

    if(IN:contains("Anger", TYPE.SHORT)) then
        OUT:addChild(TagByte.new("IsAngry", IN.lastFound.value > 0))

        if(IN.lastFound.value > 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:pig_zombie_angry"))
            OUT.definitions:addChild(TagString.new("", "-minecraft:pig_zombie_calm"))
        else
            OUT.definitions:addChild(TagString.new("", "-minecraft:pig_zombie_angry"))
        end

    else 
        OUT.definitions:addChild(TagString.new("", "-minecraft:pig_zombie_angry"))
        if(required) then OUT:addChild(TagByte.new("IsAngry")) end
    end

    return OUT
end
--
function Entity:ConvertZombieVillager(IN, OUT, required)
    OUT.def_base = "zombie_villager_v2"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.23, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("IsBaby", TYPE.BYTE)) then OUT:addChild(TagByte.new("IsBaby", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("IsBaby")) end

    local Profession = 0
    if(IN:contains("Profession", TYPE.INT)) then
        Profession = IN.lastFound.value
        if(Profession < 0 or Profession > 5) then Profession = 0 end
    end

    local Career = 1
    if(IN:contains("Career", TYPE.INT)) then
        Career = IN.lastFound.value
    end

    if(Profession == 0) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+farmer"))
        elseif(Career == 2) then
            OUT.definitions:addChild(TagString.new("", "+fisherman"))
        elseif(Career == 3) then
            OUT.definitions:addChild(TagString.new("", "+shepherd"))
        elseif(Career == 4) then
            OUT.definitions:addChild(TagString.new("", "+fletcher"))
        end
    elseif(Profession == 1) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+librarian"))
        elseif(Career == 2) then
            OUT.definitions:addChild(TagString.new("", "+cartographer"))
        end
    elseif(Profession == 2) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+cleric"))
        end
    elseif(Profession == 3) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+armorer"))
        elseif(Career == 2) then
            OUT.definitions:addChild(TagString.new("", "+weaponsmith"))
        elseif(Career == 3) then
            OUT.definitions:addChild(TagString.new("", "+toolsmith"))
        end
    elseif(Profession == 4) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+butcher"))
        elseif(Career == 2) then
            OUT.definitions:addChild(TagString.new("", "+leatherworker"))
        end
    elseif(Profession == 5) then
        if(Career == 1) then
            OUT.definitions:addChild(TagString.new("", "+nitwit"))
        end
    end
    
    if(required) then
        OUT:addChild(TagInt.new("MarkVariant"))
    end

    if(IN:contains("ConversionTime", TYPE.INT)) then
        if(IN.lastFound.value > -1) then
            OUT.definitions:addChild(TagString.new("", "+to_villager"))
        end
    end

    return OUT
end

-----------------------Base functions

function Entity:ConvertUUID(IN, OUT, required)
    if(IN:contains("UUID", TYPE.STRING)) then
        local UUID = IN.lastFound.value
        if(UUID:find("^ent") and UUID:len() == 35) then
            local uuidNum =  tonumber("0x" .. UUID:sub(4, 19))
            if(uuidNum == nil) then uuidNum =  math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295) end
            OUT.UniqueID = OUT:addChild(TagLong.new("UniqueID", uuidNum))
        end
    end

    if(OUT.UniqueID == nil and required) then
        OUT.UniqueID = OUT:addChild(TagLong.new("UniqueID", math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295)))
    end
end

function Entity:ConvertBase(IN, OUT, required)
    OUT.definitions = OUT:addChild(TagList.new("definitions"))

    if(IN:contains("OnGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("OnGround", IN.lastFound.value ~= 0)) end
    if(IN:contains("Invulnerable", TYPE.BYTE)) then OUT:addChild(TagByte.new("Invulnerable", IN.lastFound.value ~= 0)) end
    if(IN:contains("Air", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("Fire", TYPE.SHORT)) then
        local Fire = IN.lastFound.value
        if(Fire == -1) then Fire = 0 end
        OUT:addChild(TagShort.new("Fire", Fire))
    end
    if(IN:contains("Dimension", TYPE.INT)) then OUT:addChild(TagInt.new("LastDimensionId", IN.lastFound.value)) elseif(required) then
        local dim = Settings:getSettingInt("Dimension")
        if(dim == 1) then dim = -1 elseif(dim == 2) then dim = 1 end
        OUT:addChild(TagInt.new("LastDimensionId", dim))
    end
    if(IN:contains("PortalCooldown", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("FallDistance", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("CustomName", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("CustomNameVisible", TYPE.BYTE)) then OUT:addChild(TagByte.new("CustomNameVisible", IN.lastFound.value ~= 0)) end

    Entity:ConvertUUID(IN, OUT, required)

    return OUT
end

function Entity:ConvertBaseLiving(IN, OUT)
    --if(IN:contains("CanPickUpLoot", TYPE.BYTE)) then OUT:addChild(TagByte.new("CanPickUpLoot", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("CanPickUpLoot")) end
    --if(IN:contains("FallFlying", TYPE.BYTE)) then OUT:addChild(TagByte.new("FallFlying", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("FallFlying")) end
    --if(IN:contains("Leashed", TYPE.BYTE)) then OUT:addChild(TagByte.new("Leashed", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Leashed")) end
    --if(IN:contains("LeftHanded", TYPE.BYTE)) then OUT:addChild(TagByte.new("LeftHanded", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("LeftHanded")) end
    if(IN:contains("PersistenceRequired", TYPE.BYTE)) then OUT:addChild(TagByte.new("Persistent", IN.lastFound.value ~= 0)) end
    --if(IN:contains("NoAI", TYPE.BYTE)) then OUT:addChild(TagByte.new("NoAI", IN.lastFound.value ~= 0)) end
    if(IN:contains("DeathTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("DeathTime")) end
    if(IN:contains("HurtTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("HurtTime")) end
    --if(IN:contains("HurtByTimestamp", TYPE.SHORT)) then OUT:addChild(TagInt.new("HurtByTimestamp", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("HurtByTimestamp")) end
    if(IN:contains("Health", TYPE.FLOAT)) then IN.Health = IN.lastFound.value end
    if(IN:contains("AbsorptionAmount", TYPE.FLOAT)) then IN.AbsorptionAmount = IN.lastFound.value end

    --Leashed

    --legacy
    if(IN:contains("Equipment", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Equipment = IN.lastFound
        if(IN.Equipment.childCount == 5) then
            OUT.Armor = OUT:addChild(TagList.new("Armor"))
            OUT.Mainhand = OUT:addChild(TagList.new("Mainhand"))
            OUT.Offhand = OUT:addChild(TagList.new("Offhand"))
            OUT.Offhand:addChild(Item:BlankItem())

            for i=0, 4 do
                local item = Item:ConvertItem(IN.Equipment:child(i), false)
                if(item == nil) then item = Item:BlankItem() end
                if(i == 0) then OUT.Mainhand:addChild(item)
                else OUT.Armor:addChild(item)
                end
            end
        end

    else
        if(IN:contains("ArmorItems", TYPE.LIST, TYPE.COMPOUND)) then
            IN.ArmorItems = IN.lastFound
            if(IN.ArmorItems.childCount == 4) then
                OUT.Armor = OUT:addChild(TagList.new("Armor"))
    
                for i=0, 3 do
                    local item = Item:ConvertItem(IN.ArmorItems:child(i), false)
                    if(item == nil) then item = Item:BlankItem() end
                    OUT.Armor:addChild(item)
                end
            end
        end
    
        if(IN:contains("HandItems", TYPE.LIST, TYPE.COMPOUND)) then
            IN.HandItems = IN.lastFound
            if(IN.HandItems.childCount == 2) then
                OUT.Mainhand = OUT:addChild(TagList.new("Mainhand"))
                OUT.Offhand = OUT:addChild(TagList.new("Offhand"))
    
                for i=0, 1 do
                    local item = Item:ConvertItem(IN.HandItems:child(i), false)
                    if(item == nil) then item = Item:BlankItem() end
                    if(i == 0) then OUT.Mainhand:addChild(item)
                    else OUT.Offhand:addChild(item) end
                end
            end
        end
    end

    if(required and OUT.Armor == nil) then
        OUT.Armor = OUT:addChild(TagList.new("Armor"))
        OUT.Armor:addChild(Item:BlankItem())
        OUT.Armor:addChild(Item:BlankItem())
        OUT.Armor:addChild(Item:BlankItem())
        OUT.Armor:addChild(Item:BlankItem())
    end
    if(required and OUT.Mainhand == nil) then OUT:addChild(TagList.new("Mainhand")):addChild(Item:BlankItem()) end
    if(required and OUT.Offhand == nil) then OUT:addChild(TagList.new("Offhand")):addChild(Item:BlankItem()) end

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
            if(effect_in:contains("Duration", TYPE.INT)) then effect_out.Duration = effect_out:addChild(effect_in.lastFound:clone()) else effect_out.Duration = effect_out:addChild(TagInt.new("Duration", 1)) end
            effect_out:addChild(TagInt.new("DurationEasy", effect_out.Duration.value))
            effect_out:addChild(TagInt.new("DurationHard", effect_out.Duration.value))
            effect_out:addChild(TagInt.new("DurationNormal", effect_out.Duration.value))

            OUT.ActiveEffects:addChild(effect_out)

            ::effectContinue::
        end

        if(OUT.ActiveEffects.childCount == 0) then
            OUT:removeChild(OUT.ActiveEffects:getRow())
            OUT.ActiveEffects = nil
        end
    end

    --TODO convert attributes

    OUT.Attributes = OUT:addChild(TagList.new("Attributes"))

    if(IN:contains("Attributes", TYPE.LIST, TYPE.COMPOUND)) then IN.Attributes = IN.lastFound end
    if(IN.Attributes ~= nil) then
        for i=0, IN.Attributes.childCount-1 do
            local attr = IN.Attributes:child(i)
            if(attr:contains("Base", TYPE.DOUBLE)) then attr.Base = attr.lastFound.value else goto attrContinue end
            if(attr:contains("ID", TYPE.INT)) then attr.ID = attr.lastFound.value else goto attrContinue end
            --if(attr:contains("Modifiers", TYPE.LIST, TYPE.COMPOUND)) then attr.Modifiers = attr.lastFound end

            if(attr.ID == 0) then IN.Attributes.maxHealth = attr.Base
            elseif(attr.ID == 1) then IN.Attributes.followRange = attr.Base
            elseif(attr.ID == 2) then IN.Attributes.knockbackResistance = attr.Base
            elseif(attr.ID == 3) then IN.Attributes.movementSpeed = attr.Base
            elseif(attr.ID == 4) then IN.Attributes.attackDamage = attr.Base
            elseif(attr.ID == 7) then IN.Attributes.attackSpeed = attr.Base
            elseif(attr.ID == 10) then IN.Attributes.luck = attr.Base
            elseif(attr.ID == 8) then IN.Attributes.armor = attr.Base
            elseif(attr.ID == 9) then IN.Attributes.armorToughness = attr.Base
            elseif(attr.ID == 11) then IN.Attributes.flyingSpeed = attr.Base
            elseif(attr.ID == 5) then IN.Attributes.horse_jumpStrength = attr.Base
            elseif(attr.ID == 6) then IN.Attributes.zombie_spawnReinforcements = attr.Base
            end
            ::attrContinue::
        end
    end

    if(IN.Attributes == nil) then IN.Attributes = TagList.new("Attributes") end

    return OUT
end

function Entity:ConvertBaseBreedable(IN, OUT)
    if(IN:contains("InLove", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("InLove")) end

    if(IN:contains("Age", TYPE.INT)) then
        local Age = IN.lastFound.value
        if(Age < 0) then
            OUT:addChild(TagInt.new("Age", Age))
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_baby"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_adult"))
            if(Age > 0) then OUT:addChild(TagInt.new("BreedCooldown", Age)) end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_adult"))
    end

    return OUT
end

function Entity:ConvertBaseProjectile(IN, OUT)

    --TODO idenfity how tf these can be short tags when they're block coords?
    if(IN:contains("xTile", TYPE.INT)) then OUT:addChild(TagShort.new("xTile", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("xTile", -1)) end
    if(IN:contains("yTile", TYPE.INT)) then OUT:addChild(TagShort.new("yTile", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("yTile", -1)) end
    if(IN:contains("zTile", TYPE.INT)) then OUT:addChild(TagShort.new("zTile", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("zTile", -1)) end



    return OUT
end

function Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT:contains("Pos", TYPE.LIST, TYPE.FLOAT)) then
        OUT.Pos = OUT.lastFound
        if(OUT.Pos.childCount == 3) then
            OUT.Pos:child(1).value = OUT.Pos:child(1).value + 0.35

            --detect if minecart is currently shares a block with a rail
            local minecartBlock = Chunk:getBlock(math.floor(OUT.Pos:child(0).value), math.floor(OUT.Pos:child(1).value), math.floor(OUT.Pos:child(2).value))
            if(minecartBlock:contains("Name", TYPE.STRING)) then
                minecartBlock.Name = minecartBlock.lastFound.value
                if(minecartBlock.Name == "minecraft:activator_rail" or minecartBlock.Name == "minecraft:detector_rail" or minecartBlock.Name == "minecraft:golden_rail" or  minecartBlock.Name == "minecraft:rail") then
                    OUT.Pos:child(1).value = OUT.Pos:child(1).value + 0.0875
                end
            end
        end
    end

    return OUT
end

function Entity:ConvertBaseHorse(IN, OUT)

    --all become wild
    --[[
    if(IN:contains("Tame", TYPE.BYTE)) then OUT:addChild(TagByte.new("IsTamed", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("IsTamed")) end
    if(IN:contains("Temper", TYPE.INT)) then
        local Temper = IN.lastFound.value
        if(IN.lastFound.value < 0 or IN.lastFound.value > 100) then Temper = 0 end
        OUT:addChild(TagInt.new("Temper", Temper))
    elseif(required) then OUT:addChild(TagInt.new("Temper")) end

    --]]

    --TODO EatingHaystack and Bred?


    return OUT
end

function Entity:ConvertBaseZombie(IN, OUT)
    if(IN:contains("IsBaby", TYPE.BYTE)) then OUT:addChild(TagByte.new("IsBaby", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("IsBaby", false)) end

    if(IN:contains("InWaterTime", TYPE.INT)) then IN.InWaterTime = IN.lastFound.value else IN.InWaterTime = -1 end
    if(IN:contains("DrownedConversionTime", TYPE.INT)) then IN.DrownedConversionTime = IN.lastFound.value else IN.DrownedConversionTime = -1 end

    if(IN.InWaterTime > -1) then
        if(IN.DrownedConversionTime > -1) then
            OUT.definitions:addChild(TagString.new("", "-minecraft:start_drowned_transformation"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:convert_to_drowned"))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:start_drowned_transformation"))
            OUT:addChild(TagInt.new("CountTime", IN.InWaterTime))
            OUT:addChild(TagLong.new("TimeStamp", Settings:getSettingLong("currentTick")+600-IN.InWaterTime))
        end
    end

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

function Entity:AddAttribute(OUT, Name, Base, MaxDefault, Current, Max)
    local attr = OUT.Attributes:addChild(TagCompound.new())
    attr:addChild(TagString.new("Name", Name))
    attr:addChild(TagFloat.new("Base", Base))

    local appliedMax = 0

    if(Max ~= nil) then
        attr:addChild(TagFloat.new("Max", Max))
        appliedMax = Max
    else
        attr:addChild(TagFloat.new("Max", MaxDefault))
        appliedMax = MaxDefault
    end

    if(Current ~= nil) then
        if(Current < appliedMax) then 
            attr:addChild(TagFloat.new("Current", Current))
        else
            attr:addChild(TagFloat.new("Current", appliedMax))
        end
    else
        if(Base < appliedMax) then 
            attr:addChild(TagFloat.new("Current", Base))
        else
            attr:addChild(TagFloat.new("Current", appliedMax))
        end
    end

    --[[
    if(Modifiers ~= nil) then
        attr:addChild(Modifiers:clone())
    end
    ]]
    return OUT
end

return Entity