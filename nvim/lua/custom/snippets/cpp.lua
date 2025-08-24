local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt


return {
  s("fori", {
    t("for (int "), i(1, "i"), t(" = 0; "), rep(1), t(" < "), i(2, "n"), t("; "), rep(1), t({ "++) {", "\t" }),
    i(0),
    t({ "", "}" })
  })
}
