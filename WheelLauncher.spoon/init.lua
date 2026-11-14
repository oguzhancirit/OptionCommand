--- === WheelLauncher ===
--- A free radial (pie) launcher for macOS, driven by Hammerspoon.
--- Hold the trigger modifiers, point at a slice, let go.

local obj = {}
obj.__index = obj
obj.name = "WheelLauncher"
obj.version = "0.1.0"
obj.author = "WheelLauncher contributors"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local DIR = hs.spoons.resourcePath("")
local geo = dofile(DIR .. "geometry.lua")

local SIZES = { tiny = 0.6, small = 0.8, medium = 1, large = 1.25, xlarge = 1.5 }
local MODS = { "cmd", "alt", "ctrl", "shift" }

local DEFAULTS = {
  trigger = { "cmd", "alt" }, -- modifier keys that open the wheel
  doublePress = true,         -- true: press twice and hold; false: just hold
  doublePressWindow = 0.35,   -- seconds allowed between the two presses
  holdDelay = 0.15,           -- (doublePress=false) wait before showing
  size = "medium",            -- tiny | small | medium | large | xlarge
  centerOnMouse = true,       -- false: always open in the middle of the screen
  hideOthers = false,         -- hide every other app after launching one
  modes = { "items", "running" }, -- switch with ] and [ while the wheel is open
  maxRunning = 12,
  favicons = true,            -- download site icons once (see README: Gizlilik)
  menubar = true,             -- small menu bar icon that opens the settings page
  items = {},
  theme = {
    ring = { white = 0.08, alpha = 0.82 },
    hub = { white = 0.17, alpha = 0.92 },
    accent = { red = 0.95, green = 0.45, blue = 0.25, alpha = 0.55 },
    text = { white = 1, alpha = 0.92 },
    dot = { white = 1, alpha = 0.75 },
  },
}

local SAVED = { "trigger", "doublePress", "size", "centerOnMouse", "hideOthers", "favicons", "items" }
local EMOJI = { url = "🌐", shortcut = "⚡", cmd = "🖥", fn = "✨", keys = "⌨️", items = "📂", path = "📄" }

local function expand(p)
  return (p:gsub("^~", os.getenv("HOME")))
end

local function merge(base, over)
  local out = {}
  for k, v in pairs(base) do out[k] = v end
  for k, v in pairs(over or {}) do
    if k == "theme" then out.theme = merge(base.theme, v) else out[k] = v end
  end
  return out
end

local function appPath(name)
  if name:sub(1, 1) == "/" then return hs.fs.attributes(name) and name or nil end
  local dirs = { "/Applications/", "/System/Applications/", "/System/Applications/Utilities/",
    "/Applications/Utilities/", expand("~/Applications/") }
  for _, d in ipairs(dirs) do
    local p = d .. name .. ".app"
    if hs.fs.attributes(p) then return p end
  end
end

local function appName(app)
  return app:match("([^/]+)%.app/?$") or app
end

-- Site icons are downloaded once and kept in ~/.hammerspoon/wheel-icons/.
local ICON_DIR = expand("~/.hammerspoon/wheel-icons/")
local fetching = {}

local function hostOf(url)
  return url:match("^%a+://([^/:?#]+)")
end

local function siteIconPath(url)
  local h = hostOf(url)
  return h and (ICON_DIR .. h:gsub("[^%w%.%-]", "_") .. ".png")
end

local function fetchSiteIcon(url, done)
  local host, dest = hostOf(url), siteIconPath(url)
  if not host or fetching[host] then return end
  fetching[host] = true -- stays set after a failure: no retry until the next reload
  hs.fs.mkdir(ICON_DIR)
  local sources = {
    "https://" .. host .. "/apple-touch-icon.png",
    "https://www.google.com/s2/favicons?sz=128&domain=" .. host,
  }
  local function try(i)
    if not sources[i] then return end
    hs.image.imageFromURL(sources[i], function(img)
      if img and img:size().w >= 32 then
        img:saveToFile(dest)
        fetching[host] = nil
        if done then done(img) end
      else
        try(i + 1)
      end
    end)
  end
  try(1)
end

