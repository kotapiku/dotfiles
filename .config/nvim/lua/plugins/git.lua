return {
  {
    'lewis6991/gitsigns.nvim', event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      current_line_blame = false,
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        for lhs, direction in pairs({ [']c'] = 'next', ['[c'] = 'prev' }) do
          map('n', lhs, function()
            if vim.wo.diff then vim.cmd.normal({ lhs, bang = true })
            else gs.nav_hunk(direction) end
          end, direction .. ' Git change')
        end
        map('n', '<leader>hp', gs.preview_hunk, 'Preview Git change')
        map('n', '<leader>hs', gs.stage_hunk, 'Stage Git change')
        map('x', '<leader>hs', function()
          gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end, 'Stage selected changes')
        map('n', '<leader>hu', gs.reset_hunk, 'Discard Git change')
        map('n', '<leader>hb', gs.blame_line, 'Git blame for line')
      end,
    },
  },
}
