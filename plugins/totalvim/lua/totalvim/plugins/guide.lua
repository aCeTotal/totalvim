local Popup = require("nui.popup")

local pages = {
  {
    title = "STM32 Development Guide",
    content = [[
# STM32 Development Guide

## Workflow Overview

```
1. Select chip     <leader>ms    Pick STM32 target, writes .clangd
2. Build           cmake + ninja  CMake configure → build
3. Flash           <leader>mf    probe-rs or openocd
4. Debug           <leader>dc    nvim-dap (probe-rs / GDB DAP)
5. Simulate        <leader>mS    Renode + GDB attach
```

---

## 1. Chip Selection

| Key           | Action                          |
|---------------|---------------------------------|
| `<leader>ms`  | Select STM32 target (picker)    |
| `<leader>mi`  | Show current target             |
| `<leader>md`  | Open chip docs (st.com)         |

- Selecting a chip writes the CMSIS define to `.clangd`
- clangd auto-restarts to pick up the new define
- Custom chips: choose "Custom..." in picker

**Example .clangd generated:**
```yaml
CompileFlags:
  Add: [-DSTM32F411xE]
```

---

## 2. Building (CMake + Ninja)

Typical bare-metal STM32 build:
```bash
cmake -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/arm-gcc.cmake
ninja -C build
```

- `cmake-language-server` provides LSP for CMakeLists.txt
- Build artifacts land in `build/` (used by flash/debug)

---

## 3. Flashing

| Key           | Action                          |
|---------------|---------------------------------|
| `<leader>mf`  | Flash firmware (ELF picker)     |
| `<leader>mr`  | Reset chip                      |

**probe-rs** (preferred): auto-detects probe, uses chip from `<leader>ms`
**openocd**: falls back if probe-rs not found, uses `openocd.cfg` or auto-config

---

## 4. Debugging (nvim-dap)

| Key           | Action                          |
|---------------|---------------------------------|
| `<leader>dc`  | Continue / launch               |
| `<leader>dn`  | Step over                       |
| `<leader>di`  | Step into                       |
| `<leader>do`  | Step out                        |
| `<leader>db`  | Toggle breakpoint               |
| `<leader>dB`  | Conditional breakpoint          |
| `<leader>dr`  | Open REPL                       |
| `<leader>dt`  | Terminate session               |
| `<leader>du`  | Toggle debug UI                 |
| `<leader>de`  | Eval expression (n/v)           |

**Two DAP adapters configured:**

1. **probe-rs** — native DAP, flashes + debugs real hardware
   - Select "Debug STM32 (probe-rs)" when `<leader>dc`
   - Flashes ELF, resets, halts at main

2. **arm-none-eabi-gdb** — GDB DAP, connects to any GDB server
   - Select "Attach to GDB server (OpenOCD/Renode)"
   - Default target: `remote localhost:3333`

**nvim-dap-virtual-text** shows variable values inline while debugging.

---

## 5. Renode Simulation

| Key           | Action                          |
|---------------|---------------------------------|
| `<leader>mS`  | Start Renode simulation         |

**Workflow:**
1. `<leader>mS` → pick ELF → Renode starts with GDB server on `:3333`
2. `<leader>dc` → "Attach to GDB server" → `remote localhost:3333`
3. Debug as normal (breakpoints, stepping, eval)

- If `.resc` script found in project root, Renode uses it
- Otherwise auto-generates config from chip family

---

## Quick Reference

| Key           | Action                          |
|---------------|---------------------------------|
| `<leader>ms`  | Select STM32 target             |
| `<leader>mi`  | Show current target             |
| `<leader>md`  | Open chip documentation         |
| `<leader>mf`  | Flash firmware                  |
| `<leader>mr`  | Reset chip                      |
| `<leader>mS`  | Start Renode simulation         |
| `<leader>dc`  | Continue / launch debug         |
| `<leader>dn`  | Step over                       |
| `<leader>di`  | Step into                       |
| `<leader>do`  | Step out                        |
| `<leader>db`  | Toggle breakpoint               |
| `<leader>dB`  | Conditional breakpoint          |
| `<leader>dr`  | Open REPL                       |
| `<leader>dt`  | Terminate debug                 |
| `<leader>du`  | Toggle debug UI                 |
| `<leader>de`  | Eval expression                 |
]],
  },
  {
    title = "Keybindings Reference",
    content = [[
# Keybindings Reference

## Vim Motions

| Key             | Action                          |
|-----------------|---------------------------------|
| `h/j/k/l`      | Left / Down / Up / Right        |
| `w`             | Next word start                 |
| `b`             | Previous word start             |
| `e`             | Next word end                   |
| `W/B/E`         | Same but WORD (whitespace-sep)  |
| `f{c}` / `F{c}` | Find char forward / backward   |
| `t{c}` / `T{c}` | Till char forward / backward   |
| `;` / `,`       | Repeat f/t forward / backward  |
| `0`             | Start of line                   |
| `$`             | End of line                     |
| `^`             | First non-blank                 |
| `gg` / `G`     | Top / bottom of file            |
| `{` / `}`      | Previous / next paragraph       |
| `Ctrl-d/Ctrl-u` | Half-page down / up            |
| `Ctrl-f/Ctrl-b` | Full page down / up            |
| `%`             | Matching bracket                |
| `H/M/L`        | Screen top / middle / bottom    |

## Operators & Text Objects

| Key             | Action                          |
|-----------------|---------------------------------|
| `d`             | Delete                          |
| `c`             | Change (delete + insert)        |
| `y`             | Yank (copy)                     |
| `>`/`<`         | Indent / dedent                 |
| `iw` / `aw`    | Inner / around word             |
| `i"` / `a"`    | Inner / around double quotes    |
| `i'` / `a'`    | Inner / around single quotes    |
| `i)` / `a)`    | Inner / around parentheses      |
| `i]` / `a]`    | Inner / around brackets         |
| `i}` / `a}`    | Inner / around braces           |
| `it` / `at`    | Inner / around HTML tag         |
| `ip` / `ap`    | Inner / around paragraph        |

---

## Flash

| Key             | Action                          |
|-----------------|---------------------------------|
| `s`             | Flash jump (n/x/o)             |
| `S`             | Flash treesitter (n/o)         |
| `r`             | Remote flash (o)               |
| `R`             | Treesitter search (x/o)        |
| `Ctrl-s`        | Toggle flash search (c)        |

---

## Find (Telescope)                           `<leader>f`

| Key             | Action                          |
|-----------------|---------------------------------|
| `<leader>ff`    | Find file by name               |
| `<leader>fg`    | Find file by content (rg)       |
| `<leader>fb`    | Find buffer by name             |
| `<leader>fh`    | Open help                       |
| `<leader>fx`    | Run command (M-x)               |
| `<leader>fs`    | Find definitions                |
| `<leader>fr`    | Find references                 |

---

## LSP                                        `<leader>l`

| Key             | Action                          |
|-----------------|---------------------------------|
| `<leader>lgd`   | Jump to definition              |
| `<leader>lgD`   | Jump to declaration             |
| `<leader>lgt`   | Jump to type definition         |
| `<leader>lh`    | Show hover info                 |
| `<leader>ls`    | Show signature help             |
| `<leader>lr`    | Rename symbol                   |
| `<leader>lf`    | Format buffer                   |
| `<leader>l.`    | Show code actions               |
| `<leader>lpd`   | Peek definition (Lspsaga)       |
| `<leader>lpt`   | Peek type definition (Lspsaga)  |
| `<leader>l<`    | Previous diagnostic (Lspsaga)   |
| `<leader>l>`    | Next diagnostic (Lspsaga)       |
| `<leader>lf`    | Find refs & impls (Lspsaga)     |
| `<leader>lo`    | Open outline (Lspsaga)          |

---

## Git                                        `<leader>g`

| Key             | Action                          |
|-----------------|---------------------------------|
| `<leader>gg`    | Neogit status                   |
| `<leader>gbb`   | Open file blame                 |
| `<leader>gbi`   | Show blame info                 |
| `<leader>gbl`   | Toggle current line blame       |
| `<leader>gw`    | Toggle word diff                |

---

## Debug (DAP)                                `<leader>d`

| Key             | Action                          |
|-----------------|---------------------------------|
| `<leader>dc`    | Continue / launch               |
| `<leader>dn`    | Step over                       |
| `<leader>di`    | Step into                       |
| `<leader>do`    | Step out                        |
| `<leader>db`    | Toggle breakpoint               |
| `<leader>dB`    | Conditional breakpoint          |
| `<leader>dr`    | Open REPL                       |
| `<leader>dt`    | Terminate session               |
| `<leader>du`    | Toggle debug UI                 |
| `<leader>de`    | Eval expression (n/v)           |

---

## MCU / STM32                                `<leader>m`

| Key             | Action                          |
|-----------------|---------------------------------|
| `<leader>ms`    | Select STM32 target             |
| `<leader>mi`    | Show current target             |
| `<leader>md`    | Open chip documentation         |
| `<leader>mf`    | Flash firmware                  |
| `<leader>mr`    | Reset chip                      |
| `<leader>mS`    | Start Renode simulation         |

---

## Diagnostics (Trouble)                      `<leader>x`

| Key             | Action                          |
|-----------------|---------------------------------|
| `<leader>xx`    | Toggle diagnostics              |
| `<leader>xX`    | Toggle buffer diagnostics       |
| `<leader>xL`    | Location list                   |
| `<leader>xQ`    | Quickfix list                   |
| `<leader>xc`    | Toggle virtual lines            |
| `<leader>cs`    | Symbols (Trouble)               |
| `<leader>cl`    | LSP defs/refs (Trouble)         |

---

## File Explorer (Oil)                        `<leader>o`

| Key             | Action                          |
|-----------------|---------------------------------|
| `<leader>o.`    | Open current folder             |
| `<leader>o-`    | Open current folder (floating)  |
| `-`             | Open current folder (floating)  |

---

## Surround (nvim-surround)

| Key             | Action                          |
|-----------------|---------------------------------|
| `ys{motion}{c}` | Add surround                   |
| `ds{c}`         | Delete surround                 |
| `cs{old}{new}`  | Change surround                 |
| `S{c}`          | Surround selection (visual)     |
| `R`             | Raw string surround (ft-local)  |

---

## Folding (nvim-ufo)

| Key             | Action                          |
|-----------------|---------------------------------|
| `zR`            | Open all folds                  |
| `zM`            | Close all folds                 |
| `za`            | Toggle fold under cursor        |
| `zo` / `zc`    | Open / close fold               |

---

## Completion (blink.cmp)

| Key             | Action                          |
|-----------------|---------------------------------|
| `Ctrl-Space`    | Show / toggle docs              |
| `Ctrl-e`        | Hide completion                 |
| `CR`            | Accept completion               |
| `Ctrl-l`        | Select next item                |
| `Ctrl-h`        | Select prev item                |
| `Tab`           | Snippet jump forward            |
| `S-Tab`         | Snippet jump backward           |
| `Ctrl-k`        | Scroll docs up                  |
| `Ctrl-j`        | Scroll docs down                |

---

## Snippets (LuaSnip)

| Key             | Action                          |
|-----------------|---------------------------------|
| `Ctrl-e`        | Expand snippet (i/s)            |
| `Ctrl-j`        | Cycle choices in node (i/s)     |
| `Ctrl-Shift-j`  | UI select choices (i/s)        |

---

## Line Numbers                               `<leader>#`

| Key             | Action                          |
|-----------------|---------------------------------|
| `<leader>##`    | Toggle relative numbers         |
| `<leader>#+`    | Enable relative numbers         |
| `<leader>#-`    | Disable relative numbers        |

---

## Misc

| Key             | Action                          |
|-----------------|---------------------------------|
| `p`             | Paste and re-indent             |
| `P`             | Paste above and re-indent       |
| `<leader>q`     | Open this guide                 |
]],
  },
}

