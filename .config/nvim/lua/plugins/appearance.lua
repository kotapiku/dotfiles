return {
  {
    'nordtheme/vim', name = 'nord', lazy = false, priority = 1000,
    config = function() vim.cmd.colorscheme('nord') end,
  },
  {
    'vim-airline/vim-airline', lazy = false, priority = 900,
    dependencies = { 'vim-airline/vim-airline-themes' },
    init = function()
      local g = vim.g
      g.airline_theme = 'nord'
      g.airline_powerline_fonts = 0
      g.airline_left_sep = ''
      g.airline_right_sep = ''
      g.airline_left_alt_sep = '│'
      g.airline_right_alt_sep = '│'
      g.airline_skip_empty_sections = 1
      g.airline_stl_path_style = 'short'
      g.airline_section_z = '%l:%c  %p%%'
      g['airline#parts#ffenc#skip_expected_string'] = 'utf-8[unix]'
      g.airline_symbols = { modified = ' ●' }
      local prefix = 'airline#extensions#tabline#'
      for key, value in pairs({ enabled = 1, formatter = 'unique_tail',
        buffer_min_count = 0, tab_min_count = 0, show_tab_count = 0,
        show_tab_type = 0, show_splits = 0, tab_nr_type = 1, show_close_button = 0,
        left_sep = ' ', left_alt_sep = ' ', right_sep = ' ', right_alt_sep = ' ',
      }) do g[prefix .. key] = value end
      vim.opt.laststatus = 2
      vim.opt.showmode = false
    end,
  },
  {
    'folke/which-key.nvim', event = 'VeryLazy',
    opts = {
      delay = 400,
      icons = { mappings = false },
      spec = {
        { '<leader>l', group = 'LaTeX' },
        { '<leader>h', group = 'Git changes' },
        { '<leader>r', group = 'Replace with clipboard' },
        { '<Space>h', group = 'Buffers' },
        { ',', group = 'Search' },
      },
    },
    keys = {
      { '<leader>?', function() require('which-key').show({ global = false }) end, desc = 'Buffer keymaps' },
    },
  },
}
