local function assertEqual(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
  end
end

local unpack = table.unpack or unpack

local direct = { [2] = "value" }
assertEqual(#direct, 0, "direct sparse constructor length")

local list = { nil, "value" }
assertEqual(#list, 2, "list constructor length")

local dynamic = {}
dynamic[2] = "value"
assertEqual(#dynamic, 2, "dynamic sparse table length")

local copied = {}
for key, value in pairs(list) do
  copied[key] = value
end
assertEqual(#copied, 2, "copied sparse table length")
assertEqual(select("#", unpack(copied)), 2, "copied sparse table unpack count")
local first, second = unpack(copied)
assertEqual(first, nil, "copied sparse table first value")
assertEqual(second, "value", "copied sparse table second value")

print("LuaJIT table compatibility checks passed")
