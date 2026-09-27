return {
  {
    'lervag/vimtex', version = 'v2.18', lazy = false,
    -- VimtexInverseSearch must exist even before opening a TeX buffer.
    init = function()
      vim.g.tex_flavor = 'latex'
      vim.g.vimtex_quickfix_open_on_warning = 0
      vim.g.vimtex_view_method = 'skim_tabs'
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_activate = 1
      vim.g.vimtex_fold_enabled = 1
      vim.g.vimtex_fold_manual = 1
    end,
  },
  { 'L3MON4D3/LuaSnip', version = 'v2.4.1', ft = 'tex' },
}
