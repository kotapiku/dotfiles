"""TeX buffer integration checks using already installed Neovim plugins."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


CONFIG = Path(__file__).resolve().parents[1]
PLUGIN_DATA = os.environ.get("DOTFILES_NVIM_TEST_DATA")


@unittest.skipUnless(PLUGIN_DATA and shutil.which("nvim"),
                     "Set DOTFILES_NVIM_TEST_DATA to the installed XDG data directory")
class TexPerformanceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="nvim-tex-performance-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name).resolve()
        self.config = self.root / "config/nvim"
        shutil.copytree(CONFIG, self.config, ignore=shutil.ignore_patterns("tests", "__pycache__"))
        self.env = dict(os.environ, XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_DATA_HOME=PLUGIN_DATA, XDG_STATE_HOME=str(self.root / "state"),
                        XDG_CACHE_HOME=str(self.root / "cache"))
        # Existing tags avoid starting an unrelated ctags job in these checks.
        (self.root / "tags").write_text("")

    def project(self, name, body):
        file = self.root / name
        file.write_text("\\documentclass{article}\n\\begin{document}\n"
                        "\\section{Test}\\label{sec:test}\n" + body + "\\end{document}\n")
        return file

    def nvim(self, file, script):
        check = self.root / "check.lua"
        check.write_text("local ok, err = xpcall(function()\n"
                         "assert(vim.v.errmsg == '', vim.v.errmsg)\n" + script
                         + "\nend, debug.traceback)\n"
                         "if not ok then print(err); vim.cmd('cquit') end\nvim.cmd('qa!')\n")
        result = subprocess.run(
            [shutil.which("nvim"), "--headless", "-n", "-i", "NONE",
             "-u", str(self.config / "init.lua"), str(file),
             "-c", "lua dofile(" + json.dumps(str(check)) + ")"],
            env=self.env, cwd=self.root, capture_output=True, text=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("Error detected", result.stderr)

    def test_startup_thresholds_and_syntax_reload(self):
        for name, body, fast in (
            ("small.tex", "Text.\n" * 4995, False),  # 4,999 total lines
            ("many-lines.tex", "Text.\n" * 4996, True),  # 5,000 total lines
            ("many-bytes.tex", ("word " * 210 + "\n") * 500, True),
        ):
            with self.subTest(file=name):
                file = self.project(name, body)
                self.nvim(file, "local fast = " + str(fast).lower() + "\n" + r"""
assert(vim.b.dotfiles_tex_fast == fast)
assert(vim.bo.autocomplete)
assert(vim.o.autocompletedelay == (fast and 300 or 120))
assert(vim.wo.spell == not fast)
assert(vim.bo.synmaxcol == (fast and 1000 or 3000))
local group = '#vimtex_matchparen' .. vim.api.nvim_get_current_buf() .. '#CursorMoved'
assert(vim.fn.exists(group) == (fast and 0 or 1))
assert(vim.wo.foldmethod == 'manual' and vim.fn.foldlevel(4) == 0)
assert(vim.bo.omnifunc == 'dotfiles#tex_complete#omnifunc')
assert(vim.fn.exists(':VimtexCompile') == 2)
assert(vim.fn.exists(':VimtexView') == 2)
-- A syntax reload must keep the selected performance mode.
vim.cmd('setlocal syntax=tex')
local sync = vim.api.nvim_exec2('syntax sync', { output = true }).output
assert(sync:find((fast and '20' or '50') .. ' lines', 1, true), sync)
assert(vim.v.errmsg == '', vim.v.errmsg)
""")

    def test_large_buffer_keeps_snippets_lsp_and_completion(self):
        file = self.project("large.tex", "Text.\n" * 6000)
        self.nvim(file, r"""
