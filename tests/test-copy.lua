-- very first time writing tests .;
local copy = require("batelax.copy")
local COPY = copy.COPY

local meta = {
	__sub = function(self, other)
		return "custom __sub"
	end
}

local function copier()
	return "custom copier"
end


---@diagnostic disable: undefined-global
describe("the COPY object", function()
	it("should support subtraction", function()
		assert.has.no.errors(function() return COPY - 1                  end)
		assert.has.no.errors(function() return COPY - "hello"            end)
		assert.has.no.errors(function() return COPY - true               end)
		assert.has.no.errors(function() return COPY - {"1", 2, true, {}} end)

		local object = setmetatable({}, meta)

		assert.has.no.errors(function() return COPY - object end)
		assert.are.not_equal("custom __sub", COPY - object)
	end)

	it("should error when it's the second arg of subtraction", function()
		assert.has.error(function() return 1                  - COPY end, "First operand in copy must be a COPY object")
		assert.has.error(function() return "hello"            - COPY end, "First operand in copy must be a COPY object")
		assert.has.error(function() return true               - COPY end, "First operand in copy must be a COPY object")
		assert.has.error(function() return {"1", 2, true, {}} - COPY end, "First operand in copy must be a COPY object")
	end)

	it("should create truthy instances", function()
		assert.is.truthy(COPY - 1)
	end)

	it("should have a neat string representation", function()
		assert.are.same("<COPY>", tostring(COPY))
	end)

	describe("instances", function()
		it("should have a neat string representation", function()
			assert.are.same("<COPY - 1 (number)>", tostring(COPY - 1))
			assert.are.same("<COPY - hell'\"o (string)>", tostring(COPY - "hell'\"o"))
		end)
	end)

	describe("instance data", function()
		it("should be retrievable", function()
			local value = {}
			local data = copy.getObjectData(COPY - value)

			assert.is_function(data.copier, "copier must be a function")
			assert.are.equal(value, data.value, "value must be unchanged")
		end)

		it("should contain a valid copier", function()
			local value = { "hello there!", hi = { nil, 2 } }
			local data = copy.getObjectData(COPY - value)
			local copied = data.copier(data.value)

			assert.are.not_equal(value, copied, "must have been copied")
			assert.are.same(value, copied, "must have been copier properly")
		end)
	end)

	describe("custom copiers", function()
		it("should be creatable", function()
			assert.has.no.error(function() return COPY(copier) end)
		end)

		it("should accept only functions", function()
			assert.has.error(function() return COPY(1)       end, "Copier must be a function")
			assert.has.error(function() return COPY("hello") end, "Copier must be a function")
			assert.has.error(function() return COPY(true)    end, "Copier must be a function")
			assert.has.error(function() return COPY({})      end, "Copier must be a function")
		end)

		it("should not allow more than one copier", function()
			assert.has.error(function() return COPY(copier)(copier) end)
		end)

		it("should support subtraction", function()
			assert.has.no.errors(function() return COPY(copier) - 1 end)
			assert.has.no.errors(function() return COPY(copier) - "hello" end)
			assert.has.no.errors(function() return COPY(copier) - true end)
			assert.has.no.errors(function() return COPY(copier) - { "1", 2, true, {} } end)
		end)

		it("should error when it's the second arg of subtraction", function()
			assert.has.error(function() return 1                    - COPY(copier) end, "First operand in copy must be a COPY object")
			assert.has.error(function() return "hello"              - COPY(copier) end, "First operand in copy must be a COPY object")
			assert.has.error(function() return true                 - COPY(copier) end, "First operand in copy must be a COPY object")
			assert.has.error(function() return { "1", 2, true, {} } - COPY(copier) end, "First operand in copy must be a COPY object")
		end)

		it("should create truthy instances", function()
			assert.is.truthy(COPY(copier) - 1)
		end)

		it("should have a neat tostring representation", function()
			assert.are.same("<COPY>", tostring(COPY(copier)))
		end)

		describe("instances", function()
			it("should have a neat tostring representation", function()
				assert.are.same("<COPY - 1 (number)>",        tostring(COPY(copier) - 1         ))
				assert.are.same("<COPY - hell'\"o (string)>", tostring(COPY(copier) - "hell'\"o"))
			end)
		end)

		describe("instance data", function()
			it("should be retrievable", function()
				local value = {}
				local data = copy.getObjectData(COPY(copier) - value)

				assert.are.equal(copier, data.copier, "copier must be unchanged")
				assert.are.equal(value, data.value, "value must be unchanged")
			end)
		end)
	end)
end)