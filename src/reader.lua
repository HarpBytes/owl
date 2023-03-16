local lpeg = require("lib.lulpeg")

local P, S, R, B, V = lpeg.P, lpeg.S, lpeg.R, lpeg.B, lpeg.V
local C, Ct = lpeg.C, lpeg.Ct
local match = lpeg.match

local locale = lpeg.locale();

local function echo(a)
  if type(a) == "table" then
    local xs = {}
    for _, c in pairs(a) do table.insert(xs, echo(c)) end
    return "(" .. table.concat(xs, " ") .. ")"
  else
    return tostring(a)
  end
end

local function node(value)
  return setmetatable({
    kind = type(value),
    value = value,
  }, {
    __tostring = function(self)
      if type(self.value) == "table" then
        local xs = {}
        for _, c in pairs(self.value) do table.insert(xs, tostring(c)) end
        return "(" .. table.concat(xs, " ") .. ")"
      else
        return tostring(self.value)
      end
    end,
  })
end

local owl = P {
  "script",
  script    = Ct(V"ws" * (V"exp" * V"ws")^0),
  num       = C(R"09"^1) / tonumber,
  boolean   = C(P"#t" + P"#f") / function(v) return v == "#t" end,
  atom      = C((1 - (locale.space + S'()[]{}<>\',"'))^1),
  string    = C(P'"' * (1 - P'"')^0 * P'"'),
  val       = V"string" + V"num" + V"boolean" + V"atom",
  comment   = P";"^1 * (P(1) - P"\n")^0 * (P"\n" + -P(1)),
  ws        = (locale.space + V "comment")^0,
  exp       = Ct(P"(" * (V"ws" * V"exp" * V"ws")^0 * P")") + V"val",
}

local function read(ast)
  if type(ast) == "table" then
    local ns = node({})
    for i = 1, #ast do
      table.insert(ns.value, read(ast[i]))
    end
    return ns
  else
    return node(ast)
  end
end


function owl:run_tests()
  print(echo(match(owl, "1")))
  print(echo(match(owl, "123 321 9999")))
  print(echo(match(owl, "(1 2 3)")))
  print(echo(match(owl, "()")))
  print(echo(match(owl, [[
    ;; some comment
    32 ; hello
  ]])))
  print(echo(match(owl, "(#t #f)")))
  print(echo(match(owl, "a")))
  print(echo(match(owl, "hello (world)")))
  print(echo(match(owl, '"value"')))
  print(echo(match(owl, '(echo "Hello, World!")')))
  print(echo(match(owl, '(+ 1 (* 3 2) (/ 1 2))')))
end

return setmetatable({
  owl = owl,
  read = read,
  run_tests = owl.run_tests,
}, {
  __call = function(_, ...)
    local exp = owl:match(...)
    return read(exp)
  end,
})