local raw_string_configs = {
  rust = {
    add = { 'r#"', '"#' },
    find = 'r%#".-"%#',
    delete = '^(r%#")().-("%#)()$',
  },
  cpp = {
    add = { 'R"(', ')"' },
    find = 'R"%(.-%)"',
    delete = '^(R"%()().-(%)%")()$',
  },
  lua = {
    add = { "[[", "]]" },
    find = "%[%[.-%]%]",
    delete = "^(%[%[)().-(%]%])()$",
  },
}


local function setup_raw_strings()
  for filetype, config in pairs(raw_string_configs) do
    vim.api.nvim_create_autocmd("FileType", {
      pattern = filetype,
      callback = function()
        require("nvim-surround").buffer_setup({
          surrounds = { ["R"] = config },
        })
      end,
    })
  end
end


local function get_supported_filetypes()
  local filetypes = {}
  for ft, _ in pairs(raw_string_configs) do
    table.insert(filetypes, ft)
  end
  return filetypes
end


require("totalvim.lazy").add_specs({ {
  "nvim-surround",
  after = function()
    require("nvim-surround").setup({})
    setup_raw_strings()
  end,
  ft = get_supported_filetypes(),
  keys = {
    { "ys", mode = { "n" } },
    { "ds", mode = { "n" } },
    { "cs", mode = { "n" } },
    { "S", mode = { "v" } },
  },
}, })
