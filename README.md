# dotfiles

macOS 用の Zsh、Neovim、Git、LaTeX 設定と補助スクリプト。
deploy は macOS 標準の Bash 3.2 で動作します。

## 導入

リポジトリを任意の場所に clone し、そのディレクトリで実行します。

```sh
./deploy.sh --dry-run
./deploy.sh
```

通常の実行では、配置先と設定ファイルを検証してから、次の順に処理します。

1. Homebrew がなければ公式インストーラで導入し、`brew shellenv bash` で実行環境を読み込みます。
2. このリポジトリの Brewfile に対して `brew bundle` を実行します。
3. 設定へのリンクを作成し、macOS のキー長押しのアクセント選択を無効にします。
   Skim で書類を常にタブで開く設定（`AppleWindowTabbingMode=always`）も適用します。
   Neovim が見つかれば、Skim の `Cmd+Shift+クリック` で原稿へ戻る逆検索も設定します。
   起動中の Skim には再起動後に反映されます。
   `default-apps.tsv` に従い、PDF を Skim、Markdown を Warp で開くように関連付けます。
4. Bluetooth トラックパッド・キーボードのバッテリー確認を毎日22時に実行する設定を登録します。
   残量20%以下で通知します。`~/.config` への手動リンクは不要です。

Homebrew の処理が失敗した場合、設定のリンク・バックアップ・macOS 設定の変更は行いません。
Homebrew 側で途中までインストールされたパッケージは残るため、表示されたエラーを解消して
同じコマンドを再実行してください。

