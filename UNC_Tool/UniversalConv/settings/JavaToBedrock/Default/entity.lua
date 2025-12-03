Entity = {}
Item = Item or require('item')
Utils = Utils or require("utils")

FLOAT_MAX = 3.40282e+38

function Entity:ConvertEntity(IN, required)
    local OUT = TagCompound.new()

    --requires id, Pos, Rotation, Motion
    local id = ""
    if(IN:contains("id", TYPE.STRING)) then id = IN.lastFound.value
        if(id:find("^minecraft:")) then id = id:sub(11) end
    else return nil end
    if(IN:contains("Pos", TYPE.LIST, TYPE.DOUBLE)) then if(IN.lastFound.childCount == 3) then IN.Pos = IN.lastFound else return nil end elseif(required) then return nil end
    if(IN:contains("Motion", TYPE.LIST, TYPE.DOUBLE)) then if(IN.lastFound.childCount == 3) then IN.Motion = IN.lastFound else return nil end elseif(required) then return nil end
    if(IN:contains("Rotation", TYPE.LIST, TYPE.FLOAT)) then if(IN.lastFound.childCount == 2) then IN.Rotation = IN.lastFound else return nil end elseif(required) then return nil end

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

    if(Settings:dataTableContains("entities", id)) then
        local entry = Settings.lastFound
        if(required) then OUT:addChild(TagString.new("identifier", "minecraft:" .. entry[1][1])) end
        OUT = Entity[entry[1][2]](Entity, IN, OUT, required)
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
        elseif(IN:contains("Passengers", TYPE.LIST, TYPE.COMPOUND)) then
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

    if(OUT.mobEffects.childCount == 0) then return nil end

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

    if(required) then
        OUT.Pose = OUT:addChild(TagCompound.new("Pose"))
        OUT.Pose:addChild(TagInt.new("PoseIndex"))
        OUT.Pose:addChild(TagInt.new("LastSignal"))
    end

    return OUT
