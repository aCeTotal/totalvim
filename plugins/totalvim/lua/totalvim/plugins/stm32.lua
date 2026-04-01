require("which-key").add({
  { "<leader>m", group = "mcu" },
})


-- CMSIS defines for common STM32 chips, sorted by family
local chips = {
  -- F0
  "STM32F030x6", "STM32F030x8", "STM32F031x6", "STM32F042x6",
  "STM32F051x8", "STM32F070x6", "STM32F070xB", "STM32F071xB",
  "STM32F072xB", "STM32F091xC",
  -- F1
  "STM32F100xB", "STM32F100xE", "STM32F103x6", "STM32F103xB",
  "STM32F103xE", "STM32F103xG", "STM32F105xC", "STM32F107xC",
  -- F2
  "STM32F205xx", "STM32F207xx", "STM32F215xx", "STM32F217xx",
  -- F3
  "STM32F301x8", "STM32F302xC", "STM32F302xE", "STM32F303xC",
  "STM32F303xE", "STM32F334x8", "STM32F373xC",
  -- F4
  "STM32F401xC", "STM32F401xE", "STM32F405xx", "STM32F407xx",
  "STM32F410Rx", "STM32F411xE", "STM32F412Zx", "STM32F413xx",
  "STM32F415xx", "STM32F417xx", "STM32F427xx", "STM32F429xx",
  "STM32F437xx", "STM32F439xx", "STM32F446xx", "STM32F469xx",
  -- F7
  "STM32F722xx", "STM32F746xx", "STM32F756xx", "STM32F767xx",
  "STM32F769xx", "STM32F777xx",
  -- G0
  "STM32G030xx", "STM32G031xx", "STM32G070xx", "STM32G071xx",
  "STM32G0B1xx",
  -- G4
  "STM32G431xx", "STM32G441xx", "STM32G473xx", "STM32G474xx",
  "STM32G491xx",
  -- H5
  "STM32H503xx", "STM32H562xx", "STM32H563xx", "STM32H573xx",
  -- H7
  "STM32H723xx", "STM32H743xx", "STM32H745xx", "STM32H750xx",
  "STM32H753xx", "STM32H7A3xx",
  -- L0
  "STM32L011xx", "STM32L031xx", "STM32L051xx", "STM32L052xx",
  "STM32L072xx", "STM32L073xx",
  -- L1
  "STM32L151xB", "STM32L151xC", "STM32L152xC", "STM32L162xC",
  -- L4
  "STM32L431xx", "STM32L432xx", "STM32L452xx", "STM32L476xx",
  "STM32L496xx", "STM32L4R5xx",
  -- L5
  "STM32L552xx", "STM32L562xx",
  -- U5
  "STM32U535xx", "STM32U575xx", "STM32U585xx",
  -- WB
  "STM32WB55xx",
  -- WL
  "STM32WLE5xx",
}


