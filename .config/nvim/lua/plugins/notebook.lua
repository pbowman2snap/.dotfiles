return {
  {
    "Vigemus/iron.nvim",
    config = function()
      local iron = require("iron.core")
      local iron_config = require("iron.config")
      local iron_view = require("iron.view")
      local process_lines = function(lines)
        local clean = {} -- Start bracketed paste
        for _, line in ipairs(lines) do
          if not line:match("^```") then
            table.insert(clean, line)
          end
        end
        return clean
      end
      local language_logic = {
        python = {
          command = { "ipython", "--no-banner" },
          format = process_lines,
        },
        sh = {
          command = { "zsh" },
          format = process_lines,
        },
      }

      -- 2. SEARCH LOGIC
      local function get_markdown_lang()
        local buf = vim.api.nvim_get_current_buf()
        local curr_row = vim.api.nvim_win_get_cursor(0)[1]
        for i = curr_row, 1, -1 do
          local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1] or ""
          local ft = line:match("^```%{%s*([%w%d%.%-_]+)%s*%}") or line:match("^```([%w%d%.%-_]+)")
          if ft then
            return ft
          end
          if i ~= curr_row and line:match("^```$") then
            break
          end
        end
        return "sh"
      end

      local function smart_send()
        local buf = vim.api.nvim_get_current_buf()
        local curr_row = vim.api.nvim_win_get_cursor(0)[1]
        local start_line = nil
        local end_line = nil

        for i = curr_row, 1, -1 do
          local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1] or ""
          if line:match("^```") then
            start_line = i
            break
          end
        end

        local line_count = vim.api.nvim_buf_line_count(buf)
        for i = curr_row, line_count do
          local line = vim.api.nvim_buf_get_lines(buf, i - 1, i, false)[1] or ""
          if line:match("^```$") or (i > start_line and line:match("^```")) then
            end_line = i
            break
          end
        end

        if start_line and end_line then
          local lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line - 1, false)
          local lang = get_markdown_lang()
          local logic = language_logic[lang] or language_logic["sh"]
          table.insert(lines, "")
          iron_config.repl_definition.markdown = {
            command = logic.command,
            format = logic.format,
          }
          iron.send("markdown", lines)
        else
          vim.notify("Iron: Not inside a code block", vim.log.levels.WARN)
        end
      end
      iron.setup({
        -- Move this OUT of the config table

        config = {
          scratch_repl = true,
          highlight_last = "IronLastSent",
          visibility = require("iron.visibility").toggle,
          repl_open_cmd = iron_view.split.vertical.botright(50),
        },

        repl_definition = {
          python = language_logic.python,
          markdown = {
            command = { "zsh" },
            block_dividers = { "^```", "^```" },
          },
        },
      })

      local lk = require("config.keymaps").lk
      local descmap = require("config.utils").desc_keymap

      descmap("n", lk.notebook, "r", smart_send, "Execute Code Block")
    end,
  },
  {
    "GCBallesteros/jupytext.nvim",
    opts = {
      custom_language_formatting = {
        python = {
          extension = "md",
          style = "markdown",
          force_ft = "markdown",
        },
        r = {
          extension = "md",
          style = "markdown",
          force_ft = "markdown",
        },
      },
    },
  },
}