end
--
function Entity:ConvertArrow(IN, OUT, required)
    OUT.def_base = "arrow"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))

    --TODO enchantFlame, enchantInfinity, enchantPower, enchantPower

    local OnGround = false
    if(OUT:contains("OnGround", TYPE.BYTE)) then OnGround = IN.lastFound.value ~= 0 end

    OUT.StuckToBlockPos = OUT:addChild(TagList.new("StuckToBlockPos"))
    OUT.StuckToBlockPos:addChild(TagInt.new())
    OUT.StuckToBlockPos:addChild(TagInt.new())
    OUT.StuckToBlockPos:addChild(TagInt.new())

    if(OnGround) then
        if(IN:contains("xTile", TYPE.INT)) then OUT.StuckToBlockPos:child(0).value = IN.lastFound.value end
        if(IN:contains("yTile", TYPE.INT)) then OUT.StuckToBlockPos:child(1).value = IN.lastFound.value end
        if(IN:contains("zTile", TYPE.INT)) then OUT.StuckToBlockPos:child(2).value = IN.lastFound.value end
    end

    OUT.CollisionPos = OUT:addChild(TagList.new("CollisionPos"))
    OUT.CollisionPos:addChild(TagFloat.new())
    OUT.CollisionPos:addChild(TagFloat.new())
    OUT.CollisionPos:addChild(TagFloat.new())

    if(OnGround) then
        OUT.CollisionPos:child(0).value = OUT.Pos:child(0).value
        OUT.CollisionPos:child(1).value = OUT.Pos:child(1).value
        OUT.CollisionPos:child(2).value = OUT.Pos:child(2).value
    end

    if(required) then OUT:addChild(TagByte.new("IsGlobal", true)) end

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
    if(IN:contains("CustomPotionEffects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.CustomPotionEffects = IN.lastFound

        for i=0, IN.CustomPotionEffects.childCount-1 do
            local effect_in = IN.CustomPotionEffects:child(i)
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
                local effect_out2 = TagCompound.new()

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
function Entity:ConvertAxolotl(IN, OUT, required)
    OUT.def_base = "axolotl"
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
function Entity:ConvertBee(IN, OUT, required)
    OUT.def_base = "bee"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 10, 10, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 1024, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    
    if(IN:contains("HivePos", TYPE.COMPOUND)) then
        IN.HivePos = IN.lastFound

        OUT.HomePos = OUT:addChild(TagList.new("HomePos"))
        OUT.HomePos:addChild(TagFloat.new("", math.floor(OUT.Pos:child(0).value)))
        OUT.HomePos:addChild(TagFloat.new("", math.floor(OUT.Pos:child(1).value)))
        OUT.HomePos:addChild(TagFloat.new("", math.floor(OUT.Pos:child(2).value)))

        if(IN.HivePos:contains("X", TYPE.INT)) then OUT.HomePos:child(0).value = IN.HivePos.lastFound.value end
        if(IN.HivePos:contains("Y", TYPE.INT)) then OUT.HomePos:child(1).value = IN.HivePos.lastFound.value end
        if(IN.HivePos:contains("Z", TYPE.INT)) then OUT.HomePos:child(2).value = IN.HivePos.lastFound.value end
    elseif(required) then
        OUT.HomePos = OUT:addChild(TagList.new("HomePos"))
        OUT.HomePos:addChild(TagFloat.new("", math.floor(OUT.Pos:child(0).value)))
        OUT.HomePos:addChild(TagFloat.new("", math.floor(OUT.Pos:child(1).value)))
        OUT.HomePos:addChild(TagFloat.new("", math.floor(OUT.Pos:child(2).value)))
    end

    if(IN:contains("InLove", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("InLove")) end
    
    if(IN:contains("Age", TYPE.INT)) then
        local Age = IN.lastFound.value
        if(Age < 0) then
            OUT:addChild(TagInt.new("Age", Age))
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+bee_baby"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+bee_adult"))
            if(Age < 0) then OUT:addChild(TagInt.new("BreedCooldown", Age)) end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+bee_adult"))
    end

    OUT.definitions:addChild(TagString.new("", "+shelter_detection"))

    if(IN:contains("HasStung", TYPE.BYTE)) then
        local hasStung = 0
        if(IN.lastFound.value ~= 0) then hasStung = 1 end
        OUT:addChild(TagInt.new("MarkVariant", hasStung))
        OUT.definitions:addChild(TagString.new("", "+countdown_to_perish"))
        OUT.definitions:addChild(TagString.new("", "-angry_bee"))
    elseif(required) then
        OUT:addChild(TagInt.new("MarkVariant"))
    end

    if(IN:contains("HasNectar", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then
            OUT.definitions:addChild(TagString.new("", "+has_nectar"))
        else
            OUT.definitions:addChild(TagString.new("", "-has_nectar"))
        end
    elseif(required) then
        OUT.definitions:addChild(TagString.new("", "-has_nectar"))
    end

    if(IN:contains("Anger", TYPE.INT)) then
        if(IN.lastFound.value ~= 0) then
            OUT.definitions:addChild(TagString.new("", "-track_attacker"))
            OUT.definitions:addChild(TagString.new("", "+normal_attack"))
            OUT:addChild(TagByte.new("IsAngry", true))
        else
            OUT.definitions:addChild(TagString.new("", "+track_attacker"))
            OUT:addChild(TagByte.new("IsAngry"))
        end
    elseif(required) then
        OUT.definitions:addChild(TagString.new("", "+track_attacker"))
        OUT:addChild(TagByte.new("IsAngry"))
    end

    --JAVA snapshot
    --FlowerPos compound 3 ints X Y Z
    --HivePos compound 3 ints X Y Z
    --HasNectar byte 0
    --HasStung byte 0
    --Anger int 0
    --CannotEnterHiveTicks int 0
    --CropsGrownSincePollination int 0
    --TicksSincePollination int 6

    --BEDROCK beta 1
    --HomePos list float     1 4 1
    --TimeStamp int
    --lost stinger MarkVariant 1

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

    if(IN:contains("Type", TYPE.STRING)) then
        if(IN.lastFound.value == "oak") then OUT:addChild(TagInt.new("Variant", 0))
        elseif(IN.lastFound.value == "spruce") then OUT:addChild(TagInt.new("Variant", 1))
        elseif(IN.lastFound.value == "birch") then OUT:addChild(TagInt.new("Variant", 2))
        elseif(IN.lastFound.value == "jungle") then OUT:addChild(TagInt.new("Variant", 3))
        elseif(IN.lastFound.value == "acacia") then OUT:addChild(TagInt.new("Variant", 4))
        elseif(IN.lastFound.value == "dark_oak") then OUT:addChild(TagInt.new("Variant", 5))
        else
            OUT:addChild(TagInt.new("Variant"))
        end
    elseif(required) then 
        OUT:addChild(TagInt.new("Variant"))
    end

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
function Entity:ConvertCat(IN, OUT, required)
    OUT.def_base = "cat"
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

    if(IN:contains("CatType", TYPE.INT)) then
        local CatType = IN.lastFound.value
        if(CatType == 0) then OUT:addChild(TagInt.new("Variant", 8))
        elseif(CatType == 1) then OUT:addChild(TagInt.new("Variant", 1))
        elseif(CatType == 2) then OUT:addChild(TagInt.new("Variant", 2))
        elseif(CatType == 3) then OUT:addChild(TagInt.new("Variant", 3))
        elseif(CatType == 4) then OUT:addChild(TagInt.new("Variant", 4))
        elseif(CatType == 5) then OUT:addChild(TagInt.new("Variant", 5))
        elseif(CatType == 6) then OUT:addChild(TagInt.new("Variant", 6))
        elseif(CatType == 7) then OUT:addChild(TagInt.new("Variant", 7))
        elseif(CatType == 8) then OUT:addChild(TagInt.new("Variant", 0))
        elseif(CatType == 9) then OUT:addChild(TagInt.new("Variant", 10))
        elseif(CatType == 10) then OUT:addChild(TagInt.new("Variant", 9))
        end
    end

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

    --[[

    JAVA:

    EggLayTime Int
    IsChickenJockey Byte 0


    BEDROCK:

    entries List
        Compound
        SpawnTimer Int

    ]]

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

            OUT:addChild(TagLong.new("TimeStamp", Settings:getSettingLong("currentTick")+2400-Moistness))
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

    local blockName = "minecraft:air"
    local blockStates = ""

    if(IN:contains("carriedBlockState", TYPE.COMPOUND)) then
        IN.blockState = IN.lastFound

        if(IN.blockState:contains("Name", TYPE.STRING)) then IN.blockState.id = IN.blockState.lastFound end
        if(IN.blockState:contains("Properties", TYPE.COMPOUND)) then IN.blockState.meta = IN.blockState.lastFound end

        local block = Utils:findBlock(IN.blockState.id, IN.blockState.meta)
        if(block ~= nil and block.id ~= nil) then
            blockName = "minecraft:" .. block.id
            blockStates = block.meta
        end
    elseif(IN:contains("carried", TYPE.STRING)) then
        IN.inTile = IN.lastFound.value

        if(IN:contains("carriedData", TYPE.SHORT)) then IN.inData = IN.lastFound.value end

        local block = Utils:findBlock(IN.inTile, IN.inData)
        if(block ~= nil and block.id ~= nil) then
            blockName = "minecraft:" .. block.id
            blockStates = block.meta
        end
    end

    OUT.carriedBlock = OUT:addChild(TagCompound.new("carriedBlock"))

    OUT.carriedBlock:addChild(TagString.new("name", blockName))
    if(blockStates:len() ~= 0) then
        local statesTags = Utils:StringToStates(blockStates)
        if(statesTags ~= nil) then OUT.carriedBlock:addChild(statesTags) end
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

    if(IN:contains("Warmup", TYPE.INT)) then OUT:addChild(TagInt.new("limitedLife", IN.lastFound.value + 20)) elseif(required) then OUT:addChild(TagInt.new("limitedLife", 20)) end

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

    if(IN:contains("Time", TYPE.INT)) then
        OUT:addChild(TagByte.new("Time", IN.lastFound.value))
    elseif(required) then
        OUT:addChild(TagByte.new("Time"))
    end

    local blockName = "minecraft:air"
    local blockStates = ""

    if(IN:contains("BlockState", TYPE.COMPOUND)) then
        IN.blockState = IN.lastFound

        if(IN.blockState:contains("Name", TYPE.STRING)) then IN.blockState.id = IN.blockState.lastFound end
        if(IN.blockState:contains("Properties", TYPE.COMPOUND)) then IN.blockState.meta = IN.blockState.lastFound end

        local block = Utils:findBlock(IN.blockState.id, IN.blockState.meta)
        if(block ~= nil and block.id ~= nil) then
            blockName = "minecraft:" .. block.id
            blockStates = block.meta
        end
    elseif(IN:contains("Block", TYPE.STRING)) then
        IN.inTile = IN.lastFound.value

        if(IN:contains("Data", TYPE.BYTE)) then IN.inData = IN.lastFound.value end

        local block = Utils:findBlock(IN.inTile, IN.inData)
        if(block ~= nil and block.id ~= nil) then
            blockName = "minecraft:" .. block.id
            blockStates = block.meta
        end
    end

    OUT.FallingBlock = OUT:addChild(TagCompound.new("FallingBlock"))

    OUT.FallingBlock:addChild(TagString.new("name", blockName))
    if(blockStates:len() ~= 0) then
        local statesTags = Utils:StringToStates(blockStates)
        if(statesTags ~= nil) then OUT.FallingBlock:addChild(statesTags) end
    end

    --TODO identify use of Variant
    --falling sand has a variant of 2152. bit flag to store damag info? maybe test anvils

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
function Entity:ConvertFox(IN, OUT, required)
    OUT.def_base = "fox"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 2, 2, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Sitting", TYPE.BYTE)) then OUT:addChild(TagByte.new("Sitting", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Sitting")) end
    
    if(IN:contains("Type", TYPE.STRING)) then
        if(IN.lastFound.value == "snow") then
            OUT.definitions:addChild(TagString.new("", "+minecraft:fox_arctic"))
            OUT:addChild(TagInt.new("Variant", 1))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:fox_red"))
            OUT:addChild(TagInt.new("Variant"))
        end
    else
        OUT.definitions:addChild(TagString.new("", "+minecraft:fox_red"))
        if(required) then OUT:addChild(TagInt.new("Variant")) end
    end

    if(IN:contains("Sleeping", TYPE.BYTE)) then
        if(IN.lastFound.value ~= 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:fox_ambient_sleep"))
        end
    end

    --No crouching on bedrock?


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
function Entity:ConvertGlowSquid(IN, OUT, required)
    OUT.def_base = "glow_squid"
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
function Entity:ConvertGoat(IN, OUT, required)
    OUT.def_base = "goat"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Age", TYPE.INT)) then
        local Age = IN.lastFound.value
        if(Age < 0) then
            OUT:addChild(TagInt.new("Age", Age))
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+goat_baby"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+goat_adult"))
            if(Age < 0) then OUT:addChild(TagInt.new("BreedCooldown", Age)) end
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+goat_adult"))
    end

    OUT.definitions:addChild(TagString.new("", "+goat_default"))

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 10, 10, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

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
function Entity:ConvertHoglin(IN, OUT, required)
    OUT.def_base = "hoglin"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 40, 40, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0.5, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)
    OUT = Entity:AddAttribute(OUT, "minecraft:lava_movement", 0.02, FLOAT_MAX)

    --int TimeInOverworld 48

    if(IN:contains("TimeInOverworld", TYPE.INT)) then
        local timeTick = IN.lastFound.value
        if(timeTick ~= 0) then
            OUT.definitions:addChild(TagString.new("", "+start_zombification"))

            OUT:addChild(TagLong.new("TimeStamp", Settings:getSettingLong("currentTick")+300-timeTick))
        end
    end

    local huntable = true
    if(IN:contains("CannotBeHunted", TYPE.BYTE)) then
        huntable = IN.lastFound.value ~= 0
    end

    if(huntable) then
        OUT.definitions:addChild(TagString.new("", "+huntable_adult"))
    end

    if(IN:contains("IsBaby", TYPE.BYTE)) then
        if(IN.lastFound.value == 0) then
            OUT.definitions:addChild(TagString.new("", "+minecraft:hoglin_adult"))
        elseif(required) then
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+minecraft:hoglin_baby"))
        end
    elseif(required) then
        OUT.definitions:addChild(TagString.new("", "+minecraft:hoglin_adult"))
    end

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

    --TODO convert variant
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

    if(OUT:contains("Armor", TYPE.LIST, TYPE.COMPOUND)) then
        OUT.Armor = OUT.lastFound
        OUT.Armor:clear()
        OUT.Armor:addChild(Item:BlankItem())
        OUT.Armor:addChild(Item:BlankItem())
        OUT.Armor:addChild(Item:BlankItem())
        OUT.Armor:addChild(Item:BlankItem())
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

    if(IN:contains("Item", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item == nil) then return nil end
        item.name = "Item"
        OUT:addChild(item)
    else return nil end

    if(IN:contains("Age", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Age")) end
    if(IN:contains("Health", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Health", 5)) end

    return OUT
end
--
function Entity:ConvertItemFrame(IN, OUT, required)

    local id = ""
    if(IN:contains("id", TYPE.STRING)) then id = IN.lastFound.value
        if(id:find("^minecraft:")) then id = id:sub(11) end
    else return nil end
    
    --convert to tile entity
    local TOUT = TagCompound.new()
    if(id == "glow_item_frame") then
        TOUT:addChild(TagString.new("id", "GlowItemFrame"))
    else
        TOUT:addChild(TagString.new("id", "ItemFrame"))
    end
    TOUT.x = TOUT:addChild(TagInt.new("x", math.floor(OUT.Pos:child(0).value)))
    TOUT.y = TOUT:addChild(TagInt.new("y", math.floor(OUT.Pos:child(1).value)))
    TOUT.z = TOUT:addChild(TagInt.new("z", math.floor(OUT.Pos:child(2).value)))
    TOUT:addChild(TagByte.new("IsMovable", true))

    --validate coords

    local ChunkX = Settings:getSettingInt("ChunkX")
    local ChunkZ = Settings:getSettingInt("ChunkZ")

    if(TOUT.x.value < ChunkX*16 or TOUT.x.value >= (ChunkX+1)*16) then return nil end
    if(TOUT.z.value < ChunkZ*16 or TOUT.z.value >= (ChunkZ+1)*16) then return nil end

    local blockToSet = TagCompound.new()

    if(id == "glow_item_frame") then
        blockToSet:addChild(TagString.new("Name", "minecraft:glow_frame"))
    else
        blockToSet:addChild(TagString.new("Name", "minecraft:frame"))
    end
    --TODO set facing state based on input
    --states are 3_facing_direction and 1_item_frame_map_bit

    --0 down
    --1 up
    --2 north
    --3 south
    --4 west
    --5 east

    --2828, 88, -3711

    local facing_direction = 0
    if(IN:contains("Facing", TYPE.BYTE)) then
        local Facing = IN.lastFound.value

        local DataVersion = Settings:getSettingInt("DataVersion")

        if(DataVersion > 1457) then
            if(Facing < 0 or Facing > 5) then return nil end
            facing_direction = Facing
        else
            if(Facing == 0) then facing_direction = 3
            elseif(Facing == 1) then facing_direction = 4
            elseif(Facing == 2) then facing_direction = 2
            elseif(Facing == 3) then facing_direction = 5
            else return nil end
        end
    elseif(IN:contains("Direction", TYPE.BYTE)) then
        local Direction = IN.lastFound.value
        if(Direction == 0) then facing_direction = 3
        elseif(Direction == 1) then facing_direction = 4
        elseif(Direction == 2) then facing_direction = 2
        elseif(Direction == 3) then facing_direction = 5
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

    blockToSet.states = blockToSet:addChild(TagCompound.new("states"))
    blockToSet.states:addChild(TagInt.new("facing_direction", facing_direction))
    blockToSet.states:addChild(TagByte.new("item_frame_map_bit", isMap))

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

    local id = ""
    if(IN:contains("id", TYPE.STRING)) then id = IN.lastFound.value
        if(id:find("^minecraft:")) then id = id:sub(11) end
    else return nil end
    if(id == "trader_llama") then
        OUT.definitions:addChild(TagString.new("", "+minecraft:llama_wandering_trader"))
        OUT:addChild(TagInt.new("MarkVariant", 1))
    end

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
function Entity:ConvertMinecartCommandBlock(IN, OUT, required)
    OUT.def_base = "command_block_minecart"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end
 
    if(IN:contains("LastExecution", TYPE.LONG)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("TrackOutput", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("Command", TYPE.STRING)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("SuccessCont", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) end
    if(OUT:contains("CustomName", TYPE.STRING)) then
        if(OUT.lastFound.value == "@") then
            OUT.lastFound.value = ""
        end
    end
 
    -- CHECK IF ACTIVATOR RAIL IS POWERED. SETS DEFINITIONS ACCORDINGLY.
    if(OUT:contains("Pos", TYPE.LIST, TYPE.FLOAT)) then
        OUT.Pos = OUT.lastFound
        if(OUT.Pos.childCount == 3) then
            local rail = Chunk:getBlock(math.floor(OUT.Pos:child(0).value), math.floor(OUT.Pos:child(1).value), math.floor(OUT.Pos:child(2).value))
 
            if(rail:contains("Name", TYPE.STRING)) then
                rail.Name = rail.lastFound.value
                if(rail.Name:find("^minecraft:")) then rail.Name = rail.Name:sub(11) end
                if(rail.Name == "activator_rail") then
                    if(rail:contains("states", TYPE.COMPOUND)) then
                        rail.states = rail.lastFound
                        if(rail.states:contains("rail_data_bit", TYPE.BYTE)) then
                            if(rail.states.lastFound.value == 1) then
                                OUT.definitions:addChild(TagString.new("", "+minecraft:command_block_active"))
                            else
                                OUT.definitions:addChild(TagString.new("", "-minecraft:command_block_active"))
                                OUT.definitions:addChild(TagString.new("", "+minecraft:command_block_inactive"))
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

    if(IN:contains("Type", TYPE.STRING)) then 
        if(IN.lastFound.value == "red") then
            OUT.definitions:addChild(TagString.new("", "+minecraft:mooshroom_red")) 
        elseif(IN.lastFound.value == "brown") then
            OUT:addChild(TagInt.new("Variant", 1))
            OUT.definitions:addChild(TagString.new("", "+minecraft:mooshroom_brown"))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:mooshroom_red")) 
        end
    else
        OUT.definitions:addChild(TagString.new("", "+minecraft:mooshroom_red")) 
    end

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
function Entity:ConvertPanda(IN, OUT, required)
    OUT.def_base = "panda"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 2, 2, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.15, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    local mainGene = 10
    local hiddenGene = 10

    if(IN:contains("MainGene", TYPE.STRING)) then
        IN.MainGene = IN.lastFound.value

        if(IN.MainGene == "normal") then mainGene = 10
        elseif(IN.MainGene == "lazy") then mainGene = 0 
        elseif(IN.MainGene == "worried") then mainGene = 1 
        elseif(IN.MainGene == "playful") then mainGene = 2 
        elseif(IN.MainGene == "aggressive") then mainGene = 3 
        elseif(IN.MainGene == "weak") then mainGene = 4 
        elseif(IN.MainGene == "brown") then mainGene = 8 
        end
    end

    if(IN:contains("HiddenGene", TYPE.STRING)) then
        IN.HiddenGene = IN.lastFound.value

        if(IN.HiddenGene == "normal") then hiddenGene = 10
        elseif(IN.HiddenGene == "lazy") then hiddenGene = 0 
        elseif(IN.HiddenGene == "worried") then hiddenGene = 1 
        elseif(IN.HiddenGene == "playful") then hiddenGene = 2 
        elseif(IN.HiddenGene == "aggressive") then hiddenGene = 3 
        elseif(IN.HiddenGene == "weak") then hiddenGene = 4 
        elseif(IN.HiddenGene == "brown") then hiddenGene = 8 
        end
    end

    if(IN.MainGene ~= nil or IN.HiddenGene ~= nil or required) then
        OUT.GeneArray = OUT:addChild(TagList.new("GeneArray"))
        OUT.GeneArray.genes = OUT.GeneArray:addChild(TagCompound.new())
        OUT.GeneArray.genes:addChild(TagInt.new("MainAllele", mainGene))
        OUT.GeneArray.genes:addChild(TagInt.new("HiddenAllele", hiddenGene))
    end

    if(mainGene == 0 or mainGene == 1 or mainGene == 2 or mainGene == 3 or mainGene == 10) then
        --dominant gene
        if(mainGene == 0) then
            OUT:addChild(TagInt.new("Variant", 1))
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_lazy"))
        elseif(mainGene == 1) then
            OUT:addChild(TagInt.new("Variant", 2))
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_worried"))
        elseif(mainGene == 2) then
            OUT:addChild(TagInt.new("Variant", 3))
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_playful"))
        elseif(mainGene == 3) then
            OUT:addChild(TagInt.new("Variant", 6))
            OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_aggressive"))
        elseif(mainGene == 10) then
            OUT:addChild(TagInt.new("Variant", 0))
        end
    else
        --recessive gene
        if(mainGene == hiddenGene) then
            if(mainGene == 4) then
                OUT:addChild(TagInt.new("Variant", 5))
                OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_weak"))
            elseif(mainGene == 8) then
                OUT:addChild(TagInt.new("Variant", 4))
                OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base .. "_brown"))
            end
        else
            OUT:addChild(TagInt.new("Variant", 0))
        end
    end

    --Variant
    --0 normal
    --1 lazy
    --2 worried
    --3 playful
    --4 brown
    --5 weak
    --6 aggressive

    --alleles:
    --0 lazy D
    --1 worried D
    --2 playful D
    --3 aggressive D
    --4 weak R
    --5 weak R
    --6 weak R
    --7 weak R
    --8 brown R
    --9 brown R
    --10 normal D
    --11 normal D
    --12 normal D
    --13 normal D
    --14 normal D

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

    --JAVA 1.12
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

    --TODO verify these values
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
        if(motive:find("^minecraft:")) then motive = motive:sub(11) end
        if(motive == "Kebab" or motive == "kebab") then
            OUT:addChild(TagString.new("Motive", "Kebab"))
        elseif(motive == "Aztec" or motive == "aztec") then
            OUT:addChild(TagString.new("Motive", "Aztec"))
        elseif(motive == "Alban" or motive == "alban") then
            OUT:addChild(TagString.new("Motive", "Alban"))
        elseif(motive == "Aztec2" or motive == "aztec2") then
            OUT:addChild(TagString.new("Motive", "Aztec2"))
        elseif(motive == "Bomb" or motive == "bomb") then
            OUT:addChild(TagString.new("Motive", "Bomb"))
        elseif(motive == "Plant" or motive == "plant") then
            OUT:addChild(TagString.new("Motive", "Plant"))
        elseif(motive == "Wasteland" or motive == "wasteland") then
            OUT:addChild(TagString.new("Motive", "Wasteland"))
        elseif(motive == "Wanderer" or motive == "wanderer") then
            OUT:addChild(TagString.new("Motive", "Wanderer"))
            height = 2
        elseif(motive == "Graham" or motive == "graham") then
            OUT:addChild(TagString.new("Motive", "Graham"))
            height = 2
        elseif(motive == "Pool" or motive == "pool") then
            OUT:addChild(TagString.new("Motive", "Pool"))
            width = 2
        elseif(motive == "Courbet" or motive == "courbet") then
            OUT:addChild(TagString.new("Motive", "Courbet"))
            width = 2
        elseif(motive == "Sunset" or motive == "sunset") then
            OUT:addChild(TagString.new("Motive", "Sunset"))
            width = 2
        elseif(motive == "Sea" or motive == "sea") then
            OUT:addChild(TagString.new("Motive", "Sea"))
            width = 2
        elseif(motive == "Creebet" or motive == "creebet") then
            OUT:addChild(TagString.new("Motive", "Creebet"))
            width = 2
        elseif(motive == "Match" or motive == "match") then
            OUT:addChild(TagString.new("Motive", "Match"))
            width = 2
            height = 2
        elseif(motive == "Bust" or motive == "bust") then
            OUT:addChild(TagString.new("Motive", "Bust"))
            width = 2
            height = 2
        elseif(motive == "Stage" or motive == "stage") then
            OUT:addChild(TagString.new("Motive", "Stage"))
            width = 2
            height = 2
        elseif(motive == "Void" or motive == "void") then
            OUT:addChild(TagString.new("Motive", "Void"))
            width = 2
            height = 2
        elseif(motive == "SkullAndRoses" or motive == "skull_and_roses") then
            OUT:addChild(TagString.new("Motive", "SkullAndRoses"))
            width = 2
            height = 2
        elseif(motive == "Wither" or motive == "wither") then
            OUT:addChild(TagString.new("Motive", "Wither"))
            width = 2
            height = 2
        elseif(motive == "Fighters" or motive == "fighters") then
            OUT:addChild(TagString.new("Motive", "Fighters"))
            width = 4
            height = 2
        elseif(motive == "Skeleton" or motive == "skeleton") then
            OUT:addChild(TagString.new("Motive", "Skeleton"))
            width = 4
            height = 3
        elseif(motive == "DonkeyKong" or motive == "donkey_kong") then
            OUT:addChild(TagString.new("Motive", "DonkeyKong"))
            width = 4
            height = 3
        elseif(motive == "Pointer" or motive == "pointer") then
            OUT:addChild(TagString.new("Motive", "Pointer"))
            width = 4
            height = 4
        elseif(motive == "Pigscene" or motive == "pigscene") then
            OUT:addChild(TagString.new("Motive", "Pigscene"))
            width = 4
            height = 4
        elseif(motive == "BurningSkull" or motive == "burning_skull") then
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
function Entity:ConvertPiglin(IN, OUT, required)
    OUT.def_base = "piglin"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 5, 5, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 16, 16, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 64, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.35, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)
    OUT = Entity:AddAttribute(OUT, "minecraft:lava_movement", 0.02, FLOAT_MAX)

    local immune = false
    if(IN:contains("IsImmuneToZombification", TYPE.BYTE)) then
        immune = IN.lastFound.value ~= 0
    end

    if(not immune) then
        if(IN:contains("TimeInOverworld", TYPE.INT)) then
            local timeTick = IN.lastFound.value
            if(timeTick ~= 0) then
                OUT.definitions:addChild(TagString.new("", "+start_zombification"))
    
                OUT:addChild(TagLong.new("TimeStamp", Settings:getSettingLong("currentTick")+300-timeTick))
            end
        end
    end

    local canHunt = true
    if(IN:contains("CannotHunt", TYPE.BYTE)) then
        canHunt = IN.lastFound.value ~= 0
    end

    if(canHunt) then
        OUT.definitions:addChild(TagString.new("", "+hunter"))
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
    
    return OUT
end
--
function Entity:ConvertPillager(IN, OUT, required)
    OUT.def_base = "pillager"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT.definitions:addChild(TagString.new("", "+minecraft:ranged_attack"))

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 24, 24, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range",64, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.35, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

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
function Entity:ConvertRavager(IN, OUT, required)
    OUT.def_base = "ravager"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 12, 12, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 100, 100, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 64, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0.5, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.3, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    local hostile = true

    if(IN:contains("StunTick", TYPE.INT)) then
        local stunTick = IN.lastFound.value
        if(stunTick ~= 0) then
            hostile = false
            OUT.definitions:addChild(TagString.new("", "-minecraft:hostile"))
            OUT.definitions:addChild(TagString.new("", "+stunned"))
            OUT.definitions:addChild(TagString.new("", "-roaring"))

            OUT:addChild(TagByte.new("IsStunned", true))
            OUT:addChild(TagByte.new("IsRoaring", false))

            OUT:addChild(TagLong.new("TimeStamp", Settings:getSettingLong("currentTick")+40-stunTick))
        end
    end

    if(IN:contains("RoarTick", TYPE.INT)) then
        local roarTick = IN.lastFound.value
        if(roarTick ~= 0) then
            hostile = false
            OUT.definitions:addChild(TagString.new("", "-minecraft:hostile"))
            OUT.definitions:addChild(TagString.new("", "+roaring"))
            OUT.definitions:addChild(TagString.new("", "-stunned"))

            OUT:addChild(TagByte.new("IsStunned", false))
            OUT:addChild(TagByte.new("IsRoaring", true))
            OUT:addChild(TagLong.new("TimeStamp", Settings:getSettingLong("currentTick")+20-roarTick))
        end
    end

    if(hostile) then
        OUT.definitions:addChild(TagString.new("", "+minecraft:hostile"))
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
        if(Color < 0 or Color > 16) then Color = 16
        else
            Color = 15 - Color
        end
        OUT:addChild(TagInt.new("Variant", Color))

        if(Color == 0) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_black"))
        elseif(Color == 1) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_red"))
        elseif(Color == 2) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_green"))
        elseif(Color == 3) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_brown"))
        elseif(Color == 4) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_blue"))
        elseif(Color == 5) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_purple"))
        elseif(Color == 6) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_cyan"))
        elseif(Color == 7) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_silver"))
        elseif(Color == 8) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_gray"))
        elseif(Color == 9) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_pink"))
        elseif(Color == 10) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_lime"))
        elseif(Color == 11) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_yellow"))
        elseif(Color == 12) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_light_blue"))
        elseif(Color == 13) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_magenta"))
        elseif(Color == 14) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_orange"))
        elseif(Color == 15) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_white"))
        elseif(Color == 16) then OUT.definitions:addChild(TagString.new("", "+minecraft:shulker_undyed")) end
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

    local OnGround = false
    if(OUT:contains("OnGround", TYPE.BYTE)) then OnGround = IN.lastFound.value ~= 0 end

    OUT.StuckToBlockPos = OUT:addChild(TagList.new("StuckToBlockPos"))
    OUT.StuckToBlockPos:addChild(TagInt.new())
    OUT.StuckToBlockPos:addChild(TagInt.new())
    OUT.StuckToBlockPos:addChild(TagInt.new())

    if(OnGround) then
        if(IN:contains("xTile", TYPE.INT)) then OUT.StuckToBlockPos:child(0).value = IN.lastFound.value end
        if(IN:contains("yTile", TYPE.INT)) then OUT.StuckToBlockPos:child(1).value = IN.lastFound.value end
        if(IN:contains("zTile", TYPE.INT)) then OUT.StuckToBlockPos:child(2).value = IN.lastFound.value end
    end

    OUT.CollisionPos = OUT:addChild(TagList.new("CollisionPos"))
    OUT.CollisionPos:addChild(TagFloat.new())
    OUT.CollisionPos:addChild(TagFloat.new())
    OUT.CollisionPos:addChild(TagFloat.new())

    if(OnGround) then
        OUT.CollisionPos:child(0).value = OUT.Pos:child(0).value
        OUT.CollisionPos:child(1).value = OUT.Pos:child(1).value
        OUT.CollisionPos:child(2).value = OUT.Pos:child(2).value
    end

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
function Entity:ConvertStrider(IN, OUT, required)
    OUT.def_base = "strider"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 15, 15, IN.Health * 0.75, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.16, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)
    OUT = Entity:AddAttribute(OUT, "minecraft:lava_movement", 0.32, FLOAT_MAX)

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

    if(IN:contains("Fire", TYPE.SHORT)) then
        if(IN.lastFound.value ~= -1) then
            OUT.definitions:addChild(TagString.new("", "-minecraft:start_suffocating"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:detect_suffocating"))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:start_suffocating"))
        end
    else
        OUT.definitions:addChild(TagString.new("", "+minecraft:start_suffocating"))
    end

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

    local OnGround = false
    if(OUT:contains("OnGround", TYPE.BYTE)) then OnGround = IN.lastFound.value ~= 0 end

    OUT.StuckToBlockPos = OUT:addChild(TagList.new("StuckToBlockPos"))
    OUT.StuckToBlockPos:addChild(TagInt.new())
    OUT.StuckToBlockPos:addChild(TagInt.new())
    OUT.StuckToBlockPos:addChild(TagInt.new())

    if(OnGround) then
        if(IN:contains("xTile", TYPE.INT)) then OUT.StuckToBlockPos:child(0).value = IN.lastFound.value end
        if(IN:contains("yTile", TYPE.INT)) then OUT.StuckToBlockPos:child(1).value = IN.lastFound.value end
        if(IN:contains("zTile", TYPE.INT)) then OUT.StuckToBlockPos:child(2).value = IN.lastFound.value end
    end

    OUT.CollisionPos = OUT:addChild(TagList.new("CollisionPos"))
    OUT.CollisionPos:addChild(TagFloat.new())
    OUT.CollisionPos:addChild(TagFloat.new())
    OUT.CollisionPos:addChild(TagFloat.new())

    if(OnGround) then
        OUT.CollisionPos:child(0).value = OUT.Pos:child(0).value
        OUT.CollisionPos:child(1).value = OUT.Pos:child(1).value
        OUT.CollisionPos:child(2).value = OUT.Pos:child(2).value
    end

    if(required) then OUT:addChild(TagByte.new("IsGlobal", true)) end

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
    OUT.def_base = "villager_v2"
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
                    if(buy:contains("Count", TYPE.BYTE)) then
                        trade_out:addChild(TagInt.new("buyCountA", buy.lastFound.value)) 
                    else trade_out:addChild(TagInt.new("buyCountA", 0)) end
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

                    if(trade_out.buyCountB == nil) then trade_out:addChild(TagInt.new("buyCountB", 0)) end
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

                if(trade_in:contains("priceMultiplier", TYPE.FLOAT)) then
                    trade_out:addChild(TagFloat.new("priceMultiplierA", trade_in.lastFound.value))
                else trade_out:addChild(TagFloat.new("priceMultiplierA", 0)) end
                
                trade_out:addChild(TagFloat.new("priceMultiplierB"))

                if(trade_in:contains("demand", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("demand", (trade_in.lastFound.value+32)*-1))
                else trade_out:addChild(TagInt.new("demand")) end

                if(trade_in:contains("xp", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("traderExp", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("traderExp", 1)) end

                OUT.Offers.Recipes:addChild(trade_out)

                ::tradeContinue::
            end

        end

        --TODO TradeExperienceLevels, might be different for each villager? dont forget about wandering trader's trades
    end

    if(required) then TagByte.new("RewardPlayersOnFirstFounding", true) end

    local DataVersion = Settings:getSettingInt("DataVersion")

    if(DataVersion >= 1901) then
        --new villager type

        --Bedrock variants:

        --1 farmer
        --2 fisherman
        --3 shepherd
        --4 fletcher
        --5 librarian
        --6 cartographer
        --7 cleric
        --8 armorer
        --9 weaponsmith
        --10 toolsmith
        --11 butcher
        --12 leatherworker
        --13 mason
        --14 nitwit

        --Mark Variant
        --0 plains
        --1 desert
        --2 jungle
        --3 savanna
        --4 snow
        --5 swamp
        --6 taiga

        if(IN:contains("VillagerData", TYPE.COMPOUND)) then
            IN.VillagerData = IN.lastFound

            if(IN.VillagerData:contains("profession", TYPE.STRING)) then
                local profession = IN.VillagerData.lastFound.value
                if(profession:find("^minecraft:")) then profession = profession:sub(11) end

                if(profession == "none") then
                    OUT:addChild(TagString.new("PreferredProfession", "none"))
                    OUT:addChild(TagInt.new("Variant", 0))
                elseif(profession == "farmer") then
                    OUT:addChild(TagString.new("PreferredProfession", "farmer"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/farmer_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+farmer"))
                    OUT:addChild(TagInt.new("Variant", 1))
                elseif(profession == "fisherman") then
                    OUT:addChild(TagString.new("PreferredProfession", "fisherman"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/fisherman_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+fisherman"))
                    OUT:addChild(TagInt.new("Variant", 2))
                elseif(profession == "shepherd") then
                    OUT:addChild(TagString.new("PreferredProfession", "shepherd"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/shepherd_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+shepherd"))
                    OUT:addChild(TagInt.new("Variant", 3))
                elseif(profession == "fletcher") then
                    OUT:addChild(TagString.new("PreferredProfession", "fletcher"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/fletcher_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+fletcher"))
                    OUT:addChild(TagInt.new("Variant", 4))
                elseif(profession == "librarian") then
                    OUT:addChild(TagString.new("PreferredProfession", "librarian"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/librarian_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+librarian"))
                    OUT:addChild(TagInt.new("Variant", 5))
                elseif(profession == "cartographer") then
                    OUT:addChild(TagString.new("PreferredProfession", "cartographer"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/cartographer_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+cartographer"))
                    OUT:addChild(TagInt.new("Variant", 6))
                elseif(profession == "cleric") then
                    OUT:addChild(TagString.new("PreferredProfession", "cleric"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/cleric_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+cleric"))
                    OUT:addChild(TagInt.new("Variant", 7))
                elseif(profession == "armorer") then
                    OUT:addChild(TagString.new("PreferredProfession", "armorer"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/armorer_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+armorer"))
                    OUT:addChild(TagInt.new("Variant", 8))
                elseif(profession == "weaponsmith") then
                    OUT:addChild(TagString.new("PreferredProfession", "weaponsmith"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/weapon_smith_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+weaponsmith"))
                    OUT:addChild(TagInt.new("Variant", 9))
                elseif(profession == "toolsmith") then
                    OUT:addChild(TagString.new("PreferredProfession", "toolsmith"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/toolsmith_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+toolsmith"))
                    OUT:addChild(TagInt.new("Variant", 10))
                elseif(profession == "butcher") then
                    OUT:addChild(TagString.new("PreferredProfession", "butcher"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/butcher_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+butcher"))
                    OUT:addChild(TagInt.new("Variant", 11))
                elseif(profession == "leatherworker") then
                    OUT:addChild(TagString.new("PreferredProfession", "leatherworker"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/leather_worker_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+leatherworker"))
                    OUT:addChild(TagInt.new("Variant", 12))
                elseif(profession == "mason") then
                    OUT:addChild(TagString.new("PreferredProfession", "mason"))
                    OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/mason_trades.json"))
                    OUT.definitions:addChild(TagString.new("", "+mason"))
                    OUT:addChild(TagInt.new("Variant", 13))
                elseif(profession == "nitwit") then
                    OUT:addChild(TagString.new("PreferredProfession", "nitwit"))
                    OUT.definitions:addChild(TagString.new("", "+nitwit"))
                    OUT:addChild(TagInt.new("Variant", 14))
                else
                    OUT:addChild(TagString.new("PreferredProfession", "none"))
                    OUT:addChild(TagInt.new("Variant", 0))
                end
            elseif(required) then
                OUT:addChild(TagString.new("PreferredProfession", "none"))
                OUT:addChild(TagInt.new("Variant", 0))
            end

            if(IN.VillagerData:contains("type", TYPE.STRING)) then
                local type = IN.VillagerData.lastFound.value
                if(type:find("^minecraft:")) then type = type:sub(11) end

                if(type == "plains") then
                    OUT:addChild(TagInt.new("MarkVariant"))
                elseif(type == "desert") then
                    OUT:addChild(TagInt.new("MarkVariant", 1))
                    OUT.definitions:addChild(TagString.new("", "+desert_villager"))
                elseif(type == "jungle") then
                    OUT:addChild(TagInt.new("MarkVariant", 2))
                    OUT.definitions:addChild(TagString.new("", "+jungle_villager"))
                elseif(type == "savanna") then
                    OUT:addChild(TagInt.new("MarkVariant", 3))
                    OUT.definitions:addChild(TagString.new("", "+savanna_villager"))
                elseif(type == "snow") then
                    OUT:addChild(TagInt.new("MarkVariant", 4))
                    OUT.definitions:addChild(TagString.new("", "+snow_villager"))
                elseif(type == "swamp") then
                    OUT:addChild(TagInt.new("MarkVariant", 5))
                    OUT.definitions:addChild(TagString.new("", "+swamp_villager"))
                elseif(type == "taiga") then
                    OUT:addChild(TagInt.new("MarkVariant", 6))
                    OUT.definitions:addChild(TagString.new("", "+taiga_villager"))
                elseif(required) then
                    OUT:addChild(TagInt.new("MarkVariant"))
                end
            elseif(required) then 
                OUT:addChild(TagInt.new("MarkVariant"))
            end

            if(IN.VillagerData:contains("level", TYPE.INT)) then OUT:addChild(TagInt.new("TradeTier", IN.VillagerData.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("TradeTier")) end
        end

        if(IN:contains("Xp", TYPE.INT)) then OUT:addChild(TagInt.new("TradeExperience", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("TradeExperience")) end

        if(required) then OUT:addChild(TagByte.new("RewardPlayersOnFirstFounding", true)) end

    else

        --todo convert trade level

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
                OUT:addChild(TagString.new("PreferredProfession", "farmer"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/farmer_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+farmer"))
                OUT:addChild(TagInt.new("Variant", 1))
            elseif(Career == 2) then
                OUT:addChild(TagString.new("PreferredProfession", "fisherman"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/fisherman_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+fisherman"))
                OUT:addChild(TagInt.new("Variant", 2))
            elseif(Career == 3) then
                OUT:addChild(TagString.new("PreferredProfession", "shepherd"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/shepherd_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+shepherd"))
                OUT:addChild(TagInt.new("Variant", 2))
            elseif(Career == 4) then
                OUT:addChild(TagString.new("PreferredProfession", "fletcher"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/fletcher_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+fletcher"))
                OUT:addChild(TagInt.new("Variant", 3))
            end
        elseif(Profession == 1) then
            if(Career == 1) then
                OUT:addChild(TagString.new("PreferredProfession", "librarian"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/librarian_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+librarian"))
                OUT:addChild(TagInt.new("Variant", 5))
            elseif(Career == 2) then
                OUT:addChild(TagString.new("PreferredProfession", "cartographer"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/cartographer_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+cartographer"))
                OUT:addChild(TagInt.new("Variant", 6))
            end
        elseif(Profession == 2) then
            if(Career == 1) then
                OUT:addChild(TagString.new("PreferredProfession", "cleric"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/cleric_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+cleric"))
                OUT:addChild(TagInt.new("Variant", 7))
            end
        elseif(Profession == 3) then
            if(Career == 1) then
                OUT:addChild(TagString.new("PreferredProfession", "armorer"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/armorer_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+armorer"))
                OUT:addChild(TagInt.new("Variant", 8))
            elseif(Career == 2) then
                OUT:addChild(TagString.new("PreferredProfession", "weaponsmith"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/weapon_smith_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+weaponsmith"))
                OUT:addChild(TagInt.new("Variant", 9))
            elseif(Career == 3) then
                OUT:addChild(TagString.new("PreferredProfession", "toolsmith"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/toolsmith_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+toolsmith"))
                OUT:addChild(TagInt.new("Variant", 10))
            end
        elseif(Profession == 4) then
            if(Career == 1) then
                OUT:addChild(TagString.new("PreferredProfession", "butcher"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/butcher_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+butcher"))
                OUT:addChild(TagInt.new("Variant", 11))
            elseif(Career == 2) then
                OUT:addChild(TagString.new("PreferredProfession", "leatherworker"))
                OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/leather_worker_trades.json"))
                OUT.definitions:addChild(TagString.new("", "+leatherworker"))
                OUT:addChild(TagInt.new("Variant", 12))
            end
        elseif(Profession == 5) then
            if(Career == 1) then
                OUT:addChild(TagString.new("PreferredProfession", "nitwit"))
                OUT.definitions:addChild(TagString.new("", "+nitwit"))
                OUT:addChild(TagInt.new("Variant", 14))
            end
        end

        if(OUT:contains("PreferredProfession", TYPE.STRING) == false) then
            OUT:addChild(TagString.new("PreferredProfession", "none"))
            OUT:addChild(TagInt.new("Variant", 0))
        end
        
        if(required) then OUT:addChild(TagInt.new("MarkVariant")) end
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
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
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
function Entity:ConvertWanderingTrader(IN, OUT, required)
    OUT.def_base = "wandering_trader"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:health", 20, 20, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    if(IN.Attributes.movementSpeed ~= nil) then IN.Attributes.movementSpeed = IN.Attributes.movementSpeed - 0.2 end
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.5, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)

    if(IN:contains("Offers", TYPE.COMPOUND)) then
        IN.Offers = IN.lastFound
        OUT.Offers = OUT:addChild(TagCompound.new("Offers"))

        if(IN.Offers:contains("Recipes", TYPE.STRING)) then
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
                    if(buy:contains("Count", TYPE.BYTE)) then
                        trade_out:addChild(TagInt.new("buyCountA", buy.lastFound.value)) 
                    else trade_out:addChild(TagInt.new("buyCountA", 0)) end
                else goto tradeContinue end

                if(trade_in:contains("buyB", TYPE.COMPOUND)) then
                    local buyB = Item:ConvertItem(trade_in.lastFound, false)
                    if(buyB == nil) then goto tradeContinue end
                    buyB.name = "buyB"
                    trade_out:addChild(buyB)
                    if(buyB:contains("Count", TYPE.BYTE)) then
                        trade_out:addChild(TagInt.new("buyCountB", buyB.lastFound.value)) 
                    else trade_out:addChild(TagInt.new("buyCountB", 0)) end
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

                if(trade_in:contains("priceMultiplier", TYPE.FLOAT)) then
                    trade_out:addChild(TagFloat.new("priceMultiplierA", trade_in.lastFound.value))
                else trade_out:addChild(TagFloat.new("priceMultiplierA", 0)) end
                
                trade_out:addChild(TagFloat.new("priceMultiplierB"))

                if(trade_in:contains("demand", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("demand", (trade_in.lastFound.value + 32)*-1))
                else trade_out:addChild(TagInt.new("demand")) end

                if(trade_in:contains("xp", TYPE.INT)) then
                    trade_out:addChild(TagInt.new("traderExp", trade_in.lastFound.value))
                else trade_out:addChild(TagInt.new("traderExp", 1)) end

                OUT.Offers.Recipes:addChild(trade_out)

                ::tradeContinue::
            end

        end
    end

    if(IN:contains("DespawnDelay", TYPE.INT)) then
        if(IN.lastFound.value ~= 0) then OUT:addChild(TagLong.new("TimeStamp", Settings:getSettingLong("currentTick")+IN.lastFound.value)) end
    end

    if(required) then OUT:addChild(TagString.new("TradeTablePath", "trading/economy_trades/wandering_trader_trades.json")) end

    if(required) then
        OUT.entries = OUT:addChild(TagList.new("entries"))
        local entry = TagCompound.new()
        entry:addChild(TagByte.new("StopSpawning", true))
        entry:addChild(TagInt.new("SpawnTimer", -1))
        OUT.entries:addChild(entry)
    end

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
    OUT = Entity:ConvertBaseRaiding(IN, OUT, required)
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

            if(IN.Health == nil) then
                OUT:addChild(TagInt.new("Phase", 1))
                OUT:addChild(TagByte.new("AirAttack", true))
            elseif(IN.Health < baseHealth/2) then 
                OUT:addChild(TagInt.new("Phase", 0))
                OUT:addChild(TagByte.new("AirAttack"))
            else
                OUT:addChild(TagInt.new("Phase", 1))
                OUT:addChild(TagByte.new("AirAttack", true))
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
function Entity:ConvertZoglin(IN, OUT, required)
    OUT.def_base = "zoglin"
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT.definitions:addChild(TagString.new("", "+minecraft:" .. OUT.def_base))
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    OUT = Entity:AddAttribute(OUT, "minecraft:attack_damage", 3, 3, IN.Attributes.attackDamage)
    OUT = Entity:AddAttribute(OUT, "minecraft:health", 40, 40, IN.Health, IN.Attributes.maxHealth)
    OUT = Entity:AddAttribute(OUT, "minecraft:follow_range", 16, 2048, IN.Attributes.followRange)
    OUT = Entity:AddAttribute(OUT, "minecraft:luck", 0, 1024, IN.Attributes.luck)
    OUT = Entity:AddAttribute(OUT, "minecraft:knockback_resistance", 0.5, 1, IN.Attributes.knockbackResistance)
    OUT = Entity:AddAttribute(OUT, "minecraft:absorption", 0, 16, IN.AbsorptionAmount)
    OUT = Entity:AddAttribute(OUT, "minecraft:movement", 0.25, FLOAT_MAX, IN.Attributes.movementSpeed)
    OUT = Entity:AddAttribute(OUT, "minecraft:underwater_movement", 0.02, FLOAT_MAX)
    OUT = Entity:AddAttribute(OUT, "minecraft:lava_movement", 0.02, FLOAT_MAX)

    if(IN:contains("IsBaby", TYPE.BYTE)) then
        if(IN.lastFound.value == 0) then
            OUT.definitions:addChild(TagString.new("", "+zoglin_adult"))
        elseif(required) then
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+zoglin_baby"))
        end
    elseif(required) then
        OUT.definitions:addChild(TagString.new("", "+zoglin_adult"))
    end

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

    if(IN:contains("Angry", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("IsAngry", IN.lastFound.value ~= 0))

        if(IN.lastFound.value ~= 0) then
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

    local DataVersion = Settings:getSettingInt("DataVersion")

    if(DataVersion >= 1901) then
        --new villager type

        --Bedrock variants:

        --1 farmer
        --2 fisherman
        --3 shepherd
        --4 fletcher
        --5 librarian
        --6 cartographer
        --7 cleric
        --8 armorer
        --9 weaponsmith
        --10 toolsmith
        --11 butcher
        --12 leatherworker
        --13 mason
        --14 nitwit

        --Mark Variant
        --0 plains
        --1 desert
        --2 jungle
        --3 savanna
        --4 snow
        --5 swamp
        --6 taiga

        if(IN:contains("VillagerData", TYPE.COMPOUND)) then
            IN.VillagerData = IN.lastFound

            if(IN.VillagerData:contains("profession", TYPE.STRING)) then
                local profession = IN.VillagerData.lastFound.value
                if(profession:find("^minecraft:")) then profession = profession:sub(11) end

                if(profession == "farmer") then
                    OUT.definitions:addChild(TagString.new("", "+farmer"))
                elseif(profession == "fisherman") then
                    OUT.definitions:addChild(TagString.new("", "+fisherman"))
                elseif(profession == "shepherd") then
                    OUT.definitions:addChild(TagString.new("", "+shepherd"))
                elseif(profession == "fletcher") then
                    OUT.definitions:addChild(TagString.new("", "+fletcher"))
                elseif(profession == "librarian") then
                    OUT.definitions:addChild(TagString.new("", "+librarian"))
                elseif(profession == "cartographer") then
                    OUT.definitions:addChild(TagString.new("", "+cartographer"))
                elseif(profession == "cleric") then
                    OUT.definitions:addChild(TagString.new("", "+cleric"))
                elseif(profession == "armorer") then
                    OUT.definitions:addChild(TagString.new("", "+armorer"))
                elseif(profession == "weaponsmith") then
                    OUT.definitions:addChild(TagString.new("", "+weaponsmith"))
                elseif(profession == "toolsmith") then
                    OUT.definitions:addChild(TagString.new("", "+toolsmith"))
                elseif(profession == "butcher") then
                    OUT.definitions:addChild(TagString.new("", "+butcher"))
                elseif(profession == "leatherworker") then
                    OUT.definitions:addChild(TagString.new("", "+leatherworker"))
                elseif(profession == "mason") then
                    OUT.definitions:addChild(TagString.new("", "+mason"))
                elseif(profession == "nitwit") then
                    OUT.definitions:addChild(TagString.new("", "+nitwit"))
                end
            end

            if(required) then
                OUT:addChild(TagInt.new("Variant"))
                OUT:addChild(TagInt.new("MarkVariant"))
            end
        end

        if(IN:contains("ConversionTime", TYPE.INT)) then
            if(IN.lastFound.value ~= -1) then
                OUT.definitions:addChild(TagString.new("", "+to_villager"))
            end
        end

    else

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
    end

    if(IN:contains("ConversionTime", TYPE.INT)) then
        if(IN.lastFound.value > -1) then
            OUT.definitions:addChild(TagString.new("", "+to_villager"))
        end
    end

    return OUT
end
--
function Entity:ConvertZombifiedPiglin(IN, OUT, required)
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

    if(IN:contains("IsBaby", TYPE.BYTE)) then
        if(IN.lastFound.value ~= -1) then
            OUT:addChild(TagByte.new("IsBaby", true))
            OUT.definitions:addChild(TagString.new("", "+minecraft:pig_zombie_baby"))
        else
            OUT:addChild(TagByte.new("IsBaby"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:pig_zombie_adult"))
        end
    elseif(required) then
        OUT:addChild(TagByte.new("IsBaby"))
        OUT.definitions:addChild(TagString.new("", "+minecraft:pig_zombie_adult"))
    end

    if(IN:contains("Angry", TYPE.BYTE)) then
        OUT:addChild(TagByte.new("IsAngry", IN.lastFound.value ~= 0))

        if(IN.lastFound.value ~= 0) then
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


-----------------------Base functions

function Entity:ConvertUUID(IN, OUT, required)
    if(IN:contains("UUID", TYPE.INT_ARRAY)) then
        if(IN.lastFound:getSize() == 16) then
            IN.UUID = IN.lastFound

            local stringUUID = string.format("%08x", IN.UUID:getInt(0)) .. string.format("%08x", IN.UUID:getInt(4)) .. string.format("%08x", IN.UUID:getInt(8)) .. string.format("%08x", IN.UUID:getInt(12))
            OUT.UniqueID = OUT:addChild(TagLong.new("UniqueID", tonumber("0x" .. stringUUID:sub(1, 16))))
        end
        
    elseif(IN:contains("UUIDMost", TYPE.LONG)) then
        IN.UUIDMost = IN.lastFound.value
        if(IN:contains("UUIDLeast", TYPE.LONG)) then
            IN.UUIDLeast = IN.lastFound.value
            local stringUUID = string.format("%016x", IN.UUIDMost) .. string.format("%016x", IN.UUIDLeast)
            OUT.UniqueID = OUT:addChild(TagLong.new("UniqueID", tonumber("0x" .. stringUUID:sub(1, 16))))
        end
    end

    if(OUT.UniqueID == nil and required) then
        OUT.UniqueID = OUT:addChild(TagLong.new("UniqueID", math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295)))
    end
    return OUT
end

function Entity:ConvertBase(IN, OUT, required)

    OUT.definitions = OUT:addChild(TagList.new("definitions"))

    if(IN:contains("OnGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("OnGround", IN.lastFound.value ~= 0)) end
    if(IN:contains("Invulnerable", TYPE.BYTE)) then OUT:addChild(TagByte.new("Invulnerable", IN.lastFound.value ~= 0)) end
    if(IN:contains("Air", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Air", 300)) end
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
    if(IN:contains("PortalCooldown", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("PortalCooldown")) end
    if(IN:contains("FallDistance", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("FallDistance")) end
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
    if(IN:contains("CustomNameVisible", TYPE.BYTE)) then OUT:addChild(TagByte.new("CustomNameVisible", IN.lastFound.value ~= 0)) end

    Entity:ConvertUUID(IN, OUT, required)

    --No DeathLootTable on bedrock?
    --[[
    if(IN:contains("DeathLootTable", TYPE.STRING)) then
        local lootTable = IN.lastFound.value
        if(lootTable:find("^minecraft:")) then lootTable = lootTable:sub(11) end
        if(Settings:dataTableContains("loot_tables", lootTable)) then
            local entry = Settings.lastFound
            OUT:addChild(TagString.new("DeathLootTable", "loot_tables/" .. entry[1][1]))
        end
    end--]]

    return OUT
end

function Entity:ConvertBaseLiving(IN, OUT, required)
    --if(IN:contains("CanPickUpLoot", TYPE.BYTE)) then OUT:addChild(TagByte.new("CanPickUpLoot", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("CanPickUpLoot")) end
    --if(IN:contains("FallFlying", TYPE.BYTE)) then OUT:addChild(TagByte.new("FallFlying", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("FallFlying")) end
    --if(IN:contains("Leashed", TYPE.BYTE)) then OUT:addChild(TagByte.new("Leashed", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Leashed")) end
    --if(IN:contains("LeftHanded", TYPE.BYTE)) then OUT:addChild(TagByte.new("LeftHanded", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("LeftHanded")) end
    if(IN:contains("PersistenceRequired", TYPE.BYTE)) then OUT:addChild(TagByte.new("Persistent", IN.lastFound.value ~= 0)) end
    --if(IN:contains("NoAI", TYPE.BYTE)) then OUT:addChild(TagByte.new("NoAI", IN.lastFound.value ~= 0)) end
    if(IN:contains("DeathTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) end
    if(IN:contains("HurtTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) end
    --if(IN:contains("HurtByTimestamp", TYPE.SHORT)) then OUT:addChild(TagInt.new("HurtByTimestamp", IN.lastFound.value)) elseif(required) then OUT:addChild(TagInt.new("HurtByTimestamp")) end
    if(Settings:getSettingInt("DataVersion") < 169) then
        if(IN:contains("Health", TYPE.SHORT)) then IN.Health = IN.lastFound.value end
    else
        if(IN:contains("Health", TYPE.FLOAT)) then IN.Health = IN.lastFound.value end
    end
    if(IN:contains("AbsorptionAmount", TYPE.FLOAT)) then IN.AbsorptionAmount = IN.lastFound.value end

    if(IN:contains("Leash", TYPE.COMPOUND)) then
        IN.Leash = IN.lastFound

        --check for UUID
        if(IN.Leash:contains("UUIDMost", TYPE.LONG)) then
            IN.Leash.UUIDMost = IN.Leash.lastFound.value
            if(IN.Leash:contains("UUIDLeast", TYPE.LONG)) then
                IN.Leash.UUIDLeast = IN.Leash.lastFound.value
                local stringUUID = string.format("%016x", IN.Leash.UUIDMost) .. string.format("%016x", IN.Leash.UUIDLeast)

                OUT.LeasherID = OUT:addChild(TagLong.new("LeasherID", tonumber("0x" .. stringUUID:sub(1, 16))))
            end
        end

        --No UUID found, check for fence coords
        if(OUT.LeasherID == nil) then
            if(IN.Leash:contains("X", TYPE.INT)) then IN.Leash.X = IN.Leash.lastFound.value end
            if(IN.Leash:contains("Y", TYPE.INT)) then IN.Leash.Y= IN.Leash.lastFound.value end
            if(IN.Leash:contains("Z", TYPE.INT)) then IN.Leash.Z = IN.Leash.lastFound.value end

            if(IN.Leash.X ~= nil and IN.Leash.Y ~= nil and IN.Leash.Z ~= nil) then

                --Create new leash_knot entity
                local L_OUT = TagCompound.new()

                L_OUT.Motion = L_OUT:addChild(TagList.new("Motion"))
                L_OUT.Motion:addChild(TagFloat.new("", 0))
                L_OUT.Motion:addChild(TagFloat.new("", 0))
                L_OUT.Motion:addChild(TagFloat.new("", 0))
            
                L_OUT.Rotation = L_OUT:addChild(TagList.new("Rotation"))
                L_OUT.Rotation:addChild(TagFloat.new("", 0))
                L_OUT.Rotation:addChild(TagFloat.new("", 0))
            
                L_OUT.Pos = L_OUT:addChild(TagList.new("Pos"))
                L_OUT.Pos:addChild(TagFloat.new("", IN.Leash.X + 0.5))
                L_OUT.Pos:addChild(TagFloat.new("", IN.Leash.Y + 0.25))
                L_OUT.Pos:addChild(TagFloat.new("", IN.Leash.Z + 0.5))

                L_OUT:addChild(TagString.new("identifier", "minecraft:leash_knot"))

                L_OUT.UniqueID = L_OUT:addChild(TagLong.new("UniqueID", math.random(0, 4294967295)+(math.random(0, 4294967295)*4294967295)))

                OUT.LeasherID = OUT:addChild(TagLong.new("LeasherID", L_OUT.UniqueID.value))

                IN.Entities_output_ref:addChild(L_OUT)
            end
        end
    end

    if(Settings:getSettingInt("DataVersion") < 169) then
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
        end
    else
        if(IN:contains("ArmorItems", TYPE.LIST, TYPE.COMPOUND)) then
            IN.ArmorItems = IN.lastFound
            if(IN.ArmorItems.childCount == 4) then
                OUT.Armor = OUT:addChild(TagList.new("Armor"))
    
                for i=0, 3 do
                    local item = Item:ConvertItem(IN.ArmorItems:child(3-i), false)
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

            OUT.ActiveEffects:addChild(effect_out)

            ::effectContinue::
        end

        if(OUT.ActiveEffects.childCount == 0) then
            OUT:removeChild(OUT.ActiveEffects:getRow())
            OUT.ActiveEffects = nil
        end
    end

    OUT.Attributes = OUT:addChild(TagList.new("Attributes"))

    if(IN:contains("Attributes", TYPE.LIST, TYPE.COMPOUND)) then IN.Attributes = IN.lastFound end
    if(IN.Attributes ~= nil) then
        for i=0, IN.Attributes.childCount-1 do
            local attr = IN.Attributes:child(i)
            if(attr:contains("Base", TYPE.DOUBLE)) then attr.Base = attr.lastFound.value else goto attrContinue end
            if(attr:contains("Name", TYPE.STRING)) then
                attr.Name = attr.lastFound.value
            else goto attrContinue end
            --if(attr:contains("Modifiers", TYPE.LIST, TYPE.COMPOUND)) then attr.Modifiers = attr.lastFound end

            if(attr.Name == "generic.maxHealth" or attr.Name == "minecraft:generic.max_health") then IN.Attributes.maxHealth = attr.Base
            elseif(attr.Name == "generic.followRange"  or attr.Name == "minecraft:generic.follow_range") then IN.Attributes.followRange = attr.Base
            elseif(attr.Name == "generic.knockbackResistance"  or attr.Name == "minecraft:generic.knockback_resistance") then IN.Attributes.knockbackResistance = attr.Base
            elseif(attr.Name == "generic.movementSpeed"  or attr.Name == "minecraft:generic.movement_speed") then IN.Attributes.movementSpeed = attr.Base
            elseif(attr.Name == "generic.attackDamage"  or attr.Name == "minecraft:generic.attack_damage") then IN.Attributes.attackDamage = attr.Base
            elseif(attr.Name == "generic.attackSpeed"  or attr.Name == "minecraft:generic.attack_speed") then IN.Attributes.attackSpeed = attr.Base
            elseif(attr.Name == "generic.luck"  or attr.Name == "minecraft:generic.luck") then IN.Attributes.luck = attr.Base
            elseif(attr.Name == "generic.armor"  or attr.Name == "minecraft:generic.armor") then IN.Attributes.armor = attr.Base
            elseif(attr.Name == "generic.armorToughness"  or attr.Name == "minecraft:generic.armor_toughness") then IN.Attributes.armorToughness = attr.Base
            elseif(attr.Name == "generic.attackKnockback"  or attr.Name == "minecraft:generic.attack_knockback") then IN.Attributes.attackKnockback = attr.Base
            elseif(attr.Name == "generic.flyingSpeed"  or attr.Name == "minecraft:generic.flying_speed") then IN.Attributes.flyingSpeed = attr.Base
            elseif(attr.Name == "horse.jumpStrength"  or attr.Name == "minecraft:horse.jump_strength") then IN.Attributes.horse_jumpStrength = attr.Base
            elseif(attr.Name == "zombie.spawnReinforcements"  or attr.Name == "minecraft:zombie.spawn_reinforcements") then IN.Attributes.zombie_spawnReinforcements = attr.Base
            end
            ::attrContinue::
        end
    end

    if(IN.Attributes == nil) then IN.Attributes = TagList.new("Attributes") end

    return OUT
end

function Entity:ConvertBaseBreedable(IN, OUT, required)
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

function Entity:ConvertBaseProjectile(IN, OUT, required)

    local inGround = false
    if(IN:contains("inGround", TYPE.BYTE)) then
        inGround = true
        OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0))
    elseif(required) then
        OUT:addChild(TagByte.new("inGround"))
    end

    OUT.StuckToBlockPos = OUT:addChild(TagList.new("StuckToBlockPos"))
    OUT.StuckToBlockPos:addChild(TagInt.new())
    OUT.StuckToBlockPos:addChild(TagInt.new())
    OUT.StuckToBlockPos:addChild(TagInt.new())

    if(inGround) then
        if(IN:contains("xTile", TYPE.INT)) then OUT.StuckToBlockPos:child(0).value = IN.lastFound.value end
        if(IN:contains("yTile", TYPE.INT)) then OUT.StuckToBlockPos:child(1).value = IN.lastFound.value end
        if(IN:contains("zTile", TYPE.INT)) then OUT.StuckToBlockPos:child(2).value = IN.lastFound.value end
    end

    OUT.CollisionPos = OUT:addChild(TagList.new("CollisionPos"))
    OUT.CollisionPos:addChild(TagFloat.new())
    OUT.CollisionPos:addChild(TagFloat.new())
    OUT.CollisionPos:addChild(TagFloat.new())

    if(inGround) then
        OUT.CollisionPos:child(0).value = OUT.Pos:child(0).value
        OUT.CollisionPos:child(1).value = OUT.Pos:child(1).value
        OUT.CollisionPos:child(2).value = OUT.Pos:child(2).value
    end

    --BEDROCK
    --inGround byte
    --StuckToBlockPos (list of ints)
    --CollisionPos (list of floats)
    --IsGlobal (byte 1)
    --shake byte

    --JAVA
    --owner (L and M)
    --inGround byte
    --shake byte
    --x y z Tile int default -1
    
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

function Entity:ConvertBaseHorse(IN, OUT, required)

    --all horses should become wild

    --[[
    if(IN:contains("Tame", TYPE.BYTE)) then OUT:addChild(TagByte.new("IsTamed", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("IsTamed")) end
    if(IN:contains("Temper", TYPE.INT)) then
        local Temper = IN.lastFound.value
        if(IN.lastFound.value < 0 or IN.lastFound.value > 100) then Temper = 0 end
        OUT:addChild(TagInt.new("Temper", Temper))
    elseif(required) then OUT:addChild(TagInt.new("Temper")) end

    --TODO EatingHaystack and Bred?
    --]]

    return OUT
end

function Entity:ConvertBaseZombie(IN, OUT, required)
    
    if(IN:contains("InWaterTime", TYPE.INT)) then IN.InWaterTime = IN.lastFound.value else IN.InWaterTime = -1 end
    if(IN:contains("DrownedConversionTime", TYPE.INT)) then IN.DrownedConversionTime = IN.lastFound.value else IN.DrownedConversionTime = -1 end

    if(IN.InWaterTime > -1) then
        if(IN.DrownedConversionTime > -1) then
            OUT.definitions:addChild(TagString.new("", "-minecraft:start_drowned_transformation"))
            OUT.definitions:addChild(TagString.new("", "+minecraft:convert_to_drowned"))
        else
            OUT.definitions:addChild(TagString.new("", "+minecraft:start_drowned_transformation"))
            OUT:addChild(TagLong.new("TimeStamp", Settings:getSettingLong("currentTick")+600-IN.InWaterTime))
        end
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