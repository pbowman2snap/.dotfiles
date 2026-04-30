vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2

-- TS:scheme
local constant_query = [[
; extends
(chunk
  (comment) @_comment 
  . 
  local_declaration:
    (variable_declaration
      (assignment_statement
        (variable_list
          name: (identifier))
        (expression_list
          value: (string
            content: (string_content) @injection.content
            (#set! injection.language "scheme")
            (#set! priority 150))
          )))
  (#match? @_comment "TS:scheme")
)
]]

vim.api.nvim_set_hl(0, "@lsp.type.string.python", {})
local full_query = constant_query
vim.treesitter.query.set("lua", "injections", full_query)
vim.treesitter.query.set("lua", "highlights", full_query)