`brew bundle` は既定で既存パッケージの更新も行います。更新を抑えて不足分を導入する場合は、
`HOMEBREW_BUNDLE_NO_UPGRADE=1 ./deploy.sh` を使います。バージョンの固定ではありません。
詳細は [Homebrew Bundle の更新仕様](https://docs.brew.sh/Brew-Bundle-and-Brewfile#brew-bundle-upgrade-and-homebrew_bundle_no_upgrade1)
を参照してください。

Detexify のデスクトップアプリは
[Detexify の Web 版](https://detexify.kirelabs.org/) からダウンロードしてください。

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

`--target` 指定時は既定アプリの関連付けとバッテリー通知の登録を省きます。
Homebrew と他の macOS 設定の変更も省くには、
上記のスキップオプションも指定してください。
配置先の `.`・`..` と既存のシンボリックリンクは解決してから検証します。
ルートディレクトリへの配置（`//` などの別表記を含む）や、リポジトリ内に新しいリンクを
作る配置は受け付けません。`XDG_CONFIG_HOME` も絶対パスで、ルート以外を指定してください。
Brewfile は macOS 用です。macOS 以外では `--skip-brew` でリンクの配置だけを実行できます。

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
`.config` 配下では Neovim、Starship と Bluetooth バッテリー確認スクリプトを Git 管理対象とし、他のアプリの認証情報や
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

## 拡張子ごとの既定アプリ

通常の `./deploy.sh` は、Brewfile で導入する `duti` を使い、
`default-apps.tsv` の関連付けを現在の macOS ユーザーに適用します。
Finder のダブルクリックや `open ファイル名` で利用する既定アプリを設定します。

| 拡張子 | アプリ | Bundle ID |
| --- | --- | --- |
| `.pdf` | Skim | `net.sourceforge.skim-app.skim` |
| `.md`, `.markdown` | Warp | `dev.warp.Warp-Stable` |

追加・変更する場合は `default-apps.tsv` を編集して、deploy を再実行してください。
各行は `.拡張子` とアプリの Bundle ID をタブまたは空白で区切ります。
空行と `#` から始まるコメント行も使えます。例えば `.txt` を Warp で開く場合:

```text
.txt	dev.warp.Warp-Stable
```

アプリの Bundle ID と適用後の関連付けは、次のコマンドで確認できます。

```sh
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' /Applications/Warp.app/Contents/Info.plist
duti -x pdf
duti -x md
```

`--skip-macos` または `--target` 指定時は関連付けを変更しません。
`--dry-run` は `duti -s ...` の実行予定だけを表示し、`duti` が未導入でも確認できます。
`--skip-brew` を使う場合は、先に `duti` と対象アプリを導入してください。
deploy のたびに対応表の設定を適用するため、Finder で手動変更した既定アプリも再設定されます。
macOS は内部的にファイル種別（UTI）で関連付けるため、同じ種別に属する拡張子にも影響することがあります。

仕様は [duti のマニュアル](https://github.com/moretension/duti/blob/master/duti.1)、
Warp での Markdown 表示は [Warp の Markdown Viewer](https://docs.warp.dev/terminal/more-features/markdown-viewer)
を参照してください。

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
| `pdf` | 現在のディレクトリ以下の PDF を fzf で選択し、既定のアプリで開く |
| `pdf -a Dia` | PDF を fzf で選択し、Dia で開く（`-a` でアプリを指定） |
| `pdf -a Skim` | Skim を前面にしてから PDF を開き、既存ウィンドウのタブに追加 |
| `Ctrl-/` | 上記のファイル・ディレクトリ検索でプレビューを開閉 |
| `jk` | vi 挿入モードからコマンドモードへ（入力間隔は 0.2 秒以内） |
| `k` / `j` | vi コマンドモードで履歴の部分一致検索 |
| `Ctrl-N` / `Ctrl-P` | vi 挿入モードで補完・逆順の補完 |

ファイル用プレビューはファイル・ディレクトリ検索にだけ設定し、`Ctrl-R` や
任意のテキストを渡した `fzf` には適用しません。プレビューには Brewfile の bat / eza を使います。
設定変更後は `relogin` または新しいターミナルで反映します。

`pdf -a Skim` のタブ表示には、Skim の `AppleWindowTabbingMode=always` が必要です。
通常の `deploy.sh` で設定します。手動で設定する場合は、Skim を終了してから
`defaults write net.sourceforge.skim-app.skim AppleWindowTabbingMode -string always`
を実行してください。Skim のウィンドウがなければ、最初の PDF は新しいウィンドウで開きます。
詳細は [Skim の設定仕様](https://sourceforge.net/p/skim-app/wiki/Hidden_Preferences/#system-overrides)
を参照してください。

設定の仕様は [Zsh の履歴オプション](https://zsh.sourceforge.io/Doc/Release/Options.html#History)、
[補完の初期化](https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Use-of-compinit)、
[fzf のシェル連携](https://github.com/junegunn/fzf#key-bindings-for-command-line) を参照してください。

## Bluetooth トラックパッド・キーボードの充電通知

別の Mac でも、リポジトリを clone または更新してから次を実行すると、
毎日22時に接続中のトラックパッド・キーボードを確認し、残量20%以下で通知します。

```sh
./deploy.sh
```

通知に必要な `terminal-notifier` も Brewfile から導入します。
`--skip-macos` または `--target` を指定した場合はバッテリー通知を登録しません。
`--skip-brew` を指定する場合は、先に `terminal-notifier` を導入してください。
`--dry-run` では登録予定を表示するだけです。

この機能だけ導入する場合は、専用セットアップも使えます。

```sh
brew install terminal-notifier
bash setup-bluetooth-battery.sh --dry-run
bash setup-bluetooth-battery.sh
```

その Mac のホームディレクトリと clone 先に合わせて LaunchAgent を生成・登録します。
既存の同名 LaunchAgent はバックアップして置き換えます。スクリプトを直接参照するため、
リポジトリは削除せず、移動した場合はセットアップを再実行してください。
従来のユーザー名が固定された `.config/launchd/` の plist をコピーする必要はありません。

残量の確認と通知のテスト（リポジトリのルートで実行）:

```sh
zsh .config/scripts/check_bluetooth_keyboard_battery.sh 20 --dry-run
zsh .config/scripts/check_bluetooth_keyboard_battery.sh 20 --always-notify
```

macOS の「システム設定 → 通知 → terminal-notifier」で通知を許可してください。
残量データを取得できる接続中の機器が対象です。通知の再送は機器ごとに24時間以上あけます。
確認結果は `~/Library/Logs/bluetooth-keyboard-battery.log` に記録します。
この機能は macOS 専用です。

## Codex CLI の通知

`codex-notify.py` は、Codex の応答完了・承認待ち・質問時に macOS へ音なしの通知を送ります。
`terminal-notifier` が必要です（Brewfile に含まれています）。通知の時間による自動削除は
行わず、クリックすると通知センターからも削除します。Warp ではクリック時にアプリを
前面へ出し、`WARP_FOCUS_URL` が有効ならそのターミナルセッションのタブへ移動します。
リンク先のセッションがすでに存在しない場合も、Warp 自体は前面へ出します。

クリックするまで画面に残すには、macOS の「システム設定 → 通知 → terminal-notifier」で
通知スタイルを「通知パネル（Alerts）」にします（OS によっては「持続的」と表示されます）。
「バナー」のままでは、macOS が一定時間後に画面から隠し、通知センターにだけ残します。
この表示設定は `terminal-notifier` を使うほかの通知にも適用されます。

完了通知は `Stop` フックを使い、ローカルの会話記録に同じターンの `task_complete` が
書かれたことを確認してから1回だけ送ります。途中の発言、重複したイベント、すでに次の
ターンが始まった古い完了イベントでは送りません。`notify` 設定はこのスクリプトには
向けず、Computer Use などの既存設定をそのまま利用してください。

ターミナル側の通知・ベルを無効にするには、既存の `[tui]` セクションに設定します。

```toml
[tui]
notifications = false
```

`~/.codex/hooks.json` の `hooks` に以下の設定を追加します。
既存の同名イベントがある場合は、その配列に matcher group を追加してください。

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "python3 /absolute/path/to/dotfiles/codex-notify.py --hook",
        "timeout": 15
      }]
    }],
    "PermissionRequest": [{
      "hooks": [{
        "type": "command",
        "command": "python3 /absolute/path/to/dotfiles/codex-notify.py --hook",
        "timeout": 15
      }]
    }],
    "PreToolUse": [{
      "matcher": "(^|[._:])(request_user_input(_async)?|request_permissions)$",
      "hooks": [{
        "type": "command",
        "command": "python3 /absolute/path/to/dotfiles/codex-notify.py --hook",
        "timeout": 15
      }]
    }]
  }
}
```

追加したフックは Codex の `/hooks` で内容を確認して信頼済みにします。
通知フックは承認や拒否を自動で決めず、通知に失敗しても操作をブロックしません。
通常の文章で質問して応答が終わった場合は「応答完了」、質問ツールを使った場合は
「回答が必要です」と表示します。

完了確認と通知の送信はバックグラウンドで行うため、Codex の操作は待たせません。
重複防止用のハッシュだけを `~/Library/Caches/codex-notify/sent.sqlite3` に7日間保存します。
完了判定は Codex 0.158 のローカル会話記録形式を前提とし、記録を確認できない場合は
誤通知を避けるため完了通知を送りません。

設定後は Codex CLI を起動し直してください。通知が表示されない場合は、macOS の
「システム設定 → 通知 → terminal-notifier」で通知を許可してください。
`deploy.sh` は Codex の設定を変更しません。リポジトリを移動した場合はフックのパスを更新します。

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
再実行、空白を含むパス、旧 `.config` 配置、dry-run、配置先の検証を確認します。
Homebrew が PATH にない場合の環境読込、処理失敗時の設定保持、macOS 設定の実行順序、
既定アプリの関連付けとスキップ条件、macOS 以外でのリンク配置も検証します。
Homebrew や `duti` の呼び出しは代替コマンドを使い、実際のインストールや macOS 設定の変更はしません。
Neovim と Ghostscript がインストールされている場合は、それぞれ設定の読込と PDF 変換も検証します。
Neovim のプラグイン処理はテスト用の代替実装で、外部プラグインは取得しません。

## 参照

- [Homebrew Bundle の公式ドキュメント](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [Homebrew Bundle の本体への統合](https://github.com/Homebrew/homebrew-bundle)
- [Universal Ctags の Homebrew パッケージ](https://formulae.brew.sh/formula/universal-ctags)
- [latexmk の公式マニュアル](https://www.cantab.net/users/johncollins/latexmk/latexmk-488.pdf)
