local opt = vim.opt
opt.fileencodings = { 'utf-8' }
opt.autoindent = true
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.wrapscan = true
opt.swapfile = true
opt.undofile = true
opt.clipboard:append('unnamedplus')
opt.tags = './tags;,tags;'
opt.wildignorecase = true
opt.wildignore = { '.svn', 'CVS', '.git', '*.o', '*.a', '*.class', '*.mo', '*.la',
  '*.so', '*.obj', '*.swp', '*.jpg', '*.png', '*.xpm', '*.gif', '*.pdf', '*.bak',
  '*.beam', '*.cmi', '*.cmo', '*.cma' }
opt.hidden = true
opt.startofline = false
opt.spell = false
opt.completeopt = { 'menu', 'menuone', 'noselect' }
opt.infercase = true
opt.autocompletedelay = 120

-- Treat plain .tex files as LaTeX, including files without a document preamble.
vim.filetype.add({ extension = { tex = 'tex' } })
local group = vim.api.nvim_create_augroup('dotfiles_options', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'markdown', 'text' },
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.linebreak = true
    local undo = vim.b.undo_ftplugin
    vim.b.undo_ftplugin = (undo and undo .. ' | ' or '') .. 'setlocal spell< linebreak<'
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'qf',
  callback = function() vim.bo.buflisted = false end,
})
