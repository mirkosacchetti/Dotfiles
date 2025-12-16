local home = os.getenv("HOME")
local opts = { noremap = true, silent = true }
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

local on_attach = function(client, bufnr)
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', 'gcc', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', '<space>k', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<space>r', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<space>c', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', '<space>w', function()
        if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
            -- Usa pcall per eseguire la formattazione e ignorare eventuali errori
            pcall(vim.lsp.buf.format, { async = false })
        end
        vim.cmd("write")
    end, opts)

    client.server_capabilities.semanticTokensProvider = nil
end

vim.lsp.enable('ocamllsp')

vim.lsp.config('fish-lsp', {
    on_attach = on_attach,
    capabilities = capabilities,
})
vim.lsp.enable('fish-lsp')


-- npm i -g vscode-langservers-extracted
vim.lsp.config('cssls', {
    on_attach = on_attach,
    capabilities = capabilities,
})
vim.lsp.config('html', {
    on_attach = on_attach,
    capabilities = capabilities,
})
vim.lsp.enable('cssls')
vim.lsp.enable('html')

-- npm install -g @vue/language-server
-- npm install -g @vue/typescript-plugin
-- npm install -g typescript-language-server typescript
local vue_language_server_path = home .. "/.npm-packages/lib/node_modules/@vue/typescript-plugin"
local tsserver_filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' }
local vue_plugin = {
  name = '@vue/typescript-plugin',
  location = vue_language_server_path,
  languages = { 'vue' },
  configNamespace = 'typescript',
}
local ts_ls_config = {
  init_options = {
    plugins = {
      vue_plugin,
    },
  },
  filetypes = tsserver_filetypes,
  on_attach = on_attach,
  capabilities = capabilities,
}

-- If you are on most recent `nvim-lspconfig`
local vue_ls_config = {
     on_attach = on_attach,
     capabilities = capabilities,
     hybridMode = false,
}
-- vim.lsp.config('ts_ls', {
--     init_options = {
--         plugins = {
--             {
--                 name = '@vue/typescript-plugin',
--                 location = vue_language_server_path,
--                 languages = { "javascript", "typescript", "vue" },
--             },
--         },
--     },
--     filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
--     single_file_support = false,
--     on_attach = on_attach,
--     capabilities = capabilities,
-- })
vim.lsp.config('vue_ls', vue_ls_config)
vim.lsp.config('ts_ls', ts_ls_config)
vim.lsp.enable({'ts_ls', 'vue_ls'})

vim.lsp.enable('rust_analyzer')
vim.lsp.config('rust_analyzer', {
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "rust" },
    settings = {
        ['rust_analyzer'] = {
            cargo = {
                allFeatures = true,
            },
        },
    },
})

-- npm install -g pyright
vim.lsp.enable('pyright')
vim.lsp.config('pyright', {
    capabilities = capabilities,
    on_attach = on_attach
})

-- pacman -S clang
vim.lsp.enable('clangd')
vim.lsp.config('clangd', {
    capabilities = capabilities,
    on_attach = on_attach
})

-- go install golang.org/x/tools/gopls@latest
vim.lsp.enable('gopls')
vim.lsp.config('gopls', {
    cmd = { "gopls", "serve" },
    on_attach = on_attach,
    capabilities = capabilities,
    filetypes = { "go", "gomod" },
    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
            staticcheck = true,
        },
    },
})

