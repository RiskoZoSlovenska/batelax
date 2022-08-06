---@diagnostic disable: undefined-global
local get = require("batelax.get")
local GET = get.GET

describe("the GET object", function()
	it("should support multiplication with positive integers", function()
		local res = assert.has.no.error(function() return GET * 2 end)
		assert.is.truthy(res)
	end)

	it("should error when multipied with invalid numbers", function()
		assert.has.error(function() return GET * 3.2 end, "GET may only be multiplied with positive integers greater than 0")
		assert.has.error(function() return GET * 0   end, "GET may only be multiplied with positive integers greater than 0")
		assert.has.error(function() return GET * -2  end, "GET may only be multiplied with positive integers greater than 0")
	end)

	it("should error when multipied with non-number", function()
		assert.has.error(function() return GET * "3"  end, "GET may only be multiplied with positive integers greater than 0")
		assert.has.error(function() return GET * {}   end, "GET may only be multiplied with positive integers greater than 0")
		assert.has.error(function() return GET * true end, "GET may only be multiplied with positive integers greater than 0")
		
		-- LuaJIT's numbers are unsupported for now
		if jit then
			local num = (loadstring or load)("return 0ULL")()
			assert.has.error(function() return GET * num end, "GET may only be multiplied with positive integers greater than 0")
		end
	end)

	it("should have a neat string representation", function()
		assert.are.same("<GET>", tostring(GET))
	end)

	it("should have a count of 1", function()
		assert.are.same(1, get.getCount(GET))
	end)

	describe("instances", function()
		it("should have a count corresponding to what they were multiplied with", function()
			assert.are.same(4, get.getCount(GET * 4))
		end)

		it("should not support further multiplications", function()
			assert.has.error(function() return (GET * 2) * 3 end)
		end)

		it("should have a neat string representation", function()
			assert.are.same("<GET * 5>", tostring(GET * 5))
		end)
	end)
end)