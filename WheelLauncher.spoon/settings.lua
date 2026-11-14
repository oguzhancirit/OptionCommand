-- Settings window: a small web page (settings.html) shown in an hs.webview.
-- The page talks to Lua with postMessage; Lua answers by calling WL.* in the page.
-- Whatever the page saves goes to wheel.json, which start() lays over the Lua config.
return function(obj, H)
  local function plain(v)
    if type(v) ~= "table" then return v end
    local o = {}
    for k, x in pairs(v) do
      if type(x) ~= "function" then o[k] = plain(x) end
    end
    return o
  end

  -- Items as plain data. Lua-function items cannot be stored in JSON, so they are left out.
  function obj._plainItems(items)
    local out = {}
    for _, it in ipairs(items or {}) do
      if not it.fn then
        local c = plain(it)
        if it.items then c.items = obj._plainItems(it.items) end
        out[#out + 1] = c
      end
    end
    return out
  end

  function obj:_js(fn, ...)
    if not self._wv then return end
    local args = hs.json.encode({ ... }):sub(2, -2)
    self._wv:evaluateJavaScript("WL." .. fn .. "(" .. args .. ")")
  end

  function obj:openSettings()
    if self._wv then
      self._wv:show():bringToFront()
      return
    end
    local fh = io.open(H.dir .. "settings.html", "r")
    if not fh then
      hs.alert.show("WheelLauncher: settings.html not found")
      return
    end
    local html = fh:read("a")
    fh:close()

    local uc = hs.webview.usercontent.new("wheel")
    uc:setCallback(function(m)
      local ok, err = pcall(function() self:_onSettingsMsg(m.body) end)
      if not ok then hs.alert.show("WheelLauncher: " .. tostring(err)) end
    end)
    local f = hs.screen.mainScreen():frame()
    local w, h = 920, 660
    local wv = hs.webview.new({ x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h }, {}, uc)
    wv:windowStyle({ "titled", "closable", "resizable" })
    wv:windowTitle("WheelLauncher")
    wv:allowTextEntry(true)
    wv:deleteOnClose(true)
    wv:windowCallback(function(action)
      if action == "closing" then self._wv = nil end
    end)
    wv:html(html)
    wv:show()
    wv:bringToFront()
    self._wv, self._uc = wv, uc
    hs.timer.doAfter(0.2, function()
      local win = self._wv and self._wv:hswindow()
      if win then win:focus() end
    end)
  end

  function obj:_onSettingsMsg(m)
    if type(m) ~= "table" then return end
    local cfg = self.cfg
    if m.action == "ready" then
      self:_js("init", {
        trigger = cfg.trigger, doublePress = cfg.doublePress, size = cfg.size,
        centerOnMouse = cfg.centerOnMouse, hideOthers = cfg.hideOthers,
        favicons = cfg.favicons, items = obj._plainItems(cfg.items),
      })
    elseif m.action == "icon" and type(m.item) == "table" then
      local function send(img)
        local url = false
        if img then
          local ok, r = pcall(function() return img:setSize({ w = 96, h = 96 }):encodeAsURLString() end)
          if ok and type(r) == "string" then url = r end
        end
        self:_js("icon", m.key, url)
      end
      local img = H.iconFor(m.item, m.favicons ~= false, send)
      if img then send(img) end
    elseif m.action == "pick" then
      local r
      if m.what == "app" then
        r = hs.dialog.chooseFileOrFolder("Uygulama seç", "/Applications", true, false, false, { "app" })
      elseif m.what == "path" then
        r = hs.dialog.chooseFileOrFolder("Dosya veya klasör seç", H.expand("~"), true, true, false)
      else
        r = hs.dialog.chooseFileOrFolder("Simge resmi seç", H.expand("~"), true, false, false,
          { "png", "jpg", "jpeg", "icns", "gif", "tiff" })
      end
      local p = r and (r["1"] or r[1])
      if not p then return end
      if m.what == "app" then
        local name = p:match("([^/]+)%.app/?$")
        if name and H.appPath(name) then p = name end -- standard location: the name is enough
      end
      self:_js("picked", m.what, p)
    elseif m.action == "save" and type(m.cfg) == "table" then
      hs.json.write(m.cfg, self._json, true, true)
      self:start(self._arg)
      self:_js("saved")
    end
  end
end
