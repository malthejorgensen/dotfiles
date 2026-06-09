
vim.opt.clipboard = 'unnamedplus' -- use system keyboard for yank

vim.opt.nu = true                 -- set line numbers -- set line numbers
-- vim.opt.relativenumber = true     -- use relative line numbers

-- set tab size to 2 spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.wrap = false -- no line wrapping

vim.opt.incsearch = true -- incremental search
vim.opt.ignorecase = true -- Part 1: search case-insensitive when search string is all lowercase
vim.opt.smartcase = true  -- Part 2: search case-insensitive when search string is all lowercase
-- both options above are needed

vim.opt.termguicolors = true

-- FROM: https://medium.com/unixification/must-have-neovim-keymaps-51c283394070
function Map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

-- Command mode on Space
Map("n", "<Space>", ":")
Map("v", "<Space>", ":")


modes = {"n", "v", "o"}
for i, mode in ipairs(modes) do
  -- Easily go to the beginning and of line
  Map("n", ":", "$")
  Map("n", "J", "^")
  --
  -- Home-row navigation
  Map(mode, "j", "h")
  Map(mode, "k", "j")
  Map(mode, "l", "k")
  Map(mode, ";", "l")
  -- Danish
  Map(mode, "æ", "l")
  Map(mode, "-", "/")
end

Map("n", ",j", "J")

-- Window navigation (splits)
Map("n", "<C-W>j", "<C-W>h")
Map("n", "<C-W>k", "<C-W>j")
Map("n", "<C-W>l", "<C-W>k")
Map("n", "<C-W>;", "<C-W>l")
