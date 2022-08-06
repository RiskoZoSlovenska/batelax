local assert = require("luassert")
local say = require("say")

local get = require("batelax.get")
local copy = require("batelax.copy")
local varargs = require("batelax.varargs")
local util = require("batelax.util")
local assertl = require("batelax.assertl")

local FUNC_STATE_KEY = "__batelax_func_state"
local FUNC_PARAMS_KEY = "__batelax_func_params"

-- 5.1 compatibility
local table_unpack = table.unpack or unpack
local table_pack = table.pack or function(...)
	return {
		n = select("#", ...),
		...
	}
end



local function getLen(tbl)
	if tbl.n then
		return tbl.n
	end

	local highest = 0
	for index in pairs(tbl) do
		if type(index) == "number" and index > highest then
			highest = index
		end
	end

	tbl.n = highest
	return highest
end

local function append(tbl, value)
	tbl[getLen(tbl) + 1] = value
	tbl.n = tbl.n + 1
end

local function unpack(tbl, i, j)
	return table_unpack(tbl, i or 1, j or getLen(tbl))
end


local function slice(tbl, start, stop)
	local sliced = {}

	for i = start, stop do
		sliced[i - start + 1] = tbl[i]
	end
	sliced.n = stop - start + 1

	return sliced
end



-- Parses a templates list into a more workable representation by expanding
-- multiplied GETs and turning the presence of the MANY object into a boolean
-- flag property.
local function parseTemplate(template)
	local expanded = { getsCount = 0 }

	for i = 1, getLen(template) do
		local value = template[i]
		local getCount = get.getCount(value)

		if getCount then
			for _ = 1, getCount do
				append(expanded, get.GET)
				expanded.getsCount = expanded.getsCount + 1
			end
		else
			append(expanded, value)

			if value == varargs.VARARGS then
				expanded.getsCount = expanded.getsCount + 1
			end
		end
	end

	return expanded
end

local function buildValues(template, inputted, level)
	level = (level or 1) + 1
	local values = {}

	local inputtedI = 1
	for templateI = 1, getLen(template) do
		local templateValue = template[templateI]
		local isGet = get.getCount(templateValue)
		local copyData = copy.getObjectData(templateValue)

		local value
		-- VARARGS
		if templateValue == varargs.VARARGS then
			value = inputted[inputtedI]
			-- No need to increase inputtedI since we're at the end anyways

			assertl(templateI == getLen(template), "The VARARGS object must be the last value", level)
			assertl(type(value) == "table", "The VARARGS value must be table", level)

			for varargI = 1, getLen(value) do
				append(values, value[varargI])
			end
			break -- We must break so we don't append `nil`

		-- GET
		elseif isGet then
			value = inputted[inputtedI]
			inputtedI = inputtedI + 1

		-- COPY
		elseif copyData then
			value = copyData.copier(copyData.value)

		-- Normal
		else
			value = templateValue
		end

		append(values, value)
	end

	return values
end

local function iterCases(rawParams, rawReturns, values, level)
	level = (level or 1) + 1
	assertl(type(values) == "table", "First argument must be a table", level)

	local paramsTemplate = parseTemplate(rawParams)
	local returnsTemplate = parseTemplate(rawReturns)

	local valuesCount = getLen(values)
	local caseSize = paramsTemplate.getsCount + returnsTemplate.getsCount

	local i = 1 - caseSize
	local caseNum = 0

	return function()
		i = i + caseSize
		caseNum = caseNum + 1

		if i > valuesCount then
			return nil, nil, nil
		end

		local argsBegin = i
		local argsEnd = argsBegin + paramsTemplate.getsCount - 1
		local argsSlice = slice(values, argsBegin, argsEnd)
		local argValues = buildValues(paramsTemplate, argsSlice, level)

		local returnsBegin = argsEnd + 1
		local returnsEnd = returnsBegin + returnsTemplate.getsCount - 1
		local returnsSlice = slice(values, returnsBegin, returnsEnd)
		local expectedReturns = buildValues(returnsTemplate, returnsSlice, level)

		return caseNum, argValues, expectedReturns
	end
end




local function func_modifier(state, args, level)
	level = (level or 1) + 1

	local func = args[1]
	assertl(type(func) == "function", "The `func` modifier expects a function", level)

	assertl(rawget(state, FUNC_STATE_KEY) == nil, "The `func` modifier has already been set", level)
	rawset(state, FUNC_STATE_KEY, func)

	return state
end