--- Read current STM32 target from .clangd if it exists
---@return string|nil
local function read_target_from_clangd()
  local f = io.open(vim.fn.getcwd() .. "/.clangd", "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content:match("-D(STM32%w+)")
end


--- Write or update .clangd with the chip define
---@param chip string
---@return boolean
local function update_clangd_config(chip)
  local clangd_path = vim.fn.getcwd() .. "/.clangd"
  local content = ""

  local f = io.open(clangd_path, "r")
  if f then
    content = f:read("*a")
    f:close()
  end

  if content:match("-DSTM32%w+") then
    content = content:gsub("-DSTM32%w+", "-D" .. chip)
  elseif content == "" then
    content = "CompileFlags:\n  Add: [-D" .. chip .. "]\n"
  else
    content = content .. "\n---\nCompileFlags:\n  Add: [-D" .. chip .. "]\n"
  end

  f = io.open(clangd_path, "w")
  if not f then return false end
  f:write(content)
  f:close()
  return true
end


--- Restart clangd to pick up new .clangd config
local function restart_clangd()
  for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
    local bufs = vim.lsp.get_buffers_by_client_id(client.id)
    client:stop()
    vim.defer_fn(function()
      for _, buf in ipairs(bufs) do
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
        end
      end
    end, 500)
  end
end


--- Apply chip selection: store, write .clangd, restart clangd
---@param chip string
local function apply_chip(chip)
  vim.g.stm32_target = chip

  if update_clangd_config(chip) then
    vim.notify("STM32 target: " .. chip .. "  (wrote .clangd)", vim.log.levels.INFO)
    restart_clangd()
  else
    vim.notify("STM32 target: " .. chip .. "  (could not write .clangd)", vim.log.levels.WARN)
  end
end


--- Select STM32 chip via picker
local function select_chip()
  local items = vim.list_extend(vim.list_slice(chips), { "Custom..." })

  vim.ui.select(items, { prompt = "Select STM32 target:" }, function(choice)
    if not choice then return end

    if choice == "Custom..." then
      vim.ui.input({ prompt = "CMSIS define (e.g. STM32F401xE): " }, function(input)
        if input and input ~= "" then apply_chip(input) end
      end)
      return
    end

    apply_chip(choice)
  end)
end


--- Derive ST product page URL from chip define
--- STM32F401xE → https://www.st.com/en/microcontrollers-microprocessors/stm32f401.html
---@param chip string
---@return string
local function chip_to_url(chip)
  local product = chip:match("^(STM32%u%d+)")
  if not product then product = chip:sub(1, 10) end
  return "https://www.st.com/en/microcontrollers-microprocessors/" .. product:lower() .. ".html"
end


--- Open documentation for selected chip
local function open_docs()
  local chip = vim.g.stm32_target
  if not chip then
    vim.notify("No STM32 target selected. Use <leader>ms first.", vim.log.levels.WARN)
    return
  end
  vim.ui.open(chip_to_url(chip))
end


--- Derive OpenOCD target config from chip family
---@param chip string|nil
---@return string
local function chip_to_openocd_target(chip)
  if not chip then return "target/stm32f4x.cfg" end
  local family = (chip:match("^STM32(%u%d)") or "F4"):lower()
  return "target/stm32" .. family .. "x.cfg"
end


--- Flash firmware to chip via probe-rs or openocd
local function flash_firmware()
  local elf = vim.fn.input("ELF to flash: ", vim.fn.getcwd() .. "/build/", "file")
  if elf == "" then return end

  local chip = vim.g.stm32_target
  if vim.fn.executable("probe-rs") == 1 then
    local cmd = "probe-rs download " .. vim.fn.shellescape(elf)
    if chip then cmd = cmd .. " --chip " .. chip end
    vim.cmd("botright split | terminal " .. cmd)
  elseif vim.fn.executable("openocd") == 1 then
    local cfg = vim.fs.find("openocd.cfg", { upward = true, type = "file" })[1]
    local ocd_args
    if cfg then
      ocd_args = "-f " .. vim.fn.shellescape(cfg)
    else
      ocd_args = "-f interface/stlink.cfg -f " .. chip_to_openocd_target(chip)
    end
    vim.cmd(string.format(
      "botright split | terminal openocd %s -c 'program %s verify reset exit'",
      ocd_args, vim.fn.shellescape(elf)
    ))
  else
    vim.notify("Neither probe-rs nor openocd found", vim.log.levels.ERROR)
  end
end


--- Reset chip via probe-rs or st-flash
local function reset_chip()
  if vim.fn.executable("probe-rs") == 1 then
    vim.fn.system("probe-rs reset")
    vim.notify("Chip reset via probe-rs", vim.log.levels.INFO)
  elseif vim.fn.executable("st-flash") == 1 then
    vim.fn.system("st-flash reset")
    vim.notify("Chip reset via st-flash", vim.log.levels.INFO)
  else
    vim.notify("Neither probe-rs nor st-flash found", vim.log.levels.ERROR)
  end
end


--- Start Renode simulation in a terminal split
local function start_renode()
  local elf = vim.fn.input("ELF for simulation: ", vim.fn.getcwd() .. "/build/", "file")
  if elf == "" then return end

  -- Look for .resc script in project root
  local resc = vim.fs.find(function(name) return name:match("%.resc$") end, { type = "file" })[1]

  local cmd
  if resc then
    cmd = string.format(
      "renode --console --disable-xwt %s -e 'machine StartGdbServer 3333'",
      vim.fn.shellescape(resc)
    )
  else
    local chip = vim.g.stm32_target
    local family = "f4"
    if chip then
      family = (chip:match("^STM32(%u%d)") or "F4"):lower()
    end
    cmd = string.format(
      "renode --console --disable-xwt -e '"
      .. "mach create \"stm32\"; "
      .. "machine LoadPlatformDescription @platforms/cpus/stm32%s.repl; "
      .. "sysbus LoadELF @%s; "
      .. "machine StartGdbServer 3333"
      .. "'",
      family, vim.fn.shellescape(elf)
    )
  end

  vim.cmd("botright split | terminal " .. cmd)
  vim.notify("Renode GDB server on localhost:3333 — use <leader>dc → 'Attach to GDB server'", vim.log.levels.INFO)
end


-- Initialize from existing .clangd
vim.g.stm32_target = vim.g.stm32_target or read_target_from_clangd()


require("which-key").add({
  { "<leader>ms", select_chip, desc = "select STM32 target" },
  { "<leader>md", open_docs, desc = "open chip documentation" },
  { "<leader>mf", flash_firmware, desc = "flash firmware" },
  { "<leader>mr", reset_chip, desc = "reset chip" },
  { "<leader>mS", start_renode, desc = "start Renode simulation" },
  {
    "<leader>mi",
    function()
      local chip = vim.g.stm32_target
      if chip then
        vim.notify("Current target: " .. chip, vim.log.levels.INFO)
      else
        vim.notify("No STM32 target selected", vim.log.levels.INFO)
      end
    end,
    desc = "show current target",
  },
})
