Utils = {}

function Utils:CompareStates(statesString, statesTags)
    for state in statesString:gmatch("([^|]*)|?") do 
        state = state:gsub("^%s*(.-)%s*$", "%1")

        local equalsIndex = state:find("=")
        if(equalsIndex ~= nil) then
            local stateName = state:sub(1, equalsIndex-1)
            local stateValue = state:sub(equalsIndex+1)

            if(stateName:find("^1_")) then
                if(statesTags:contains(stateName:sub(3), TYPE.BYTE)) then
                    if(statesTags.lastFound.value ~= tonumber(stateValue)) then return false end
                else return false end
            elseif(stateName:find("^3_")) then
                if(statesTags:contains(stateName:sub(3), TYPE.INT)) then
                    if(statesTags.lastFound.value ~= tonumber(stateValue)) then return false end
                else return false end
            elseif(stateName:find("^8_")) then
                if(statesTags:contains(stateName:sub(3), TYPE.STRING)) then
                    if(statesTags.lastFound.value ~= stateValue) then return false end
                else return false end
            else return false end
        else return false end
    end
    return true
end

function Utils:StringToProperties(props)
    if(props:len() == 0) then return nil end

    local OUT = TagCompound.new("Properties")
    for prop in props:gmatch("([^|]*)|?") do 
        prop = prop:gsub("^%s*(.-)%s*$", "%1")
        
        local equalsIndex = prop:find("=")
        if(equalsIndex ~= nil) then
            OUT:addChild(TagString.new(prop:sub(1, equalsIndex-1), prop:sub(equalsIndex+1)))
        end
    end

    return OUT
end

function Utils:findItem(id, meta, version)

    --id in can be a number, string, TagByte, TagShort, TagInt, TagString
    if(id == nil) then return nil end
    if(type(id) == "userdata") then
        if(id.type == TYPE.SHORT or id.type == TYPE.BYTE or id.type == TYPE.INT or id.type == TYPE.STRING) then id = id.value else return nil end
    end
    if(type(id) == "string") then if(id:find("^minecraft:")) then id = id:sub(11) end end
    if(type(id) ~= "number" and type(id) ~= "string") then return nil end
    if(type(id) ~= "string") then id = tostring(id) end
    --id out must be a string

    --meta in can be a nil, number, TagByte, TagShort, TagInt
    if(meta ~= nil) then
        if(type(meta) == "userdata") then
            if(meta.type == TYPE.SHORT or meta.type == TYPE.BYTE or meta.type == TYPE.INT) then meta = meta.value else return nil end
        end
        if(type(meta) ~= "number") then return nil end
    end
    --meta out must be a nil or number

    --version
    if(version == nil) then version = Settings:getSettingInt("ChunkVersion") end
    if(type(version) ~= "number") then return nil end

    if(Settings:dataTableContains("items", id)) then
        local group = Settings.lastFound
        for index, _ in ipairs(group) do
            local entry = group[index]

            --if the table's version is higher
            if(entry[1]:len() > 0) then if(tonumber(entry[1], 10) > version) then goto entryContinue end end

            --if the table's meta is empty
            if(entry[2]:len() == 0) then
                local OUT = TagCompound.new()
                OUT.id = entry[3]
                OUT.flags = entry[4]
                OUT.tileEntity = entry[5]
                return OUT
            --if the input meta is a number
            elseif(meta ~= nil) then
                --if the table's meta is a number
                if(tonumber(entry[2], 10) ~= nil) then
                    --if the input meta matches
                    if(tonumber(entry[2], 10) == meta) then
                        local OUT = TagCompound.new()
                        OUT.id = entry[3]
                        OUT.flags = entry[4]
                        OUT.tileEntity = entry[5]
                        return OUT
                    end
                end
            end

            ::entryContinue::
        end
    end

    return nil
end

function Utils:findBlock(id, meta, version)

    --id in can be a number, string, TagByte, TagShort, TagInt, TagString
    if(id == nil) then return nil end
    if(type(id) == "userdata") then
        if(id.type == TYPE.SHORT or id.type == TYPE.BYTE or id.type == TYPE.INT or id.type == TYPE.STRING) then id = id.value else return nil end
    end
    if(type(id) == "string") then if(id:find("^minecraft:")) then id = id:sub(11) end end
    if(type(id) ~= "number" and type(id) ~= "string") then return nil end
    if(type(id) ~= "string") then id = tostring(id) end
    --id out must be a string

    --meta in can be a nil, number, TagByte, TagShort, TagInt, TagCompound
    if(meta ~= nil) then
        if(type(meta) == "userdata") then
            if(meta.type == TYPE.SHORT or meta.type == TYPE.BYTE or meta.type == TYPE.INT) then meta = meta.value elseif(meta.type ~= TYPE.COMPOUND) then return nil end
        end
        if(type(meta) ~= "number" and type(meta) ~= "userdata") then return nil end
    end
    --meta out must be a nil, number, compound

    --version
    if(version == nil) then version = Settings:getSettingInt("ChunkVersion") end

    if(Settings:dataTableContains("blocks", id)) then
        local group = Settings.lastFound
        for index, _ in ipairs(group) do
            local entry = group[index]

            --if the table's version is higher
            if(version ~= -1) then
                if(entry[1]:len() > 0) then if(tonumber(entry[1], 10) > version) then goto entryContinue end end
            end
            

            --if the table's meta is empty
            if(entry[2]:len() == 0) then
                local OUT = TagCompound.new()
                OUT.id = entry[3]
                OUT.meta = entry[4]
                OUT.flags = entry[5]
                OUT.heightmaps = entry[6]
                return OUT
            --if the input meta is a number or compound
            elseif(meta ~= nil) then
                --if the table's meta is a number
                if(tonumber(entry[2], 10) ~= nil) then
                    --if the input meta is a number
                    if(type(meta) == "number") then
                        --if the meta matches
                        if(tonumber(entry[2], 10) == meta) then
                            local OUT = TagCompound.new()
                            OUT.id = entry[3]
                            OUT.meta = entry[4]
                            OUT.flags = entry[5]
                            OUT.heightmaps = entry[6]
                            return OUT
                        end
                    end
                else
                    if(type(meta) == "userdata") then
                        if(Utils:CompareStates(entry[2], meta)) then
                            local OUT = TagCompound.new()
                            OUT.id = entry[3]
                            OUT.meta = entry[4]
                            OUT.flags = entry[5]
                            OUT.heightmaps = entry[6]
                            return OUT
                        end
                    end
                end
            end

            ::entryContinue::
        end
    end

    return nil
end

return Utils