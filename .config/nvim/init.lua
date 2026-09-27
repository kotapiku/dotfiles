-- Resolve this checkout even when started through a symlink or with -u.
local source = debug.getinfo(1, 'S').source:sub(2)
local config = vim.fs.dirname(vim.uv.fs_realpath(source) or source)
vim.g.dotfiles_config = config
local runtime = {}
for _, path in ipairs(vim.opt.runtimepath:get()) do
  local real = vim.uv.fs_realpath(path)
  if real ~= config and real ~= config .. '/after' then
    table.insert(runtime, path)
  end
end
table.insert(runtime, 1, config)
table.insert(runtime, config .. '/after')
vim.opt.runtimepath = runtime

if vim.g.vscode then
  vim.cmd.source(vim.fs.dirname(vim.fs.dirname(config)) .. '/.vimrc_vscode')
  return
end

vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'
require('dotfiles.options')
require('dotfiles.keymaps')
vim.cmd.source(config .. '/appearance.vim')
require('dotfiles.lazy')
