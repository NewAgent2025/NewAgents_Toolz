Entity = {}
Item = Item or require("item")

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

    if(IN.Motion ~= nil) then OUT:addChild(IN.Motion:clone()) end
    if(IN.Rotation ~= nil) then OUT:addChild(IN.Rotation:clone()) end
    if(IN.Pos ~= nil) then
        OUT.Pos = OUT:addChild(TagList.new("Pos"))
        OUT.Pos:addChild(TagDouble.new("", IN.Pos:child(0).value - (Settings:getSettingInt("ChunkOffsetX")*16)))
        OUT.Pos:addChild(TagDouble.new("", IN.Pos:child(1).value))
        OUT.Pos:addChild(TagDouble.new("", IN.Pos:child(2).value - (Settings:getSettingInt("ChunkOffsetZ")*16)))
    end 

    if(Settings:dataTableContains("entities", id)) then
        local entry = Settings.lastFound
        OUT:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
        if(tostring(entry[1][3]) == "TRUE") then OUT.Spawnable = true else OUT.Spawnable = false end
        OUT = Entity[entry[1][2]](Entity, IN, OUT, required)
        if(OUT == nil) then return nil end
    else return nil end

    if(IN:contains("Riding", TYPE.COMPOUND)) then
        --Legacy
        IN.Riding = IN.lastFound

        local ridingEntity = Entity:ConvertEntity(IN.Riding, true)
        if(ridingEntity ~= nil) then
            if(ridingEntity:contains("Riding", TYPE.LIST, TYPE.COMPOUND)) then ridingEntity.Riding = ridingEntity.lastFound else ridingEntity.Riding = ridingEntity:addChild(TagList.new("Riding")) end
            ridingEntity.Riding:addChild(OUT)
            OUT = ridingEntity
            OUT.Spawnable = false
        end
    elseif(IN:contains("Passengers", TYPE.LIST, TYPE.COMPOUND)) then
        --Normal
        IN.Passengers = IN.lastFound
        OUT.Riding = OUT:addChild(TagList.new("Riding"))

        for i=0, IN.Passengers.childCount-1 do
            local passenger_in = IN.Passengers:child(i)
            local passenger_out = TagCompound.new()
            passenger_out = Entity:ConvertEntity(passenger_in, true)
            if(passenger_out ~= nil) then OUT.Riding:addChild(passenger_out) end
        end

        if(OUT.Riding.childCount == 0) then
            OUT:removeChild(OUT.Riding:getRow())
            OUT.Riding = nil
        else
            OUT.Spawnable = false
        end
    end

    return OUT
end

