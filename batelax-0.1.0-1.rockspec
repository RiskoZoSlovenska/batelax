package = "batelax"
version = "0.1.0-1"
source = {
   url = "git+http://github.com/RiskoZoSlovenska/batelax",
}
description = {
   summary = "A luassert extension for easily testing lots of function calls.",
   detailed = [[
      TBA
   ]],
   homepage = "http://github.com/RiskoZoSlovenska/batelax", -- We don't have one yet
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.4",
   "luassert",
   "say",
}
build = {
   type = "builtin",
   modules = {
      ["batelax.init"] = "src/init.lua",
      ["batelax.core"] = "src/core.lua",
      ["batelax.get"] = "src/get.lua",
      ["batelax.copy"] = "src/copy.lua",
      ["batelax.varargs"] = "src/varargs.lua",
      ["batelax.inject"] = "src/inject.lua",
      ["batelax.assertl"] = "src/assertl.lua",
      ["batelax.util"] = "src/util.lua",
   },
}