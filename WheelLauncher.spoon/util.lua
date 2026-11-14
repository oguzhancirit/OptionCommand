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

return M
