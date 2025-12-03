TileTick = {}
Item = Item or require("item")

function TileTick:ConvertTileTick(IN, currentTick)
    local OUT = TagCompound.new()

    if(IN:contains("x", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("y", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("z", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("time", TYPE.LONG)) then OUT:addChild(TagInt.new("t", IN.lastFound.value - currentTick)) else return nil end

    --TODO legacy support
    if(IN:contains("blockState", TYPE.COMPOUND)) then
        IN.blockState = IN.lastFound

        if(IN.blockState:contains("name", TYPE.STRING)) then
            local tileTickName = IN.blockState.lastFound.value
            if(tileTickName:find("^minecraft:")) then tileTickName = tileTickName:sub(11) end

            if(IN.blockState:contains("states", TYPE.COMPOUND)) then IN.blockState.states = IN.blockState.lastFound
            elseif(IN.blockState:contains("val", TYPE.SHORT)) then IN.blockState.val = IN.blockState.lastFound
            end

            if(Settings:dataTableContains("blocks_names", tileTickName)) then
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

                    OUT.i = OUT:addChild(TagInt.new("i", tonumber(subEntry[4])))
                    break
                    ::entryContinue::
                end
            end
            
        end
    end

    if(OUT.i == nil) then return nil end

    return OUT
end

return TileTick