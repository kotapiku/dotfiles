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

    def deploy(self, *options, with_brew=False, with_macos=False, env=None, check=True):
        command = ["/bin/bash", str(self.checkout / "deploy.sh"), "--target", str(self.target)]
        if not with_macos:
            command.append("--skip-macos")
        if not with_brew:
            command.append("--skip-brew")
        return subprocess.run(command + list(options), cwd=self.root, env=env, check=check,
                              text=True, capture_output=True, timeout=20)

    def stub_commands(self, **commands):
        binaries = self.root / "bin"
        binaries.mkdir(exist_ok=True)
        for name, content in commands.items():
            script = binaries / name
            script.write_text("#!/bin/bash\nset -eu\n" + content)
            script.chmod(0o755)
        return dict(os.environ, PATH=str(binaries) + os.pathsep + "/usr/bin:/bin:/usr/sbin:/sbin")

    def test_deploy_from_another_directory_and_repeat(self):
        self.deploy()
        link = self.target / ".zshrc"
        inode = link.lstat().st_ino
        self.assertEqual(link.resolve(), self.checkout / ".zshrc")
        self.assertEqual((self.target / ".config/nvim/init.lua").resolve(),
                         self.checkout / ".config/nvim/init.lua")
        self.assertFalse((self.target / ".config/nvim/init.vim").exists())
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

    def test_root_target_aliases_are_rejected_without_changes(self):
        alias = self.root / "root alias"
        alias.symlink_to("/")
        for target in ("/", "//", "////", "/usr/..", str(alias)):
            with self.subTest(target=target):
                result = self.deploy("--target", target, "--dry-run", check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("must not resolve to /", result.stderr)
                self.assertNotIn("ln -s", result.stdout)
        self.assertFalse(self.target.exists())

    def test_target_normalizes_missing_components_and_symlinks(self):
        alias = self.root / "home alias"
        self.target.mkdir()
        alias.symlink_to(self.target, target_is_directory=True)
        self.deploy("--target", str(alias) + "/missing/../", "--force")
        self.assertEqual((self.target / ".zshrc").resolve(), self.checkout / ".zshrc")
        self.assertFalse((self.target / "missing").exists())

    def test_root_xdg_config_directory_is_rejected(self):
        env = dict(os.environ, HOME=str(self.target), XDG_CONFIG_HOME="/")
        result = subprocess.run(
            ["/bin/bash", str(self.checkout / "deploy.sh"), "--skip-brew", "--skip-macos",
             "--dry-run"], env=env, text=True, capture_output=True, timeout=20,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("config directory must not resolve to /", result.stderr)
        self.assertFalse(self.target.exists())

    def test_custom_xdg_config_directory_and_backup(self):
        config = self.root / "custom config"
        config.mkdir()
        (config / "starship.toml").write_text("original prompt")
        env = dict(os.environ, HOME=str(self.target), XDG_CONFIG_HOME=str(config))
        subprocess.run(
            ["/bin/bash", str(self.checkout / "deploy.sh"), "--skip-brew", "--skip-macos", "--force"],
            env=env, check=True, text=True, capture_output=True, timeout=20,
        )
        self.assertEqual((config / "nvim").resolve(), self.checkout / ".config/nvim")
        self.assertEqual((config / "starship.toml").resolve(), self.checkout / ".config/starship.toml")
        self.assertFalse((self.target / ".config").exists())
        backup, = (self.target / ".dotfiles-backups").iterdir()
        self.assertEqual((backup / ".config/starship.toml").read_text(), "original prompt")

    def test_target_inside_checkout_is_rejected_before_creating_links(self):
        result = self.deploy("--target", str(self.checkout / "nested home"), check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("destination would modify the checkout", result.stderr)
        self.assertFalse((self.checkout / "nested home").exists())

    def test_config_symlink_into_managed_directory_is_rejected(self):
        self.target.mkdir()
        (self.target / ".config").symlink_to(self.checkout / ".config/nvim")
        result = self.deploy("--force", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("destination would modify the checkout", result.stderr)
        self.assertFalse((self.target / ".zshrc").exists())
        self.assertFalse((self.checkout / ".config/nvim/nvim").exists())
        self.assertFalse((self.target / ".dotfiles-backups").exists())

    def test_optional_ctags_file(self):
        (self.checkout / "latex.ctags").write_text("--languages=LaTeX\n")
        self.deploy()
        self.assertEqual((self.target / ".ctags.d/latex.ctags").resolve(), self.checkout / "latex.ctags")

    def test_existing_brew_runs_bundle_without_installer(self):
        log = self.root / "brew.log"
        env = self.stub_commands(
            uname='echo Darwin\n',
            brew='printf "%s\\n" "$@" >> "$DOTFILES_TEST_BREW_LOG"\n',
            curl='echo "unexpected installer download" >&2\nexit 99\n',
        )
        env["DOTFILES_TEST_BREW_LOG"] = str(log)
        self.deploy(with_brew=True, env=env)
        self.assertEqual(log.read_text().splitlines(),
                         ["shellenv", "bash", "bundle", f"--file={self.checkout}/Brewfile"])
        log.unlink()
        self.deploy("--dry-run", with_brew=True, env=env)
        self.assertFalse(log.exists())

    def test_brew_outside_path_loads_environment_before_bundle(self):
        prefix = self.root / "Homebrew with spaces"
        (prefix / "bin").mkdir(parents=True)
        brew = prefix / "bin/brew"
        brew.write_text("""#!/bin/bash
set -eu
case "$1" in
  shellenv)
    [[ "$2" = bash ]]
    printf 'export PATH=%q/bin:$PATH\\n' "$HOMEBREW_PREFIX"
    ;;
  bundle)
    command -v mas > "$DOTFILES_TEST_BREW_LOG"
    ;;
  *) exit 99 ;;
esac
""")
        brew.chmod(0o755)
        mas = prefix / "bin/mas"
        mas.write_text("#!/bin/bash\nexit 0\n")
        mas.chmod(0o755)
        log = self.root / "brew.log"
        env = self.stub_commands(uname='echo Darwin\n', curl='exit 99\n')
        env.update(HOMEBREW_PREFIX=str(prefix), DOTFILES_TEST_BREW_LOG=str(log))
        self.deploy(with_brew=True, env=env)
        self.assertEqual(log.read_text().strip(), str(mas))

    def test_brew_failure_preserves_existing_configuration_and_macos_settings(self):
        self.target.mkdir()
        (self.target / ".zshrc").write_text("working configuration")
        log = self.root / "defaults.log"
        env = self.stub_commands(
            uname='echo Darwin\n',
            brew='[[ "$1" = shellenv ]] && exit 0\nexit 42\n',
            defaults='echo called > "$DOTFILES_TEST_DEFAULTS_LOG"\n',
        )
        env["DOTFILES_TEST_DEFAULTS_LOG"] = str(log)
        result = self.deploy("--force", with_brew=True, with_macos=True, env=env, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("brew bundle failed", result.stderr)
        self.assertEqual(list(self.target.iterdir()), [self.target / ".zshrc"])
        self.assertEqual((self.target / ".zshrc").read_text(), "working configuration")
        self.assertFalse(log.exists())

    def test_missing_brewfile_fails_before_external_commands_and_links(self):
        (self.checkout / "Brewfile").unlink()
        log = self.root / "brew.log"
        env = self.stub_commands(
            uname='echo Darwin\n', brew='echo called > "$DOTFILES_TEST_BREW_LOG"\n',
        )
        env["DOTFILES_TEST_BREW_LOG"] = str(log)
        result = self.deploy(with_brew=True, env=env, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Brewfile", result.stderr)
        self.assertFalse(self.target.exists())
        self.assertFalse(log.exists())
        self.deploy(env=env)
        self.assertTrue((self.target / ".zshrc").is_symlink())

    def test_non_macos_requires_skip_brew_but_can_deploy_links(self):
        log = self.root / "external.log"
        env = self.stub_commands(
            uname='echo Linux\n',
            brew='echo brew > "$DOTFILES_TEST_EXTERNAL_LOG"\n',
            defaults='echo defaults > "$DOTFILES_TEST_EXTERNAL_LOG"\n',
        )
        env["DOTFILES_TEST_EXTERNAL_LOG"] = str(log)
        result = self.deploy(with_brew=True, with_macos=True, env=env, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("requires macOS", result.stderr)
        self.assertFalse(self.target.exists())
        self.assertFalse(log.exists())
        self.deploy(with_macos=True, env=env)
        self.assertTrue((self.target / ".zshrc").is_symlink())
        self.assertFalse(log.exists())

    def test_macos_preferences_follow_successful_bundle_and_are_skipped_in_dry_run(self):
        log = self.root / "defaults.log"
        env = self.stub_commands(
            uname='echo Darwin\n',
            brew='[[ ! -L "$DOTFILES_TEST_TARGET/.zshrc" ]]\n',
            defaults='[[ -L "$DOTFILES_TEST_TARGET/.zshrc" ]]\nprintf "%s\\n" "$@" >> "$DOTFILES_TEST_DEFAULTS_LOG"\n',
        )
        env.update(DOTFILES_TEST_TARGET=str(self.target), DOTFILES_TEST_DEFAULTS_LOG=str(log))
        self.deploy("--dry-run", with_brew=True, with_macos=True, env=env)
        self.assertFalse(log.exists())
        self.assertFalse(self.target.exists())
        self.deploy(with_brew=True, with_macos=True, env=env)
        self.assertEqual(log.read_text().splitlines(), [
            "write", "-g", "ApplePressAndHoldEnabled", "-bool", "false",
            "write", "net.sourceforge.skim-app.skim", "AppleWindowTabbingMode", "-string", "always",
        ])

    def test_help_and_invalid_option(self):
        self.assertEqual(self.deploy("--help").returncode, 0)
        self.assertNotEqual(self.deploy("--unknown", check=False).returncode, 0)
        self.assertFalse(self.target.exists())

    @unittest.skipUnless(shutil.which("nvim"), "Neovim is not installed")
    def test_neovim_configs_load_from_relocated_checkout(self):
        data = self.root / "data with spaces"
        lazy = data / "nvim/lazy/lazy.nvim/lua"
        lazy.mkdir(parents=True)
        (lazy / "lazy.lua").write_text("""
return { setup = function(options)
  vim.g.test_lazy_lockfile = options.lockfile
  vim.g.test_lazy_import = options.spec[1].import
end }
""")
        def quote(value):
            return "'" + str(value).replace("'", "''") + "'"

        env = dict(os.environ, XDG_DATA_HOME=str(data), XDG_CACHE_HOME=str(self.root / "cache"),
                   XDG_STATE_HOME=str(self.root / "state"), XDG_CONFIG_HOME=str(self.root / "config"))
        for config, vscode in ((".config/nvim/init.lua", False),
                               (".config/nvim/init.lua", True), (".vimrc_vscode", True)):
            with self.subTest(config=config, vscode=vscode):
                if vscode:
                    assertions = ["call assert_false(exists('g:test_lazy_lockfile'))",
                                  "call assert_equal('gcc', maparg('\\c', 'n'))"]
                else:
                    assertions = [
                        f"call assert_equal({quote(self.checkout / '.config/nvim/lazy-lock.json')}, g:test_lazy_lockfile)",
                        "call assert_equal('plugins', g:test_lazy_import)",
                        "call assert_true(&undofile)",
                        "call assert_equal('gcc', maparg('\\c', 'n'))",
                        "Vimrc",
                        f"call assert_equal({quote(self.checkout / '.config/nvim/init.lua')}, expand('%:p'))",
                    ]
                assertions += [
                    "call assert_equal('', v:errmsg)",
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
