local function map(mode, lhs, rhs, desc, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend('force', { desc = desc }, opts or {}))
end

map('i', 'jk', '<Esc>', 'Leave insert mode')
-- CTRL-X completion modes consume Ctrl+n/p before insert mappings run.
-- Handle those keys before completion processes them, including omnifunc.
vim.on_key(function(key)
  local step = key == '\14' and 1 or key == '\16' and -1 or nil
  if step and vim.fn.mode():sub(1, 1) == 'i' and vim.fn.pumvisible() == 1 then
    vim.api.nvim_feedkeys(vim.keycode(step == 1 and '<Down>' or '<Up>'), 'ni', false)
    return ''
  end
end, vim.api.nvim_create_namespace('dotfiles_completion_navigation'))
map('i', '<CR>', function()
  if vim.fn.pumvisible() == 1 then
    return vim.fn.complete_info({ 'selected' }).selected == -1 and '<C-n><C-y>' or '<C-y>'
  end
  return '<CR>'
end, 'Confirm completion or insert newline', { expr = true })
map('t', 'jk', '<C-\\><C-n>', 'Leave terminal input')
for key, direction in pairs({ j = 'down', k = 'up' }) do
  map('t', '<C-w>' .. key, '<C-\\><C-n><C-w>' .. key, 'Move to window ' .. direction)
end
-- Expand an interactively typed :terminal without affecting plugin terminals.
local terminal_buffer
vim.api.nvim_create_user_command('Terminal', function(opts)
  if opts.args == '' and terminal_buffer and vim.api.nvim_buf_is_valid(terminal_buffer) then
    local windows = vim.fn.win_findbuf(terminal_buffer)
    if #windows > 0 then
      vim.api.nvim_set_current_win(windows[1])
    else
      vim.cmd('botright split')
      vim.api.nvim_set_current_buf(terminal_buffer)
    end
  else
    vim.cmd('botright split')
    vim.cmd('terminal ' .. opts.args)
    terminal_buffer = vim.api.nvim_get_current_buf()
    vim.bo[terminal_buffer].bufhidden = 'hide'
  end
  vim.cmd.startinsert()
end, { nargs = '*', complete = 'shellcmd', desc = 'Open or resume the bottom terminal' })
map('n', ',t', '<Cmd>Terminal<CR>', 'Open or resume terminal')
map('ca', 'terminal', function()
  if vim.fn.getcmdtype() == ':' and vim.fn.getcmdline() == 'terminal' then
    return 'Terminal'
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
local function hide_terminal()
  local current = vim.api.nvim_get_current_buf()
  if vim.bo[current].buftype == 'terminal' then
    vim.bo[current].bufhidden = 'hide'
    if #vim.api.nvim_tabpage_list_wins(0) > 1 then
      vim.api.nvim_win_close(0, false)
    else
      -- Keep Neovim open even when the terminal is the last window.
      local replacement
      for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        if buf.bufnr ~= current and vim.bo[buf.bufnr].buftype ~= 'terminal' then
          replacement = buf.bufnr
          break
        end
      end
      vim.api.nvim_set_current_buf(replacement or vim.api.nvim_create_buf(true, false))
    end
  end
end
map('n', '<Space>hh', hide_terminal, 'Hide terminal')
map('t', '<Space>hh', function()
  vim.cmd.stopinsert()
  hide_terminal()
end, 'Hide terminal')

local function close_buffer()
  local current = vim.api.nvim_get_current_buf()
  if vim.bo[current].buftype == 'terminal' then
    hide_terminal()
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
end, 'Delete terminal')

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
}) do
  vim.api.nvim_create_user_command(command, function() vim.cmd.edit(file) end, {})
end
