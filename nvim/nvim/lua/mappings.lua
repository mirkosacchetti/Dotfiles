local opts = { noremap = true, silent = true }

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set('i', 'kj', '<Esc>',opts)

vim.keymap.set('n', 'k', 'gk',opts)
vim.keymap.set('n', 'j', 'gj',opts)
vim.keymap.set('n', '<leader>z', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<leader>p', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', '<leader>n', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)
vim.keymap.set('n', '<Leader>a', 'ggVG',opts)
vim.keymap.set('n', '<Leader>e', ':Oil<CR>', opts)
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

-- =============================================================================
-- Quickfix List (:c... comandi)
-- =============================================================================

-- Apri/Chiudi finestra Quickfix
vim.keymap.set('n', '<leader>co', ':copen<CR>', vim.tbl_extend('force', opts, { desc = "Apri finestra Quickfix" }))
vim.keymap.set('n', '<leader>cc', ':silent! cclose<Bar>silent! lclose<CR>', vim.tbl_extend('force', opts, { desc = "Chiudi finestra Quickfix/Location List" })) -- Chiude entrambe!
vim.keymap.set('n', '<leader>cw', ':cwindow<CR>', vim.tbl_extend('force', opts, { desc = "Toggle finestra Quickfix" }))

-- Naviga elementi Quickfix (convenzione vim-unimpaired)
vim.keymap.set('n', ']q', ':cnext<CR>', vim.tbl_extend('force', opts, { desc = "Prossimo elemento Quickfix" }))
vim.keymap.set('n', '[q', ':cprevious<CR>', vim.tbl_extend('force', opts, { desc = "Precedente elemento Quickfix" }))
vim.keymap.set('n', ']Q', ':clast<CR>', vim.tbl_extend('force', opts, { desc = "Ultimo elemento Quickfix" })) -- Meno comune
vim.keymap.set('n', '[Q', ':cfirst<CR>', vim.tbl_extend('force', opts, { desc = "Primo elemento Quickfix" }))  -- Meno comune

-- =============================================================================
-- Location List (:l... comandi) - Spesso usata da LSP per diagnostica
-- =============================================================================

-- Apri/Chiudi finestra Location List
vim.keymap.set('n', '<leader>lo', ':lopen<CR>', vim.tbl_extend('force', opts, { desc = "Apri finestra Location List" }))
-- Nota: <leader>cc sopra chiude anche questa. Se vuoi un comando separato:
-- vim.keymap.set('n', '<leader>lc', ':lclose<CR>', vim.tbl_extend('force', opts, { desc = "Chiudi finestra Location List" }))
vim.keymap.set('n', '<leader>lw', ':lwindow<CR>', vim.tbl_extend('force', opts, { desc = "Toggle finestra Location List" }))

-- Naviga elementi Location List (convenzione vim-unimpaired)
vim.keymap.set('n', ']l', ':lnext<CR>', vim.tbl_extend('force', opts, { desc = "Prossimo elemento Location List" }))
vim.keymap.set('n', '[l', ':lprevious<CR>', vim.tbl_extend('force', opts, { desc = "Precedente elemento Location List" }))
vim.keymap.set('n', ']L', ':llast<CR>', vim.tbl_extend('force', opts, { desc = "Ultimo elemento Location List" })) -- Meno comune
vim.keymap.set('n', '[L', ':lfirst<CR>', vim.tbl_extend('force', opts, { desc = "Primo elemento Location List" }))  -- Meno comune


vim.keymap.set('n', '<leader>co', ':colder<CR>', vim.tbl_extend('force', opts, { desc = "Vai a lista Quickfix precedente" })) -- Attenzione a conflitti
vim.keymap.set('n', '<leader>cn', ':cnewer<CR>', vim.tbl_extend('force', opts, { desc = "Vai a lista Quickfix successiva" })) -- Attenzione a conflitti
