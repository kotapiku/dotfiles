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

local function restore_completion_delay(state)
  if state.completion_delay then
    if vim.o.autocompletedelay == state.applied_delay then
      vim.o.autocompletedelay = state.completion_delay
    end
    state.completion_delay = nil
  end
end

local function apply_completion_delay(state)
  if state.enabled then
    state.completion_delay = state.completion_delay or vim.o.autocompletedelay
    state.applied_delay = math.max(state.completion_delay, 300)
    -- This option is global: restore it when leaving the large buffer.
    vim.o.autocompletedelay = state.applied_delay
  end
end

local function cancel_matchparen(state)
  state.sequence = (state.sequence or 0) + 1
  if state.timer then
    state.timer:stop()
  end
end

local function defer_native_matchparen(bufnr)
  vim.api.nvim_clear_autocmds({ group = 'vimtex_matchparen' .. bufnr,
    buffer = bufnr, event = matchparen_events })
end

local function schedule_matchparen(bufnr, state)
  if not state.enabled or not state.matchparen then
    return
  end
  cancel_matchparen(state)
  state.timer = state.timer or vim.uv.new_timer()
  local sequence = state.sequence
  local win = vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  state.timer:start(80, 0, vim.schedule_wrap(function()
    if buffers[bufnr] ~= state or not state.enabled or state.sequence ~= sequence
      or vim.api.nvim_get_current_buf() ~= bufnr or vim.api.nvim_get_current_win() ~= win
      or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick
      or not vim.deep_equal(vim.api.nvim_win_get_cursor(win), cursor) then
      return
    end
    -- The public enable() refreshes the pair using VimTeX's own matching.
    -- Keep its leave/clear handlers and defer the expensive movement handlers.
    local ok, err = pcall(vim.fn['vimtex#matchparen#enable'])
    defer_native_matchparen(bufnr)
    if not ok then
      error(err)
    end
  end))
end

local function dispose(state)
  restore_completion_delay(state)
  cancel_matchparen(state)
  if state.timer then
    state.timer:close()
  end
  vim.api.nvim_del_augroup_by_id(state.group)
end

function M.is_large(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= '' then
    return false
  end
  local lines = vim.api.nvim_buf_line_count(bufnr)
  -- The end offset gives the byte size without copying/scanning the buffer.
  local bytes = vim.api.nvim_buf_get_offset(bufnr, lines)
  return lines >= (vim.g.dotfiles_tex_large_file_lines or 5000)
    or bytes >= (vim.g.dotfiles_tex_large_file_bytes or 512 * 1024)
end

function M.apply_syntax()
  local state = buffers[vim.api.nvim_get_current_buf()]
  if state and state.enabled then
    -- Keep VimTeX syntax (and math snippets), but bound resync work on jumps.
    vim.cmd('syntax sync minlines=20 maxlines=100')
  end
end

local function set_enabled(bufnr, enabled)
  local state = buffers[bufnr]
  state.enabled = enabled
  vim.b[bufnr].dotfiles_tex_fast = enabled
  if enabled then
    apply_completion_delay(state)
  else
    restore_completion_delay(state)
    vim.b[bufnr].dotfiles_tex_label_cache = nil
  end
  local windows = vim.fn.win_findbuf(bufnr)
  for _, win in ipairs(windows) do
    vim.wo[win].spell = not enabled and state.spell
  end
  vim.bo[bufnr].synmaxcol = enabled and state.limited_synmaxcol or state.synmaxcol
  vim.b[bufnr].airline_whitespace_disabled = enabled and 1 or state.airline_whitespace_disabled
  if state.matchparen then
    if enabled then
      defer_native_matchparen(bufnr)
      schedule_matchparen(bufnr, state)
    else
      cancel_matchparen(state)
      vim.fn['vimtex#matchparen#enable']()
    end
  end
  if vim.b.current_syntax == 'tex' then
    if enabled then
      M.apply_syntax()
    else
      -- Restore VimTeX's normal synchronization settings.
      vim.fn['vimtex#syntax#core#init_options']()
    end
  end
end

function M.setup_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if buffers[bufnr] then
    return
  end
  local synmaxcol = vim.bo.synmaxcol
  local state = {
    spell = vim.wo.spell,
    synmaxcol = synmaxcol,
    limited_synmaxcol = synmaxcol > 0 and math.min(synmaxcol, 1000) or 1000,
    airline_whitespace_disabled = vim.b.airline_whitespace_disabled,
    matchparen = vim.fn.exists('#vimtex_matchparen' .. bufnr .. '#CursorMoved') == 1,
  }
  buffers[bufnr] = state
  state.group = vim.api.nvim_create_augroup('dotfiles_tex_performance' .. bufnr, { clear = true })
  local refresh_events = vim.list_extend(vim.deepcopy(matchparen_events), { 'InsertLeave' })
  vim.api.nvim_create_autocmd(refresh_events, {
    group = state.group,
    buffer = bufnr,
    callback = function() schedule_matchparen(bufnr, state) end,
  })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = state.group,
    buffer = bufnr,
    callback = function() apply_completion_delay(state) end,
  })
  vim.api.nvim_create_autocmd('WinLeave', {
    group = state.group,
    buffer = bufnr,
    callback = function() cancel_matchparen(state) end,
  })
  vim.api.nvim_create_autocmd('BufLeave', {
    group = state.group,
    buffer = bufnr,
    callback = function()
      restore_completion_delay(state)
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
  vim.api.nvim_buf_create_user_command(bufnr, 'TexPerformanceToggle', function()
    set_enabled(bufnr, not state.enabled)
    vim.notify('TeX: large-file mode ' .. (state.enabled and 'enabled' or 'disabled'))
  end, { desc = 'Toggle lighter TeX highlighting and automatic checks' })
  state.enabled = false
  vim.b.dotfiles_tex_fast = false
  if M.is_large(bufnr) then
    set_enabled(bufnr, true)
  end
end

function M.undo_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = buffers[bufnr]
  if not state then
    return
  end
  vim.bo[bufnr].synmaxcol = state.synmaxcol
  vim.b[bufnr].airline_whitespace_disabled = state.airline_whitespace_disabled
  vim.b[bufnr].dotfiles_tex_fast = nil
  vim.b[bufnr].dotfiles_tex_label_cache = nil
  vim.api.nvim_buf_del_user_command(bufnr, 'TexPerformanceToggle')
  dispose(state)
  buffers[bufnr] = nil
end

return M
