local objects = setmetatable({}, {__mode = "k"})

local function getCount(object)
	return objects[object] or nil
end

local function setCount(object, count)
	objects[object] = count
	return object
end

local function objectTostring(self)
	return "<GET * " .. getCount(self) .. ">"
end


local GET = setmetatable({}, {
	__mul = function(self, num)
		if objects[num] then
			self, num = num, self
		end

		if type(num) ~= "number" or num <= 0 or math.floor(num) ~= num then
			error("GET may only be multiplied with positive integers greater than 0", 2)
		end

		local object = setmetatable({}, { __tostring = objectTostring })

		return setCount(object, num)
	end,
	__tostring = function() return "<GET>" end,
})

setCount(GET, 1)

return {
	GET = GET,
	getCount = getCount,
}