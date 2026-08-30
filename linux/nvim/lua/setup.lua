local cmp = require('cmp')

cmp.setup({
  window = {
    documentation = cmp.config.window.bordered(),
  },
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-l>'] = cmp.mapping.scroll_docs(-4),
    ['<C-k>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<esc>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
    { name = 'path' },
  })
})

require 'oil'.setup {}
require 'lualine'.setup{
    options ={
        icons_enabled=false,
    }
}

require 'fzf-lua'.setup {
    buffers = {
        file_icons        = false,
    },
    files = {
        file_icons        = false,
    },
    keymap = {
        fzf = {
            -- ["ctrl-k"]     = "down",
            -- ["ctrl-l"]     = "up",
            ["ctrl-z"]     = "abort",
            ["ctrl-u"]     = "unix-line-discard",
            ["ctrl-f"]     = "half-page-down",
            ["ctrl-b"]     = "half-page-up",
            ["ctrl-a"]     = "beginning-of-line",
            ["ctrl-e"]     = "end-of-line",
            ["alt-a"]      = "toggle-all",
            ["f3"]         = "toggle-preview-wrap",
            ["f4"]         = "toggle-preview",
            ["shift-down"] = "preview-page-down",
            ["shift-up"]   = "preview-page-up",
        },
    },
}

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "vue",
--   callback = function()
--     vim.bo.commentstring = "// %s"
--   end,
-- })
