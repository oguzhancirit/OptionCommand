-- Pure math for the wheel (no Hammerspoon calls, so it can be tested with plain Lua).
-- Angles are clockwise, 0 = straight up. Slot 1 sits at the top.
local M = {}

--- Which slot is the pointer over? dx,dy = pointer offset from the wheel centre.
--- Returns slotIndex (or nil inside the dead zone) and the distance.
function M.pick(dx, dy, n, dead)
  local d = math.sqrt(dx * dx + dy * dy)
  if n < 1 or d < dead then return nil, d end
  local a = math.atan(dx, -dy)
  if a < 0 then a = a + 2 * math.pi end
  local step = 2 * math.pi / n
  return math.floor((a + step / 2) / step) % n + 1, d
end

--- Offset of slot i (of n) on a circle of radius r.
function M.slot(i, n, r)
  local a = (i - 1) * 2 * math.pi / n
  return r * math.sin(a), -r * math.cos(a)
end

--- Polygon points of the ring slice that belongs to slot i.
function M.sector(cx, cy, rIn, rOut, i, n)
  local step = 2 * math.pi / n
  local a0 = (i - 1) * step - step / 2
  local k = math.max(4, math.ceil(48 / n))
  local pts = {}
  for j = 0, k do
    local a = a0 + step * j / k
    pts[#pts + 1] = { x = cx + rOut * math.sin(a), y = cy - rOut * math.cos(a) }
  end
  for j = k, 0, -1 do
    local a = a0 + step * j / k
    pts[#pts + 1] = { x = cx + rIn * math.sin(a), y = cy - rIn * math.cos(a) }
  end
  return pts
end

--- Keep a wheel of radius r fully inside a screen frame {x,y,w,h}.
function M.clamp(cx, cy, r, f)
  cx = math.max(f.x + r, math.min(f.x + f.w - r, cx))
  cy = math.max(f.y + r, math.min(f.y + f.h - r, cy))
  return cx, cy
end

return M
