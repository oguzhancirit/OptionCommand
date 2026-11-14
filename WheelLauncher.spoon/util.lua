-- Small pure helpers (no Hammerspoon calls, tested with plain Lua).
local M = {}

-- Schemes that are written without "//".
local BARE = { mailto = true, tel = true, sms = true, facetime = true, ["facetime-audio"] = true, maps = true }

--- Turn whatever the user typed into a URL a browser can open.
--- "chatgpt.com" -> "https://chatgpt.com"; "https://https://x.com" -> "https://x.com";
--- "https//x.com" -> "https://x.com". Other schemes (obsidian://, mailto:) are kept.
function M.normalizeURL(u)
  if type(u) ~= "string" then return u end
  u = u:match("^%s*(.-)%s*$")
  if u == "" then return u end
  local scheme, rest = nil, u
  while true do
    local s, r = rest:match("^([Hh][Tt][Tt][Pp][Ss]?):?/+(.*)$")
    if not s then s, r = rest:match("^([Hh][Tt][Tt][Pp][Ss]?):(.*)$") end
    if not s then break end
    scheme = scheme or s:lower()
    rest = r
  end
  if not scheme then
    if rest:match("^%a[%w+.-]*://") then return rest end
    local s = rest:match("^(%a[%w+.-]*):")
    if s and (BARE[s:lower()] or s:lower():match("^x%-apple")) then return rest end
    scheme = "https"
  end
  if rest == "" then return "" end
  return scheme .. "://" .. rest
end

--- Fix every url in an item tree in place (also repairs configs saved before this fix).
function M.fixItems(items)
  for _, it in ipairs(items or {}) do
    if type(it) == "table" then
      if it.url then it.url = M.normalizeURL(it.url) end
      if it.items then M.fixItems(it.items) end
    end
  end
  return items
end

local function splitURL(u)
  u = M.normalizeURL(u or "")
  local host, path = u:match("^%a[%w+.-]*://([^/?#]*)([^?#]*)")
  if not host then return nil end
  host = host:lower():gsub(":%d+$", ""):gsub("^www%.", "")
  return host, (path:gsub("/+$", ""))
end

--- First open tab that shows the site `item` (a URL the user saved), or nil.
--- Same host (or a subdomain of it, www ignored); if the saved URL has a path,
--- the tab must be on that path or below it. `tabs` holds URL strings or {url=, app=} tables.
--- `prefer` (a browser bundle id) is searched first.
function M.findTab(item, tabs, prefer)
  local h, p = splitURL(item)
  if not h or h == "" then return nil end
  local hit
  for _, t in ipairs(tabs or {}) do
    local th, tp = splitURL(type(t) == "table" and t.url or t)
    if th and (th == h or th:sub(-#h - 1) == "." .. h)
      and (p == "" or tp == p or tp:sub(1, #p + 1) == p .. "/") then
      if not prefer or (type(t) == "table" and t.app == prefer) then return t end
      hit = hit or t
    end
  end
  return hit
end

function M.urlOpen(item, tabs)
  return M.findTab(item, tabs) ~= nil
end

--- "file:///Users/me/My%20Files/" -> "/Users/me/My Files"
function M.filePath(u)
  if type(u) ~= "string" then return nil end
  local p = u:match("^file://[^/]*(/.*)$") or u
  p = p:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  return (#p > 1 and p:gsub("/+$", "") or p)
end

--- Index of the Finder window showing folder `path` (already expanded), or nil.
function M.findPath(path, paths)
  if type(path) ~= "string" then return nil end
  local want = #path > 1 and path:gsub("/+$", "") or path
  for i, q in ipairs(paths or {}) do
    if q == want then return i end
  end
  return nil
end

function M.pathOpen(path, paths)
  return M.findPath(path, paths) ~= nil
end

--- Parse the probe output: lines "U<TAB>bundle-id<TAB>url" (browser tab) and
--- "P<TAB>file-url" (Finder window). Returns tabs {url=, app=}, folder paths, and their raw file URLs.
function M.parseProbe(text)
  local tabs, paths, raw = {}, {}, {}
  for line in (text or ""):gmatch("[^\r\n]+") do
    local k, v = line:match("^(%u)\t(.+)$")
    if k == "U" then
      local app, url = v:match("^([^\t]+)\t(.+)$")
      if app then tabs[#tabs + 1] = { url = url, app = app } end
    elseif k == "P" then
      paths[#paths + 1] = M.filePath(v)
      raw[#raw + 1] = v
    end
  end
  return tabs, paths, raw
end

return M
