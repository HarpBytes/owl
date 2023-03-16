local reader = require("src.reader")

print("Owl - a programming language")

reader:run_tests()

local f = string.format

local function owl_fun_to_lua(st, ident, args, body)
  return f(
    "function %s ()\n %s \nend",
      ident.value,
      ""
  )
end

local function owl_expr_to_lua(st, node)
  if node.kind == "table" then
    if #node.value > 0 then
      local ident, vs = node.value[1], node.value

      if ident.value == "fun" then
        return owl_fun_to_lua(st, vs[2], vs[3])
      else
        local rest = {}
        for i = 2, #vs do table.insert(rest, vs[i]) end
        return f("_G[\'%s\'](%s)", ident.value, table.concat(rest, ", "))
      end
    else
      return "{}"
    end
  else
    return f("%s", tostring(node.value))
  end
end

local function owl_expr_to_lua_stmt(st, node)
  table.insert(st.statements, f("local _%d = %s", st.num_locals, owl_expr_to_lua(st, node)))
end

local function owl_to_lua_v1(code)
  local ast = reader(code)

  if nil then
    error("Cannot parse")
  end

  local st = {
    num_locals = #ast.value,
    statements = {}
  }

  for i = 1, #ast.value do
    table.insert(st.statements, owl_expr_to_lua(st, ast.value[i]))
  end

  return table.concat(st.statements, "\n")
end

print(":::::::")

local function read_file(path)
  local file = io.open(path, "r")
  if file then
    local contents = file:read("*a")
    file:close()
    return contents
  else
    return ""
  end
end

local lua = owl_to_lua_v1(read_file("repl.owl"))

print("LUA: ")
print(lua)

local ok, error = pcall(function()
  return load(lua)()
end)

print(ok, error)