assert(vim.b.dotfiles_tex_fast and vim.bo.autocomplete)
assert(vim.wait(10000, function()
  local client = vim.lsp.get_clients({ bufnr = 0, name = 'texlab' })[1]
  return client and client.initialized
end, 50), 'TexLab did not initialize')
assert(vim.bo.tagfunc == 'v:lua.vim.lsp.tagfunc')
vim.api.nvim_buf_set_lines(0, 3, 4, false, { '$$' })
vim.api.nvim_win_set_cursor(0, { 4, 1 })
vim.api.nvim_feedkeys(vim.keycode('iff<Tab><Esc>'), 'xt', false)
assert(vim.api.nvim_get_current_line():find([[\frac{]], 1, true), 'math snippet failed')
vim.api.nvim_buf_set_lines(0, 4, 5, false, { [[\ref{sec:]] })
vim.api.nvim_win_set_cursor(0, { 5, 8 })
vim.fn['dotfiles#tex_complete#omnifunc'](1, '')
local matches = vim.fn['dotfiles#tex_complete#omnifunc'](0, 'SEC:')
assert(vim.inspect(matches):find('sec:test', 1, true), 'manual label completion failed')
assert(vim.bo.autocomplete, 'automatic completion was disabled')
""")

    def test_automatic_completion_popup_in_large_buffer(self):
        file = self.project("large.tex", "Text.\n" * 6000)
        self.nvim(file, r"""
vim.api.nvim_buf_set_lines(0, 3, 4, false, { '' })
vim.api.nvim_win_set_cursor(0, { 4, 0 })
local completion = {}
vim.defer_fn(function() completion.typed = vim.api.nvim_get_current_line() end, 50)
-- Keep insert mode running while Neovim's native autocomplete timer fires.
vim.defer_fn(function()
  completion.visible = vim.fn.pumvisible() == 1
  completion.items = vim.fn.complete_info({ 'items' }).items
  completion.line = vim.api.nvim_get_current_line()
  vim.api.nvim_feedkeys(vim.keycode('<C-e><Esc>'), 'nt', false)
end, 1500)
vim.api.nvim_feedkeys(vim.keycode([[i\ref{SEC:]]), 'xt!', false)
assert(completion.visible, 'automatic completion popup did not appear')
assert(vim.inspect(completion.items):find('sec:test', 1, true), 'label candidate was missing')
assert(completion.line == completion.typed,
  'completion inserted a candidate without selection: ' .. vim.inspect(completion))
""")

    def test_toggle_buffer_isolation_and_filetype_cleanup(self):
        large = self.project("large.tex", "Text.\n" * 6000)
        small = self.project("small.tex", "Text.\n" * 10)
        self.nvim(large, "local small = " + json.dumps(str(small)) + "\n" + r"""
local large_buf = vim.api.nvim_get_current_buf()
local group = '#vimtex_matchparen' .. large_buf .. '#CursorMoved'
vim.cmd('TexPerformanceToggle')
assert(not vim.b.dotfiles_tex_fast and vim.bo.autocomplete and vim.wo.spell)
assert(vim.bo.synmaxcol == 3000 and vim.b.airline_whitespace_disabled == nil)
assert(vim.o.autocompletedelay == 120)
assert(vim.fn.exists(group) == 1)
local sync = vim.api.nvim_exec2('syntax sync', { output = true }).output
assert(sync:find('50 lines', 1, true), sync)
local first_win = vim.api.nvim_get_current_win()
vim.cmd.vsplit()
local second_win = vim.api.nvim_get_current_win()
for _, win in ipairs({ first_win, second_win }) do
  vim.api.nvim_win_call(win, function()
    vim.api.nvim_win_set_cursor(0, { 3, 8 })
    vim.api.nvim_exec_autocmds('CursorMoved', { buffer = large_buf })
    assert(vim.w.vimtex_match_id1, 'test did not highlight a bracket pair')
  end)
end
vim.cmd('TexPerformanceToggle')
assert(vim.b.dotfiles_tex_fast and vim.bo.autocomplete and not vim.wo.spell)
assert(vim.o.autocompletedelay == 300)
for _, win in ipairs({ first_win, second_win }) do
  assert(not vim.wo[win].spell, 'spell check remained enabled in another split')
  assert(vim.w[win].vimtex_match_id1, 'bracket pair disappeared in another split')
end
vim.cmd('TexPerformanceToggle')
assert(vim.wo[first_win].spell and vim.wo[second_win].spell)
vim.cmd('TexPerformanceToggle')
vim.cmd.edit(small)
local small_buf = vim.api.nvim_get_current_buf()
assert(not vim.b.dotfiles_tex_fast and vim.bo.autocomplete and vim.wo.spell)
assert(vim.o.autocompletedelay == 120, 'large-buffer completion delay leaked')
assert(vim.bo.synmaxcol == 3000, 'large-buffer limit leaked into small buffer')
vim.cmd.buffer(large_buf)
assert(vim.b.dotfiles_tex_fast and vim.bo.autocomplete and not vim.wo.spell)
assert(vim.o.autocompletedelay == 300)
vim.bo.filetype = 'text'
assert(vim.b.dotfiles_tex_fast == nil)
assert(vim.b.airline_whitespace_disabled == nil)
assert(vim.bo.synmaxcol == 3000)
assert(vim.fn.exists(':TexPerformanceToggle') == 0)
assert(vim.o.autocompletedelay == 120)
assert(vim.fn.exists(group) == 0, 'TeX matchparen callback leaked into text')
vim.cmd.buffer(small_buf)
assert(vim.bo.autocomplete and vim.wo.spell and not vim.b.dotfiles_tex_fast)
assert(vim.v.errmsg == '', vim.v.errmsg)
""")

    def test_bracket_updates_are_deferred_and_cancelled_on_leave(self):
        large = self.project("large.tex", "Text.\n" * 6000)
        small = self.project("small.tex", "Text.\n" * 10)
        self.nvim(large, "local small = " + json.dumps(str(small)) + "\n" + r"""
local large_buf = vim.api.nvim_get_current_buf()
vim.api.nvim_win_set_cursor(0, { 3, 8 })
vim.api.nvim_exec_autocmds('CursorMoved', { buffer = large_buf })
assert(vim.w.vimtex_match_id1 == nil, 'matching ran synchronously on movement')
assert(vim.wait(1000, function() return vim.w.vimtex_match_id1 ~= nil end, 10),
  'bracket pair did not appear after the cursor stopped')
-- Repeated moves should leave only the latest position pending.
for col = 1, 7 do
  vim.api.nvim_win_set_cursor(0, { 3, col })
  vim.api.nvim_exec_autocmds('CursorMoved', { buffer = large_buf })
end
assert(vim.wait(1000, function() return vim.w.vimtex_match_id1 == nil end, 10),
  'stale bracket pair remained at the new position')
vim.api.nvim_win_set_cursor(0, { 3, 8 })
vim.api.nvim_exec_autocmds('CursorMovedI', { buffer = large_buf })
assert(vim.wait(1000, function() return vim.w.vimtex_match_id1 ~= nil end, 10),
  'insert-mode movement did not update bracket matching')
vim.api.nvim_exec_autocmds('CursorMoved', { buffer = large_buf })
vim.cmd.edit(small)
vim.wait(150)
assert(vim.w.vimtex_match_id1 == nil, 'pending matching leaked into another buffer')
-- Wiping an inactive large buffer must close its timer and keep the small delay.
vim.api.nvim_buf_delete(large_buf, { force = true })
assert(vim.o.autocompletedelay == 120)
assert(vim.v.errmsg == '', vim.v.errmsg)
""")

    def test_label_cache_reuse_and_saved_source_changes(self):
        main = self.project("main.tex", "\\input{child}\n" + "Text.\n" * 6000)
        child = self.root / "child.tex"
        child.write_text("\\label{sec:child}\n")
        self.nvim(main, r"""
local function labels()
  return vim.inspect(vim.fn['vimtex#parser#auxiliary#labels_manual']())
end
local first = labels()
assert(first:find('sec:child', 1, true) and first:find('sec:test', 1, true))
local cache = vim.b.dotfiles_tex_label_cache
assert(cache and labels() == first, 'label candidates were not reused')
assert(vim.deep_equal(cache, vim.b.dotfiles_tex_label_cache))
-- Returned candidates may be modified by close-brace completion.
local candidates = vim.fn['vimtex#parser#auxiliary#labels_manual']()
candidates[1].word = 'mutated'
assert(not labels():find('mutated', 1, true), 'completion mutated the cached labels')
-- Same-size external changes must be detected, including within one second.
vim.fn.writefile({ [[\label{sec:other}]] }, 'child.tex')
local changed = labels()
assert(changed:find('sec:other', 1, true), 'external edit did not invalidate labels')
assert(not changed:find('sec:child', 1, true), 'external edit kept the old label')
vim.api.nvim_buf_set_lines(0, 2, 3, false, { [[\section{Test}\label{sec:next}]] })
vim.cmd.write()
assert(vim.b.dotfiles_tex_label_cache == nil, 'saving did not invalidate candidates')
assert(labels():find('sec:next', 1, true), 'saved edit did not update labels')
-- Refresh sources after a new include, and monitor the new file too.
vim.fn.writefile({ [[\label{sec:new}]] }, 'another.tex')
vim.api.nvim_buf_set_lines(0, 4, 5, false, { [[\input{another}]] })
vim.cmd.write()
assert(labels():find('sec:new', 1, true), 'newly included labels were missing')
vim.fn.writefile({ [[\label{sec:end}]] }, 'another.tex')
assert(labels():find('sec:end', 1, true), 'newly included source was not monitored')
assert(vim.v.errmsg == '', vim.v.errmsg)
""")


if __name__ == "__main__":
    unittest.main()
