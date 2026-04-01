local lualine = require("lualine")


local function treesitter_status()
  local highlighter = require("vim.treesitter.highlighter")
  local buf = vim.api.nvim_get_current_buf()

  local has_parser = pcall(function()
    return vim.treesitter.get_parser(buf):lang()
  end)

  if not has_parser then return "TS: \u{2717}" end
  if highlighter.active[buf] then return "TS: \u{2713}" end
  return "TS: \u{25CB}"
end


local filename = {
  "filename",
  symbols = {
    modified = "[\u{25CF}]",
    readonly = "[\u{1F512}]",
  },
}


lualine.setup({
  options = { theme = "auto" },
  sections = {
    lualine_c = { filename },
    lualine_x = { "encoding", "fileformat", "filetype", treesitter_status },
  },
})