--- Icon for an item, or nil when an emoji should be drawn instead.
--- `done(img)` is called later if a site icon had to be downloaded first.
local function iconFor(item, favicons, done)
  if item.icon then return hs.image.imageFromPath(expand(item.icon)) end
  if item.emoji then return nil end
  if item.bundleID then return hs.image.imageFromAppBundle(item.bundleID) end
  if item.app then
    local p = appPath(item.app)
    return p and hs.image.iconForFile(p) or nil
  end
  if item.path and not item.items then return hs.image.iconForFile(expand(item.path)) end
  if item.url and favicons then
    local p = siteIconPath(item.url)
    if p and hs.fs.attributes(p) then return hs.image.imageFromPath(p) end
    fetchSiteIcon(item.url, done)
  end
end

local function emojiFor(item)
  if item.emoji then return item.emoji end
  for _, k in ipairs({ "items", "url", "path", "shortcut", "cmd", "keys", "fn" }) do
    if item[k] then return EMOJI[k] end
  end
  return "❔"
end

local function labelFor(item)
  if item.name then return item.name end
  if item.app then return appName(item.app) end
  if item.url then return item.url:match("^%a+://([^/]+)") or item.url end
  if item.path then return item.path:match("([^/]+)/?$") or item.path end
  return item.shortcut or item.cmd or item.bundleID or "?"
end

local function runningApp(item)
  if item.bundleID or item.app then return hs.application.get(item.bundleID or appName(item.app)) end
end

-- ---------------------------------------------------------------- actions

function obj:_run(item)
  local ok, err = pcall(function()
    if item.fn then item.fn()
    elseif item.bundleID then hs.application.launchOrFocusByBundleID(item.bundleID)
    elseif item.app then hs.application.launchOrFocus(item.app)
    elseif item.url then
      if item.browser then hs.urlevent.openURLWithBundle(item.url, item.browser)
      else hs.urlevent.openURL(item.url) end
    elseif item.path then hs.open(expand(item.path))
    elseif item.shortcut then hs.shortcuts.run(item.shortcut)
    elseif item.cmd then hs.task.new("/bin/zsh", nil, { "-lc", item.cmd }):start()
    elseif item.keys then hs.eventtap.keyStroke(item.keys[1], item.keys[2])
    end
  end)
  if not ok then hs.alert.show("WheelLauncher: " .. tostring(err)) end
  if ok and self.cfg.hideOthers and (item.app or item.bundleID) then
    hs.timer.doAfter(0.4, function()
      local front = hs.application.frontmostApplication()
      for _, a in ipairs(hs.application.runningApplications()) do
        if a:kind() == 1 and a ~= front then a:hide() end
      end
    end)
  end
end

