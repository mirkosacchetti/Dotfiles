local opts = { noremap = true, silent = true }

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set('i', 'kj', '<Esc>',opts)
vim.keymap.set("i", "<C-BS>", "<C-w>", { noremap = true })

vim.keymap.set('n', 'k', 'gk',opts)
vim.keymap.set('n', 'j', 'gj',opts)
vim.keymap.set('n', '<leader>z', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<leader>p', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', '<leader>n', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
vim.keymap.set('n', '<Leader>a', 'ggVG',opts)
vim.keymap.set('n', '<Leader>e', ':Oil<CR>', opts)
vim.keymap.set('n', '<Leader>g', ':LazyGit<CR>', opts)
vim.keymap.set('n', '<Leader>d', ':bd<CR>', opts)
vim.keymap.set('n', '<Leader>w', ':w<CR>',opts)
vim.keymap.set('n', '<Leader>s', ':w<CR>',opts)
vim.keymap.set('n', '<Leader>u', "<cmd>lua require('fzf-lua').buffers()<CR>",opts)
vim.keymap.set('n', '<Leader>o', "<cmd>lua require('fzf-lua').files()<CR>",opts)
vim.keymap.set('n', '<Leader>i', "<cmd>lua require('fzf-lua').live_grep()<CR>",opts)
vim.keymap.set('n', '<Leader>y', "<cmd>lua require('fzf-lua').quickfix()<CR>",opts)

vim.keymap.set('n', '<C-,>', ':tabprevious<CR>', { desc = 'Previous tab' })
vim.keymap.set('n', '<C-.>', ':tabnext<CR>', { desc = 'Next tab' })

vim.keymap.set('n', '<C-w>j', '<C-w>h',opts)
vim.keymap.set('n', '<C-w>k', '<C-w>j',opts)
vim.keymap.set('n', '<C-w>l', '<C-w>k',opts)
vim.keymap.set('n', '<C-w>;', '<C-w>l',opts)
vim.keymap.set("t", "j", "<Left>", { noremap = true, silent = true, buffer = true })
vim.keymap.set("t", "k", "<Down>", { noremap = true, silent = true, buffer = true })
vim.keymap.set("t", "l", "<Up>", { noremap = true, silent = true, buffer = true })
vim.keymap.set("t", ";", "<Right>", { noremap = true, silent = true, buffer = true })

-- Quickfix
vim.keymap.set('n', '<leader>co', ':copen<CR>', vim.tbl_extend('force', opts, { desc = "Open quickfix window" }))
vim.keymap.set('n', '<leader>cc', ':silent! cclose<Bar>silent! lclose<CR>', vim.tbl_extend('force', opts, { desc = "Close quickfix and location list" }))
vim.keymap.set('n', '<leader>cw', ':cwindow<CR>', vim.tbl_extend('force', opts, { desc = "Toggle quickfix window" }))

-- vim-unimpaired convention
vim.keymap.set('n', ']q', ':cnext<CR>', vim.tbl_extend('force', opts, { desc = "Next quickfix item" }))
vim.keymap.set('n', '[q', ':cprevious<CR>', vim.tbl_extend('force', opts, { desc = "Previous quickfix item" }))
vim.keymap.set('n', ']Q', ':clast<CR>', vim.tbl_extend('force', opts, { desc = "Last quickfix item" }))
vim.keymap.set('n', '[Q', ':cfirst<CR>', vim.tbl_extend('force', opts, { desc = "First quickfix item" }))

-- Location list, often filled by LSP diagnostics. <leader>cc above closes it too.
vim.keymap.set('n', '<leader>lo', ':lopen<CR>', vim.tbl_extend('force', opts, { desc = "Open location list" }))
vim.keymap.set('n', '<leader>lw', ':lwindow<CR>', vim.tbl_extend('force', opts, { desc = "Toggle location list" }))

vim.keymap.set('n', ']l', ':lnext<CR>', vim.tbl_extend('force', opts, { desc = "Next location list item" }))
vim.keymap.set('n', '[l', ':lprevious<CR>', vim.tbl_extend('force', opts, { desc = "Previous location list item" }))
vim.keymap.set('n', ']L', ':llast<CR>', vim.tbl_extend('force', opts, { desc = "Last location list item" }))
vim.keymap.set('n', '[L', ':lfirst<CR>', vim.tbl_extend('force', opts, { desc = "First location list item" }))

-- NOTE: this <leader>co overrides the :copen mapping above
vim.keymap.set('n', '<leader>co', ':colder<CR>', vim.tbl_extend('force', opts, { desc = "Older quickfix list" }))
vim.keymap.set('n', '<leader>cn', ':cnewer<CR>', vim.tbl_extend('force', opts, { desc = "Newer quickfix list" }))
