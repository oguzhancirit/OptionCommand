-- Run from the repo root:  lua tests/run.lua
-- Part 1 checks the wheel math. Part 2 loads the Spoon against a fake `hs`
-- and walks through open -> point -> release, so typos and nil errors show up
-- without a Mac.
local geo = dofile("WheelLauncher.spoon/geometry.lua")
local n = 0
local function eq(a, b, msg)
  n = n + 1
  if a ~= b then error(("FAIL %s: got %s, want %s"):format(msg, tostring(a), tostring(b)), 2) end
end

-- ---- geometry
eq(geo.pick(0, -100, 4, 50), 1, "up = slot 1")
eq(geo.pick(100, 0, 4, 50), 2, "right = slot 2")
eq(geo.pick(0, 100, 4, 50), 3, "down = slot 3")
eq(geo.pick(-100, 0, 4, 50), 4, "left = slot 4")
eq(geo.pick(-10, -100, 4, 50), 1, "just left of up still slot 1")
eq(geo.pick(10, 10, 4, 50), nil, "dead zone")
eq(geo.pick(5, 900, 1, 50), 1, "single item")
eq(geo.pick(0, -100, 0, 50), nil, "no items")
local dx, dy = geo.slot(2, 4, 100)
eq(math.floor(dx + 0.5), 100, "slot 2 x")
eq(math.floor(dy + 0.5), 0, "slot 2 y")
for i = 1, 7 do -- every slot centre must pick itself
  local x, y = geo.slot(i, 7, 100)
  eq(geo.pick(x, y, 7, 50), i, "roundtrip " .. i)
