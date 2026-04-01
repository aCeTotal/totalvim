local health = require("totalvim.health")

-- Register which-key group
require("which-key").add({
  { "<leader>d", group = "debug" },
})

-- Health checks for ARM toolchain
health.register_program("arm-none-eabi-gdb", false)
health.register_program("arm-none-eabi-gcc", false)
health.register_program("openocd", false)
health.register_program("cmake", false)
health.register_program("ninja", false)
health.register_program("st-info", false)
health.register_program("probe-rs", false)
health.register_program("renode", false)


require("totalvim.lazy").add_specs({
  -- nvim-dap
  {
    "nvim-dap",
    keys = {
      { "<leader>dc", function() require("dap").continue() end, desc = "continue" },
      { "<leader>dn", function() require("dap").step_over() end, desc = "step over" },
      { "<leader>di", function() require("dap").step_into() end, desc = "step into" },
      { "<leader>do", function() require("dap").step_out() end, desc = "step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "toggle breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        desc = "conditional breakpoint",
      },
      { "<leader>dr", function() require("dap").repl.open() end, desc = "open REPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "terminate" },
    },
    after = function()
      local dap = require("dap")

      -- Inline virtual text for variable values during debugging
      vim.cmd.packadd("nvim-dap-virtual-text")
      require("nvim-dap-virtual-text").setup()

      -- Breakpoint signs
      vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticInfo", linehl = "CursorLine" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticHint" })

      -- probe-rs: native DAP adapter for real hardware (ST-Link, J-Link, CMSIS-DAP)
      dap.adapters.probe_rs = {
        type = "server",
        port = "${port}",
        executable = {
          command = "probe-rs",
          args = { "dap-server", "--port", "${port}" },
        },
      }

      -- GDB DAP: arm-none-eabi-gdb with built-in DAP interpreter (GDB 14+)
      -- Connects to any GDB server backend: OpenOCD, Renode, J-Link GDB server
      dap.adapters.arm_gdb = {
        type = "executable",
        command = "arm-none-eabi-gdb",
        args = { "--interpreter=dap" },
      }

      -- Launch configurations for C/C++
      dap.configurations.c = {
        {
          name = "Debug STM32 (probe-rs)",
          type = "probe_rs",
          request = "launch",
          chip = function()
            return vim.fn.input("probe-rs chip: ", vim.g.stm32_target or "")
          end,
          flashingConfig = {
            flashingEnabled = true,
            resetAfterFlashing = true,
            haltAfterReset = true,
          },
          coreConfigs = {
            {
              coreIndex = 0,
              programBinary = function()
                return vim.fn.input("ELF: ", vim.fn.getcwd() .. "/build/", "file")
              end,
            },
          },
        },
        {
          name = "Attach to GDB server (OpenOCD/Renode)",
          type = "arm_gdb",
          request = "attach",
          target = function()
            return vim.fn.input("GDB target: ", "remote localhost:3333")
          end,
          program = function()
            return vim.fn.input("ELF: ", vim.fn.getcwd() .. "/build/", "file")
          end,
          cwd = "${workspaceFolder}",
        },
      }
      dap.configurations.cpp = dap.configurations.c

      -- Load .vscode/launch.json if present
      local ok, vscode = pcall(require, "dap.ext.vscode")
      if ok then
        vscode.load_launchjs(nil, { probe_rs = { "c", "cpp" }, arm_gdb = { "c", "cpp" } })
      end
    end,
  },

  -- nvim-dap-ui
  {
    "nvim-dap-ui",
    keys = {
      { "<leader>du", function() require("dapui").toggle() end, desc = "toggle debug UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "eval expression", mode = { "n", "v" } },
    },
    after = function()
      local dapui = require("dapui")

      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.35 },
              { id = "breakpoints", size = 0.15 },
              { id = "stacks", size = 0.25 },
              { id = "watches", size = 0.25 },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "console", size = 0.5 },
            },
            size = 10,
            position = "bottom",
          },
        },
      })

      -- Auto open/close UI on debug session events
      local dap = require("dap")
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },
})