function Entity:ConvertAreaEffectCloud(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Duration", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Duration", 600)) end
    if(IN:contains("DurationOnUse", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("DurationOnUse")) end
    if(IN:contains("ReapplicationDelay", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ReapplicationDelay", 20)) end
    if(IN:contains("WaitTime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("WaitTime", 10)) end

    if(IN:contains("Radius", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("Radius", 3)) end
    if(IN:contains("RadiusOnUse", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("RadiusOnUse", -0.5)) end
    if(IN:contains("RadiusPerTick", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("RadiusPerTick", -0.005)) end

    if(IN:contains("Potion", TYPE.STRING)) then
        local potionName = IN.lastFound.value
        if(potionName:find("^minecraft:")) then potionName = potionName:sub(11) end

        if(Settings:dataTableContains("potions", potionName)) then
            OUT.Potion = OUT:addChild(TagString.new("Potion", "minecraft:" .. potionName))
        end

    end

    if(OUT.Potion == nil) then OUT:addChild(TagString.new("Potion", "minecraft:water")) end

    if(IN:contains("Effects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Effects = IN.lastFound
        OUT.Effects = OUT:addChild(TagList.new("Effects"))

        for i=0, IN.Effects.childCount-1 do
            local effect_in = IN.Effects:child(i)
            local effect_out = TagCompound.new()

            if(effect_in:contains("Id", TYPE.BYTE)) then
                if(effect_in.lastFound.value > 0 and effect_in.lastFound.value <= 30) then effect_out:addChild(effect_in.lastFound:clone()) end
            else goto effectContinue end

            if(effect_in:contains("ShowParticles", TYPE.BYTE)) then effect_out:addChild(TagByte.new("ShowParticles", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("ShowParticles", true)) end
            if(effect_in:contains("Ambient", TYPE.BYTE)) then effect_out:addChild(TagByte.new("Ambient", effect_in.lastFound.value ~= 0)) else effect_out:addChild(TagByte.new("Ambient")) end
            if(effect_in:contains("Amplifier", TYPE.BYTE)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagByte.new("Amplifier")) end
            if(effect_in:contains("Duration", TYPE.INT)) then effect_out:addChild(effect_in.lastFound:clone()) else effect_out:addChild(TagInt.new("Duration", 1)) end

            OUT.Effects:addChild(effect_out)

            ::effectContinue::
        end

        if(OUT.Effects.childCount == 0) then
            OUT:removeChild(OUT.Effects:getRow())
            OUT.Effects = nil
        end
    end

    --TODO particle effect

    return OUT
end

function Entity:ConvertArmorStand(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Invisible", TYPE.BYTE)) then OUT:addChild(TagByte.new("Invisible", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Invisible")) end
    if(IN:contains("NoBasePlate", TYPE.BYTE)) then OUT:addChild(TagByte.new("NoBasePlate", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("NoBasePlate")) end
    if(IN:contains("Small", TYPE.BYTE)) then OUT:addChild(TagByte.new("Small", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Small")) end
    if(IN:contains("Marker", TYPE.BYTE)) then OUT:addChild(TagByte.new("Marker", IN.lastFound.value ~= 0)) end
    if(IN:contains("FallFlying", TYPE.BYTE)) then OUT:addChild(TagByte.new("FallFlying", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("FallFlying")) end

    --TODO check chunk version and convert equipment instead

    if(IN:contains("ArmorItems", TYPE.LIST, TYPE.COMPOUND)) then
        IN.ArmorItems = IN.lastFound
        if(IN.ArmorItems.childCount == 4) then
            OUT.ArmorItems = OUT:addChild(TagList.new("ArmorItems"))

            for i=0, 3 do
                local item = Item:ConvertItem(IN.ArmorItems:child(i), false)
                if(item ~= nil) then OUT.ArmorItems:addChild(item) else OUT.ArmorItems:addChild(TagCompound.new()) end
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
    
    if(IN:contains("HandItems", TYPE.LIST, TYPE.COMPOUND)) then
        IN.HandItems = IN.lastFound
        if(IN.HandItems.childCount == 2) then
            OUT.HandItems = OUT:addChild(TagList.new("HandItems"))

            for i=0, 1 do
                local item = Item:ConvertItem(IN.HandItems:child(i), false)
                if(item ~= nil) then OUT.HandItems:addChild(item) else OUT.HandItems:addChild(TagCompound.new()) end
            end
        end
    end
    if(required and OUT.HandItems == nil) then
        OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
        OUT.HandItems:addChild(TagCompound.new())
        OUT.HandItems:addChild(TagCompound.new())
    end

    if(IN:contains("ActiveEffects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.ActiveEffects = IN.lastFound
        OUT.ActiveEffects = OUT:addChild(TagList.new("ActiveEffects"))

        for i=0, IN.ActiveEffects.childCount-1 do
            local effect_in = IN.ActiveEffects:child(i)
            local effect_out = TagCompound.new()

            if(effect_in:contains("Id", TYPE.BYTE)) then
                if(effect_in.lastFound.value > 0 and effect_in.lastFound.value <= 30) then effect_out:addChild(effect_in.lastFound:clone()) end
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

    --TODO disabledslots

    return OUT
end

function Entity:ConvertArrow(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end
    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end
    if(IN:contains("crit", TYPE.BYTE)) then OUT:addChild(TagByte.new("crit", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("crit")) end
    if(IN:contains("pickup", TYPE.BYTE)) then
        local pickup = IN.lastFound.value
        if(pickup < 0 or pickup > 2) then pickup = 1 end
        OUT:addChild(TagByte.new("pickup", pickup))
    elseif(required) then OUT:addChild(TagByte.new("pickup", 1)) end
    if(IN:contains("life", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("life")) end

    if(IN:contains("Potion", TYPE.STRING)) then
        local potionName = IN.lastFound.value
        if(potionName:find("^minecraft:")) then potionName = potionName:sub(11) end

        if(Settings:dataTableContains("potions", potionName)) then
            OUT.Potion = OUT:addChild(TagString.new("Potion", "minecraft:" .. potionName))
        end

        if(OUT.Potion == nil) then OUT:addChild(TagString.new("Potion", "minecraft:empty")) end
    end

    if(IN:contains("CustomPotionEffects", TYPE.LIST, TYPE.COMPOUND)) then
        IN.CustomPotionEffects = IN.lastFound
        OUT.CustomPotionEffects = OUT:addChild(TagList.new("CustomPotionEffects"))

        for i=0, IN.CustomPotionEffects.childCount-1 do
            local effect_in = IN.CustomPotionEffects:child(i)
            local effect_out = TagCompound.new()

            if(effect_in:contains("Id", TYPE.BYTE)) then
                if(effect_in.lastFound.value > 0 and effect_in.lastFound.value <= 30) then effect_out:addChild(effect_in.lastFound:clone()) end
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


    --TODO damage turned into enchantPower?

    return OUT
end

function Entity:ConvertBat(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("BatFlags", TYPE.BYTE)) then OUT:addChild(TagByte.new("BatFlags", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("BatFlags")) end

    return OUT
end

function Entity:ConvertBlaze(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertBoat(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Type", TYPE.STRING)) then
        local Type = IN.lastFound.value

        if(Type == "oak") then OUT:addChild(TagByte.new("Type", 0))
        elseif(Type == "spruce") then OUT:addChild(TagByte.new("Type", 1))
        elseif(Type == "birch") then OUT:addChild(TagByte.new("Type", 2))
        elseif(Type == "jungle") then OUT:addChild(TagByte.new("Type", 3))
        elseif(Type == "acacia") then OUT:addChild(TagByte.new("Type", 4))
        elseif(Type == "dark_oak") then OUT:addChild(TagByte.new("Type", 5))
        else OUT:addChild(TagByte.new("Type", 0))
        end

    elseif(required) then OUT:addChild(TagByte.new("Type")) end

    return OUT
end

function Entity:ConvertBottleOEnchanting(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end
    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

    return OUT
end

function Entity:ConvertCaveSpider(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertChicken(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("IsChickenJockey", TYPE.BYTE)) then OUT:addChild(TagByte.new("IsChickenJockey", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("IsChickenJockey")) end
    if(IN:contains("EggLayTime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("EggLayTime")) end

    return OUT
end

function Entity:ConvertCod(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertCow(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    return nil
end

function Entity:ConvertCreeper(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("powered", TYPE.BYTE)) then OUT:addChild(TagByte.new("powered", IN.lastFound.value ~= 0)) end
    if(IN:contains("ExplosionRadius", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("ExplosionRadius", 3)) end
    if(IN:contains("ignited", TYPE.BYTE)) then OUT:addChild(TagByte.new("ignited", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("ignited")) end
    if(IN:contains("Fuse", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Fuse", 30)) end

    return OUT
end

function Entity:ConvertDolphin(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Moistness", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Moistness", 2400)) end

    return OUT
end

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

function Entity:ConvertDragonFireball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagByte.new("inGround")) end

    if(IN:contains("direction", TYPE.LIST, TYPE.DOUBLE)) then
        if(IN.lastFound.childCount == 3) then OUT.direction = OUT:addChild(IN.lastFound) end
    end

    if(OUT.direction == nil) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
    end

    if(IN:contains("power", TYPE.LIST, TYPE.DOUBLE)) then
        if(IN.lastFound.childCount == 3) then OUT.power = OUT:addChild(IN.lastFound) end
    end

    if(OUT.power == nil) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
    end

    if(IN:contains("life", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("life")) end

    return OUT
end

function Entity:ConvertDrowned(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertEgg(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end
    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

    return OUT
end

function Entity:ConvertElderGuardian(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertEnderCrystal(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("ShowBottom", TYPE.BYTE)) then OUT:addChild(TagByte.new("ShowBottom", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("ShowBottom", true)) end
    
    if(IN:contains("BeamTarget", TYPE.COMPOUND)) then 
        IN.BeamTarget = IN.lastFound
        OUT.BeamTarget = OUT:addChild(TagCompound.new("BeamTarget"))

        if(IN.BeamTarget:contains("X", TYPE.INT)) then OUT.BeamTarget:addChild(IN.BeamTarget.lastFound:clone()) else OUT.BeamTarget:addChild(TagInt.new("X")) end
        if(IN.BeamTarget:contains("Y", TYPE.INT)) then OUT.BeamTarget:addChild(IN.BeamTarget.lastFound:clone()) else OUT.BeamTarget:addChild(TagInt.new("Y")) end
        if(IN.BeamTarget:contains("Z", TYPE.INT)) then OUT.BeamTarget:addChild(IN.BeamTarget.lastFound:clone()) else OUT.BeamTarget:addChild(TagInt.new("Z")) end
    end

    return OUT
end

function Entity:ConvertEnderman(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("carriedBlockState", TYPE.COMPOUND)) then
        IN.inBlockState = IN.lastFound
        if(IN.inBlockState:contains("Name", TYPE.STRING)) then
            IN.inBlockState.Name = IN.inBlockState.lastFound.value
            if(IN.inBlockState.Name:find("^minecraft:")) then IN.inBlockState.Name = IN.inBlockState.Name:sub(11) end
            if(Settings:dataTableContains("blocks_states", IN.inBlockState.Name)) then
                local entry = Settings.lastFound
                local DataVersion = Settings:getSettingInt("DataVersion")
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                    OUT.outTile = OUT:addChild(TagString.new("carried", "minecraft:" .. subEntry[5]))
                    if(subEntry[4]:len() > 0) then OUT.outData = OUT:addChild(TagShort.new("carriedData", tonumber(subEntry[4]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    elseif(IN:contains("carried", TYPE.STRING)) then
        IN.inTile = IN.lastFound.value
        if(IN:contains("carriedData", TYPE.SHORT)) then
            IN.inData = IN.lastFound.value

            if(IN.inTile:find("^minecraft:")) then IN.inTile = IN.inTile:sub(11) end
            if(Settings:dataTableContains("blocks_names", IN.inTile)) then
                local entry = Settings.lastFound
                local DataVersion = Settings:getSettingInt("DataVersion")
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                    if(subEntry[2]:len() > 0) then if(tonumber(subEntry[2]) > IN.inData) then goto entryContinue end end
                    OUT.outTile = OUT:addChild(TagString.new("carried", "minecraft:" .. subEntry[5]))
                    if(subEntry[4]:len() > 0) then OUT.outData = OUT:addChild(TagShort.new("carriedData", tonumber(subEntry[4]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    end

    if(OUT.outTile == nil) then OUT:addChild(TagString.new("carried", "minecraft:air")) end
    if(OUT.outData == nil) then OUT:addChild(TagShort.new("carriedData", 0)) end

    return OUT
end

function Entity:ConvertEndermite(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("PlayerSpawned", TYPE.BYTE)) then OUT:addChild(TagByte.new("PlayerSpawned", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("PlayerSpawned")) end
    if(IN:contains("Lifetime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Lifetime")) end

    return OUT
end

function Entity:ConvertEnderPearl(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end
    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

    return OUT
end

function Entity:ConvertEvoker(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("SpellTicks", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("SpellTicks")) end

    return OUT
end

function Entity:ConvertEvokerFangs(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Warmup", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Warmup")) end

    return OUT
end

function Entity:ConvertExperienceOrb(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Age", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Age")) end
    if(IN:contains("Health", TYPE.SHORT)) then OUT:addChild(TagShort.new("Health", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("Health", 5)) end
    if(IN:contains("Value", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Value", 3)) end

    return OUT
end

function Entity:ConvertEyeOfEnder(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertFallingBlock(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("DropItem", TYPE.BYTE)) then OUT:addChild(TagByte.new("DropItem", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("DropItem", true)) end
    if(IN:contains("HurtEntities", TYPE.BYTE)) then OUT:addChild(TagByte.new("HurtEntities", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("HurtEntities", true)) end
    if(IN:contains("FallHurtMax", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("FallHurtMax", 40)) end
    if(IN:contains("Time", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Time")) end
    if(IN:contains("FallHurtAmount", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("FallHurtAmount", 2.0)) end

    if(IN:contains("BlockState", TYPE.COMPOUND)) then
        IN.inBlockState = IN.lastFound
        if(IN.inBlockState:contains("Name", TYPE.STRING)) then
            IN.inBlockState.Name = IN.inBlockState.lastFound.value
            if(IN.inBlockState.Name:find("^minecraft:")) then IN.inBlockState.Name = IN.inBlockState.Name:sub(11) end
            if(Settings:dataTableContains("blocks_states", IN.inBlockState.Name)) then
                local entry = Settings.lastFound
                local DataVersion = Settings:getSettingInt("DataVersion")
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                    OUT.outTile = OUT:addChild(TagString.new("Block", "minecraft:" .. subEntry[5]))
                    if(subEntry[4]:len() > 0) then OUT.outData = OUT:addChild(TagByte.new("Data", tonumber(subEntry[4]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    elseif(IN:contains("Block", TYPE.STRING)) then
        IN.inTile = IN.lastFound.value
        if(IN:contains("Data", TYPE.BYTE)) then
            IN.inData = IN.lastFound.value

            if(IN.inTile:find("^minecraft:")) then IN.inTile = IN.inTile:sub(11) end
            if(Settings:dataTableContains("blocks_names", IN.inTile)) then
                local entry = Settings.lastFound
                local DataVersion = Settings:getSettingInt("DataVersion")
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                    if(subEntry[2]:len() > 0) then if(tonumber(subEntry[2]) > IN.inData) then goto entryContinue end end
                    OUT.outTile = OUT:addChild(TagString.new("Block", "minecraft:" .. subEntry[5]))
                    if(subEntry[4]:len() > 0) then OUT.outData = OUT:addChild(TagByte.new("Data", tonumber(subEntry[4]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    end

    if(OUT.outTile == nil) then OUT:addChild(TagString.new("Block", "minecraft:air")) end
    if(OUT.outData == nil) then OUT:addChild(TagByte.new("Data", 0)) end

    return OUT
end

function Entity:ConvertFireball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagByte.new("inGround")) end

    if(IN:contains("direction", TYPE.LIST, TYPE.DOUBLE)) then
        if(IN.lastFound.childCount == 3) then OUT.direction = OUT:addChild(IN.lastFound) end
    end

    if(OUT.direction == nil) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
    end

    if(IN:contains("power", TYPE.LIST, TYPE.DOUBLE)) then
        if(IN.lastFound.childCount == 3) then OUT.power = OUT:addChild(IN.lastFound) end
    end

    if(OUT.power == nil) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
    end

    if(IN:contains("life", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("life")) end
    if(IN:contains("ExplosionPower", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ExplosionPower", 1)) end

    return OUT
end

function Entity:ConvertFireworkRocket(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Life", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Life")) end
    if(IN:contains("LifeTime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("LifeTime", 20)) end

    if(IN:contains("FireworksItem", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "FireworksItem"
            OUT:addChild(item)
        end
    end

    return OUT
end

function Entity:ConvertGhast(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("ExplosionPower", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ExplosionPower", 1)) end

    return OUT
end

function Entity:ConvertGiant(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertGuardian(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertHorse(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Variant", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Variant", 0)) end

    --TODO legacy horse type support

    return OUT
end

function Entity:ConvertHusk(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertIronGolem(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("PlayerCreated", TYPE.BYTE)) then OUT:addChild(TagByte.new("PlayerCreated", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("PlayerCreated")) end

    return OUT
end

function Entity:ConvertItemDrop(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Age", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Age")) end
    if(IN:contains("Health", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Health", 5)) end
    if(IN:contains("PickupDelay", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("PickupDelay")) end

    if(IN:contains("Item", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "Item"
            OUT:addChild(item)
        else return nil end
    else return nil end

    return OUT
end

function Entity:ConvertItemFrame(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    --this is what side of the block it's on
    --Tile coords is the air space the item frame is in
    --Console: Facing 0 south, 1 west, 2 north, 3 east
    --Java: Facing, 0 bottom, 1 top, 2 north, 3 south, 4 west, 5 east

    --TODO verify these values
    if(IN:contains("Facing", TYPE.BYTE)) then
        local Facing = IN.lastFound.value

        local DataVersion = Settings:getSettingInt("DataVersion")

        if(DataVersion > 1457) then
            if(Facing == 2) then OUT:addChild(TagByte.new("Facing", 2))
            elseif(Facing == 3) then OUT:addChild(TagByte.new("Facing", 0))
            elseif(Facing == 4) then OUT:addChild(TagByte.new("Facing", 1))
            elseif(Facing == 5) then OUT:addChild(TagByte.new("Facing", 3))
            else return nil end
        else
            if(Facing == 0) then OUT:addChild(TagByte.new("Facing", 2))
            elseif(Facing == 1) then OUT:addChild(TagByte.new("Facing", 1))
            elseif(Facing == 2) then OUT:addChild(TagByte.new("Facing", 0))
            elseif(Facing == 3) then OUT:addChild(TagByte.new("Facing", 3))
            else return nil end
        end

        if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
        if(IN:contains("TileY", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then return nil end
        if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
    elseif(IN:contains("Direction", TYPE.BYTE)) then
        --JAVA Direction
        --north 2 Direction
        --east 3
        --south 0
        --west 1 
        --tile is block it's hanging on
        local Direction = IN.lastFound.value
        if(Direction == 1) then
            --west
            OUT:addChild(TagByte.new("Facing", 1))
            if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value+1 - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
            if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
        elseif(Direction == 2) then
            --north
            OUT:addChild(TagByte.new("Facing", 0))
            if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
            if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value-1 - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
        elseif(Direction == 3) then
            --east
            OUT:addChild(TagByte.new("Facing", 3))
            if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value-1 - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
            if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
        elseif(Direction == 0) then
            --south
            OUT:addChild(TagByte.new("Facing", 2))
            if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
            if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value+1 - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
        else return nil end
        if(IN:contains("TileY", TYPE.INT)) then OUT:addChild(TagInt.new("TileY", IN.lastFound.value)) elseif(required) then return nil end
    elseif(required) then return nil end

    if(IN:contains("ItemRotation", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("ItemRotation")) end
    if(IN:contains("ItemDropChance", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("ItemDropChance", 1.0)) end

    if(IN:contains("Item", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "Item"
            OUT:addChild(item)
        end
    end

    return OUT
end

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

    if(IN:contains("DecorItem", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "DecorItem"
            OUT:addChild(item)
        end
    end
    
    return OUT
end

function Entity:ConvertMagmaCube(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("wasOnGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("wasOnGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("wasOnGround", true)) end
    if(IN:contains("Size", TYPE.INT)) then
        local Size = IN.lastFound.value
        if(IN.lastFound.value < 0) then Size = 0 end
        OUT:addChild(TagInt.new("Size", Size))
    elseif(required) then OUT:addChild(TagInt.new("Size")) end

    return OUT
end

function Entity:ConvertMinecart(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertMinecartChest(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    Entity:ConvertItems(IN, OUT, required)

    return OUT
end

function Entity:ConvertMinecartHopper(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Enabled", TYPE.BYTE)) then OUT:addChild(TagByte.new("Enabled", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Enabled", true)) end
    if(IN:contains("TransferCooldown", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("TransferCooldown")) end

    Entity:ConvertItems(IN, OUT, required)

    return OUT
end

function Entity:ConvertMinecartFurnace(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Fuel", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Fuel")) end
    if(IN:contains("PushX", TYPE.DOUBLE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagDouble.new("PushX")) end
    if(IN:contains("PushZ", TYPE.DOUBLE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagDouble.new("PushZ")) end

    return OUT
end

function Entity:ConvertMinecartSpawner(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

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

        local SpawnData = Entity:ConvertEntity(SpawnData, false)
        if(SpawnData ~= nil) then

            if(SpawnData.Spawnable) then
                SpawnData.name = "SpawnData"
                OUT.SpawnData = OUT:addChild(SpawnData)
            end
        end
    end

    if(IN:contains("SpawnPotentials", TYPE.LIST, TYPE.COMPOUND)) then
        IN.SpawnPotentials = IN.lastFound
        OUT.SpawnPotentials = OUT:addChild(TagList.new("SpawnPotentials"))
        if(OUT.SpawnData == nil) then OUT:addChild(TagCompound.new("SpawnData")) end
        for i=0, IN.SpawnPotentials.childCount-1 do
            local spawnPotential_in = IN.SpawnPotentials:child(i)
            local spawnPotential_out = TagCompound.new()
            if(spawnPotential_in:contains("Weight", TYPE.INT)) then spawnPotential_out:addChild(spawnPotential_in.lastFound:clone()) elseif(required) then spawnPotential_out:addChild(TagInt.new("Weight", 1)) end
            
            if(spawnPotential_in:contains("Entity", TYPE.COMPOUND)) then
                local Entity_out = Entity:ConvertEntity(spawnPotential_in.lastFound, false)
                if(Entity_out ~= nil) then
                    if(Entity_out.Spawnable == false) then goto spawnPotentialContinue end

                    Entity_out.name = "Entity"
                    spawnPotential_out:addChild(Entity_out)
                else goto spawnPotentialContinue end
            elseif(spawnPotential_in:contains("Properties", TYPE.COMPOUND) and spawnPotential_in:contains("Type", TYPE.STRING)) then
                --Legacy
                if(spawnPotential_in:contains("Properties", TYPE.COMPOUND)) then
                    spawnPotential_in.Properties = spawnPotential_in.lastFound
                    if(spawnPotential_in:contains("Type", TYPE.STRING)) then
                        spawnPotential_in.Properties:addChild(TagString.new("id", spawnPotential_in.lastFound.value))
                        local Entity_out = Entity:ConvertEntity(spawnPotential_in.Properties, false)
                        if(Entity_out ~= nil) then
                            Entity_out.name = "Entity"
                            spawnPotential_out:addChild(Entity_out)
                        else goto spawnPotentialContinue end
                    end
                end
            else goto spawnPotentialContinue end
            OUT.SpawnPotentials:addChild(spawnPotential_out)
            ::spawnPotentialContinue::
        end
    elseif(IN:contains("EntityId", TYPE.STRING)) then
        --Transform into SpawnPotentials

        local id = IN.lastFound.value
        if(id:find("^minecraft:")) then id = id:sub(11) end
        if(Settings:dataTableContains("entities", id)) then
            local entry = Settings.lastFound
            OUT.SpawnPotentials = OUT:addChild(TagList.new("SpawnPotentials"))
            local spawnPotential = TagCompound.new()
            spawnPotential:addChild(TagInt.new("Weight", 1))
            spawnPotential.Entity = spawnPotential:addChild(TagCompound.new("Entity"))
            spawnPotential.Entity:addChild(TagString.new("id", "minecraft:" .. entry[1][1]))
            OUT.SpawnPotentials:addChild(spawnPotential)
        end
    end

    return OUT
end

function Entity:ConvertMinecartTNT(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseMinecart(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("TNTFuse", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("TNTFuse", -1)) end

    return OUT
end

function Entity:ConvertMooshroom(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

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

function Entity:ConvertOcelot(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("CatType", TYPE.INT)) then
        local CatType = IN.lastFound.value
        if(IN.lastFound.value < 0 or IN.lastFound.value > 3) then CatType = 0 end
        OUT:addChild(TagInt.new("CatType", CatType))
    elseif(required) then OUT:addChild(TagInt.new("CatType")) end

    --TODO cats

    return OUT
end

function Entity:ConvertParrot(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Variant", TYPE.INT)) then
        local Variant = IN.lastFound.value
        if(IN.lastFound.value < 0 or IN.lastFound.value > 4) then Variant = 0 end
        OUT:addChild(TagInt.new("Variant", Variant))
    elseif(required) then OUT:addChild(TagInt.new("Variant")) end

    return OUT
end

function Entity:ConvertPainting(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    --TODO verify these values
    if(IN:contains("Facing", TYPE.BYTE)) then
        local Facing = IN.lastFound.value

        if(Facing == 0) then OUT:addChild(TagByte.new("Facing", 2))
        elseif(Facing == 1) then OUT:addChild(TagByte.new("Facing", 1))
        elseif(Facing == 2) then OUT:addChild(TagByte.new("Facing", 0))
        elseif(Facing == 3) then OUT:addChild(TagByte.new("Facing", 3))
        else return nil end

        if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
        if(IN:contains("TileY", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then return nil end
        if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
    elseif(IN:contains("Direction", TYPE.BYTE)) then
        --JAVA Direction
        --north 2 Direction
        --east 3
        --south 0
        --west 1 
        --tile is block it's hanging on
        local Direction = IN.lastFound.value
        if(Direction == 1) then
            --west
            OUT:addChild(TagByte.new("Facing", 1))
            if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value+1 - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
            if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
        elseif(Direction == 2) then
            --north
            OUT:addChild(TagByte.new("Facing", 0))
            if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
            if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value-1 - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
        elseif(Direction == 3) then
            --east
            OUT:addChild(TagByte.new("Facing", 3))
            if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value-1 - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
            if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
        elseif(Direction == 0) then
            --south
            OUT:addChild(TagByte.new("Facing", 2))
            if(IN:contains("TileX", TYPE.INT)) then OUT:addChild(TagInt.new("TileX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then return nil end
            if(IN:contains("TileZ", TYPE.INT)) then OUT:addChild(TagInt.new("TileZ", IN.lastFound.value+1 - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then return nil end
        else return nil end
        if(IN:contains("TileY", TYPE.INT)) then OUT:addChild(TagInt.new("TileY", IN.lastFound.value)) elseif(required) then return nil end
    elseif(required) then return nil end

    if(IN:contains("Motive", TYPE.STRING)) then
        local motive = IN.lastFound.value
        if(motive:find("^minecraft:")) then motive = motive:sub(11) end
        if(motive == "Kebab" or motive == "kebab") then OUT:addChild(TagString.new("Motive", "Kebab"))
        elseif(motive == "Aztec" or motive == "aztec") then OUT:addChild(TagString.new("Motive", "Aztec"))
        elseif(motive == "Alban" or motive == "alban") then OUT:addChild(TagString.new("Motive", "Alban"))
        elseif(motive == "Aztec2" or motive == "aztec2") then OUT:addChild(TagString.new("Motive", "Aztec2"))
        elseif(motive == "Bomb" or motive == "bomb") then OUT:addChild(TagString.new("Motive", "Bomb"))
        elseif(motive == "Plant" or motive == "plant") then OUT:addChild(TagString.new("Motive", "Plant"))
        elseif(motive == "Wasteland" or motive == "wasteland") then OUT:addChild(TagString.new("Motive", "Wasteland"))
        elseif(motive == "Wanderer" or motive == "wanderer") then OUT:addChild(TagString.new("Motive", "Wanderer"))
        elseif(motive == "Graham" or motive == "graham") then OUT:addChild(TagString.new("Motive", "Graham"))
        elseif(motive == "Pool" or motive == "pool") then OUT:addChild(TagString.new("Motive", "Pool"))
        elseif(motive == "Courbet" or motive == "courbet") then OUT:addChild(TagString.new("Motive", "Courbet"))
        elseif(motive == "Sunset" or motive == "sunset") then OUT:addChild(TagString.new("Motive", "Sunset"))
        elseif(motive == "Sea" or motive == "sea") then OUT:addChild(TagString.new("Motive", "Sea"))
        elseif(motive == "Creebet" or motive == "creebet") then OUT:addChild(TagString.new("Motive", "Creebet"))
        elseif(motive == "Match" or motive == "match") then OUT:addChild(TagString.new("Motive", "Match"))
        elseif(motive == "Bust" or motive == "bust") then OUT:addChild(TagString.new("Motive", "Bust"))
        elseif(motive == "Stage" or motive == "stage") then OUT:addChild(TagString.new("Motive", "Stage"))
        elseif(motive == "Void" or motive == "void") then OUT:addChild(TagString.new("Motive", "Void"))
        elseif(motive == "SkullAndRoses" or motive == "skull_and_roses") then OUT:addChild(TagString.new("Motive", "SkullAndRoses"))
        elseif(motive == "Wither" or motive == "wither") then OUT:addChild(TagString.new("Motive", "Wither"))
        elseif(motive == "Fighters" or motive == "fighters") then OUT:addChild(TagString.new("Motive", "Fighters"))
        elseif(motive == "Skeleton" or motive == "skeleton") then OUT:addChild(TagString.new("Motive", "Skeleton"))
        elseif(motive == "DonkeyKong" or motive == "donkey_kong") then OUT:addChild(TagString.new("Motive", "DonkeyKong"))
        elseif(motive == "Pointer" or motive == "pointer") then OUT:addChild(TagString.new("Motive", "Pointer"))
        elseif(motive == "Pigscene" or motive == "pigscene") then OUT:addChild(TagString.new("Motive", "Pigscene"))
        elseif(motive == "BurningSkull" or motive == "burning_skull") then OUT:addChild(TagString.new("Motive", "BurningSkull"))
        else return nil end
    else return nil end

    return OUT
end

function Entity:ConvertPhantom(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("AX", TYPE.INT)) then OUT:addChild(TagInt.new("AX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then OUT:addChild(TagInt.new("AX", OUT.Pos:child(0).value)) end
    if(IN:contains("AY", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("AY", OUT.Pos:child(1).value)) end
    if(IN:contains("AZ", TYPE.INT)) then OUT:addChild(TagInt.new("AX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then OUT:addChild(TagInt.new("AZ", OUT.Pos:child(2).value)) end
    if(IN:contains("Size", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Size")) end

    return OUT
end

function Entity:ConvertPig(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Saddle", TYPE.BYTE)) then OUT:addChild(TagByte.new("Saddle", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Saddle")) end

    return OUT
end

function Entity:ConvertPolarBear(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertPotion(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end

    --TODO ownerName to ownerUUID

    if(IN:contains("Potion", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "Potion"
            OUT:addChild(item)
        else return nil end
    else return nil end

    return OUT
end

function Entity:ConvertPufferfish(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertRabbit(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("RabbitType", TYPE.INT)) then
        local RabbitType = IN.lastFound.value
        if((IN.lastFound.value < 0 or IN.lastFound.value > 5) and IN.lastFound.value ~= 99) then RabbitType = 0 end
        OUT:addChild(TagInt.new("RabbitType", RabbitType))
    elseif(required) then OUT:addChild(TagInt.new("RabbitType")) end
    if(IN:contains("MoreCarrotTicks", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("MoreCarrotTicks")) end

    return OUT
end

function Entity:ConvertSalmon(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertSheep(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Color", TYPE.BYTE)) then
        local Color = IN.lastFound.value
        if(IN.lastFound.value < 0 or IN.lastFound.value > 15) then Color = 0 end
        OUT:addChild(TagByte.new("Color", Color))
    elseif(required) then OUT:addChild(TagByte.new("Color")) end
    if(IN:contains("Sheared", TYPE.BYTE)) then OUT:addChild(TagByte.new("Sheared", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Sheared")) end

    return OUT
end

function Entity:ConvertShulker(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Color", TYPE.BYTE)) then
        local Color = IN.lastFound.value
        if(IN.lastFound.value < 0 or IN.lastFound.value > 15) then Color = 0 end
        OUT:addChild(TagByte.new("Color", Color))
    elseif(required) then OUT:addChild(TagByte.new("Color")) end

    if(IN:contains("AttachFace", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("AttachFace")) end
    if(IN:contains("Peak", TYPE.BYTE)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagByte.new("Peak")) end
    if(IN:contains("APX", TYPE.INT)) then OUT:addChild(TagInt.new("APX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then OUT:addChild(TagInt.new("APX")) end
    if(IN:contains("APY", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("APY")) end
    if(IN:contains("APZ", TYPE.INT)) then OUT:addChild(TagInt.new("APX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then OUT:addChild(TagInt.new("APZ")) end

    return OUT
end

function Entity:ConvertSilverfish(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertSkeleton(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertSkeletonHorse(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseHorse(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("ArmorItem", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "ArmorItem"
            OUT:addChild(item)
        end
    end

    if(IN:contains("SaddleItem", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "SaddleItem"
            OUT:addChild(item)
        end
    end

    return OUT
end

function Entity:ConvertSlime(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("wasOnGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("wasOnGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("wasOnGround", true)) end
    if(IN:contains("Size", TYPE.INT)) then
        local Size = IN.lastFound.value
        if(IN.lastFound.value < 0) then Size = 0 end
        OUT:addChild(TagInt.new("Size", Size))
    elseif(required) then OUT:addChild(TagInt.new("Size")) end

    return OUT
end

function Entity:ConvertSmallFireball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagByte.new("inGround")) end

    if(IN:contains("direction", TYPE.LIST, TYPE.DOUBLE)) then
        if(IN.lastFound.childCount == 3) then OUT.direction = OUT:addChild(IN.lastFound) end
    end

    if(OUT.direction == nil) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
    end

    if(IN:contains("power", TYPE.LIST, TYPE.DOUBLE)) then
        if(IN.lastFound.childCount == 3) then OUT.power = OUT:addChild(IN.lastFound) end
    end

    if(OUT.power == nil) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
    end

    if(IN:contains("life", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("life")) end

    return OUT
end

function Entity:ConvertSnowball(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end
    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end

    return OUT
end

function Entity:ConvertSnowman(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Pumpkin", TYPE.BYTE)) then OUT:addChild(TagByte.new("Pumpkin", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Pumpkin", true)) end

    return OUT
end

function Entity:ConvertSpider(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertStray(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertSquid(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertTNT(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(Settings:getSettingInt("DataVersion") < 100) then 
        if(IN:contains("Fuse", TYPE.BYTE)) then OUT:addChild(TagShort.new("Fuse", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("Fuse")) end
    else
        if(IN:contains("Fuse", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Fuse")) end
    end

    return OUT
end

function Entity:ConvertTrident(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseProjectile(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("shake", TYPE.BYTE)) then OUT:addChild(TagByte.new("shake", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("shake")) end
    if(IN:contains("inGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("inGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("inGround")) end
    if(IN:contains("crit", TYPE.BYTE)) then OUT:addChild(TagByte.new("crit", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("crit")) end
    if(IN:contains("pickup", TYPE.BYTE)) then
        local pickup = IN.lastFound.value
        if(pickup < 0 or pickup > 2) then pickup = 1 end
        OUT:addChild(TagByte.new("pickup", pickup))
    elseif(required) then OUT:addChild(TagByte.new("pickup", 1)) end
    if(IN:contains("life", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("life")) end
    if(IN:contains("damage", TYPE.BYTE)) then OUT:addChild(TagByte.new("DealtDamage", IN.lastFound.value)) elseif(required) then OUT:addChild(TagByte.new("DealtDamage")) end

    if(IN:contains("Trident", TYPE.COMPOUND)) then
        local item = Item:ConvertItem(IN.lastFound, false)
        if(item ~= nil) then
            item.name = "Trident"
            OUT:addChild(item)
        else return nil end
    else return nil end

    return OUT
end

function Entity:ConvertTropicalFish(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertTurtle(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("HasEgg", TYPE.BYTE)) then OUT:addChild(TagByte.new("HasEgg", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("HasEgg")) end
    if(IN:contains("HomePosX", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("HomePosX")) end
    if(IN:contains("HomePosY", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("HomePosY")) end
    if(IN:contains("HomePosZ", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("HomePosZ")) end
    if(IN:contains("TravelPosX", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("TravelPosX")) end
    if(IN:contains("TravelPosY", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("TravelPosY")) end
    if(IN:contains("TravelPosZ", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("TravelPosZ")) end

    return OUT
end

function Entity:ConvertVex(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("BoundX", TYPE.INT)) then OUT:addChild(TagInt.new("BoundX", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then OUT:addChild(TagInt.new("BoundX", OUT.Pos:child(0).value)) end
    if(IN:contains("BoundY", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("BoundY", OUT.Pos:child(1).value)) end
    if(IN:contains("BoundZ", TYPE.INT)) then OUT:addChild(TagInt.new("BoundZ", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then OUT:addChild(TagInt.new("BoundZ", OUT.Pos:child(2).value)) end
    if(IN:contains("LifeTicks", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("LifeTicks", 20)) end

    return OUT
end

function Entity:ConvertVillager(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Willing", TYPE.BYTE)) then OUT:addChild(TagByte.new("Willing", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Willing")) end

    if(IN:contains("Inventory", TYPE.LIST, TYPE.COMPOUND)) then
        IN.Inventory = IN.lastFound
        OUT.Inventory = OUT:addChild(TagList.new("Inventory"))
        for i=0, IN.Inventory.childCount-1 do
            local item = Item:ConvertItem(IN.Inventory:child(i), true)
            if(item ~= nil) then
                OUT.Inventory:addChild(item)
            end
        end
    elseif(required) then
        OUT:addChild(TagList.new("Inventory"))
    end

    if(IN:contains("Offers", TYPE.COMPOUND)) then
        IN.Offers = IN.lastFound
        OUT.Offers = OUT:addChild(TagCompound.new("Offers"))

        if(IN.Offers:contains("Recipes", TYPE.LIST, TYPE.COMPOUND)) then
            IN.Offers.Recipes = IN.Offers.lastFound
            OUT.Offers.Recipes = OUT.Offers:addChild(TagList.new("Recipes"))

            for i=0, IN.Offers.Recipes.childCount-1 do
                local recipe_in = IN.Offers.Recipes:child(i)
                local recipe_out = TagCompound.new()

                if(recipe_in:contains("buy", TYPE.COMPOUND)) then
                    local buy = Item:ConvertItem(recipe_in.lastFound, false)
                    if(buy ~= nil) then
                        buy.name = "buy"
                        recipe_out:addChild(buy)
                    else goto recipeContinue end
                else goto recipeContinue end

                if(recipe_in:contains("sell", TYPE.COMPOUND)) then
                    local sell = Item:ConvertItem(recipe_in.lastFound, false)
                    if(sell ~= nil) then
                        sell.name = "sell"
                        recipe_out:addChild(sell)
                    else goto recipeContinue end
                else goto recipeContinue end

                if(recipe_in:contains("buyB", TYPE.COMPOUND)) then
                    local buyB = Item:ConvertItem(recipe_in.lastFound, false)
                    if(buyB ~= nil) then
                        buyB.name = "buyB"
                        recipe_out:addChild(buyB)
                    end
                end

                if(recipe_in:contains("rewardExp", TYPE.BYTE)) then recipe_out:addChild(TagByte.new("rewardExp", recipe_in.lastFound.value ~= 0)) elseif(required) then recipe_out:addChild(TagByte.new("rewardExp", 1)) end
                if(recipe_in:contains("maxUses", TYPE.INT)) then recipe_out:addChild(recipe_in.lastFound:clone()) elseif(required) then recipe_out:addChild(TagInt.new("maxUses", 7)) end
                if(recipe_in:contains("uses", TYPE.INT)) then recipe_out:addChild(recipe_in.lastFound:clone()) elseif(required) then recipe_out:addChild(TagInt.new("uses")) end

                OUT.Offers.Recipes:addChild(recipe_out)
                ::recipeContinue::
            end
        end
    end

    local DataVersion = Settings:getSettingInt("DataVersion")

    if(DataVersion >= 1901) then
        if(IN:contains("VillagerData", TYPE.COMPOUND)) then
            IN.VillagerData = IN.lastFound
            if(IN.VillagerData:contains("profession", TYPE.STRING)) then
                local profession = IN.VillagerData.lastFound.value
                if(profession:find("^minecraft:")) then profession = profession:sub(11) end

                if(IN.VillagerData:contains("level", TYPE.STRING)) then
                    IN.VillagerData.level = IN.VillagerData.lastFound.value
                end

                OUT.Profession = OUT:addChild(TagInt.new("Profession"))
                OUT.Career = OUT:addChild(TagInt.new("Career"))
                OUT.CareerLevel = OUT:addChild(TagInt.new("CareerLevel", 1))

                --TODO identify all profession's levels and how they convert to CareerLevel
                if(profession == "armorer") then
                    OUT.Profession.value = 3
                    OUT.Career.value = 0
                elseif(profession == "butcher") then
                    OUT.Profession.value = 4
                    OUT.Career.value = 0
                elseif(profession == "cartographer") then
                    OUT.Profession.value = 1
                    OUT.Career.value = 1
                elseif(profession == "cleric") then
                    OUT.Profession.value = 2
                    OUT.Career.value = 0
                elseif(profession == "farmer") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 0
                elseif(profession == "fisherman") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 1
                elseif(profession == "fletcher") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 3
                elseif(profession == "leatherworker") then
                    OUT.Profession.value = 4
                    OUT.Career.value = 1
                elseif(profession == "librarian") then
                    OUT.Profession.value = 1
                    OUT.Career.value = 0
                elseif(profession == "nitwit") then
                    OUT.Profession.value = 5
                    OUT.Career.value = 0
                elseif(profession == "none") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 0
                elseif(profession == "mason") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 0
                elseif(profession == "shepherd") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 2
                elseif(profession == "toolsmith") then
                    OUT.Profession.value = 3
                    OUT.Career.value = 2
                elseif(profession == "weaponsmith") then
                    OUT.Profession.value = 3
                    OUT.Career.value = 1
                end
            end
        end

        OUT:addChild(TagInt.new("Riches"))

        if(OUT.Profession == nil and required) then OUT:addChild(TagInt.new("Profession")) end
        if(OUT.Career == nil and required) then OUT:addChild(TagInt.new("Career")) end
        if(OUT.CareerLevel == nil and required) then OUT:addChild(TagInt.new("CareerLevel", 1)) end

    else
        --Legacy
        if(IN:contains("Riches", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Riches")) end
        if(IN:contains("Profession", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Profession")) end
        if(IN:contains("Career", TYPE.INT)) then OUT:addChild(TagInt.new("Career", IN.lastFound.value-1)) elseif(required) then OUT:addChild(TagInt.new("Career", 1)) end
        if(IN:contains("CareerLevel", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("CareerLevel", 1)) end
    end

    return OUT
end

function Entity:ConvertVindicator(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Johnny", TYPE.BYTE)) then OUT:addChild(TagByte.new("Johnny", IN.lastFound.value ~= 0)) end

    return OUT
end

function Entity:ConvertWitch(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertWither(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Invul", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Invul")) end

    return OUT
end

function Entity:ConvertWitherSkeleton(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertWitherSkull(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(required) then OUT:addChild(TagByte.new("inGround")) end

    if(IN:contains("direction", TYPE.LIST, TYPE.DOUBLE)) then
        if(IN.lastFound.childCount == 3) then OUT.direction = OUT:addChild(IN.lastFound) end
    end

    if(OUT.direction == nil) then
        OUT.direction = OUT:addChild(TagList.new("direction"))
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
        OUT.direction:addChild(TagDouble.new())
    end

    if(IN:contains("power", TYPE.LIST, TYPE.DOUBLE)) then
        if(IN.lastFound.childCount == 3) then OUT.power = OUT:addChild(IN.lastFound) end
    end

    if(OUT.power == nil) then
        OUT.power = OUT:addChild(TagList.new("power"))
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
        OUT.power:addChild(TagDouble.new())
    end

    if(IN:contains("life", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("life")) end

    return OUT
end

function Entity:ConvertWolf(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseBreedable(IN, OUT, required)
    if(OUT == nil) then return nil end

    return OUT
end

function Entity:ConvertZombie(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    --TODO legacy zombie villager
    --TODO legacy zombie type

    return OUT
end

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

function Entity:ConvertZombiePigman(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Anger", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Anger")) end

    return OUT
end

function Entity:ConvertZombieVillager(IN, OUT, required)
    OUT = Entity:ConvertBase(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseLiving(IN, OUT, required)
    if(OUT == nil) then return nil end
    OUT = Entity:ConvertBaseZombie(IN, OUT, required)
    if(OUT == nil) then return nil end

    if(IN:contains("Offers", TYPE.COMPOUND)) then
        IN.Offers = IN.lastFound
        OUT.Offers = OUT:addChild(TagCompound.new("Offers"))

        if(IN.Offers:contains("Recipes", TYPE.LIST, TYPE.COMPOUND)) then
            IN.Offers.Recipes = IN.Offers.lastFound
            OUT.Offers.Recipes = OUT.Offers:addChild(TagList.new("Recipes"))

            for i=0, IN.Offers.Recipes.childCount-1 do
                local recipe_in = IN.Offers.Recipes:child(i)
                local recipe_out = TagCompound.new()

                if(recipe_in:contains("buy", TYPE.COMPOUND)) then
                    local buy = Item:ConvertItem(recipe_in.lastFound, false)
                    if(buy ~= nil) then
                        buy.name = "buy"
                        recipe_out:addChild(buy)
                    else goto recipeContinue end
                else goto recipeContinue end

                if(recipe_in:contains("sell", TYPE.COMPOUND)) then
                    local sell = Item:ConvertItem(recipe_in.lastFound, false)
                    if(sell ~= nil) then
                        sell.name = "sell"
                        recipe_out:addChild(sell)
                    else goto recipeContinue end
                else goto recipeContinue end

                if(recipe_in:contains("buyB", TYPE.COMPOUND)) then
                    local buyB = Item:ConvertItem(recipe_in.lastFound, false)
                    if(buyB ~= nil) then
                        buyB.name = "buyB"
                        recipe_out:addChild(buyB)
                    end
                end

                if(recipe_in:contains("rewardExp", TYPE.BYTE)) then recipe_out:addChild(TagByte.new("rewardExp", recipe_in.lastFound.value ~= 0)) elseif(required) then recipe_out:addChild(TagByte.new("rewardExp", 1)) end
                if(recipe_in:contains("maxUses", TYPE.INT)) then recipe_out:addChild(recipe_in.lastFound:clone()) elseif(required) then recipe_out:addChild(TagInt.new("maxUses", 7)) end
                if(recipe_in:contains("uses", TYPE.INT)) then recipe_out:addChild(recipe_in.lastFound:clone()) elseif(required) then recipe_out:addChild(TagInt.new("uses")) end

                OUT.Offers.Recipes:addChild(recipe_out)
                ::recipeContinue::
            end
        end
    end

    local DataVersion = Settings:getSettingInt("DataVersion")

    if(DataVersion >= 1901) then
        if(IN:contains("VillagerData", TYPE.COMPOUND)) then
            IN.VillagerData = IN.lastFound
            if(IN.VillagerData:contains("profession", TYPE.STRING)) then
                local profession = IN.VillagerData.lastFound.value
                if(profession:find("^minecraft:")) then profession = profession:sub(11) end

                if(IN.VillagerData:contains("level", TYPE.STRING)) then
                    IN.VillagerData.level = IN.VillagerData.lastFound.value
                end

                OUT.Profession = OUT:addChild(TagInt.new("Profession"))
                OUT.Career = OUT:addChild(TagInt.new("Career"))
                OUT.CareerLevel = OUT:addChild(TagInt.new("CareerLevel", 1))

                --TODO identify all profession's levels and how they convert to CareerLevel
                if(profession == "armorer") then
                    OUT.Profession.value = 3
                    OUT.Career.value = 0
                elseif(profession == "butcher") then
                    OUT.Profession.value = 4
                    OUT.Career.value = 0
                elseif(profession == "cartographer") then
                    OUT.Profession.value = 1
                    OUT.Career.value = 1
                elseif(profession == "cleric") then
                    OUT.Profession.value = 2
                    OUT.Career.value = 0
                elseif(profession == "farmer") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 0
                elseif(profession == "fisherman") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 1
                elseif(profession == "fletcher") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 3
                elseif(profession == "leatherworker") then
                    OUT.Profession.value = 4
                    OUT.Career.value = 1
                elseif(profession == "librarian") then
                    OUT.Profession.value = 1
                    OUT.Career.value = 0
                elseif(profession == "nitwit") then
                    OUT.Profession.value = 5
                    OUT.Career.value = 0
                elseif(profession == "none") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 0
                elseif(profession == "mason") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 0
                elseif(profession == "shepherd") then
                    OUT.Profession.value = 0
                    OUT.Career.value = 2
                elseif(profession == "toolsmith") then
                    OUT.Profession.value = 3
                    OUT.Career.value = 2
                elseif(profession == "weaponsmith") then
                    OUT.Profession.value = 3
                    OUT.Career.value = 1
                end
            end
        end

        OUT:addChild(TagInt.new("Riches"))

        if(OUT.Profession == nil) then OUT:addChild(TagInt.new("Profession")) end
        if(OUT.Career == nil) then OUT:addChild(TagInt.new("Career")) end
        if(OUT.CareerLevel == nil) then OUT:addChild(TagInt.new("CareerLevel", 1)) end

    else
        --Legacy
        if(IN:contains("Riches", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Riches")) end
        if(IN:contains("Profession", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Profession")) end
        if(IN:contains("Career", TYPE.INT)) then OUT:addChild(TagInt.new("Career", IN.lastFound-1)) elseif(required) then OUT:addChild(TagInt.new("Career", 1)) end
        if(IN:contains("CareerLevel", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("CareerLevel", 1)) end
    end

    if(IN:contains("ConversionTime", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ConversionTime", -1)) end

    return OUT
end

---------------Base functions

function Entity:ConvertUUID(IN, OUT)
    if(IN:contains("UUID", TYPE.INT_ARRAY)) then
        if(IN.lastFound:getSize() == 16) then
            IN.UUID = IN.lastFound
            local stringUUID = string.format("%08x", IN.UUID:getInt(0)) .. string.format("%08x", IN.UUID:getInt(4)) .. string.format("%08x", IN.UUID:getInt(8)) .. string.format("%08x", IN.UUID:getInt(12))
            OUT:addChild(TagString.new("UUID", "ent" .. stringUUID))
        end
        
    elseif(IN:contains("UUIDMost", TYPE.LONG)) then
        IN.UUIDMost = IN.lastFound.value
        if(IN:contains("UUIDLeast", TYPE.LONG)) then
            IN.UUIDLeast = IN.lastFound.value
            OUT:addChild(TagString.new("UUID", "ent" .. string.format("%016x", IN.UUIDMost) .. string.format("%016x", IN.UUIDLeast)))
        end
    end
    return OUT
end

function Entity:ConvertBase(IN, OUT, required)
    if(IN:contains("OnGround", TYPE.BYTE)) then OUT:addChild(TagByte.new("OnGround", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("OnGround", true)) end
    if(IN:contains("Invulnerable", TYPE.BYTE)) then OUT:addChild(TagByte.new("Invulnerable", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Invulnerable")) end
    if(IN:contains("Glowing", TYPE.BYTE)) then OUT:addChild(TagByte.new("Glowing", IN.lastFound.value ~= 0)) end
    if(IN:contains("NoGravity", TYPE.BYTE)) then OUT:addChild(TagByte.new("NoGravity", IN.lastFound.value ~= 0)) end
    if(IN:contains("Silent", TYPE.BYTE)) then OUT:addChild(TagByte.new("Silent", IN.lastFound.value ~= 0)) end
    if(IN:contains("Air", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Air", 300)) end
    if(IN:contains("Fire", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("Fire", -1)) end
    if(IN:contains("Dimension", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then
        local dim = Settings:getSettingInt("Dimension")
        if(dim == 1) then dim = -1 elseif(dim == 2) then dim = 1 end
        OUT:addChild(TagInt.new("Dimension", dim))
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

    Entity:ConvertUUID(IN, OUT)

    return OUT
end

function Entity:ConvertBaseLiving(IN, OUT, required)
    if(IN:contains("CanPickUpLoot", TYPE.BYTE)) then OUT:addChild(TagByte.new("CanPickUpLoot", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("CanPickUpLoot")) end
    if(IN:contains("FallFlying", TYPE.BYTE)) then OUT:addChild(TagByte.new("FallFlying", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("FallFlying")) end
    if(IN:contains("Leashed", TYPE.BYTE)) then OUT:addChild(TagByte.new("Leashed", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("Leashed")) end
    if(IN:contains("LeftHanded", TYPE.BYTE)) then OUT:addChild(TagByte.new("LeftHanded", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("LeftHanded")) end
    if(IN:contains("PersistenceRequired", TYPE.BYTE)) then OUT:addChild(TagByte.new("PersistenceRequired", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("PersistenceRequired")) end
    if(IN:contains("NoAI", TYPE.BYTE)) then OUT:addChild(TagByte.new("NoAI", IN.lastFound.value ~= 0)) end
    if(IN:contains("DeathTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("DeathTime")) end
    if(IN:contains("HurtTime", TYPE.SHORT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagShort.new("HurtTime")) end
    if(IN:contains("HurtByTimestamp", TYPE.INT)) then OUT:addChild(TagShort.new("HurtByTimestamp", IN.lastFound.value)) elseif(required) then OUT:addChild(TagShort.new("HurtByTimestamp")) end
    if(IN:contains("AbsorptionAmount", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("AbsorptionAmount")) end

    if(Settings:getSettingInt("DataVersion") < 169) then
        if(IN:contains("Health", TYPE.SHORT)) then OUT:addChild(TagFloat.new("Health", IN.lastFound.value)) elseif(required) then OUT:addChild(TagFloat.new("Health", 20)) end
    else
        if(IN:contains("Health", TYPE.FLOAT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagFloat.new("Health", 20)) end
    end

    --TODO Leash

    if(Settings:getSettingInt("DataVersion") < 169) then
        if(IN:contains("Equipment", TYPE.LIST, TYPE.COMPOUND)) then
            IN.Equipment = IN.lastFound
            if(IN.Equipment.childCount == 5) then
                OUT.ArmorItems = OUT:addChild(TagList.new("ArmorItems"))
                OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
    
                for i=0, 4 do
                    local item = Item:ConvertItem(IN.Equipment:child(i), false)
                    if(item == nil) then item = TagCompound.new() end
    
                    if(i == 0) then
                        OUT.HandItems:addChild(item)
                        OUT.HandItems:addChild(TagCompound.new())
                    else
                        OUT.ArmorItems:addChild(item)
                    end
                end
            end
        end

        if(IN:contains("DropChances", TYPE.LIST, TYPE.FLOAT)) then
            IN.DropChances = IN.lastFound
    
            if(IN.DropChances.childCount == 5) then
                OUT.ArmorDropChances = OUT:addChild(TagList.new("ArmorDropChances"))
                OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
                OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
                OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
                OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
    
                OUT.HandDropChances = OUT:addChild(TagList.new("HandDropChances"))
                OUT.HandDropChances:addChild(TagFloat.new("", 0.085))
                OUT.HandDropChances:addChild(TagFloat.new("", 0.085))
    
                for i=0, 4 do
                    if(i == 0) then OUT.HandDropChances:child(0).value = IN.DropChances:child(i).value
                    else OUT.ArmorDropChances:child(i-1).value = IN.DropChances:child(i).value end
                end
            end

        end

    else

        if(IN:contains("ArmorItems", TYPE.LIST, TYPE.COMPOUND)) then
            IN.ArmorItems = IN.lastFound
            if(IN.ArmorItems.childCount == 4) then
                OUT.ArmorItems = OUT:addChild(TagList.new("ArmorItems"))
    
                for i=0, 3 do
                    local item = Item:ConvertItem(IN.ArmorItems:child(i), false)
                    if(item ~= nil) then OUT.ArmorItems:addChild(item) else OUT.ArmorItems:addChild(TagCompound.new()) end
                end
            end
        end
        
        
        if(IN:contains("ArmorDropChances", TYPE.LIST, TYPE.FLOAT)) then
            IN.ArmorDropChances = IN.lastFound
            if(IN.ArmorDropChances.childCount == 4) then
                OUT.ArmorDropChances = OUT:addChild(TagList.new("ArmorDropChances"))
                OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
                OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
                OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
                OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
    
                for i=0, 3 do
                    OUT.ArmorDropChances:child(i).value = IN.ArmorDropChances:child(i).value
                end
            end
        end
    
        
        if(IN:contains("HandItems", TYPE.LIST, TYPE.COMPOUND)) then
            IN.HandItems = IN.lastFound
            if(IN.HandItems.childCount == 2) then
                OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
    
                for i=0, 1 do
                    local item = Item:ConvertItem(IN.HandItems:child(i), false)
                    if(item ~= nil) then OUT.HandItems:addChild(item) else OUT.HandItems:addChild(TagCompound.new()) end
                end
            end
        end
    
        
        if(IN:contains("HandDropChances", TYPE.LIST, TYPE.FLOAT)) then
            IN.HandDropChances = IN.lastFound
            if(IN.HandDropChances.childCount == 2) then
                OUT.HandDropChances = OUT:addChild(TagList.new("HandDropChances"))
                OUT.HandDropChances:addChild(TagFloat.new("", 0.085))
                OUT.HandDropChances:addChild(TagFloat.new("", 0.085))
    
                for i=0, 1 do
                    OUT.HandDropChances:child(i).value = IN.HandDropChances:child(i).value
                end
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
    if(required and OUT.ArmorDropChances == nil) then
        OUT.ArmorDropChances = OUT:addChild(TagList.new("ArmorDropChances"))
        OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
        OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
        OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
        OUT.ArmorDropChances:addChild(TagFloat.new("", 0.085))
    end
    if(required and OUT.HandItems == nil) then
        OUT.HandItems = OUT:addChild(TagList.new("HandItems"))
        OUT.HandItems:addChild(TagCompound.new())
        OUT.HandItems:addChild(TagCompound.new())
    end
    if(required and OUT.HandDropChances == nil) then
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
                if(effect_in.lastFound.value > 0 and effect_in.lastFound.value <= 30) then effect_out:addChild(effect_in.lastFound:clone()) end
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

        for a=0, IN.Attributes.childCount-1 do
            local attribute_in = IN.Attributes:child(a)
            local attribute_out = TagCompound.new()

            if(attribute_in:contains("Name", TYPE.STRING)) then
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

            if(attribute_in:contains("Base", TYPE.DOUBLE)) then
                attribute_out:addChild(attribute_in.lastFound:clone())
            else goto attributeContinue end

            if(attribute_in:contains("Modifiers", TYPE.LIST, TYPE.COMPOUND)) then
                attribute_in.Modifiers = attribute_in.lastFound
                attribute_out.Modifiers = attribute_out:addChild(TagList.new("Modifiers"))

                for i=0, attribute_in.Modifiers.childCount-1 do
                    local modifier_in = attribute_in.Modifiers:child(i)
                    local modifier_out = TagCompound.new()

                    if(modifier_in:contains("Operation", TYPE.INT)) then
                        if(modifier_in.lastFound.value >= 0 or modifier_in.lastFound.value <= 2) then modifier_out:addChild(modifier_in.lastFound:clone()) else goto modifierContinue end
                    else goto modifierContinue end
    
                    if(modifier_in:contains("Amount", TYPE.DOUBLE)) then
                        modifier_out:addChild(modifier_in.lastFound:clone())
                    else goto modifierContinue end
    
                    if(modifier_in:contains("UUIDMost", TYPE.LONG)) then
                        modifier_out:addChild(TagInt.new("UUID", modifier_in.lastFound.value))
                    else goto modifierContinue end
    
                    if(modifier_in:contains("Slot", TYPE.STRING)) then
                        local Slot = modifier_in.lastFound.value
                        if(Slot == "mainhand" or Slot == "offhand" or Slot == "feet" or Slot == "legs" or Slot == "chest" or Slot == "head") then modifier_out:addChild(modifier_in.lastFound:clone()) end
                    end
    
                    if(modifier_in:contains("Name", TYPE.STRING)) then
                        modifier_out:addChild(modifier_in.lastFound:clone())
                    end

                    attribute_out.Modifiers:addChild(modifier_out)

                    ::modifierContinue::
                end

                if(attribute_out.Modifiers.childCount == 0) then
                    attribute_out:removeChild(attribute_out.Modifiers:getRow())
                    attribute_out.Modifiers = nil
                end
            end

            OUT.Attributes:addChild(attribute_out)

            ::attributeContinue::
        end

        if(OUT.Attributes.childCount == 0) then
            OUT:removeChild(OUT.Attributes:getRow())
            OUT.Attributes = nil
        end
    end

    return OUT
end

function Entity:ConvertBaseBreedable(IN, OUT, required)
    if(IN:contains("InLove", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("InLove")) end
    if(IN:contains("Age", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("Age")) end
    if(IN:contains("ForcedAge", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("ForcedAge")) end
    return OUT
end

function Entity:ConvertBaseZombie(IN, OUT, required)
    if(IN:contains("IsBaby", TYPE.BYTE)) then OUT:addChild(TagByte.new("IsBaby", IN.lastFound.value ~= 0)) end
    if(IN:contains("CanBreakDoors", TYPE.BYTE)) then OUT:addChild(TagByte.new("CanBreakDoors", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("CanBreakDoors")) end

    if(IN:contains("DrownedConversionTime", TYPE.INT)) then
        local DrownedConversionTime = IN.lastFound.value
        if(IN.lastFound.value == -1) then DrownedConversionTime = 0 end
        OUT:addChild(TagInt.new("DrownedConversionTime", DrownedConversionTime))
    elseif(required) then OUT:addChild(TagInt.new("DrownedConversionTime")) end

    if(IN:contains("InWaterTime", TYPE.INT)) then
        local InWaterTime = IN.lastFound.value
        if(IN.lastFound.value == -1) then InWaterTime = 0 end
        OUT:addChild(TagInt.new("InWaterTime", InWaterTime))
    elseif(required) then OUT:addChild(TagInt.new("InWaterTime")) end
    return OUT
end

function Entity:ConvertBaseHorse(IN, OUT, required)
    if(IN:contains("EatingHaystack", TYPE.BYTE)) then OUT:addChild(TagByte.new("EatingHaystack", IN.lastFound.value ~= 0)) elseif(required) then OUT:addChild(TagByte.new("EatingHaystack")) end
    if(IN:contains("Temper", TYPE.INT)) then
        local Temper = IN.lastFound.value
        if(IN.lastFound.value < 0 or IN.lastFound.value > 100) then Temper = 0 end
        OUT:addChild(TagInt.new("Temper", Temper))
    elseif(required) then OUT:addChild(TagInt.new("Temper")) end

    --all horses become wild

    return OUT
end

function Entity:ConvertBaseMinecart(IN, OUT, required)

    if(IN:contains("CustomDisplayTile", TYPE.BYTE)) then OUT:addChild(TagByte.new("CustomDisplayTile", IN.lastFound.value ~= 0)) end
    if(IN:contains("DisplayOffset", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) end

    if(IN:contains("DisplayState", TYPE.COMPOUND)) then
        IN.inBlockState = IN.lastFound
        if(IN.inBlockState:contains("Name", TYPE.STRING)) then
            IN.inBlockState.Name = IN.inBlockState.lastFound.value
            if(IN.inBlockState.Name:find("^minecraft:")) then IN.inBlockState.Name = IN.inBlockState.Name:sub(11) end
            if(Settings:dataTableContains("blocks_states", IN.inBlockState.Name)) then
                local entry = Settings.lastFound
                local DataVersion = Settings:getSettingInt("DataVersion")
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                    OUT.outTile = OUT:addChild(TagString.new("DisplayTile", "minecraft:" .. subEntry[5]))
                    if(subEntry[4]:len() > 0) then OUT.outData = OUT:addChild(TagInt.new("DisplayData", tonumber(subEntry[4]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    elseif(IN:contains("DisplayTile", TYPE.STRING)) then
        IN.inTile = IN.lastFound.value
        if(IN:contains("DisplayData", TYPE.INT)) then
            IN.inData = IN.lastFound.value

            if(IN.inTile:find("^minecraft:")) then IN.inTile = IN.inTile:sub(11) end
            if(Settings:dataTableContains("blocks_names", IN.inTile)) then
                local entry = Settings.lastFound
                local DataVersion = Settings:getSettingInt("DataVersion")
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                    if(subEntry[2]:len() > 0) then if(tonumber(subEntry[2]) > IN.inData) then goto entryContinue end end
                    OUT.outTile = OUT:addChild(TagString.new("DisplayTile", "minecraft:" .. subEntry[5]))
                    if(subEntry[4]:len() > 0) then OUT.outData = OUT:addChild(TagInt.new("DisplayData", tonumber(subEntry[4]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    end

    if(OUT.outTile == nil) then OUT:addChild(TagString.new("DisplayTile", "minecraft:air")) end
    if(OUT.outData == nil) then OUT:addChild(TagInt.new("DisplayData", 0)) end

    return OUT
end

function Entity:ConvertBaseProjectile(IN, OUT, required)

    if(IN:contains("xTile", TYPE.INT)) then OUT:addChild(TagInt.new("xTile", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) elseif(required) then OUT:addChild(TagInt.new("xTile", -1)) end
    if(IN:contains("yTile", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) elseif(required) then OUT:addChild(TagInt.new("yTile", -1)) end
    if(IN:contains("zTile", TYPE.INT)) then OUT:addChild(TagInt.new("zTile", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) elseif(required) then OUT:addChild(TagInt.new("zTile", -1)) end

    --TODO legacy projectile support

    if(IN:contains("inBlockState", TYPE.COMPOUND)) then
        IN.inBlockState = IN.lastFound
        if(IN.inBlockState:contains("Name", TYPE.STRING)) then
            IN.inBlockState.Name = IN.inBlockState.lastFound.value
            if(IN.inBlockState.Name:find("^minecraft:")) then IN.inBlockState.Name = IN.inBlockState.Name:sub(11) end
            if(Settings:dataTableContains("blocks_states", IN.inBlockState.Name)) then
                local entry = Settings.lastFound
                local DataVersion = Settings:getSettingInt("DataVersion")
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                    OUT.outTile = OUT:addChild(TagString.new("inTile", "minecraft:" .. subEntry[5]))
                    if(subEntry[4]:len() > 0) then OUT.outData = OUT:addChild(TagShort.new("inData", tonumber(subEntry[4]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    elseif(IN:contains("inTile", TYPE.STRING)) then
        IN.inTile = IN.lastFound.value
        if(IN:contains("inData", TYPE.SHORT)) then
            IN.inData = IN.lastFound.value

            if(IN.inTile:find("^minecraft:")) then IN.inTile = IN.inTile:sub(11) end
            if(Settings:dataTableContains("blocks_names", IN.inTile)) then
                local entry = Settings.lastFound
                local DataVersion = Settings:getSettingInt("DataVersion")
                for index, _ in ipairs(entry) do
                    local subEntry = entry[index]
                    if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                    if(subEntry[2]:len() > 0) then if(tonumber(subEntry[2]) > IN.inData) then goto entryContinue end end
                    OUT.outTile = OUT:addChild(TagString.new("inTile", "minecraft:" .. subEntry[5]))
                    if(subEntry[4]:len() > 0) then OUT.outData = OUT:addChild(TagShort.new("inData", tonumber(subEntry[4]))) end
                    break
                    ::entryContinue::
                end
            end
        end
    end

    if(OUT.outTile == nil) then OUT:addChild(TagString.new("inTile", "minecraft:air")) end
    if(OUT.outData == nil) then OUT:addChild(TagShort.new("inData", 0)) end

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

return Entity