end
eq(#geo.sector(0, 0, 50, 100, 1, 4) >= 10, true, "sector has points")
local cx, cy = geo.clamp(5, 2000, 100, { x = 0, y = 0, w = 1000, h = 800 })
eq(cx, 100, "clamp x")
eq(cy, 700, "clamp y")

-- ---- fake Hammerspoon
local function stub()
  return setmetatable({}, {
    __index = function(t, k) local s = stub() rawset(t, k, s) return s end,
    __call = function() return stub() end,
  })
end
local mouse = { x = 500, y = 500 }
local taps, ran, canvas = {}, {}, nil
hs = stub()
hs.spoons.resourcePath = function(p) return "WheelLauncher.spoon/" .. p end
hs.fs.attributes = function() return nil end
hs.mouse.absolutePosition = function() return { x = mouse.x, y = mouse.y } end
hs.mouse.getCurrentScreen = function()
  return { fullFrame = function() return { x = 0, y = 0, w = 1440, h = 900 } end }
end
hs.application.get = function() return nil end
hs.application.runningApplications = function() return {} end
hs.application.launchOrFocus = function(name) ran[#ran + 1] = name end
hs.urlevent.openURL = function(u) ran[#ran + 1] = u end
hs.timer.secondsSinceEpoch = function() return 1000 end
hs.keycodes.map = { [53] = "escape", [18] = "1", [0] = "a", [43] = "," }
local savedJson, written, jsCalls = nil, nil, {}
hs.json.read = function() return savedJson end
hs.json.write = function(data, path) written = { data = data, path = path } end
hs.json.encode = function() return "[]" end
hs.fs.attributes = function(p) return (savedJson and p:match("wheel%.json$")) and {} or nil end
hs.screen.mainScreen = function() return { frame = function() return { x = 0, y = 0, w = 1440, h = 900 } end } end
hs.webview.new = function()
  local w = {}
  return setmetatable(w, { __index = function(_, k)
    if k == "evaluateJavaScript" then return function(_, js) jsCalls[#jsCalls + 1] = js end end
    return function() return w end
  end })
end
hs.eventtap.event.types = { keyDown = 10, flagsChanged = 12 }
hs.eventtap.new = function(types, fn)
  local t = { fn = fn }
  function t:start() return self end
  function t:stop() return self end
  taps[types[1]] = t
  return t
end
hs.canvas.new = function()
  canvas = { deleted = false }
  function canvas:appendElements(els) for i, e in ipairs(els) do self[i] = e end end
  function canvas:level() end
  function canvas:behavior() end
  function canvas:show() end
  function canvas:delete() self.deleted = true end
  return canvas
end

local wl = dofile("WheelLauncher.spoon/init.lua")
wl:start({
  doublePress = true,
  items = {
    { app = "Claude" },
    { url = "https://github.com" },
    { name = "More", items = { { app = "Mail" }, { app = "Notes" } } },
    { app = "Safari" },
  },
})
local function flags(f) taps[12].fn({ getFlags = function() return f end }) end
local function key(code) return taps[10].fn({ getKeyCode = function() return code end }) end
local held, none = { cmd = true, alt = true }, {}
local function open() flags(held) flags(none) flags(held) end

flags(held)
eq(wl._open, false, "one press does not open")
flags(none)
flags(held)
eq(wl._open, true, "double press opens")
eq(canvas[2].action, "skip", "nothing highlighted at centre")

mouse.x = 620 -- right = slot 2 (github)
wl:_tick()
eq(wl._sel, 2, "points at slot 2")
eq(canvas[2].action, "fill", "highlight on")
eq(canvas[4].text, "github.com", "hub shows label")
flags(none)
eq(wl._open, false, "release closes")
eq(ran[#ran], "https://github.com", "release runs the item")
eq(canvas.deleted, true, "canvas removed")

mouse.x = 500
open()
flags(none)
eq(#ran, 1, "release in centre runs nothing")

open()
mouse.y = 900 -- far below = slot 3 (folder), past the outer edge
wl:_tick()
eq(#wl._items, 2, "entered sub wheel")
mouse.y = 600
wl:_tick()
eq(wl._sel, 1, "sub wheel slot 1")
flags(none)
eq(ran[#ran], "Mail", "sub item runs")

mouse.x, mouse.y = 500, 500
open()
eq(key(18), true, "digit is swallowed")
eq(ran[#ran], "Claude", "digit 1 runs first item")
open()
eq(key(53), true, "escape swallowed")
eq(wl._open, false, "escape closes")
open()
eq(key(0), false, "other keys pass through")
eq(wl._open, false, "other keys cancel")

-- settings page
open()
eq(key(43), true, "comma swallowed")
eq(wl._open, false, "comma closes the wheel")
eq(wl._wv ~= nil, true, "comma opens settings")
wl:_onSettingsMsg({ action = "ready" })
eq(jsCalls[#jsCalls]:match("^WL%.init%(") ~= nil, true, "page gets init")
local plain = wl._plainItems({ { app = "A" }, { name = "f", fn = function() end }, { name = "g", items = { { url = "u" } } } })
eq(#plain, 2, "function items are not sent to the page")
eq(plain[2].items[1].url, "u", "nested items kept")
wl:_onSettingsMsg({ action = "save", cfg = { size = "large", items = { { app = "Notes" } } } })
eq(written.data.size, "large", "save writes json")
eq(written.path:match("wheel%.json$") ~= nil, true, "save path")
eq(jsCalls[#jsCalls], "WL.saved()", "page told it was saved")

-- saved json wins over the Lua config
savedJson = { size = "large", items = { { app = "Notes" } } }
wl:start({ size = "tiny", doublePress = false, items = { { app = "Claude" } } })
eq(wl.cfg.size, "large", "json size wins")
eq(wl.cfg.items[1].app, "Notes", "json items win")
eq(wl.cfg.doublePress, false, "keys missing from json come from Lua")
savedJson = nil

wl:start({ doublePress = false, items = { { app = "Claude" } } })
eq(wl.cfg.theme.ring.alpha, 0.82, "theme defaults kept")
wl:stop()

print(("ok - %d checks passed"):format(n))
