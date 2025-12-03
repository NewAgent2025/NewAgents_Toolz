TileEntity = TileEntity or require("tileEntity")
Entity = Entity or require("entity")
TileTick = TileTickc or require("tileTick")

function ConvertChunk(IN)
	local OUT = TagCompound.new()
	
	math.randomseed(os.clock()*100000000000)

	OUT.TileEntities = OUT:addChild(TagList.new("TileEntities"))
	OUT.Entities = OUT:addChild(TagList.new("Entities"))
	OUT.TileTicks = OUT:addChild(TagList.new("TileTicks"))

	local ConvertedPassengers = TagList.new()

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
				local out_tileEntity = TileEntity:ConvertTileEntity(in_tileEntity, true)
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
				in_entity.ConvertedPassengers = ConvertedPassengers
				in_entity.Entities_input_ref = IN.Entities
				local out_entity = Entity:ConvertEntity(in_entity, true)
				if (out_entity ~= nil) then
					OUT.Entities:addChild(out_entity)
				end
			end
		end
	end
	
	if(Settings:getSettingBool(optionsString .. "/tileTicks")) then
		if(IN:contains("TileTicks", TYPE.COMPOUND)) then
			IN.TileTicks = IN.lastFound

			local currentTick = 0
			if(IN.TileTicks:contains("currentTick", TYPE.INT)) then currentTick = IN.TileTicks.lastFound.value end

			if(IN.TileTicks:contains("tickList", TYPE.LIST, TYPE.COMPOUND)) then
				local tickList = IN.TileTicks.lastFound

				for i=0, tickList.childCount-1 do
					local in_tileTick = tickList:child(i)
					local out_tileTick = TileTick:ConvertTileTick(in_tileTick, currentTick)

					if(out_tileTick ~= nil) then
						OUT.TileTicks:addChild(out_tileTick)
					end
				end
			end

		end
	end
    
    return OUT
end