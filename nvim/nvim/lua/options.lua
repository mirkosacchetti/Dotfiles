vim.g.netrw_banner = 0
vim.opt.relativenumber = false
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.errorbells = false
vim.opt.linebreak = true
vim.opt.updatetime = 250
vim.opt.signcolumn = "yes:1"

vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smartindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.scrolloff = 8
vim.opt.swapfile = false
vim.opt.hlsearch = false
vim.opt.backup = false
vim.opt.mouse = "a"

vim.opt.clipboard = "unnamedplus"
vim.opt.shortmess = vim.opt.shortmess + 'I'
vim.opt.completeopt = menu, menuone, noselect

vim.opt.showmode = false 
vim.opt.ruler = false 
vim.o.laststatus = 2
vim.opt.showcmd = false
vim.opt.showmatch = false
vim.opt.shortmess = vim.opt.shortmess + 'c'

require("lumon").setup({ transparent = true })
vim.cmd("colorscheme lumon")