function obj:_modeItems()
  local mode = self.cfg.modes[self._mode] or "items"
  if mode ~= "running" then return self.cfg.items end
  local out = {}
  for _, a in ipairs(hs.application.runningApplications()) do
    if a:kind() == 1 and #out < self.cfg.maxRunning then
      out[#out + 1] = { name = a:name(), bundleID = a:bundleID() }
    end
  end
  return out
end

-- ---------------------------------------------------------------- drawing

function obj:_draw(items, cx, cy)
  if self._canvas then self._canvas:delete() end
  local cfg, th = self.cfg, self.cfg.theme
  local n = #items
  local s = SIZES[cfg.size] or 1
  local outer = (150 + math.max(0, n - 8) * 10) * s
  local inner = outer * 0.47
  local mid = (outer + inner) / 2
  local icon = math.min(56 * s, (outer - inner) * 0.72, 2 * math.pi * mid / math.max(n, 1) * 0.7)
  cx, cy = geo.clamp(cx, cy, outer + 4, hs.mouse.getCurrentScreen():fullFrame())
  local W = outer * 2 + 8
  local c = W / 2
  local ts = 14 * s

  local els = {
    { type = "circle", action = "fill", center = { x = c, y = c }, radius = outer, fillColor = th.ring },
    { type = "segments", action = "skip", closed = true, fillColor = th.accent,
      coordinates = geo.sector(c, c, inner, outer, 1, math.max(n, 1)) },
    { type = "circle", action = "fill", center = { x = c, y = c }, radius = inner, fillColor = th.hub },
    { type = "text", text = "", textAlignment = "center", textSize = ts, textColor = th.text,
      textLineBreak = "truncateTail",
      frame = { x = c - inner + 8, y = c - ts * 0.7, w = inner * 2 - 16, h = ts * 1.5 } },
  }
  for i, item in ipairs(items) do
    local dx, dy = geo.slot(i, n, mid)
    local x, y = c + dx - icon / 2, c + dy - icon / 2
    local img = iconFor(item, cfg.favicons)
    if img then
      els[#els + 1] = { type = "image", image = img, imageScaling = "scaleProportionally",
        frame = { x = x, y = y, w = icon, h = icon } }
    else
      els[#els + 1] = { type = "text", text = emojiFor(item), textAlignment = "center",
        textSize = icon * 0.72, frame = { x = x - icon * 0.25, y = y, w = icon * 1.5, h = icon * 1.2 } }
    end
    if runningApp(item) then
      els[#els + 1] = { type = "circle", action = "fill", radius = 2.5 * s, fillColor = th.dot,
        center = { x = c + dx, y = c + dy + icon / 2 + 5 * s } }
    end
  end

  local cv = hs.canvas.new({ x = cx - c, y = cy - c, w = W, h = W })
  cv:appendElements(els)
  cv:level(hs.canvas.windowLevels.overlay)
  cv:behavior({ "canJoinAllSpaces", "stationary" })
  cv:show()
  self._canvas, self._items, self._sel = cv, items, nil
  self._cx, self._cy, self._inner, self._outer, self._c = cx, cy, inner, outer, c
end

function obj:_select(idx)
  if idx == self._sel then return end
  self._sel = idx
  local cv = self._canvas
  if idx then
    cv[2].coordinates = geo.sector(self._c, self._c, self._inner, self._outer, idx, #self._items)
    cv[2].action = "fill"
    cv[4].text = labelFor(self._items[idx])
  else
    cv[2].action = "skip"
    cv[4].text = ""
  end
end

-- ---------------------------------------------------------------- open / close

function obj:_show()
  local items = self:_modeItems()
  if #items == 0 then
    hs.alert.show("WheelLauncher: no items")
    return
  end
  local p = hs.mouse.absolutePosition()
  if not self.cfg.centerOnMouse then
    local f = hs.mouse.getCurrentScreen():fullFrame()
    p = { x = f.x + f.w / 2, y = f.y + f.h / 2 }
  end
  self._stack = {}
  self:_draw(items, p.x, p.y)
  self._open = true
  self._keys:start()
  self._ticker = hs.timer.doEvery(1 / 60, function() self:_tick() end)
end

function obj:_close()
  self._open = false
  if self._ticker then self._ticker:stop() self._ticker = nil end
  self._keys:stop()
  if self._canvas then self._canvas:delete() self._canvas = nil end
end

function obj:_enter(item)
  local p = hs.mouse.absolutePosition()
  self._stack[#self._stack + 1] = self._items
  self:_draw(item.items, p.x, p.y)
end

function obj:_back()
  local prev = table.remove(self._stack)
  if not prev then return end
  local p = hs.mouse.absolutePosition()
  self:_draw(prev, p.x, p.y)
end

function obj:_tick()
  local p = hs.mouse.absolutePosition()
  local idx, dist = geo.pick(p.x - self._cx, p.y - self._cy, #self._items, self._inner)
  self:_select(idx)
  local item = idx and self._items[idx]
  -- Push the pointer past the outer edge of a folder slice to open it.
  if item and item.items and #item.items > 0 and dist > self._outer then self:_enter(item) end
end

function obj:_commit()
  local item = self._sel and self._items[self._sel]
  self:_close()
  if item and not item.items then self:_run(item) end
end

function obj:_onKey(e)
  local key = hs.keycodes.map[e:getKeyCode()]
  local num = tonumber(key)
  if key == "escape" then
    self:_close()
  elseif num and num >= 1 and self._items[num] then
    local item = self._items[num]
    if item.items then self:_enter(item) else self:_close() self:_run(item) end
  elseif key == "]" or key == "[" then
    local n = #self.cfg.modes
    self._mode = (self._mode - 1 + (key == "]" and 1 or -1)) % n + 1
    self:_close()
    self:_show()
  elseif key == "," then
    self:_close()
    self:openSettings()
  elseif key == "delete" then
    self:_back()
  elseif key == "h" or key == "q" then
    local item = self._sel and self._items[self._sel]
    local app = item and runningApp(item)
    if app then
      if key == "h" then app:hide() else app:kill() end
    end
  else
    self:_close() -- some other shortcut was meant: get out of the way
    return false
  end
  return true
end

-- ---------------------------------------------------------------- trigger

local function modState(flags, trigger)
  local want, exact, has = {}, true, true
  for _, m in ipairs(trigger) do want[m] = true end
  for _, m in ipairs(MODS) do
    local down = flags[m] and true or false
    if down ~= (want[m] or false) then exact = false end
    if want[m] and not down then has = false end
  end
  return exact, has
end

function obj:_onFlags(e)
  local cfg = self.cfg
  local exact, has = modState(e:getFlags(), cfg.trigger)
  if self._open then
    if not has then self:_commit() end
  elseif exact and not self._was then
    local now = hs.timer.secondsSinceEpoch()
    if cfg.doublePress then
      if now - self._last <= cfg.doublePressWindow then
        self._last = 0
        self:_show()
      else
        self._last = now
      end
    else
      self._pending = hs.timer.doAfter(cfg.holdDelay, function()
        self._pending = nil
        if modState(hs.eventtap.checkKeyboardModifiers(), cfg.trigger) then self:_show() end
      end)
    end
  elseif not exact and self._pending then
    self._pending:stop()
    self._pending = nil
  end
  self._was = exact
  return false
end

-- ---------------------------------------------------------------- public API

--- WheelLauncher:start(config)
--- config: a table, or the path of a Lua file that returns a table
--- (the file is watched and reloaded when you save it). The settings page
--- stores its changes next to it as wheel.json, which wins over the Lua file.
function obj:start(config)
  self:stop()
  self._arg = config
  local jsonPath = expand("~/.hammerspoon/wheel.json")
  if type(config) == "string" then
    self._path = expand(config)
    jsonPath = (self._path:gsub("%.lua$", "")) .. ".json"
    local res = {}
    if hs.fs.attributes(self._path) then
      local ok, r = pcall(dofile, self._path)
      if ok and type(r) == "table" then
        res = r
      else
        hs.alert.show("WheelLauncher: config error\n" .. tostring(r))
      end
      self._watch = hs.pathwatcher.new(self._path, function()
        hs.timer.doAfter(0.3, function() self:start(self._path) end)
      end):start()
    end
    config = res
  end
  self.cfg = merge(DEFAULTS, config)
  -- Whatever the settings page saved wins over the Lua file.
  self._json = jsonPath
  local saved = hs.fs.attributes(jsonPath) and hs.json.read(jsonPath)
  if type(saved) == "table" then
    for _, k in ipairs(SAVED) do
      if saved[k] ~= nil then self.cfg[k] = saved[k] end
    end
  end
  if self.cfg.menubar then
    self._menu = hs.menubar.new()
    if self._menu then
      self._menu:setTitle("◎")
      self._menu:setMenu({
        { title = "Ayarlar…", fn = function() self:openSettings() end },
        { title = "Yeniden yükle", fn = function() self:start(self._arg) end },
      })
    end
  end
  self._mode, self._last, self._was, self._open = 1, 0, false, false
  local T = hs.eventtap.event.types
  self._keys = hs.eventtap.new({ T.keyDown }, function(e) return self:_onKey(e) end)
  self._flags = hs.eventtap.new({ T.flagsChanged }, function(e) return self:_onFlags(e) end):start()
  return self
end

function obj:stop()
  if self._open then self:_close() end
  for _, k in ipairs({ "_flags", "_keys", "_watch", "_pending" }) do
    if self[k] then self[k]:stop() self[k] = nil end
  end
  if self._menu then self._menu:delete() self._menu = nil end
  return self
end

dofile(DIR .. "settings.lua")(obj, { dir = DIR, iconFor = iconFor, appPath = appPath, expand = expand })

return obj
