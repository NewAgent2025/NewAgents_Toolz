TileEntity = TileEntity or require("tileEntity")
Entity = Entity or require("entity")
TileTick = TileTick or require("tileTick")

function ConvertChunk(IN)
	math.randomseed(os.clock()*100000000000)

	local OUT = TagCompound.new()
	OUT:addChild(TagByte.new("V", 7))

	OUT.TileEntities = OUT:addChild(TagList.new("TileEntities"))
	OUT.Entities = OUT:addChild(TagList.new("Entities"))
	--OUT.PendingTicks = OUT:addChild(TagCompound.new("PendingTicks"))

	local dim = Settings:getSettingInt("Dimension")
	local optionsString = "options_overworld"
	if (dim == 1) then
		optionsString = "options_nether"
	elseif (dim == 2) then
		optionsString = "options_end"
	end

	if (Settings:getSettingBool(optionsString .. "/tileEntities")) then
		if (IN:contains("TileEntities", TYPE.LIST, TYPE.COMPOUND)) then
			IN.TileEntities = IN.lastFound

			for i = 0, IN.TileEntities.childCount - 1 do
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
				in_entity.Entities_output_ref = OUT.Entities
				local out_entity = Entity:ConvertEntity(in_entity, true)
				if (out_entity ~= nil) then
					OUT.Entities:addChild(out_entity)
				end
			end
		end
	end
	
	if(Settings:getSettingBool(optionsString .. "/tileTicks")) then
		local tickList = TagList.new("tickList")

		if(IN:contains("TileTicks", TYPE.LIST, TYPE.COMPOUND)) then
			IN.TileTicks = IN.lastFound

			for i=0, IN.TileTicks.childCount-1 do
				local tileTick = TileTick:ConvertTileTick(IN.TileTicks:child(i))
				if(tileTick ~= nil) then
					tickList:addChild(tileTick)
				end
			end
		end

		if(tickList.childCount > 0) then
			OUT.PendingTicks = OUT:addChild(TagCompound.new("PendingTicks"))
			OUT.PendingTicks:addChild(tickList)
		end
	end

return OUT
end
