-- Discord Rich Presence: shows "Editing <file> / Workspace: <name>" with a timer.
-- To get a custom app name/logo in Discord (instead of "Neovim"), create an
-- application at https://discord.com/developers/applications, upload a logo
-- asset named "logo", and put its Application ID in `client_id` below.
require("totalvim.lazy").add_specs({ {
  "neocord",
  event = "DeferredUIEnter",
  after = function()
    require("neocord").setup({
      client_id = "1532490679681417306",
      -- The app icon uploaded in the Discord developer portal (Nix snowflake).
      -- The hash changes if a new icon is uploaded; get the current one from
      -- https://discord.com/api/v10/applications/1532490679681417306/rpc
      logo = "https://cdn.discordapp.com/app-icons/1532490679681417306/afc49e1b872180c83af102144853b104.png?size=512",
      logo_tooltip = "Totalvim",
      main_image = "logo",
      show_time = true,
      editing_text = function(filename)
        local ext = filename:match("%.[%w_]+$")
        return ext and ("Writing code in a " .. ext .. " file") or "Writing code"
      end,
      reading_text = "reading %s",
      workspace_text = "NixlyOS Workspace",
      file_explorer_text = "browsing %s",
      git_commit_text = "committing changes",
      terminal_text = "using terminal",
      line_number_text = "line %s of %s",
    })
  end,
}, })
