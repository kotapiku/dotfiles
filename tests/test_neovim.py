"""Integration checks against installed plugins, without downloading or opening a GUI.

Run with DOTFILES_NVIM_TEST_DATA pointing to the XDG data directory containing
nvim/lazy, e.g. DOTFILES_NVIM_TEST_DATA="$HOME/.local/share" python3 -m unittest
discover -s tests -p test_neovim.py -v.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]
PLUGIN_DATA = os.environ.get("DOTFILES_NVIM_TEST_DATA")


@unittest.skipUnless(PLUGIN_DATA and shutil.which("nvim"), "Set DOTFILES_NVIM_TEST_DATA to installed plugins")
class NeovimTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="nvim-integration-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.config = self.root / "config/nvim"
        shutil.copytree(REPOSITORY / ".config/nvim", self.config)
        self.env = dict(os.environ, XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_DATA_HOME=PLUGIN_DATA, XDG_STATE_HOME=str(self.root / "state"),
                        XDG_CACHE_HOME=str(self.root / "cache"))

    def nvim(self, script, timeout=30, files=(), default_config=False):
        check = self.root / "check.lua"
        capture = ("lua _G.dotfiles_test_notifications = {}; "
                   "vim.notify = function(msg, level) "
                   "if (level or vim.log.levels.INFO) >= vim.log.levels.WARN then "
                   "table.insert(_G.dotfiles_test_notifications, msg) end end")
        check.write_text("local notifications = _G.dotfiles_test_notifications\n"
                         + "local ok, err = xpcall(function()\n"
                         + "assert(vim.v.errmsg == '', vim.v.errmsg)\n" + script
                         + "\nvim.wait(100)\nassert(#notifications == 0, table.concat(notifications, '\\n'))\n"
                         + "\nend, debug.traceback)\n"
                         + "if not ok then print(err); vim.cmd('cquit') end\n"
                         + "vim.cmd('qa!')\n")
        command = [shutil.which("nvim"), "--headless", "-n", "-i", "NONE", "--cmd", capture]
        if not default_config:
            command += ["-u", str(self.config / "init.lua")]
        command += [str(file) for file in files]
        command += ["-c", "lua dofile(" + json.dumps(str(check)) + ")"]
        result = subprocess.run(
            command,
            env=self.env, cwd=self.root, capture_output=True, text=True, timeout=timeout,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("Error detected", result.stderr)
        return result

    def tex_project(self):
        main = self.root / "main.tex"
        main.write_text(r"""\documentclass{article}
\begin{document}
\section{Test}\label{sec:test}
See \ref{sec:test}.
$ff$
\end{document}
""")
        (self.root / ".latexmkrc").write_text("$pdf_mode = 1;\n")
        return main

    def test_startup_native_comments_and_counted_prose_motion(self):
        self.nvim(r"""
assert(vim.g.colors_name == 'nord')
assert(vim.fn.exists(':VimtexInverseSearch') == 2)
assert(vim.fn.exists(':Lazy') == 2)
assert(vim.fn.exists(':Deintoml') == 0)
local plugins = require('lazy.core.config').plugins
for _, name in ipairs({ 'dein.vim', 'vim-racer', 'lean.vim', 'coquille', 'caw.vim', 'vim-toml' }) do
  assert(plugins[name] == nil, name)
end
vim.cmd('enew')
vim.bo.filetype = 'markdown'
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'Hello', 'world' })
vim.cmd('normal \\c')
assert(vim.api.nvim_get_current_line():find('<!--', 1, true))
vim.cmd('normal \\c')
assert(vim.api.nvim_get_current_line() == 'Hello')
local text = string.rep('word ', 60)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { text, text, text, text, text, text })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd('normal j')
assert(vim.fn.line('.') == 1, 'j should move within a wrapped prose line')
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd('normal 3j')
assert(vim.fn.line('.') == 4, '3j should move three logical lines')
vim.bo.filetype = 'lua'
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd('normal j')
assert(vim.fn.line('.') == 2, 'code should use logical lines')
""")

    def test_tex_file_passed_at_startup(self):
        main = self.tex_project()
        for default_config in (False, True):
            with self.subTest(default_config=default_config):
                self.nvim(r"""
