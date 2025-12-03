TileTick = {}

function TileTick:ConvertTileTick(IN)
    local OUT = TagCompound.new()

    if(IN:contains("x", TYPE.INT)) then OUT:addChild(TagInt.new("x", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetX")*16))) else return nil end
    if(IN:contains("y", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("z", TYPE.INT)) then OUT:addChild(TagInt.new("z", IN.lastFound.value - (Settings:getSettingInt("ChunkOffsetZ")*16))) else return nil end
    if(IN:contains("t", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end

	if(IN:contains("i", TYPE.STRING)) then
		local tileTick_ID = IN.lastFound.value
		if(tileTick_ID:find("^minecraft:")) then tileTick_ID = tileTick_ID:sub(11) end

		local DataVersion = Settings:getSettingInt("DataVersion")

		if(Settings:dataTableContains("blocks_states", tileTick_ID)) then
			local entry = Settings.lastFound

            for index, _ in ipairs(entry) do
                local subEntry = entry[index]
                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                OUT.i = OUT:addChild(TagInt.new("i", tonumber(subEntry[3])))
                break
                ::entryContinue::
            end
		else return nil end
		
	elseif(IN:contains("i", TYPE.INT)) then
		local tileTick_ID = IN.lastFound.value

		local DataVersion = Settings:getSettingInt("DataVersion")

		if(Settings:dataTableContains("blocks_ids", tostring(tileTick_ID))) then
			local entry = Settings.lastFound

			for index, _ in ipairs(entry) do
                local subEntry = entry[index]
                if(subEntry[1]:len() > 0) then if(tonumber(subEntry[1]) > DataVersion) then goto entryContinue end end
                OUT.i = OUT:addChild(TagInt.new("i", tonumber(subEntry[3])))
                break
                ::entryContinue::
            end
		else
			OUT.i = OUT:addChild(TagInt.new("i", tileTick_ID))
		end
	else return nil end

	if(OUT.i == nil) then return nil end

    return OUT
end

return TileTick