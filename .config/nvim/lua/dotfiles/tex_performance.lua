local M = {}
local buffers = {}
local matchparen_events = { 'CursorMoved', 'CursorMovedI', 'TextChangedP', 'WinEnter' }

function M.source_signature(root, sources)
  local signature = {}
  for _, source in ipairs(sources) do
    local stat = vim.uv.fs_stat(vim.fs.joinpath(root, source))
    signature[#signature + 1] = { source, stat and stat.size or -1,
      stat and stat.mtime.sec or -1, stat and stat.mtime.nsec or -1 }
  end
  return vim.json.encode(signature)
end

vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('dotfiles_tex_completion_cache', { clear = true }),
  pattern = '*.tex',
  callback = function()
    -- A saved subfile can change another buffer's project-wide candidates.
    for bufnr in pairs(buffers) do
      vim.b[bufnr].dotfiles_tex_label_cache = nil
    end
  end,
})

local function cancel_matchparen(state)
  state.sequence = (state.sequence or 0) + 1
  state.pending = nil
  if state.timer then
    state.timer:stop()
  end
end

local function defer_native_matchparen(bufnr)
  vim.api.nvim_clear_autocmds({ group = 'vimtex_matchparen' .. bufnr,
    buffer = bufnr, event = matchparen_events })
end

local function schedule_matchparen(bufnr, state)
  if not state.matchparen or vim.api.nvim_get_current_buf() ~= bufnr then
    return
  end
  local group = '#vimtex_matchparen' .. bufnr .. '#'
  -- Respect VimTeX's public disable()/enable() even with an update pending.
  if vim.fn.exists(group .. 'BufLeave') == 0 then
    state.last = nil
    cancel_matchparen(state)
    return
  end
  if vim.fn.exists(group .. 'CursorMoved') == 1 then
    state.last = nil
    defer_native_matchparen(bufnr)
  end
  local key = {
    win = vim.api.nvim_get_current_win(),
    cursor = vim.api.nvim_win_get_cursor(0),
    tick = vim.api.nvim_buf_get_changedtick(bufnr),
    mode = vim.fn.mode(),
    syntax = state.syntax_generation,
  }
  -- Multiple events often describe the same cursor position and buffer text.
  if vim.deep_equal(state.pending, key) then
    return
  end
  if vim.deep_equal(state.last, key) then
    cancel_matchparen(state)
    return
  end
  cancel_matchparen(state)
  state.pending = key
  state.timer = state.timer or vim.uv.new_timer()
  local sequence = state.sequence
  state.timer:start(30, 0, vim.schedule_wrap(function()
    if buffers[bufnr] ~= state or state.sequence ~= sequence then
      return
    end
    state.pending = nil
    if vim.api.nvim_get_current_buf() ~= bufnr or vim.api.nvim_get_current_win() ~= key.win
      or vim.fn.exists(group .. 'BufLeave') == 0
      or vim.api.nvim_buf_get_changedtick(bufnr) ~= key.tick or vim.fn.mode() ~= key.mode
      or not vim.deep_equal(vim.api.nvim_win_get_cursor(key.win), key.cursor) then
      return
    end
    -- The public enable() refreshes the pair using VimTeX's own matching.
    -- Keep its leave/clear handlers and defer the expensive movement handlers.
    local ok, err = pcall(vim.fn['vimtex#matchparen#enable'])
    defer_native_matchparen(bufnr)
    if not ok then
      error(err)
    end
    state.last = key
  end))
end

local function dispose(state)
  cancel_matchparen(state)
  if state.timer then
    state.timer:close()
  end
  vim.api.nvim_del_augroup_by_id(state.group)
end

function M.invalidate_syntax()
  local state = buffers[vim.api.nvim_get_current_buf()]
  if state then
    state.syntax_generation = state.syntax_generation + 1
    state.last = nil
    schedule_matchparen(vim.api.nvim_get_current_buf(), state)
  end
end

function M.setup_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if buffers[bufnr] then
    return
  end
  local state = {
    matchparen = vim.fn.exists('#vimtex_matchparen' .. bufnr .. '#CursorMoved') == 1,
    syntax_generation = 0,
  }
  buffers[bufnr] = state
  state.group = vim.api.nvim_create_augroup('dotfiles_tex_performance' .. bufnr, { clear = true })
  local refresh_events = vim.list_extend(vim.deepcopy(matchparen_events),
    { 'BufEnter', 'InsertEnter', 'InsertLeave', 'TextChanged', 'TextChangedI' })
  vim.api.nvim_create_autocmd(refresh_events, {
    group = state.group,
    buffer = bufnr,
    callback = function() schedule_matchparen(bufnr, state) end,
  })
  vim.api.nvim_create_autocmd('Syntax', {
    group = state.group,
    buffer = bufnr,
    callback = M.invalidate_syntax,
  })
  vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
    group = state.group,
    buffer = bufnr,
    callback = function()
      state.last = nil
      cancel_matchparen(state)
    end,
  })
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = state.group,
    buffer = bufnr,
    once = true,
    callback = function()
      dispose(state)
      buffers[bufnr] = nil
    end,
  })
  if state.matchparen then
    defer_native_matchparen(bufnr)
    schedule_matchparen(bufnr, state)
  end
end

function M.undo_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = buffers[bufnr]
  if not state then
    return
  end
  vim.b[bufnr].dotfiles_tex_label_cache = nil
  dispose(state)
  buffers[bufnr] = nil
end

return M
