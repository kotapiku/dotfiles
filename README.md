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
macOS ではキー長押しのアクセント選択を無効にし、Skim で書類を常にタブで開く設定
（`AppleWindowTabbingMode=always`）を適用します。

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
Neovim は `.config/nvim/init.lua`、通常の Vim は `.vimrc` を読み込みます。
設定内でリポジトリの場所を解決するため、clone 先やユーザー名が変わっても利用できます。
リポジトリ自体を移動した場合は、移動先の `deploy.sh` を `--force` で再実行して
ホーム側のリンクを更新してください。

Neovim のプラグインは lazy.nvim で管理し、`$XDG_DATA_HOME/nvim/lazy`
（既定は `~/.local/share/nvim/lazy`）に取得します。バージョンは
`.config/nvim/lazy-lock.json` に固定しています。Neovim 0.12.4 以上が必要です。
Neovim は初回起動時にプラグインを取得します。Zsh のプラグインは、導入後に新しいシェルで
`zsh-plugins-install` を実行して取得します。いずれも取得時にはネットワーク接続が必要です。

## Zsh

`.zshenv` には PATH・エディター・ページャーなどの環境変数を置き、
補完・履歴・fzf・プラグインは対話シェル用の `.zshrc` にまとめています。
Starship・mise・zoxide と、既存のエイリアス・vi モードを利用します。

通常の起動では導入済みプラグインを直接読み込み、ダウンロードを行いません。
Zinit は導入・更新などの管理コマンドを使ったときに読み込みます。
プラグイン未導入でも起動でき、vi コマンドモードの `k` / `j` は標準の履歴検索になります。
初回導入や不足しているプラグインの取得は、対話シェルで実行してください。

```sh
zsh-plugins-install
relogin
```

導入先は `$XDG_DATA_HOME/zinit`（既定は `~/.local/share/zinit`）です。
既存の Zinit のプラグインをそのまま利用します。更新は手動で行います。

```sh
zinit self-update
zinit update --all
relogin
```

履歴はメモリー内で最大 20 万件、ファイルに最大 10 万件を保持し、コマンド終了後に追記します。
先頭が空白のコマンドは保存しません。他のターミナルの履歴を自動で取り込む設定は無効です。
補完には Homebrew の補完定義も含め、キャッシュを `$XDG_CACHE_HOME/zsh`
（既定は `~/.cache/zsh`）に置きます。補完ファイルの権限チェックは毎回行います。

| 操作 | 動作 |
| --- | --- |
| `Ctrl-R` | fzf で履歴検索 |
| `Ctrl-T` | ファイルを検索してパスを挿入、bat でプレビュー |
| `Alt-C` | ディレクトリを検索して移動、eza でプレビュー |
| `g` | ghq のリポジトリを検索して移動 |
| `Ctrl-/` | 上記のファイル・ディレクトリ検索でプレビューを開閉 |
| `jk` | vi 挿入モードからコマンドモードへ（入力間隔は 0.2 秒以内） |
| `k` / `j` | vi コマンドモードで履歴の部分一致検索 |
| `Ctrl-N` / `Ctrl-P` | vi 挿入モードで補完・逆順の補完 |

ファイル用プレビューはファイル・ディレクトリ検索にだけ設定し、`Ctrl-R` や
任意のテキストを渡した `fzf` には適用しません。プレビューには Brewfile の bat / eza を使います。
設定変更後は `relogin` または新しいターミナルで反映します。

設定の仕様は [Zsh の履歴オプション](https://zsh.sourceforge.io/Doc/Release/Options.html#History)、
[補完の初期化](https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit)、
[fzf のシェル連携](https://github.com/junegunn/fzf#key-bindings-for-command-line) を参照してください。

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

## `gd` で差分を見る

`gd`（forgit）は、ファイル一覧の下に横幅いっぱいの差分を表示します。
削除行は赤い `-`、追加行は緑の `+` で示し、長い行は折り返します。
`gd` では Git 標準の差分形式を使います。通常の `git diff` は従来どおり Difftastic を使います。
変更後は新しいシェルを開くか、`source ~/.zshrc` で設定を読み直してください。

```sh
gd                 # 未ステージの変更
gd --staged        # ステージ済みの変更
gd HEAD~1 HEAD     # コミット間の変更
```

- `↑` / `↓`: ファイルを選択
- `Ctrl-D` / `Ctrl-U`: 差分をページ単位でスクロール
- `Alt-W`: 長い行の折り返しを切り替え
- `Enter`: 選択したファイルの差分を全画面表示（`q` で一覧へ戻る）
- `Esc`: 終了

設定は `.zshrc` の `FORGIT_DIFF_GIT_OPTS` と `FORGIT_DIFF_FZF_OPTS` にあります。
[forgit の設定仕様](https://github.com/wfxr/forgit#options) と
[Difftastic のコマンド単位での切り替え](https://difftastic.wilfred.me.uk/git.html#difftastic-by-default)
に沿って設定しています。

## Markdown をブラウザで表示する

Node.js が使える環境では、表示したい Markdown ファイルのあるディレクトリで
`md` を実行すると、ブラウザで Markdown をプレビューできます。

```sh
md                  # 8521 が使用中なら、8522 以降の空きポートで起動
md --port 9000      # ポートを明示して起動（短縮形: md -p 9000）
md ./docs           # 指定したディレクトリを表示
```

ローカルサーバーが起動してブラウザが自動で開き、現在のディレクトリ内の Markdown を
ツリーから選んで表示できます。`md` は `npx mdts --port auto` のエイリアスで、
既定の `8521` が使用中なら最大 `8531` まで順に試します。`--port` で番号を指定した場合は、
そのポートを使用します。
変更後は新しいシェルを開くか、`source ~/.zshrc` で設定を読み直してください。
詳しくは [mdts の公式 README](https://github.com/unhappychoice/mdts) を参照してください。

## LaTeX

`.latexmkrc` は pdfLaTeX 用です。プロジェクトのディレクトリで、配置場所に合わせて実行します。

```sh
latexmk -r /path/to/dotfiles/.latexmkrc main.tex
```

pLaTeX 用は `.latexmkrc_platex` を指定します。
標準の `.latexmkrc` は従来どおり `-shell-escape` を有効にしています。
Neovim の設定が使う Universal Ctags と TexLab は Brewfile に含めています。
LaTeX・Markdown の設定と更新方法は [Neovim の README](.config/nvim/README.md) を参照してください。

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