assert(vim.bo.filetype == 'tex')
assert(package.loaded.luasnip, 'LuaSnip did not load for the initial file')
assert(vim.bo.omnifunc == 'dotfiles#tex_complete#omnifunc')
assert(vim.wo.foldenable and vim.wo.foldlevel == 99)
assert(vim.fn.maparg('<Tab>', 'i', false, true).buffer == 1)
vim.api.nvim_buf_set_lines(0, 4, 5, false, { '$$' })
vim.api.nvim_win_set_cursor(0, { 5, 1 })
vim.cmd('syntax sync fromstart')
vim.api.nvim_feedkeys(vim.keycode('iff<Tab><Esc>'), 'xt', false)
assert(vim.api.nvim_get_current_line():find([[\frac{]], 1, true), 'initial-file snippet did not expand')
""", files=[main], default_config=default_config)

    def test_inverse_search_switches_to_tex_in_another_tab(self):
        main = self.tex_project()
        other = self.root / "other project/other.tex"
        other.parent.mkdir()
        other.write_text(main.read_text())
        self.nvim("local main = " + json.dumps(str(main)) + "\n"
                  + "local other = " + json.dumps(str(other)) + "\n" + r"""
vim.cmd.edit(main)
local main_win = vim.api.nvim_get_current_win()
vim.cmd.tabedit(other)
local other_win = vim.api.nvim_get_current_win()
-- Keep an unrelated split selected in the destination tab.
vim.cmd.vnew()
vim.bo.filetype = 'text'
vim.api.nvim_win_set_buf(0, vim.fn.bufadd('notes.txt'))
vim.api.nvim_set_current_win(main_win)
vim.api.nvim_buf_set_lines(0, 3, 4, false, { 'Unsaved text in the original tab.' })
local main_buf = vim.api.nvim_get_current_buf()
assert(vim.fn['vimtex#view#inverse_search'](4, other, 3) == 0)
assert(vim.api.nvim_get_current_win() == other_win, 'inverse search did not select the existing TeX window')
assert(vim.api.nvim_buf_get_name(0) == other)
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 4, 2 }))
assert(#vim.api.nvim_list_tabpages() == 2, 'inverse search duplicated a tab')
assert(vim.bo[main_buf].modified, 'inverse search discarded unsaved changes')
assert(vim.api.nvim_buf_get_lines(main_buf, 3, 4, false)[1] == 'Unsaved text in the original tab.')

-- Reverse search also works while a non-TeX tab is selected.
vim.cmd.tabnew()
vim.bo.filetype = 'text'
assert(vim.fn['vimtex#view#inverse_search'](3, main) == 0)
assert(vim.api.nvim_get_current_win() == main_win)
assert(vim.fn.line('.') == 3)
assert(#vim.api.nvim_list_tabpages() == 3)

-- A PDF belonging to another Neovim session must leave this session alone.
local cursor = vim.api.nvim_win_get_cursor(0)
assert(vim.fn['vimtex#view#inverse_search'](4, vim.fn.getcwd() .. '/unrelated.tex') == -2)
assert(vim.api.nvim_get_current_win() == main_win)
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), cursor))
""")

    def test_inverse_search_command_from_another_process(self):
        main = self.tex_project()
        other = self.root / 'other project/other.tex'
        other.parent.mkdir()
        other.write_text(main.read_text())
        ready = self.root / 'ready'
        setup = self.root / 'receiver.lua'
        setup.write_text('vim.cmd.edit(' + json.dumps(str(main)) + ')\n'
                         + 'vim.cmd.edit(' + json.dumps(str(other)) + ')\n'
                         + 'vim.fn.writefile({vim.v.servername}, ' + json.dumps(str(ready)) + ')\n')
        command = [shutil.which('nvim'), '--headless', '-n', '-i', 'NONE']
        receiver = subprocess.Popen(
            command + ['-c', 'lua dofile(' + json.dumps(str(setup)) + ')'],
            env=self.env, cwd=self.root, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        try:
            deadline = time.monotonic() + 10
            while not ready.exists() and receiver.poll() is None and time.monotonic() < deadline:
                time.sleep(0.02)
            self.assertTrue(ready.exists(), 'Neovim receiver did not initialize')
            server = ready.read_text().strip()
            self.assertTrue(server, 'Neovim RPC server did not start')
            # Run the exact command used by Skim while the receiver's event loop is idle.
            request = subprocess.run(
                command + ['-c', "VimtexInverseSearch 4 '" + str(main) + "'"],
                env=self.env, cwd=self.root, capture_output=True, text=True, timeout=10,
            )
            self.assertEqual(request.returncode, 0, request.stderr)
            state = subprocess.run(
                [shutil.which('nvim'), '--server', server, '--remote-expr',
                 "json_encode([expand('%:p'), line('.'), tabpagenr('$')])"],
                env=self.env, cwd=self.root, capture_output=True, text=True, timeout=10,
            )
            self.assertEqual(state.returncode, 0, state.stderr)
            self.assertEqual(json.loads(state.stdout), [str(main), 4, 1])
        finally:
            receiver.terminate()
            try:
                receiver.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                receiver.kill()
                receiver.communicate()

    def test_inverse_search_switches_to_hidden_tex_buffer(self):
        main = self.tex_project()
        other = self.root / 'other.tex'
        other.write_text(main.read_text())
        self.nvim('local main = ' + json.dumps(str(main)) + '\n'
                  + 'local other = ' + json.dumps(str(other)) + '\n' + r"""
