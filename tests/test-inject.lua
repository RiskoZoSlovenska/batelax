---@diagnostic disable: undefined-global
describe("batelax", function()
	it("should inject special objects into the global scope", function()
		require("batelax")

		assert.is.not_nil(GET)
		assert.is.not_nil(COPY)
		assert.is.not_nil(VARARGS)
	end)
end)