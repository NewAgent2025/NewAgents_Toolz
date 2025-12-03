TileEntity = TileEntity or require("tileEntity")
Entity = Entity or require("entity")
TileTick = TileTick or require("tileTick")

function ConvertChunk(IN)
	local OUT = TagCompound.new()
	
	OUT.TileEntities = OUT:addChild(TagList.new("TileEntities"))
	OUT.Entities = OUT:addChild(TagList.new("Entities"))
	OUT.TileTicks = OUT:addChild(TagList.new("TileTicks"))
	
	local dim = Settings:getSettingInt("Dimension")
	local optionsString = "options_overworld"
	if(dim == 1) then
		optionsString = "options_nether"
	elseif(dim == 2) then
		optionsString = "options_end"
	end
	
	if(Settings:getSettingBool(optionsString .. "/tileEntities")) then
		if(IN:contains("TileEntities", TYPE.LIST, TYPE.COMPOUND)) then
			IN.TileEntities = IN.lastFound
			
			for i=0, IN.TileEntities.childCount-1 do
				local in_tileEntity = IN.TileEntities:child(i)
				in_tileEntity.Entities_output_ref = OUT.Entities
				local out_tileEntity = TileEntity:ConvertTileEntity(in_tileEntity)
				if (out_tileEntity ~= nil) then
					OUT.TileEntities:addChild(out_tileEntity)
				end
			end
		end
	end
	
	if(Settings:getSettingBool(optionsString .. "/entities")) then
		if(IN:contains("Entities", TYPE.LIST, TYPE.COMPOUND)) then
			IN.Entities = IN.lastFound
			
			for i=0, IN.Entities.childCount-1 do
				local in_entity = IN.Entities:child(i)
				in_entity.TileEntities_output_ref = OUT.TileEntities
				local out_entity = Entity:ConvertEntity(in_entity, true)
				if (out_entity ~= nil) then
					OUT.Entities:addChild(out_entity)
				end
			end
		end
	end
	
	if(Settings:getSettingBool(optionsString .. "/tileTicks")) then
		if(IN:contains("TileTicks", TYPE.LIST, TYPE.COMPOUND)) then
			IN.TileTicks = IN.lastFound
			
			for i=0, IN.TileTicks.childCount-1 do
				local tileTick = TileTick:ConvertTileTick(IN.TileTicks:child(i))
				if(tileTick ~= nil) then
					OUT.TileTicks:addChild(tileTick)
				end
			end
		end

		if(IN:contains("LiquidTicks", TYPE.LIST, TYPE.COMPOUND)) then
			IN.LiquidTicks = IN.lastFound
			
			for i=0, IN.LiquidTicks.childCount-1 do
				local tileTick = TileTick:ConvertTileTick(IN.LiquidTicks:child(i))
				if(tileTick ~= nil) then
					OUT.TileTicks:addChild(tileTick)
				end
			end
		end
	end

return OUT
end