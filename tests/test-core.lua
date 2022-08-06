local assert = require("batelax")

local function wrap(func)
	return function(...)
		local success, err = pcall(func, ...)
		if not success then
			error(tostring(err), 0)
		else
			return err
		end
	end
end

local function addOne(x)
	return x + 1
end

local function sub(a, b)
	return a - b
end

local function identity(a, b, c)
	if a ~= b then
		return "a ~= b"
	elseif b == c then
		return "b == c"
	else
		return "ok"
	end
end

local function identityError(a, b, c)
	if a ~= b then
		error("a ~= b")
	elseif b == c then
		error("b == c")
	else
		error("ok")
	end
end

local function constant()
	return "Hello World!"
end

local function echo(...)
	return ...
end

local function echoError(a, b)
	error(a .. b)
end

local function constantError()
	error("constant error")
end


---@diagnostic disable: undefined-global
describe("the `func` modifier", function()
	it("should accept only functions", function()
		assert.has.no.error(function() assert.func(sub) end)
		assert.has.error(function() assert.func(3) end, "The `func` modifier expects a function")
	end)

	it("should error if called more than once", function()
		assert.has.error(function() assert.func(sub).func(sub) end, "The `func` modifier has already been set")
	end)
end)

describe("the `with_params` modifier", function()
	it("should error if called without the `func` modifier", function()
		assert.has.error(function() assert.with_params() end, "The `with_params` modifier requires the `func` modifier")
	end)
end)

describe("the `returns` assertion", function()
	it("should error if called without the `func` modifier", function()
		assert.has.error(function() assert.returns({}) end, "The `returns` assertion requires the `func` modifier")
	end)

	it("should error if called without a table value", function()
		assert.has.error(function() assert.func(sub).returns(2) end, "The `returns` assertion must be passed a table")
	end)

	it("should perform simple tests", function()
		assert.has.no.error(wrap(function()
			assert.func(addOne).returns{
				1,  2;
				3,  4;
				-1, 0;
			}
		end))

		assert.error.matches(wrap(function()
			assert.func(addOne).returns{
				1,  2;
				1,  3; -- Uh oh!
				-1, 0;
			}
		end), "Case 2, return 1 expected to match:\nExpected:\n.-3.-\nGot:\n.-2.-")
	end)

	it("should handle the negative modifier", function()
		assert.has.no.error(wrap(function()
			assert.func(addOne).does.not_return{
				1,  1;
				2,  4;
			}
		end))

		assert.error.matches(wrap(function()
			assert.func(addOne).does.not_return{
				1,   5;
				1,   2; -- Uh oh!
				-1, -1;
			}
		end), "Case 2, return 1 expected to not match, but it did:\n.-2.-")
	end)

	it("should allow 0 params", function()
		assert.has.no.error(wrap(function()
			assert.func(constant).with.params().returns {
				"Hello World!",
				"Hello World!",
			}
		end))
	end)

	it("should allow 0 values", function()
		assert.has.no.error(wrap(function()
			assert.func(addOne).with.params(GET * 5).returns{}
		end))
	end)

	it("should allow multiple params", function()
		assert.has.no.error(wrap(function()
			assert.func(sub).with.params(GET, GET).returns{
				5, 2,  3;
				5, 1,  4;
			}
		end))

		assert.has.no.error(wrap(function()
			assert.func(sub).with.params(GET * 2).returns{
				5, 2,  3;
				5, 1,  4;
			}
		end))
	end)

	it("should allow constant params", function()
		assert.has.no.error(wrap(function()
			assert.func(sub).with.params(2, GET).returns{
				-2,   4;
				 3,  -1;
			}
		end))

		assert.has.no.error(wrap(function()
			assert.func(sub).with.params(GET, 2).returns{
				6,   4;
				1,  -1;
			}
		end))
	end)

	it("should allow copied constant params", function()
		local a = {}
		assert.has.no.error(wrap(function()
			assert.func(identity).with.params(a, GET, COPY - a).returns{
				a,    "ok";
				{},   "a ~= b";
			}
		end))
	end)

	it("should respect custom copiers", function()
		local function custom()
			return "custom copier"
		end

		assert.has.no.error(wrap(function()
			assert.func(echo).with.params(COPY(custom) - {}).returns{
				"custom copier";
				"custom copier";
			}
		end))
	end)

	it("should error if the `returns` field is not a table", function ()
		assert.has.error(wrap(function()
			assert.func(sub).returns {
				returns = 3;
			}
		end), "`returns` must be a table")
	end)

	it("should allow multiple returns", function()
		assert.has.no.error(wrap(function()
			assert.func(echo).with.params(GET * 2).returns {
				returns = { GET, GET };

				1, 2,         1, 2;
				"hello", {},  "hello", {};
			}
		end))

		assert.has.no.error(wrap(function()
			assert.func(echo).with.params(GET * 2).returns {
				returns = { GET * 2 };

				1, 2,          1, 2;
				"hello", {},   "hello", {};
			}
		end))

		assert.error.matches(wrap(function()
			assert.func(echo).with.params(GET * 2).returns {
				returns = { GET * 2 };

				1, 2,          1, 2;
				{}, "hello",   {}, "helo";
			}
		end), "Case 2, return 2 expected to match:\nExpected:\n.-helo.-\nGot:\n.-hello.-")
	end)

	it("should allow constant returns", function()
		assert.has.no.error(wrap(function()
			assert.func(echo).with_params("pre", GET, "post").returns{
				returns = { "pre", GET, "post" };

				"hi",  "hi";
				{},    {};
			}
		end))
	end)

	it("should allow VARARGS", function()
		assert.has.no.error(wrap(function()
			assert.func(echo).with.params(GET, VARARGS).returns{
				returns = { GET * 2, VARARGS };

				1, {2, 3},      1, 2, {3};
				1, {4, 5, 6},   1, 4, {5, 6};
			}
		end))
	end)

	it("should error if the VARARGS object isn't the last parameter", function()
		assert.has.error(wrap(function()
			assert.func(echo).with.params(VARARGS, GET).returns{
				{5}, 2,    5;
			}
		end), "The VARARGS object must be the last value")

		assert.has.error(wrap(function()
			assert.func(echo).returns{
				returns = { VARARGS, GET };

				5,   {5}, 2;
			}
		end), "The VARARGS object must be the last value")
	end)

	it("should error if the VARARGS value isn't a table", function()
		assert.has.error(wrap(function()
			assert.func(echo).with.params(VARARGS).returns {
				4,  4;
			}
		end), "The VARARGS value must be table")

		assert.has.error(wrap(function()
			assert.func(echo).returns {
				returns = { VARARGS };

				4,   4;
			}
		end), "The VARARGS value must be table")
	end)
end)

