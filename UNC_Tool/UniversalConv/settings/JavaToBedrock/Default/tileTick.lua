TileTick = {}
Item = Item or require("item")
Utils = Utils or require("utils")

function TileTick:ConvertTileTick(IN)
    local OUT = TagCompound.new()

    local currentTick = Settings:getSettingLong("currentTick")

    if(IN:contains("x", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("y", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("z", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("t", TYPE.INT)) then OUT:addChild(TagLong.new("time", currentTick + IN.lastFound.value)) else return nil end

    OUT.blockState = OUT:addChild(TagCompound.new("blockState"))
    OUT.blockState:addChild(TagInt.new("version", 16973838))

    if(IN:contains("i")) then
        IN.i = IN.lastFound

        local tileBlock = Utils:findBlock(IN.i)
        if(tileBlock == nil) then return nil end
        if(tileBlock.id == nil) then return nil end
        OUT.blockState.blockName = OUT.blockState:addChild(TagString.new("name", "minecraft:" .. tileBlock.id))
        OUT.blockState.states = OUT.blockState:addChild(Utils:StringToStates(tileBlock.meta))
    else return nil end

    if(OUT.blockState.blockName == nil) then return nil end

    return OUT
end

return TileTick