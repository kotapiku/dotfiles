# dotfiles

macOS 用の Zsh、Neovim、Git、LaTeX 設定と補助スクリプト。
deploy は macOS 標準の Bash 3.2 で動作します。

## 導入

リポジトリを任意の場所に clone し、そのディレクトリで実行します。

```sh
./deploy.sh --dry-run
./deploy.sh
```

通常の実行では設定へのリンクを作成し、Homebrew がなければ公式インストーラで導入します。
Homebrew の導入済み・未導入にかかわらず、このリポジトリの Brewfile に対して
`brew bundle` を実行します。Brewfile には MacTeX などのアプリも含まれます。
Mac App Store のアプリにはサインインが必要です。
macOS ではキー長押しのアクセント選択を無効にします。

設定のリンクだけを作る場合:

```sh
./deploy.sh --skip-brew --skip-macos
```

既存のファイル・ディレクトリ・壊れたリンクは、通常の実行ではそのまま保持します。
このリポジトリの設定へ切り替える場合は、変更予定を確認してから `--force` を使います。

```sh
./deploy.sh --force --dry-run
./deploy.sh --force --skip-brew --skip-macos
```

`--force` は衝突する設定を `~/.dotfiles-backups/日時.ランダム文字列/` へ移してから
リンクを作ります。すでに同じ設定を参照しているリンクは変更しません。
`--dry-run` はファイルの作成・バックアップ・ダウンロード・外部設定の変更を行いません。
利用できるオプションは `./deploy.sh --help` で確認できます。

ホームディレクトリ以外で試す場合は、絶対パスを指定します。

```sh
./deploy.sh --target /tmp/dotfiles-preview --skip-brew --skip-macos
```

`--target` は設定の配置先だけを変えます。Homebrew と macOS の変更を省くには、
上記のスキップオプションも指定してください。

## 管理対象

| リポジトリ内 | 配置先 |
| --- | --- |
| `.zshenv`, `.zshrc` | ホームの同名ファイル |
| `.gitconfig`, `.gitignore_global` | ホームの同名ファイル |
| `.vimrc`, `.latexmkrc_platex` | ホームの同名ファイル |
| `.config/nvim` | `$XDG_CONFIG_HOME/nvim`（既定は `~/.config/nvim`） |
| `.config/starship.toml` | `$XDG_CONFIG_HOME/starship.toml` |
| ルートに追加した `*.ctags` | `~/.ctags.d/` の同名ファイル |

`--target` 指定時の設定ディレクトリは、その配置先の `.config` です。
`.config` 全体は置き換えません。以前の deploy で `.config` 全体をリンクした環境も利用できます。
`.config` 配下では Neovim と Starship だけを Git 管理対象とし、他のアプリの認証情報や
実行時データは管理しません。

`.latexmkrc`、`.vimrc_vscode` は自動配置しません。
LaTeX 設定はプロジェクトで選択し、VS Code 用設定は拡張機能側から指定します。
Neovim の起動設定はリポジトリ内の相対リンクで `.vimrc` を参照するため、
clone 先やユーザー名が変わっても利用できます。
リポジトリ自体を移動した場合は、移動先の `deploy.sh` を `--force` で再実行して
ホーム側のリンクを更新してください。

Neovim の dein キャッシュは `$XDG_CACHE_HOME/dein`（既定は `~/.cache/dein`）に作成します。
初回の Zsh / Neovim 起動時には、プラグインの取得にネットワーク接続が必要です。

## バックアップから戻す

deploy が表示したバックアップディレクトリから、対象の設定を戻します。
例えば `.zshrc` を復元する場合（`日時.ランダム文字列` は実際の名前に置き換えます）:

```sh
unlink "$HOME/.zshrc"
mv "$HOME/.dotfiles-backups/日時.ランダム文字列/.zshrc" "$HOME/.zshrc"
```

`unlink` の対象は deploy が作ったシンボリックリンクです。
Neovim のバックアップは同じバックアップディレクトリの `.config/nvim` にあります。
Homebrew のインストール・更新や macOS の設定は、このバックアップには含まれません。

## Markdown を Warp で開く

Zsh では `md` で Markdown ファイルを Warp に開けます。複数ファイルも指定できます。
設定変更後は新しいシェルを開くか、`source ~/.zshrc` で読み直してください。

```sh
md README.md
md README.md .config/nvim/README.md
```

`md` は `open -a Warp` のエイリアスです。複数ファイルを1つのペイン内のタブにまとめるには、
Warp の Settings → Code → Editor and Code Review で
「Group files into single editor pane」をオンにします。
Warp 上部の別タブに開く場合は、同じ画面の「Choose a layout to open files in Warp」を
「New tab」にします。これらの表示設定は Warp 側で変更します。
詳しくは [Warp の公式ガイド](https://docs.warp.dev/code/code-editor#tabbed-file-viewer) を参照してください。

## LaTeX

`.latexmkrc` は pdfLaTeX 用です。プロジェクトのディレクトリで、配置場所に合わせて実行します。

```sh
latexmk -r /path/to/dotfiles/.latexmkrc main.tex
```

pLaTeX 用は `.latexmkrc_platex` を指定します。
標準の `.latexmkrc` は従来どおり `-shell-escape` を有効にしています。
Neovim の設定が使う Universal Ctags は Brewfile に含めています。

## PDF の目次を追加する

Python 3.9 以降と Ghostscript（Brewfile に含まれます）を使用します。

```sh
python3 pdfoutline.py input.pdf contents.toc 0 output.pdf
```

目次ファイルは UTF-8 で、各行を `見出し ページ番号` とし、4 個のスペースで階層を表します。
ページ番号は 1 始まりです。第 3 引数の数値を各ページに加算します。

```text
はじめに 1
第1章 基礎 3
    定義 4
    具体例 7
第2章 応用 10
```

空行と行末の空白は許容します。ページ番号の欠落、階層の飛び越し、不正な字下げは
行番号付きで報告します。入力と出力には異なる PDF を指定してください。
Ghostscript が失敗した場合、このスクリプトも終了コード 1 を返します。

## 検証

リポジトリのルートで実行します。Python の追加パッケージは不要です。

```sh
bash -n deploy.sh
zsh -n .zshenv
zsh -n .zshrc
python3 -B -m unittest discover -s tests -v
```

deploy のテストは一時ディレクトリ内のコピーを使い、既存設定の保持、バックアップ、
再実行、空白を含むパス、旧 `.config` 配置、dry-run、Homebrew の導入済み判定を確認します。
Homebrew の呼び出しは代替コマンドを使い、実際のインストールや macOS 設定の変更はしません。
Neovim と Ghostscript がインストールされている場合は、それぞれ設定の読込と PDF 変換も検証します。
Neovim のプラグイン処理はテスト用の代替実装で、外部プラグインは取得しません。

## 参照

- [Homebrew Bundle の公式ドキュメント](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [Homebrew Bundle の本体への統合](https://github.com/Homebrew/homebrew-bundle)
- [Universal Ctags の Homebrew パッケージ](https://formulae.brew.sh/formula/universal-ctags)
- [latexmk の公式マニュアル](https://www.cantab.net/users/johncollins/latexmk/latexmk-488.pdf)