describe("the `throws()` assertion", function()
	it("should error if called without the `func` modifier", function()
		assert.has.error(function() assert.throws({}) end, "The `throws` assertion requires the `func` modifier")
	end)

	it("should error if called without a table value", function()
		assert.has.error(function() assert.func(sub).throws(2) end, "The `throws` assertion must be passed a table")
	end)

	it("should match basic errors", function()
		assert.has.no.error(wrap(function()
			assert.func(error).throws{
				"oh no this is bad",   "oh no this is bad";
				"123456",              "%d+";
				"enbksgfahlksfhak",    ".*";
			}
		end))

		assert.error.matches(wrap(function()
			assert.func(error).throws{
				"oh no",  "huh";
			}
		end), "Case 1 error expected to match:\nExpected:\n.-huh.-\nGot:\n.-oh no.-\nOther returns:\n%(none%)")

		assert.error.matches(wrap(function()
			assert.func(addOne).throws{
				4, "what";
			}
		end), "Case 1 error expected to match:\nExpected:\n.-what.-\nGot:\n%(no error%)\nOther returns:\n5")
	end)

	it("should compare non-string errors", function()
		assert.has.no.error(wrap(function()
			assert.func(error).throws{
				3,                             _VERSION < "Lua 5.3" and "3" or 3;
				{ [true] = { "hello", 2 } },   { [true] = { "hello", 2 } };
			}
		end))
	end)

	it("should handle the negative modifier", function()
		assert.has.no.error(wrap(function()
			assert.func(error).does.not_throw{
				"oh no this is bad",   "idk";
				"123456",              "%s+";
			}
		end))

		assert.has.no.error(wrap(function()
			assert.func(addOne).does.not_throw{
				3,   "idk";
			}
		end))

		assert.error.matches(wrap(function()
			assert.func(error).does.not_throw{
				"oh no", "oh no";
			}
		end), "Case 1 error expected to not match, but it did:\n.-oh no.-")
	end)

	it("should allow 0 values", function()
		assert.has.no.error(wrap(function()
			assert.func(error).with.params(GET * 5).throws{}
		end))
	end)

	it("should allow 0 params", function()
		assert.has.no.error(wrap(function()
			assert.func(constantError).with.params().throws{
				"constant error",
				"constant error",
			}
		end))
	end)

	it("should allow multiple params", function()
		assert.has.no.error(wrap(function()
			assert.func(echoError).with.params(GET, GET).throws{
				"he", "llo",  "hello";
			}
		end))

		assert.has.no.error(wrap(function()
			assert.func(echoError).with.params(GET * 2).throws{
				"he", "llo",  "hello";
			}
		end))
	end)

	it("should allow constant params", function()
		assert.has.no.error(wrap(function()
			assert.func(echoError).with.params("he", GET).throws{
				"llo",   "hello";
			}
		end))

		assert.has.no.error(wrap(function()
			assert.func(echoError).with.params(GET, "llo").throws{
				"he",  "hello";
			}
		end))
	end)

	it("should allow copied constant params", function()
		local a = {}
		assert.has.no.error(wrap(function()
			assert.func(identityError).with.params(a, GET, COPY - a).throws{
				a,    "ok";
				{},   "a ~= b";
			}
		end))
	end)

	it("should respect custom copiers", function()
		local function custom()
			return "custom copier"
		end

		assert.has.no.error(wrap(function()
			assert.func(echoError).with.params(COPY(custom) - {}, "").throws{
				"custom copier";
				"custom copier";
			}
		end))
	end)

	it("should allow VARARGS", function()
		assert.has.no.error(wrap(function()
			assert.func(echoError).with.params(GET, VARARGS).throws{
				"hel", {"lo"},   "hello";
			}
		end))
	end)

	it("should error if the VARARGS object isn't the last parameter", function()
		assert.has.error(wrap(function()
			assert.func(echoError).with.params(VARARGS, GET).throws{
				{"he"}, "llo",    "hello";
			}
		end), "The VARARGS object must be the last value")
	end)

	it("should error if the VARARGS value isn't a table", function()
		assert.has.error(wrap(function()
			assert.func(error).with.params(VARARGS).returns {
				"hello",   "hello";
			}
		end), "The VARARGS value must be table")
	end)
end)