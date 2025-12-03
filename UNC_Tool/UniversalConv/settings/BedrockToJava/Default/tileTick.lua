TileTick = {}
Item = Item or require("item")
Utils = Utils or require("utils")

function TileTick:ConvertTileTick(IN, currentTick)
    local OUT = TagCompound.new()

    OUT.isLiquid = false

    if(IN:contains("x", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("y", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("z", TYPE.INT)) then OUT:addChild(IN.lastFound:clone()) else return nil end
    if(IN:contains("time", TYPE.LONG)) then OUT:addChild(TagInt.new("t", IN.lastFound.value - currentTick)) else return nil end

    --TODO legacy support
    if(IN:contains("blockState", TYPE.COMPOUND)) then
        IN.blockState = IN.lastFound

        if(IN.blockState:contains("name", TYPE.STRING)) then IN.blockState.id = IN.blockState.lastFound end
        if(IN.blockState:contains("states", TYPE.COMPOUND)) then IN.blockState.meta = IN.blockState.lastFound
        elseif(IN.blockState:contains("val", TYPE.SHORT)) then IN.blockState.meta = IN.blockState.lastFound
        end

        local block = Utils:findBlock(IN.blockState.id, IN.blockState.meta)
        if(block == nil) then return nil end
        if(block.id == nil) then return nil end

        if(block.id == "water" or block.id == "flowing_water" or block.id == "lava" or block.id == "flowing_lava") then OUT.isLiquid = true end
        OUT.i = OUT:addChild(TagString.new("i", "minecraft:" .. block.id))
    end

    if(OUT.i == nil) then return nil end

    return OUT
end

return TileTick