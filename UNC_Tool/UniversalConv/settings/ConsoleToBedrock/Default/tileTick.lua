TileTick = {}
Item = Item or require("item")

function TileTick:ConvertTileTick(IN)
    local OUT = TagCompound.new()

    if(IN:contains("x", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("y", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("z", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("t", TYPE.INT)) then OUT:addChild(TagLong.new("time", IN.lastFound.value)) else return nil end
    OUT.blockState = OUT:addChild(TagCompound.new("blockState"))

    if(IN:contains("i", TYPE.INT)) then
        local tileTick_ID = IN.lastFound.value

        local ChunkVersion = Settings:getSettingInt("ChunkVersion")

		if(Settings:dataTableContains("blocks_ids", tostring(tileTick_ID)) and tileTick_ID ~= 0) then
			local entry = Settings.lastFound

			for index, _ in ipairs(entry) do
                local subEntry = entry[index]
                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > ChunkVersion) then goto entryContinue end end
                OUT.blockState.blockName = OUT.blockState:addChild(TagString.new("name", "minecraft:" .. subEntry[3]))
                local blockVal = 0
                if(subEntry[4]:len() ~= 0) then blockVal = tonumber(subEntry[4]) end
                OUT.blockState.val = OUT.blockState:addChild(TagShort.new("val", blockVal))
                break
                ::entryContinue::
            end
        end

    else return nil end

    if(OUT.blockState.blockName == nil) then return nil end

    return OUT
end

return TileTick