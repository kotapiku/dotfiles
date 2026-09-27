local function picker(name, options)
  return function() require('fzf-lua')[name](options) end
end

return {
  {
    'ibhagwan/fzf-lua', cmd = 'FzfLua',
    opts = {
      winopts = { height = 0.85, width = 0.9, border = 'rounded' },
      files = { file_icons = false, git_icons = false },
      buffers = { file_icons = false },
    },
    keys = {
      { ',f', picker('files'), desc = 'Find files' },
      { ',g', picker('git_files'), desc = 'Git files' },
      { ',F', picker('git_status'), desc = 'Git status' },
      { ',b', picker('buffers'), desc = 'Find buffers' },
      { ',l', picker('blines'), desc = 'Lines in buffer' },
      { ',L', picker('lines'), desc = 'Lines in all buffers' },
      { ',h', picker('oldfiles'), desc = 'Recent files' },
      { ',m', picker('marks'), desc = 'Marks' },
      { ',r', picker('live_grep'), desc = 'Search project text' },
      { ',d', picker('diagnostics_document'), desc = 'Buffer diagnostics' },
      { ',D', picker('diagnostics_workspace'), desc = 'Workspace diagnostics' },
      { ',s', picker('lsp_document_symbols'), desc = 'Document symbols' },
      { ',R', picker('lsp_references'), desc = 'LSP references' },
      { '<C-]>', function()
        require('fzf-lua').tags({ query = vim.fn.expand('<cword>') })
      end, desc = 'Find tags for word' },
    },
  },
}
