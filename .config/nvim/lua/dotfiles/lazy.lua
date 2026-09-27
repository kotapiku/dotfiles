local path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(path) then
  local result = vim.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', path }, { text = true }):wait()
  if result.code ~= 0 then
    vim.notify('Could not install lazy.nvim. Restart after restoring network access.\n'
      .. (result.stderr or ''), vim.log.levels.ERROR)
    return
  end
end
vim.opt.runtimepath:prepend(path)
require('lazy').setup({
  spec = { { import = 'plugins' } },
  lockfile = vim.g.dotfiles_config .. '/lazy-lock.json',
  local_spec = false,
  checker = { enabled = false },
  change_detection = { notify = false },
  rocks = { enabled = false },
  install = { colorscheme = { 'hybrid' } },
  performance = { rtp = { reset = false } },
})
