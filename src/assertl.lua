-- Utility assert function which takes a level. Using luassert messes up tests
-- for whatever reason (returns a table which doesn't get caught properly by
-- assert.has.error).
return function(cond, msg, level, ...)
	if cond then
		return cond
	else
		error(string.format(msg, ...), (level or 1) + 1)
	end
end