local M = {}

---Retrieves the root of the current git repository/workspace
---@return string|nil path The path of the git-root, or nil if not in a git repository
function M.git_root()
  if vim.fn.executable("git") ~= 1 then
    return vim.fs.root(vim.fn.getcwd(), ".git")
  end

  local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if result.code ~= 0 and result.code ~= 128 then
    vim.notify(
      string.format("git errored when searching for the project root:\n%s", result.stderr),
      vim.log.levels.WARN
    )
    return nil
  end

  local git_path = vim.trim(result.stdout)
  if git_path == "" then return nil end

  return git_path
end

return M
