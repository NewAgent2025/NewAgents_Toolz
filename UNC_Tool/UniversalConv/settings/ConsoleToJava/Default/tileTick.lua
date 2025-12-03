TileTick = {}

function TileTick:ConvertTileTick(IN)
    local OUT = TagCompound.new()
    OUT.isLiquid = false

    if(IN:contains("x", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("y", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("z", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("t", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    OUT:addChild(TagInt.new("p"))

    if(IN:contains("i", TYPE.INT)) then 
        local tileTick_ID = IN.lastFound.value

        local ChunkVersion = Settings:getSettingInt("ChunkVersion")

        if(Settings:dataTableContains("blocks_ids", tostring(tileTick_ID)) and tileTick_ID ~= 0) then
            local entry = Settings.lastFound

            for index, _ in ipairs(entry) do
                local subEntry = entry[index]
                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                OUT.i = OUT:addChild(TagString.new("i", "minecraft:" .. subEntry[3]))
                if(OUT.i.value == "minecraft:water" or OUT.i.value == "minecraft:flowing_water" or OUT.i.value == "minecraft:lava" or OUT.i.value == "minecraft:flowing_lava") then OUT.isLiquid = true end
                break
                ::entryContinue::
            end
        else return nil end
    else return nil end

    if(OUT.i == nil) then return nil end

    return OUT
end

return TileTick