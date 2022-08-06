local assertl = require("batelax.assertl")
local util = require("batelax.util")

local creators = setmetatable({}, { __mode = "k" })
local objects = setmetatable({}, { __mode = "k" })

local function getObjectData(object)
	return objects[object]
end

local function getCreatorCopier(creator)
	return creators[creator] or nil
end


local function creatorTostring(self)
	return "<COPY>"
end

local function objectTostring(self)
	local value = getObjectData(self).value
	return string.format("<COPY - %s (%s)>", tostring(value), type(value))
end


local function createObject(self, value)
	local copier = assertl(getCreatorCopier(self), "First operand in copy must be a COPY object", 2)

	local object = setmetatable({}, { __tostring = objectTostring })
	local objectData = {
		value = value,
		copier = copier,
	}

	objects[object] = objectData
	return object
end

local function createCreator(copier, isBase)
	assertl(type(copier) == "function", "Copier must be a function", 3)

	local meta = {
		__sub = createObject,
		__tostring = creatorTostring,
	}
	if isBase then
		meta.__call = function(self, newCopier)
			return createCreator(newCopier, false)
		end
	end

	local creator = setmetatable({}, meta)

	creators[creator] = copier
	return creator
end


local COPY = createCreator(util.deepcopy, true)

return {
	getObjectData = getObjectData,
	COPY = COPY,
}