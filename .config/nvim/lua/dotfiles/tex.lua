local M = {}
local buffers = {}
local warned = {}

local function warn_once(key, message)
  if not warned[key] then
    warned[key] = true
    vim.schedule(function()
      vim.notify(message, vim.log.levels.WARN)
    end)
  end
end

local function texlab_command()
  for _, path in ipairs({ vim.fn.exepath('texlab'), '/opt/homebrew/bin/texlab', '/usr/local/bin/texlab' }) do
    if path ~= '' and vim.fn.executable(path) == 1 then
      return path
    end
  end
end

local function project_root(bufnr)
  local vimtex = vim.b[bufnr].vimtex
  if vimtex and vimtex.root and vimtex.root ~= '' then
    return vim.fs.normalize(vimtex.root)
  end
  local file = vim.api.nvim_buf_get_name(bufnr)
  return vim.fs.root(file, { '.latexmkrc', 'latexmkrc', '.git' }) or vim.fs.dirname(file)
end

function M.setup_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.g.vscode or buffers[bufnr] then
    return
  end
  local ft = vim.bo[bufnr].filetype
  if ft ~= 'tex' and ft ~= 'bib' then
    return
  end
  buffers[bufnr] = {
    tagfunc = vim.bo[bufnr].tagfunc,
    omnifunc = vim.bo[bufnr].omnifunc,
    formatexpr = vim.bo[bufnr].formatexpr,
    snippets = ft == 'tex',
  }
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = bufnr,
    once = true,
    callback = function() buffers[bufnr] = nil end,
  })
  if ft == 'tex' then
    local ok, err = pcall(require('dotfiles.tex_snippets').setup_buffer, bufnr)
    if not ok then
      warn_once('snippets', 'LuaSnip could not be loaded. Run :call dein#install().\n' .. tostring(err))
    end
  end

  local command = texlab_command()
  if not command then
    warn_once('texlab', 'TexLab is not installed. Run: brew install texlab')
    return
  end
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == '' or vim.bo[bufnr].buftype ~= '' then
    return
  end

  vim.lsp.start({
    name = 'texlab',
    cmd = { command },
    root_dir = project_root(bufnr),
    settings = {
      texlab = {
        build = { onSave = false, forwardSearchAfter = false },
        chktex = { onOpenAndSave = false, onEdit = false },
        diagnosticsDelay = 500,
      },
    },
    flags = { debounce_text_changes = 250 },
    on_init = function(client)
      -- Keep gq and formatting under the existing TeX settings.
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
    on_attach = function(client, attached_bufnr)
      local state = buffers[attached_bufnr]
      if not state then
        vim.lsp.buf_detach_client(attached_bufnr, client.id)
        return
      end
      -- Native tagfunc keeps gd / Ctrl+t working and falls back to tags.
      vim.bo[attached_bufnr].tagfunc = 'v:lua.vim.lsp.tagfunc'
      if vim.bo[attached_bufnr].filetype == 'tex' then
        vim.bo[attached_bufnr].omnifunc = state.omnifunc
      end
      vim.diagnostic.config({
        virtual_text = false,
        underline = true,
        signs = true,
        update_in_insert = false,
        severity_sort = true,
      }, vim.lsp.diagnostic.get_namespace(client.id))
    end,
  }, { bufnr = bufnr })
end

function M.undo_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = buffers[bufnr]
  if not state then
    return
  end
  buffers[bufnr] = nil
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = 'texlab' })) do
    vim.lsp.buf_detach_client(bufnr, client.id)
  end
  local lsp_defaults = {
    tagfunc = 'v:lua.vim.lsp.tagfunc',
    omnifunc = 'v:lua.vim.lsp.omnifunc',
    formatexpr = 'v:lua.vim.lsp.formatexpr()',
  }
  for option, value in pairs(lsp_defaults) do
    if vim.bo[bufnr][option] == value then
      vim.bo[bufnr][option] = state[option]
    end
  end
  if state.snippets then
    for _, mode in ipairs({ 'i', 's' }) do
      for _, lhs in ipairs({ '<Tab>', '<S-Tab>' }) do
        pcall(vim.keymap.del, mode, lhs, { buffer = bufnr })
      end
    end
  end
end

return M
