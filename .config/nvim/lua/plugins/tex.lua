return {
  {
    'lervag/vimtex', version = 'v2.18', lazy = false,
    -- VimtexInverseSearch must exist even before opening a TeX buffer.
    init = function()
      vim.g.tex_flavor = 'latex'
      -- Completion ignores case independently of / and ? searches.
      vim.g.vimtex_complete_ignore_case = 1
      vim.g.vimtex_complete_smart_case = 0
      vim.g.vimtex_quickfix_open_on_warning = 0
      vim.g.vimtex_view_method = 'skim_tabs'
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_activate = 1
      vim.g.vimtex_fold_enabled = 1
      vim.g.vimtex_fold_manual = 1
    end,
    config = function(plugin)
      -- Load VimTeX's implementation before wrapping its current-buffer lookup.
      vim.cmd.source(plugin.dir .. '/autoload/vimtex/view.vim')
      vim.cmd.source(vim.g.dotfiles_config .. '/autoload/vimtex/view.vim')

      vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('dotfiles_tex_focus', { clear = true }),
        pattern = 'VimtexEventViewReverse',
        desc = 'Bring Warp forward after a successful inverse search',
        callback = function()
          if vim.fn.has('macunix') == 1 and vim.env.TERM_PROGRAM == 'WarpTerminal' then
            vim.system({ '/usr/bin/open', '-a', 'Warp' }, { detach = true })
          end
        end,
      })
    end,
  },
  { 'L3MON4D3/LuaSnip', version = 'v2.4.1', ft = 'tex' },
}
