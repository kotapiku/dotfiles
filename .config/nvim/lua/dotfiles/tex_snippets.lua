local M = {}
local loaded = false

function M.setup()
  local ls = require('luasnip')
  if loaded then
    return ls
  end
  loaded = true
  ls.config.setup({
    enable_autosnippets = false,
    update_events = 'TextChanged,TextChangedI',
    delete_check_events = 'TextChanged',
  })

  local s, t, i = ls.snippet, ls.text_node, ls.insert_node
  local fmt = require('luasnip.extras.fmt').fmta
  local rep = require('luasnip.extras').rep
  local function in_math()
    return vim.fn['vimtex#syntax#in_mathzone']() == 1
  end
  local function in_text()
    return not in_math() and vim.fn['vimtex#syntax#in_comment']() == 0
  end

  ls.add_snippets('tex', {
    s({ trig = 'ff', dscr = 'Fraction' },
      fmt([[\frac{<>}{<>}<>]], { i(1), i(2), i(0) }), { condition = in_math }),
    s({ trig = 'sq', dscr = 'Square root' },
      fmt([[\sqrt{<>}<>]], { i(1), i(0) }), { condition = in_math }),
    s({ trig = 'sum', dscr = 'Sum with limits' },
      fmt([[\sum_{<>}^{<>} <>]], { i(1, 'i=1'), i(2, 'n'), i(0) }), { condition = in_math }),
    s({ trig = 'int', dscr = 'Integral with limits' },
      fmt([[\int_{<>}^{<>} <> \, d<>]], { i(1, 'a'), i(2, 'b'), i(3), i(4, 'x') }),
      { condition = in_math }),
    s({ trig = 'mk', dscr = 'Inline math' },
      fmt([[$<>$<>]], { i(1), i(0) }), { condition = in_text }),
    s({ trig = 'dm', dscr = 'Display math' },
      fmt('\\[\n  <>\n\\]\n<>', { i(1), i(0) }), { condition = in_text }),
    s({ trig = 'ali', dscr = 'Unnumbered aligned equations' },
      fmt('\\begin{align*}\n  <>\n\\end{align*}\n<>', { i(1), i(0) }),
      { condition = in_text }),
    s({ trig = 'eq', dscr = 'Equation with a label' },
      fmt('\\begin{equation}\n  \\label{<>}\n  <>\n\\end{equation}\n<>',
        { i(1, 'eq:name'), i(2), i(0) }), { condition = in_text }),
    s({ trig = 'env', dscr = 'Environment (matching names)' },
      fmt('\\begin{<>}\n  <>\n\\end{<>}\n<>', { i(1, 'environment'), i(2), rep(1), i(0) }),
      { condition = in_text }),
    s({ trig = 'itm', dscr = 'Itemize' }, {
      t({ '\\begin{itemize}', '  \\item ' }), i(1), t({ '', '\\end{itemize}', '' }), i(0),
    }, { condition = in_text }),
  }, { key = 'dotfiles-tex' })
  return ls
end

function M.setup_buffer(bufnr)
  local ls = M.setup()
  local function feed(keys)
    vim.api.nvim_feedkeys(vim.keycode(keys), 'ni', false)
  end
  -- Run after preceding typed characters are inserted. An expr mapping can
  -- inspect an incomplete trigger when characters and Tab arrive together.
  vim.keymap.set({ 'i', 's' }, '<Tab>', function()
    if vim.fn.pumvisible() == 1 then
      feed('<C-n>')
    elseif ls.expandable() then
      ls.expand()
    elseif ls.locally_jumpable(1) then
      ls.jump(1)
    else
      feed('<Tab>')
    end
  end, { buffer = bufnr, silent = true, desc = 'LaTeX snippet: expand / next field' })
  vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
    if vim.fn.pumvisible() == 1 then
      feed('<C-p>')
    elseif ls.locally_jumpable(-1) then
      ls.jump(-1)
    else
      feed('<S-Tab>')
    end
  end, { buffer = bufnr, silent = true, desc = 'LaTeX snippet: previous field' })
end

return M
