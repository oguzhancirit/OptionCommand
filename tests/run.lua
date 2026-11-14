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

-- ---- url repair
local util = dofile("WheelLauncher.spoon/util.lua")
local N = util.normalizeURL
eq(N("https://https://chatgpt.com"), "https://chatgpt.com", "double scheme")
eq(N("https://https//chatgpt.com/"), "https://chatgpt.com/", "double scheme, missing colon")
eq(N("https//chatgpt.com"), "https://chatgpt.com", "missing colon")
eq(N("  chatgpt.com "), "https://chatgpt.com", "no scheme")
eq(N("http://localhost:3000"), "http://localhost:3000", "http kept")
eq(N("localhost:3000"), "https://localhost:3000", "host:port is not a scheme")
eq(N("httpbin.org"), "https://httpbin.org", "http-looking host")
eq(N("obsidian://open?vault=x"), "obsidian://open?vault=x", "other scheme kept")
eq(N("mailto:a@b.c"), "mailto:a@b.c", "mailto kept")
eq(N("https://"), "", "scheme only = empty")
local tree = util.fixItems({ { url = "x.com" }, { items = { { url = "https://https://y.com" } } } })
eq(tree[2].items[1].url, "https://y.com", "nested fix")

-- ---- open tabs / folders
local tabs = { "https://www.youtube.com/watch?v=1", "https://m.github.com/me/repo/issues", "https://chatgpt.com/" }
eq(util.urlOpen("youtube.com", tabs), true, "www ignored")
eq(util.urlOpen("https://youtube.com/", tabs), true, "trailing slash ignored")
eq(util.urlOpen("github.com/me/repo", tabs), true, "subdomain + path prefix")
eq(util.urlOpen("github.com/me/repository", tabs), false, "path prefix must end at a slash")
eq(util.urlOpen("github.com/other", tabs), false, "other path")
eq(util.urlOpen("hub.com", tabs), false, "not a suffix match")
eq(util.urlOpen("https://chatgpt.com", tabs), true, "plain host")
eq(util.urlOpen("gmail.com", {}), false, "no tabs")
eq(util.filePath("file:///Users/me/My%20Files/"), "/Users/me/My Files", "file url decoded")
eq(util.filePath("file:///"), "/", "root kept")
local t2, p2, r2 = util.parseProbe("U\tcom.google.Chrome\thttps://a.com/x\nP\tfile:///Users/me/Downloads/\njunk\n")
eq(t2[1].app, "com.google.Chrome", "probe tab browser")
eq(r2[1], "file:///Users/me/Downloads/", "probe keeps raw folder url")
local both = { { url = "https://a.com/1", app = "com.apple.Safari" }, { url = "https://a.com/2", app = "com.brave.Browser" } }
eq(util.findTab("a.com", both).app, "com.apple.Safari", "first matching tab")
eq(util.findTab("a.com", both, "com.brave.Browser").url, "https://a.com/2", "preferred browser first")
eq(util.findTab("b.com", both), nil, "no tab")
eq(#t2, 1, "probe tabs")
eq(p2[1], "/Users/me/Downloads", "probe paths")
eq(util.pathOpen("/Users/me/Downloads/", p2), true, "folder open")
eq(util.pathOpen("/Users/me/Desktop", p2), false, "folder closed")

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
-- hs.task: finishes at once. Probe answers probeOut, focus answers focusOut.
local tasks, probeOut, focusOut = {}, "", "no"
hs.task.new = function(path, cb, args)
  local t = { args = args }
  function t:start()
    tasks[#tasks + 1] = self
    local isFocus = args and args[5] ~= nil
    if cb then cb(0, isFocus and focusOut or probeOut) end
    return self
  end
  return t
end
hs.open = function(p) ran[#ran + 1] = "open:" .. p end
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
wl.cfg.items[2].url = "https://https://github.com"
wl:_run(wl.cfg.items[2])
eq(ran[#ran], "https://github.com", "broken url is repaired when run")
table.remove(ran)
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

-- dots: open tabs / folders
flags(none) -- the last test left the keys held
open()
eq(wl._open, true, "wheel open for the dot test")
eq(wl._dots ~= nil and #wl._dots, 4, "every slot has a dot element")
eq(canvas[wl._dots[2]].action, "skip", "site not open yet")
wl._probe = { tabs = { "https://www.github.com/me" }, paths = {} }
wl:_refreshDots()
eq(canvas[wl._dots[2]].action, "fill", "open tab shows a dot")
eq(canvas[wl._dots[1]].action, "skip", "closed app has no dot")
eq(canvas[wl._dots[3]].action, "skip", "group with nothing open")
key(53)
wl._probe = nil

-- open tab: focus it instead of opening a second one
local runs = #ran
probeOut, focusOut = "U\tcom.brave.Browser\thttps://www.github.com/me\n", "ok"
local function pickRight() -- open at the centre, point at slot 2 (github), release
  mouse.x, mouse.y = 500, 500
  flags(none) open()
  mouse.x = 620
  wl:_tick()
  flags(none)
  mouse.x = 500
end
pickRight()
eq(#ran, runs, "open tab: no new page")
eq(tasks[#tasks].args[5], "com.brave.Browser", "focus asks the right browser")
eq(tasks[#tasks].args[6], "https://www.github.com/me", "focus asks the exact tab")
focusOut = "no" -- tab closed in the meantime
pickRight()
eq(ran[#ran], "https://github.com", "closed meanwhile: new page")
probeOut = "" -- nothing open
table.remove(ran)
pickRight()
eq(ran[#ran], "https://github.com", "not open: new page")
-- released before the browsers answered: wait, then decide
wl._probe = nil
focusOut = "ok"
wl._probeTask = {}
wl:_run({ url = "github.com" })
eq(wl._afterProbe ~= nil, true, "run waits for the probe")
local before = #ran
wl:_probeDone(0, "U\tcom.apple.Safari\thttps://github.com/\n")
eq(#ran, before, "probe found the tab: focused, not opened")
eq(tasks[#tasks].args[5], "com.apple.Safari", "focus after waiting")
-- folders
local home = os.getenv("HOME")
probeOut, focusOut = "P\tfile://" .. home .. "/Downloads/\n", "ok"
wl._probe = nil
wl:_probeOpen({ { path = "~/Downloads" } })
before = #ran
wl:_run({ path = "~/Downloads" })
eq(#ran, before, "open folder: focused")
eq(tasks[#tasks].args[5], "com.apple.finder", "focus Finder")
wl:_run({ path = "~/Desktop" })
eq(ran[#ran], "open:" .. home .. "/Desktop", "closed folder: opened")
probeOut, focusOut = "", "no"
mouse.x, mouse.y = 500, 500

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