vim.cmd.edit(main)
local main_buf = vim.api.nvim_get_current_buf()
vim.cmd.edit(other)
local other_buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(0, 3, 4, false, { 'Keep these unsaved changes.' })
assert(#vim.fn.win_findbuf(main_buf) == 0, 'target must be hidden')
assert(vim.fn['vimtex#view#inverse_search'](4, main, 3) == 0)
assert(vim.api.nvim_get_current_buf() == main_buf, 'inverse search did not select the hidden buffer')
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 4, 2 }))
assert(#vim.api.nvim_list_tabpages() == 1, 'inverse search created an unnecessary tab')
assert(vim.bo[other_buf].modified)
assert(vim.api.nvim_buf_get_lines(other_buf, 3, 4, false)[1] == 'Keep these unsaved changes.')
-- The previous source becomes hidden and must still be reachable in reverse.
assert(vim.fn['vimtex#view#inverse_search'](3, other) == 0)
assert(vim.api.nvim_get_current_buf() == other_buf)
assert(vim.fn.line('.') == 3)
""")

    def test_texlab_snippets_tags_and_filetype_cleanup(self):
        main = self.tex_project()
        self.nvim("vim.cmd.edit(" + json.dumps(str(main)) + ")\n" + r"""
assert(vim.bo.filetype == 'tex')
assert(vim.bo.omnifunc == 'dotfiles#tex_complete#omnifunc')
assert(vim.b.vimtex.viewer._start ~= nil, 'custom Skim viewer must load')
assert(vim.wait(10000, function()
  local client = vim.lsp.get_clients({ bufnr = 0, name = 'texlab' })[1]
  return client and client.initialized
end, 50), 'TexLab did not initialize')
assert(vim.bo.omnifunc == 'dotfiles#tex_complete#omnifunc', 'LSP replaced VimTeX completion')
assert(vim.bo.tagfunc == 'v:lua.vim.lsp.tagfunc')
assert(vim.wait(5000, function() return vim.fn.filereadable('tags') == 1 end, 50))
local tags = table.concat(vim.fn.readfile('tags'), '\n')
assert(tags:find('sec:test', 1, true), 'ctags omitted TeX labels')
vim.api.nvim_win_set_cursor(0, { 4, 10 })
local result = vim.lsp.buf_request_sync(0, 'textDocument/definition',
  vim.lsp.util.make_position_params(0, 'utf-16'), 5000)
local found = false
for _, response in pairs(result or {}) do
  if response.result and #response.result > 0 then found = true end
end
assert(found, 'TexLab did not resolve the label')
vim.api.nvim_buf_set_lines(0, 4, 5, false, { '$$' })
vim.api.nvim_win_set_cursor(0, { 5, 1 })
vim.cmd('syntax sync fromstart')
local keys = vim.api.nvim_replace_termcodes('iff<Tab><Esc>', true, false, true)
vim.api.nvim_feedkeys(keys, 'xt', false)
assert(vim.api.nvim_get_current_line():find([[\frac{]], 1, true), 'fraction did not expand')
vim.cmd.stopinsert()
vim.bo.filetype = 'text'
assert(#vim.lsp.get_clients({ bufnr = 0, name = 'texlab' }) == 0, 'TexLab was not detached')
assert(vim.fn.maparg('<Tab>', 'i', false, true).buffer ~= 1, 'TeX snippet map leaked into text')
assert(vim.fn.maparg('gd', 'n', false, true).buffer ~= 1, 'TeX gd map leaked into text')
""")

    @unittest.skipUnless(shutil.which("latexmk"), "latexmk is not installed")
    def test_vimtex_build_and_completion(self):
        main = self.tex_project()
        self.nvim("vim.g.vimtex_view_enabled = 0\nvim.cmd.edit(" + json.dumps(str(main)) + ")\n" + r"""
vim.cmd('VimtexCompileSS')
assert(vim.wait(20000, function()
  local running = vim.fn.eval('b:vimtex.compiler.is_running()')
  return vim.fn.filereadable('main.pdf') == 1 and (running == false or running == 0)
end, 100), 'VimTeX build did not finish')
assert(vim.fn.filereadable('main.synctex.gz') == 1)
local aux = table.concat(vim.fn.readfile('main.aux'), '\n')
assert(aux:find('sec:test', 1, true))
vim.api.nvim_win_set_cursor(0, { 4, 16 })
vim.fn['vimtex#complete#omnifunc'](1, '')
local matches = vim.fn['vimtex#complete#omnifunc'](0, 'sec:')
assert(vim.inspect(matches):find('sec:test', 1, true), 'VimTeX reference completion failed')
""", timeout=40)

    def test_search_which_key_and_markdown(self):
        markdown = self.root / "note.md"
        markdown.write_text("# Note\n\nSome text\n")
        self.nvim("vim.cmd.edit(" + json.dumps(str(markdown)) + ")\n" + r"""
assert(vim.bo.filetype == 'markdown' and vim.wo.spell and vim.wo.linebreak)
assert(vim.g.previm_open_cmd == 'open')
assert(vim.fn.exists(':PrevimOpen') == 2)
require('lazy').load({ plugins = { 'fzf-lua', 'which-key.nvim', 'gitsigns.nvim' } })
local fzf = require('fzf-lua')
for _, name in ipairs({ 'files', 'live_grep', 'diagnostics_document', 'lsp_references' }) do
  assert(type(fzf[name]) == 'function', name)
end
assert(vim.fn.maparg(',r', 'n') ~= '')
assert(vim.fn.maparg('\\?', 'n') ~= '')
""")

    def test_git_changes_and_file_picker(self):
        note = self.root / 'probe.md'
        note.write_text('# Original\n')
        for args in (
            ['init', '-q'], ['add', 'probe.md'],
            ['-c', 'user.name=Neovim Test', '-c', 'user.email=test@example.invalid',
             '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null',
             'commit', '-qm', 'Test fixture'],
        ):
            subprocess.run(['git', '-C', str(self.root)] + args, check=True, capture_output=True)
        note.write_text('# Changed\n')
        self.nvim('vim.cmd.edit(' + json.dumps(str(note)) + ')\n' + r"""
assert(vim.wait(5000, function()
  return vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.changed == 1
end, 50), 'Git change was not detected')
assert(vim.fn.maparg('\\hp', 'n', false, true).buffer == 1)
require('fzf-lua').files({ cwd = vim.fn.getcwd(), query = 'probe.md' })
local terminal
assert(vim.wait(5000, function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == 'terminal' then
      local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
      if text:find('probe.md', 1, true) then terminal = buf; return true end
    end
  end
end, 50), 'fzf file picker did not show the project file')
local job = vim.b[terminal].terminal_job_id
require('fzf-lua').hide()
vim.fn.jobstop(job)
""")

    def test_tex_file_picker_defers_folds_until_requested(self):
        main = self.tex_project()
        main.write_text("\\documentclass{article}\n\\begin{document}\n"
                        + "".join(f"\\section{{Section {n}}}\nText.\nMore text.\n"
                                  for n in range(200))
                        + "\\end{document}\n")
        self.nvim('local main = ' + json.dumps(str(main)) + '\n' + r"""
vim.cmd('normal ,f')
local terminal
assert(vim.wait(5000, function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == 'terminal' then
      local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
      if text:find('main.tex', 1, true) then terminal = buf; return true end
    end
  end
end, 50), 'fzf did not show the TeX file')
-- Accept through the terminal, including fzf's close and file-open actions.
vim.api.nvim_chan_send(vim.b[terminal].terminal_job_id, 'main.tex')
vim.wait(200)
vim.api.nvim_chan_send(vim.b[terminal].terminal_job_id, '\r')
assert(vim.wait(5000, function()
  return vim.api.nvim_buf_get_name(0) == main and vim.bo.filetype == 'tex'
end, 50), 'fzf did not open the selected TeX file')
vim.cmd.stopinsert()
vim.cmd('normal! 4G')
vim.api.nvim_exec_autocmds('CursorMoved', { buffer = 0 })
vim.cmd.redraw()
assert(vim.wo.foldmethod == 'manual')
assert(vim.fn.foldlevel(4) == 0, 'opening/moving the cursor eagerly computed folds')
assert(vim.bo.omnifunc == 'dotfiles#tex_complete#omnifunc')

-- A second window exists before the first window computes its fold ranges.
local first = vim.api.nvim_get_current_win()
vim.cmd.vsplit()
local second = vim.api.nvim_get_current_win()
vim.api.nvim_set_current_win(first)
vim.cmd('normal za')
assert(vim.fn.foldclosed(4) == 3, 'za did not compute and close the section')
vim.cmd('normal za')
assert(vim.fn.foldclosed(4) == -1, 'za did not reopen the section')
vim.api.nvim_set_current_win(second)
vim.cmd('normal zM')
assert(vim.fn.foldclosed(4) == 3, 'folds were not initialized in the other split')
vim.cmd('normal zR')
assert(vim.fn.foldclosed(4) == -1)
vim.cmd('normal 2zm')
assert(vim.wo.foldlevel == 0, 'folding lost the command count')
vim.cmd('normal zR')

vim.api.nvim_buf_set_lines(0, 3, 3, false, { 'Inserted text.' })
vim.cmd('normal zx')
vim.cmd('normal zM')
assert(vim.fn.foldclosedend(4) == 6, 'zx did not refresh ranges after editing')
vim.bo.filetype = 'text'
for _, key in ipairs({ 'za', 'zM', 'zx', 'zj', '[z' }) do
  assert(vim.fn.maparg(key, 'n', false, true).buffer ~= 1, key .. ' leaked into text')
end
assert(vim.wo.foldexpr ~= 'vimtex#fold#level(v:lnum)')
""")


if __name__ == '__main__':
    unittest.main()
