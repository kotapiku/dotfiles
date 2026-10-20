local function map(mode, lhs, rhs, desc, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', { desc = desc }, opts or {}))
end

map('i', 'jk', '<Esc>', 'Leave insert mode')
map('t', 'jk', '<C-\\><C-n>', 'Leave terminal input')
for key, direction in pairs({ j = 'down', k = 'up' }) do
  map('t', '<C-w>' .. key, '<C-\\><C-n><C-w>' .. key, 'Move to window ' .. direction)
end
-- Expand an interactively typed :terminal without affecting plugin terminals.
map('ca', 'terminal', function()
  if vim.fn.getcmdtype() == ':' and vim.fn.getcmdline() == 'terminal' then
    return 'botright split | startinsert | terminal'
  end
  return 'terminal'
end, 'Open terminal in a bottom split', { expr = true })
map('n', 'n', 'nzz', 'Next search match, centered')
map('n', 'N', 'Nzz', 'Previous search match, centered')
map('n', 'gs', ':<C-u>%s///g<Left><Left><Left>', 'Replace in file')
map('x', 'gs', ':s///g<Left><Left><Left>', 'Replace in selection')
map('n', ';', ':', 'Command line')
map('n', ':', ';', 'Repeat character search')
map('n', '<Esc>', '<Cmd>nohlsearch<CR>', 'Clear search highlighting')

-- Wrapped prose moves by screen line; counts and code keep logical lines.
local prose = { tex = true, markdown = true, text = true }
for _, key in ipairs({ 'j', 'k', '0', '$' }) do
  map({ 'n', 'x', 'o' }, key, function()
    return prose[vim.bo.filetype] and vim.v.count == 0 and ('g' .. key) or key
  end, 'Move within wrapped prose: ' .. key, { expr = true })
end

local buffers = { n = 'bnext', p = 'bprevious', b = 'buffer #', f = 'bfirst', l = 'blast' }
for key, command in pairs(buffers) do
  map('n', '<Space>h' .. key, '<Cmd>' .. command .. '<CR>', 'Buffer: ' .. command)
end
map('n', '<Space>hm', function()
  local listed = vim.fn.getbufinfo({ buflisted = 1 })
  if #listed > 0 then
    vim.api.nvim_set_current_buf(listed[math.ceil(#listed / 2)].bufnr)
  end
end, 'Middle buffer')
local function close_buffer()
  local current = vim.api.nvim_get_current_buf()
  if vim.bo[current].buftype == 'terminal' then
    if #vim.api.nvim_tabpage_list_wins(0) > 1 then
      vim.api.nvim_win_close(0, true)
    end
    vim.api.nvim_buf_delete(current, { force = true })
    return
  end
  if vim.bo[current].modified then
    vim.notify('Save changes before closing this buffer.', vim.log.levels.WARN)
    return
  end
  if #vim.fn.getbufinfo({ buflisted = 1 }) > 1 then vim.cmd.bprevious() end
  vim.api.nvim_buf_delete(current, {})
end
map('n', '<Space>hd', close_buffer, 'Close buffer or terminal')
map('t', '<Space>hd', function()
  vim.cmd.stopinsert()
  close_buffer()
end, 'Close terminal')

for _, object in ipairs({ 'w', '"', "'", '(', '[', '{' }) do
  map('n', '<leader>r' .. object, '"_ci' .. object .. '<C-r>+<Esc>', 'Replace inside ' .. object .. ' with clipboard')
end
map('n', '<leader>s', ']s', 'Next spelling mistake')
map('n', '<leader>c', 'gcc', 'Toggle line comment', { remap = true })
map('x', '<leader>c', 'gc', 'Toggle selection comment', { remap = true })

local config = vim.g.dotfiles_config
for command, file in pairs({
  Vimrc = config .. '/init.lua',
  Plugins = config .. '/lua/plugins',
  Keybindings = config .. '/KEYBINDINGS.md',
  Zshrc = vim.fn.expand('~/.zshrc'),
  Tmuxconf = vim.fn.expand('~/.tmux.conf'),
}) do
  vim.api.nvim_create_user_command(command, function() vim.cmd.edit(file) end, {})
end
