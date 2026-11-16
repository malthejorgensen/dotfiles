
-- vim.opt.clipboard = 'unnamedplus' -- use system clipboard for yank
vim.opt.clipboard = '' -- Don't use system clipboard for yank! (usually I don't want to overwrite clipboard on yank)

vim.opt.nu = true                 -- set line numbers
-- vim.opt.relativenumber = true  -- use relative line numbers

-- set tab size to 2 spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.wrap = false -- no line wrapping

-- Show trailing whitespace as dots.
vim.opt.list = true
vim.opt.listchars:append({ trail = '·' })

vim.opt.incsearch = true -- incremental search
vim.opt.ignorecase = true -- Part 1: search case-insensitive when search string is all lowercase
vim.opt.smartcase = true  -- Part 2: search case-insensitive when search string is all lowercase
-- both options above are needed

vim.opt.termguicolors = true

-- Give trailing spaces and tabs a pink background.
local whitespace_group = vim.api.nvim_create_augroup('TrailingWhitespace', { clear = true })
local function highlight_trailing_whitespace()
  vim.api.nvim_set_hl(0, 'TrailingWhitespace', { fg = '#5c2744', bg = '#f2b8cf' })
end
highlight_trailing_whitespace()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = whitespace_group,
  callback = highlight_trailing_whitespace,
})

local function show_trailing_whitespace()
  for _, match in ipairs(vim.fn.getmatches()) do
    if match.group == 'TrailingWhitespace' then
      return
    end
  end
  vim.fn.matchadd('TrailingWhitespace', [[\s\+$]])
end
vim.api.nvim_create_autocmd('WinEnter', {
  group = whitespace_group,
  callback = show_trailing_whitespace,
})
for _, win in ipairs(vim.api.nvim_list_wins()) do
  vim.api.nvim_win_call(win, show_trailing_whitespace)
end

-- Reopen files at the last line visited.
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local line = vim.api.nvim_buf_get_mark(0, '"')[1]
    if line > 0 and line <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
    end
  end,
})

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
