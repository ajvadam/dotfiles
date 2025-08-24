local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmta = require("luasnip.extras.fmt").fmta

-- Only available in C/C++ files
return {
  s({ trig = "fori", dscr = "Indexed for-loop for C/C++" }, {
    t("for (int "), i(1, "i"), t(" = 0; "), i(2, "i"), t(" < "), i(3, "n"), t({ "; ", "" }),
    t("i++"), t({ ") {", "\t" }),
    i(0),
    t({ "", "}" }),
  }, {
    condition = function()
      return vim.bo.filetype == "c" or vim.bo.filetype == "cpp"
    end
  }),

  s({ trig = "forr", dscr = "Range-based for-loop (C++)" }, fmta([[
  for (auto& <elem> : <container>) {
      <code>
  }
  ]], {
    elem = i(1, "item"),
    container = i(2, "container"),
    code = i(0),
  }), {
    condition = function()
      return vim.bo.filetype == "cpp" -- C++11+ only
    end
  })
}