local popup_instance = nil

local function close_popup()
  if popup_instance then
    popup_instance:unmount()
    popup_instance = nil
  end
end

local function render_page(popup, n)
  local page = pages[n]

  vim.api.nvim_buf_set_option(popup.bufnr, "modifiable", true)
  local lines = vim.split(page.content, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(popup.bufnr, "modifiable", false)

  popup.border:set_text("top", " " .. page.title .. " ", "center")

  -- Build footer with page indicator
  local parts = {}
  for i = 1, #pages do
    if i == n then
      parts[i] = "[" .. i .. "]"
    else
      parts[i] = " " .. i .. " "
    end
  end
  local footer = table.concat(parts, " ") .. "  Tab/S-Tab: nav  q: close"
  popup.border:set_text("bottom", " " .. footer .. " ", "center")
end

local function open_guide()
  if popup_instance then
    close_popup()
    return
  end

  local popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = { top = "", top_align = "center", bottom = "", bottom_align = "center" },
    },
    position = "50%",
    size = { width = "80%", height = "80%" },
    buf_options = {
      filetype = "markdown",
      modifiable = false,
      readonly = true,
    },
    win_options = {
      conceallevel = 2,
      wrap = true,
    },
  })

  popup:mount()
  popup_instance = popup

  local current_page = 1

  render_page(popup, current_page)

  local function next_page()
    if current_page < #pages then
      current_page = current_page + 1
      render_page(popup, current_page)
    end
  end

  local function prev_page()
    if current_page > 1 then
      current_page = current_page - 1
      render_page(popup, current_page)
    end
  end

  -- Navigation
  popup:map("n", "<Tab>", next_page)
  popup:map("n", "l", next_page)
  popup:map("n", "<S-Tab>", prev_page)
  popup:map("n", "h", prev_page)

  -- Direct page jumps
  for i = 1, #pages do
    local page_num = i
    popup:map("n", tostring(i), function()
      current_page = page_num
      render_page(popup, current_page)
    end)
  end

  -- Close
  popup:map("n", "q", close_popup)
  popup:map("n", "<Esc>", close_popup)

  -- Close on leave
  popup:on("WinLeave", close_popup)
end

require("which-key").add({
  { "<leader>q", open_guide, desc = "open guide" },
})
