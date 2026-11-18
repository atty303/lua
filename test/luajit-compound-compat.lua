-- Compound-assignment compatibility with LuaJIT 2460b3ff93a1c955de3d62cfc825de7d68dc272e.
-- This runtime implements its existing arithmetic and concatenation operators;
-- LuaJIT's newer bitwise operators remain outside this test's scope.
local compile = loadstring or load
local function rejects(source)
  assert(not compile(source), "unexpectedly accepted: " .. source)
end

local count = 0
count += 1
count -= -4
count *= 3
count /= 5
count %= 2
assert(count == 1)
local url = "base"
url ..= "/" .. "league"
url ..= "/query"
assert(url == "base/league/query")

-- Ordinary precedence and one return value from a RHS call.
local function values() return 3, 99 end
count += values() * 2
assert(count == 7)
local function upvalue()
  count += 2
end
upvalue()
assert(count == 9)
_G.compound_global = 7
compound_global += 2
assert(compound_global == 9)
compound_global = nil

-- Evaluate an indexed target only once, keeping temporary registers alive
-- across a RHS that needs registers of its own.
local events = {}
local object = { value = 10 }
local function base() events[#events + 1] = "base"; return object end
local function key() events[#events + 1] = "key"; return "value" end
local function rhs(a, b, c) events[#events + 1] = "rhs"; return a + b + c end
base()[key()] += rhs(1, 2, 3)
assert(object.value == 16)
assert(table.concat(events, ",") == "base,key,rhs")
base()[key()] ..= "!"
assert(object.value == "16!")

-- Match LuaJIT's local-register alias behavior, not a source rewrite that
-- copies every local before the RHS: arithmetic reads a local after the call.
local x = 2
local function change_x() x = 10; return 3 end
x += change_x()
assert(x == 13)
-- Concatenation places its left operand in a temporary before the call.
local text = "old"
local function change_text() text = "new"; return "!" end
text ..= change_text()
assert(text == "old!")

-- The indexed read precedes the RHS, but local base/key registers can change
-- before the store. This is the behavior of the pinned LuaJIT parser.
local target = { a = 2 }
local original = target
local index = "a"
local function change_target()
  target = { a = 100 }
  index = "b"
  return 3
end
target[index] += change_target()
assert(original.a == 2 and original.b == nil)
assert(target.a == 100 and target.b == 5)

-- Indexed metamethods run once in read, RHS, arithmetic, store order.
events = {}
local proxy = setmetatable({}, {
  __index = function()
    events[#events + 1] = "get"
    return setmetatable({}, {
      __add = function(_, n) events[#events + 1] = "add"; return n + 10 end,
    })
  end,
  __newindex = function(_, k, n)
    events[#events + 1] = "set"
    assert(k == "value" and n == 16)
  end,
})
proxy.value += rhs(1, 2, 3)
assert(table.concat(events, ",") == "get,rhs,add,set")

rejects("local x=1; x + = 2")
rejects("local x=1; x +\n= 2")
rejects("local x='a'; x .. = 'b'")
rejects("local x=1; x ^= 2")
rejects("local x,y=1,2; x,y += 2,3")
rejects("local x=1; x += 2,3")
rejects("local x=1; return x += 2")
rejects("local x=1; (x + 1) += 2")
print("LuaJIT compound assignment compatibility passed")
