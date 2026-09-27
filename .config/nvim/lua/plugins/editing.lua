return {
  { 'machakann/vim-sandwich' },
  { 'itmammoth/doorboy.vim', event = 'InsertEnter' },
  {
    'embear/vim-localvimrc',
    init = function() vim.g.localvimrc_ask = 0 end,
  },
  {
    'previm/previm', ft = 'markdown', cmd = 'PrevimOpen',
    init = function() vim.g.previm_open_cmd = 'open' end,
  },
}