local function with_params_modifier(state, args, level)
	level = (level or 1) + 1

	assertl(rawget(state, FUNC_STATE_KEY) ~= nil, "The `with_params` modifier requires the `func` modifier", level)
	rawset(state, FUNC_PARAMS_KEY, args)

	return state
end



local function getStateInformation(where, state, args, level)
	level = (level or 1) + 1

	local func = rawget(state, FUNC_STATE_KEY)
	assertl(func ~= nil, "The %s requires the `func` modifier", level, where)

	local values = args[1]
	assertl(type(values) == "table", "The %s must be passed a table", level, where)

	local params = rawget(state, FUNC_PARAMS_KEY) or { GET }

	return func, values, params
end

local function formatReturnArgs(args, values, size, noFmt, crumbs)
	-- This formatting API might be unstable, welp
	for i = 1, size do
		args[i] = values[i]
	end
	args.n = size

	if noFmt then
		args.nofmt = {}
		for _, index in ipairs(noFmt) do
			args.nofmt[index] = true
		end
	end

	if crumbs then
		args.fmtargs = args.fmtargs or {}
		for i, crumbs in pairs(crumbs) do
			args.fmtargs[i] = { crumbs = crumbs }
		end
	end
end

local function returns_assertion(state, args, level)
	level = (level or 1) + 1

	local func, values, rawParams = getStateInformation("`returns` assertion", state, args, level)
	local rawReturns = values.returns or { GET }

	assertl(type(rawReturns) == "table", "`returns` must be a table", level)

	for caseNum, argValues, expectedReturns in iterCases(rawParams, rawReturns, values, level) do
		local actualReturns = table_pack(func(unpack(argValues)))

		for returnNum = 1, actualReturns.n do
			local actual, expected = actualReturns[returnNum], expectedReturns[returnNum]

			local same, crumbs = util.deepcompare(actual, expected)
			if same ~= (not not state.mod) then
				formatReturnArgs(args,
					{ caseNum, returnNum, expected, actual }, 4,
					{ 1, 2 },
					{ [3] = crumbs, [4] = crumbs }
				)

				return not state.mod
			end
		end
	end

	return state.mod
end

local function throws_assertion(state, args, level)
	level = (level or 1) + 1

	local func, values, rawParams = getStateInformation("`throws` assertion", state, args, level)
	local rawReturns = { GET }

	for caseNum, argValues, expectedReturns in iterCases(rawParams, rawReturns, values, level) do
		local actualReturns = table_pack(pcall(func, unpack(argValues)))
		local passed, err = actualReturns[1], actualReturns[2]
		local expectedError = expectedReturns[1]

		local same, crumbs
		if passed then
			same, crumbs = false, nil
		elseif type(err) == "string" and type(expectedError) == "string" then
			same = (string.find(err, expectedError) ~= nil)
			crumbs = nil
		else
			same, crumbs = util.deepcompare(expectedError, err)
		end

		local otherReturns = {}
		for i = 2, actualReturns.n do
			append(otherReturns, tostring(actualReturns[i]))
		end

		if same ~= (not not state.mod) then
			formatReturnArgs(args,
				{ caseNum, expectedError, passed and "(no error)" or err, passed and table.concat(otherReturns, "\t") or "(none)" }, 4,
				{ 1, 4, (passed and 3 or nil) },
				{ [2] = crumbs, [3] = crumbs }
			)

			return not state.mod
		end
	end

	return state.mod
end



say:set_namespace("en")
say:set("assertion.func_returns.positive", "Case %s, return %s expected to match:\nExpected:\n%s\nGot:\n%s")
say:set("assertion.func_returns.negative", "Case %s, return %s expected to not match, but it did:\n%s")
say:set("assertion.func_throws.positive", "Case %s error expected to match:\nExpected:\n%s\nGot:\n%s\nOther returns:\n%s")
say:set("assertion.func_throws.negative", "Case %s error expected to not match, but it did:\n%s")

assert:register("modifier", "func", func_modifier)
assert:register("modifier", "with_params", with_params_modifier)

assert:register("assertion", "returns", returns_assertion,
	"assertion.func_returns.positive", "assertion.func_returns.negative"
)
assert:register("assertion", "return", returns_assertion,
	"assertion.func_returns.positive", "assertion.func_returns.negative"
)

assert:register("assertion", "throws", throws_assertion,
	"assertion.func_throws.positive", "assertion.func_throws.negative"
)
assert:register("assertion", "throw", throws_assertion,
	"assertion.func_throws.positive", "assertion.func_throws.negative"
)
