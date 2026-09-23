import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPOSITORY = Path(__file__).resolve().parents[1]


class DeployTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.checkout = self.root / "checkout with spaces"
        self.checkout.mkdir()
        self.target = self.root / "target home"
        for name in ("deploy.sh", "Brewfile", ".zshenv", ".zshrc", ".gitconfig",
                     ".gitignore_global", ".vimrc", ".vimrc_vscode", ".latexmkrc_platex"):
            shutil.copy2(REPOSITORY / name, self.checkout / name)
        shutil.copytree(
            REPOSITORY / ".config/nvim", self.checkout / ".config/nvim",
            symlinks=True, ignore=shutil.ignore_patterns("repos", "spell"),
        )
        shutil.copy2(REPOSITORY / ".config/starship.toml", self.checkout / ".config/starship.toml")

    def deploy(self, *options, with_brew=False, env=None, check=True):
        command = ["/bin/bash", str(self.checkout / "deploy.sh"), "--target", str(self.target),
                   "--skip-macos"]
        if not with_brew:
            command.append("--skip-brew")
        return subprocess.run(command + list(options), cwd=self.root, env=env, check=check,
                              text=True, capture_output=True)

    def test_deploy_from_another_directory_and_repeat(self):
        self.deploy()
        link = self.target / ".zshrc"
        inode = link.lstat().st_ino
        self.assertEqual(link.resolve(), self.checkout / ".zshrc")
        self.assertEqual((self.target / ".config/nvim/init.vim").resolve(), self.checkout / ".vimrc")
        self.assertFalse((self.target / ".ctags.d").exists())
        self.deploy("--force")
        self.assertEqual(link.lstat().st_ino, inode)
        self.assertFalse((self.target / ".dotfiles-backups").exists())

    def test_preserve_conflicts_then_back_up_on_force(self):
        (self.target / ".config/nvim").mkdir(parents=True)
        (self.target / ".config/nvim/init.lua").write_text("user configuration")
        (self.target / ".config/unrelated").write_text("keep")
        (self.target / ".zshrc").write_text("original shell")
        (self.target / ".vimrc").symlink_to("missing-vimrc")
        self.deploy()
        self.assertEqual((self.target / ".zshrc").read_text(), "original shell")
        self.assertEqual(os.readlink(self.target / ".vimrc"), "missing-vimrc")
        self.assertFalse((self.target / ".config/nvim").is_symlink())
        self.deploy("--force")
        backups = list((self.target / ".dotfiles-backups").iterdir())
        self.assertEqual(len(backups), 1)
        backup = backups[0]
        self.assertEqual((backup / ".zshrc").read_text(), "original shell")
        self.assertEqual(os.readlink(backup / ".vimrc"), "missing-vimrc")
        self.assertEqual((backup / ".config/nvim/init.lua").read_text(), "user configuration")
        self.assertEqual((self.target / ".config/unrelated").read_text(), "keep")
        self.assertFalse((self.target / ".config").is_symlink())
        self.assertTrue((self.target / ".config/nvim").is_symlink())
        self.deploy("-f")
        self.assertEqual(list((self.target / ".dotfiles-backups").iterdir()), backups)

    def test_excluded_files_are_never_replaced(self):
        self.target.mkdir()
        for name in (".latexmkrc", ".vimrc_vscode", ".gitignore", ".lvimrc"):
            (self.target / name).write_text("keep " + name)
        self.deploy("--force")
        for name in (".latexmkrc", ".vimrc_vscode", ".gitignore", ".lvimrc"):
            self.assertEqual((self.target / name).read_text(), "keep " + name)

    def test_dry_run_does_not_create_target(self):
        self.deploy("--dry-run")
        self.assertFalse(self.target.exists())

    def test_force_dry_run_keeps_existing_file_and_creates_no_backup(self):
        self.target.mkdir()
        (self.target / ".zshrc").write_text("keep")
        self.deploy("--force", "--dry-run")
        self.assertEqual(list(self.target.iterdir()), [self.target / ".zshrc"])
        self.assertEqual((self.target / ".zshrc").read_text(), "keep")

    def test_legacy_config_symlink_does_not_move_sources(self):
        self.target.mkdir()
        (self.target / ".config").symlink_to(self.checkout / ".config")
        before = (self.checkout / ".config/starship.toml").read_bytes()
        self.deploy("--force")
        self.assertEqual((self.checkout / ".config/starship.toml").read_bytes(), before)
        self.assertFalse((self.checkout / ".config/nvim").is_symlink())
        self.assertFalse((self.target / ".dotfiles-backups").exists())

    def test_invalid_parent_fails_before_creating_links(self):
        self.target.mkdir()
        (self.target / ".config").write_text("not a directory")
        result = self.deploy(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("not a directory", result.stderr)
        self.assertFalse((self.target / ".zshrc").exists())

    def test_optional_ctags_file(self):
        (self.checkout / "latex.ctags").write_text("--languages=LaTeX\n")
        self.deploy()
        self.assertEqual((self.target / ".ctags.d/latex.ctags").resolve(), self.checkout / "latex.ctags")

    def test_existing_brew_runs_bundle_without_installer(self):
        binaries = self.root / "bin"
        binaries.mkdir()
        log = self.root / "brew.log"
        for name, content in {
            "brew": '#!/bin/bash\nprintf "%s\\n" "$@" > "$DOTFILES_TEST_BREW_LOG"\n',
            "curl": '#!/bin/bash\necho "unexpected installer download" >&2\nexit 99\n',
        }.items():
            script = binaries / name
            script.write_text(content)
            script.chmod(0o755)
        env = dict(os.environ, PATH=str(binaries) + os.pathsep + os.environ["PATH"],
                   DOTFILES_TEST_BREW_LOG=str(log))
        self.deploy(with_brew=True, env=env)
        self.assertEqual(log.read_text().splitlines(), ["bundle", f"--file={self.checkout}/Brewfile"])
        log.unlink()
        self.deploy("--dry-run", with_brew=True, env=env)
        self.assertFalse(log.exists())

    def test_help_and_invalid_option(self):
        self.assertEqual(self.deploy("--help").returncode, 0)
        self.assertNotEqual(self.deploy("--unknown", check=False).returncode, 0)
        self.assertFalse(self.target.exists())

    @unittest.skipUnless(shutil.which("nvim"), "Neovim is not installed")
    def test_neovim_configs_load_from_relocated_checkout(self):
        cache = self.root / "cache with spaces"
        autoload = cache / "dein/repos/github.com/Shougo/dein.vim/autoload"
        autoload.mkdir(parents=True)
        (autoload / "dein.vim").write_text("""
function! dein#load_state(path) abort
  let g:test_dein_base = a:path
  let g:test_tomls = []
  return 1
endfunction
function! dein#load_toml(path, options) abort
  call add(g:test_tomls, a:path)
endfunction
function! dein#check_install() abort
  return 0
endfunction
""" + "\n".join(
            f"function! dein#{name}(...) abort\nendfunction"
            for name in ("begin", "end", "save_state", "recache_runtimepath", "add")
        ))
        def quote(value):
            return "'" + str(value).replace("'", "''") + "'"

        env = dict(os.environ, XDG_CACHE_HOME=str(cache), XDG_DATA_HOME=str(self.root / "data"),
                   XDG_STATE_HOME=str(self.root / "state"), XDG_CONFIG_HOME=str(self.root / "config"))
        for config, vscode in ((".config/nvim/init.vim", False), (".vimrc_vscode", True)):
            with self.subTest(config=config):
                assertions = [
                    f"call assert_equal({quote(cache / 'dein')}, g:test_dein_base)",
                    f"call assert_equal({0 if vscode else 2}, len(g:test_tomls))",
                    "Deintoml",
                    f"call assert_equal({quote(self.checkout / '.config/nvim/dein/toml/dein.toml')}, expand('%:p'))",
                    "if !empty(v:errors) | echoerr join(v:errors, '\\n') | cquit | endif",
                    "qa!",
                ]
                commands = self.root / "check.vim"
                commands.write_text("\n".join(assertions))
                command = [shutil.which("nvim"), "--headless", "-n", "-i", "NONE"]
                if vscode:
                    command.extend(["--cmd", "let g:vscode = 1"])
                result = subprocess.run(command + ["-u", str(self.checkout / config), "-S", str(commands)],
                                        cwd=self.root, env=env, text=True, capture_output=True, timeout=20)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn("Error", result.stderr)


if __name__ == "__main__":
    unittest.main()
