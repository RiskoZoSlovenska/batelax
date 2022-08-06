# Batelax

**BA**tch **TE**sting **L**u**A**ssert e**X**tension

An experimental [luassert](https://github.com/Olivine-Labs/luassert) extension which aims to simplify writing many similar tests.

For example, consider the following:
```lua
assert.are.same(parse("34"), { { Literal(34), lineNum = 1 } })
assert.are.same(parse("34.3"), { { Literal(34.3), lineNum = 1 } })
assert.are.same(parse("34e2"), { { Literal(3400), lineNum = 1 } })
assert.are.same(parse("34.3e2"), { { Literal(3430), lineNum = 1 } })
assert.are.same(parse("34.3e-2"), { { Literal(0.343), lineNum = 1 } })
assert.are.same(parse("-34"), { { Literal(-34), lineNum = 1 } })
assert.are.same(parse("-34.3"), { { Literal(-34.3), lineNum = 1 } })
assert.are.same(parse("-34e2"), { { Literal(-3400), lineNum = 1 } })
assert.are.same(parse("-34.3e2"), { { Literal(-3430), lineNum = 1 } })
assert.are.same(parse("-34.3e-2"), { { Literal(-0.343), lineNum = 1 } })
```

Using Batelax, it can be rewritten as:
```lua
assert.func(parse).returns{
	"34", { { Literal(34), lineNum = 1 } },
	"34.3", { { Literal(34.3), lineNum = 1 } },
	"34e2", { { Literal(3400), lineNum = 1 } },
	"34.3e2", { { Literal(3430), lineNum = 1 } },
	"34.3e-2", { { Literal(0.343), lineNum = 1 } },
	"-34", { { Literal(-34), lineNum = 1 } },
	"-34.3", { { Literal(-34.3), lineNum = 1 } },
	"-34e2", { { Literal(-3400), lineNum = 1 } },
	"-34.3e2", { { Literal(-3430), lineNum = 1 } },
	"-34.3e-2", { { Literal(-0.343), lineNum = 1 } },
}
```


## Installation

Not published to Luarocks yet. For now, `git clone` the repo and then run `luarocks make`.


## Docs

TBA. For now just see `tests/`.


## Development

Run tests: `luarocks make && busted`