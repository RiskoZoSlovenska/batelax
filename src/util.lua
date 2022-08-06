--[[--
	These functions were taken from luassert's `util` module. They are copied
	here because I believe said module is not considered public and thus is
	unstable.
]]

local spy = require("luassert.spy")

--[[
	Original taken from https://github.com/Olivine-Labs/luassert/blob/5f3f32946a33c41579340e7239f4d6367144d32a/src/util.lua#L12-L97
	
	Not modified to keep behavior the same as luassert's.
]]
local function deepcompare(t1, t2, ignore_mt, cycles, thresh1, thresh2)
	local ty1 = type(t1)
	local ty2 = type(t2)
	-- non-table types can be directly compared
	if ty1 ~= 'table' or ty2 ~= 'table' then return t1 == t2 end
	local mt1 = debug.getmetatable(t1)
	local mt2 = debug.getmetatable(t2)
	-- would equality be determined by metatable __eq?
	if mt1 and mt1 == mt2 and mt1.__eq then
		-- then use that unless asked not to
		if not ignore_mt then return t1 == t2 end
	else -- we can skip the deep comparison below if t1 and t2 share identity
		if rawequal(t1, t2) then return true end
	end

	-- handle recursive tables
	cycles = cycles or { {}, {} }
	thresh1, thresh2 = (thresh1 or 1), (thresh2 or 1)
	cycles[1][t1] = (cycles[1][t1] or 0)
	cycles[2][t2] = (cycles[2][t2] or 0)
	if cycles[1][t1] == 1 or cycles[2][t2] == 1 then
		thresh1 = cycles[1][t1] + 1
		thresh2 = cycles[2][t2] + 1
	end
	if cycles[1][t1] > thresh1 and cycles[2][t2] > thresh2 then
		return true
	end

	cycles[1][t1] = cycles[1][t1] + 1
	cycles[2][t2] = cycles[2][t2] + 1

	for k1, v1 in next, t1 do
		local v2 = t2[k1]
		if v2 == nil then
			return false, { k1 }
		end

		local same, crumbs = deepcompare(v1, v2, nil, cycles, thresh1, thresh2)
		if not same then
			crumbs = crumbs or {}
			table.insert(crumbs, k1)
			return false, crumbs
		end
	end
	for k2, _ in next, t2 do
		-- only check whether each element has a t1 counterpart, actual comparison
		-- has been done in first loop above
		if t1[k2] == nil then return false, { k2 } end
	end

	cycles[1][t1] = cycles[1][t1] - 1
	cycles[2][t2] = cycles[2][t2] - 1

	return true
end

-- Copied and modified from https://github.com/Olivine-Labs/luassert/blob/5f3f32946a33c41579340e7239f4d6367144d32a/src/util.lua#L78-L97
--   * Removed deepmt param (now always false)
--   * Moved `spy` require to the top of the file
local function deepcopy(t, cache)
	if type(t) ~= "table" then return t end
	local copy = {}

	-- handle recursive tables
	cache = cache or {}
	if cache[t] then return cache[t] end
	cache[t] = copy

	for k, v in next, t do
		copy[k] = (spy.is_spy(v) and v or deepcopy(v, cache))
	end
	debug.setmetatable(copy, debug.getmetatable(t))
	return copy
end


return {
	deepcompare = deepcompare,
	deepcopy = deepcopy,
}