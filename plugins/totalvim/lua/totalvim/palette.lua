local M = {}

local DIR = vim.fs.joinpath(vim.uv.os_homedir(), ".local/state/nixly-theme")
local FILE = "nixlytile.conf"
local PATH = vim.fs.joinpath(DIR, FILE)
local DEBOUNCE_MS = 60

---Catppuccin name: role or mix.
local ROLES = {
  rosewater = "primary",
  flamingo = "on_red_container",
  pink = "magenta",
  mauve = { "magenta", "blue", 0.5 },
  red = "error",
  maroon = { "red", "magenta", 0.5 },
  peach = { "red", "yellow", 0.5 },
  yellow = { "yellow", "on_yellow_container", 0.5 },
  green = "green",
  teal = "cyan",
  sky = { "cyan", "blue", 0.5 },
  sapphire = { "blue", "cyan", 0.75 },
  blue = "blue",
  lavender = { "blue", "on_blue_container", 0.5 },
  text = "on_surface",
  subtext1 = "on_surface_variant",
  subtext0 = { "on_surface_variant", "outline", 0.5 },
  overlay2 = "outline",
  overlay1 = { "outline", "outline_variant", 0.75 },
  overlay0 = { "outline", "outline_variant", 0.5 },
  surface2 = "outline_variant",
  surface1 = { "surface_container_highest", "outline_variant", 0.5 },
  surface0 = "surface_container_high",
  base = "surface",
  mantle = "surface_container_low",
  crust = "surface_container_lowest",
  selection = "secondary_container",
}

---@type string|nil
local loaded_text = nil


---@param text string
---@return table<string, string>
local function parse(text)
  local roles = {}
  for line in text:gmatch("[^\n]+") do
    local name, hex = line:match("^dark%.([%w_]+) (%x%x%x%x%x%x)$")
    if name then roles[name] = "#" .. hex end
  end
  return roles
end


---@param hex string "#rrggbb"
---@return integer, integer, integer
local function channels(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end


---@param x integer
---@param y integer
---@param weight number share of x
---@return integer
local function lerp(x, y, weight)
  return math.floor(x * weight + y * (1 - weight) + 0.5)
end


---@param a string
---@param b string
---@param weight number share of a
---@return string
local function mix(a, b, weight)
  local ar, ag, ab = channels(a)
  local br, bg, bb = channels(b)
  return string.format("#%02x%02x%02x", lerp(ar, br, weight), lerp(ag, bg, weight), lerp(ab, bb, weight))
end


---@param roles table<string, string>
---@param role string|table
---@return string|nil
local function resolve(roles, role)
  if type(role) == "string" then return roles[role] end

  local a, b = roles[role[1]], roles[role[2]]
  if not (a and b) then return nil end
  return mix(a, b, role[3])
end


---@return table<string, string>|nil colors nil when absent, partial or unchanged
function M.load()
  local file = io.open(PATH)
  if not file then return nil end

  local text = file:read("*a")
  file:close()
  if text == loaded_text then return nil end

  local roles = parse(text)
  local colors = {}
  for name, role in pairs(ROLES) do
    colors[name] = resolve(roles, role)
    if not colors[name] then return nil end
  end

  loaded_text = text
  return colors
end


---@param apply fun(colors: table<string, string>)
function M.watch(apply)
  local timer = assert(vim.uv.new_timer())
  local event = assert(vim.uv.new_fs_event())
  local reload = vim.schedule_wrap(function()
    local colors = M.load()
    if colors then apply(colors) end
  end)

  local ok = event:start(DIR, {}, function(err, name)
    if not err and name == FILE then timer:start(DEBOUNCE_MS, 0, reload) end
  end)
  if ok then return end

  event:close()
  timer:close()
end

return M
