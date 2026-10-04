# LaTeX・Markdown 用 Neovim 設定

操作方法とキーの一覧は **[KEYBINDINGS.md](KEYBINDINGS.md)** を参照してください。
コンパイル・PDF との往復に加えて、検索・置換・バッファ操作などもまとめています。

`init.lua` が Neovim 専用の設定を読み込みます。通常の Vim は `../../.vimrc` を使います。
LaTeX のプラグイン設定は `lua/plugins/tex.lua`、バッファ固有の設定は
`after/ftplugin/tex.vim` にあります。
コンパイルには VimTeX と latexmk、PDF の表示には Skim を使います。

## セットアップと構成

Neovim 0.12.4 以上と macOS を想定しています。検証環境は Neovim 0.12.5、
fzf 0.74.4、TexLab 5.25.1、VimTeX v2.18、LuaSnip v2.4.1 です。

```sh
brew install neovim fzf ripgrep texlab universal-ctags
# すでに導入済みなら、必要に応じて更新
brew upgrade neovim fzf
```

コンパイル用の MacTeX と PDF 表示用の Skim も必要です。これらは Brewfile に含まれます。
初回起動時に lazy.nvim がプラグインを取得します。`:Lazy` で状態を確認できます。

| ファイル | 内容 |
| --- | --- |
| `init.lua` | 読み込みの入口。VS Code では専用設定へ切り替え |
| `lua/dotfiles/options.lua` | 基本設定・文章用のスペルチェック |
| `lua/dotfiles/keymaps.lua` | 共通キー・設定を開くコマンド |
| `lua/dotfiles/lazy.lua` | プラグイン管理 |
| `lua/plugins/appearance.lua` | Nord・Airline・which-key |
| `lua/plugins/search.lua` | fzf-lua による検索 |
| `lua/plugins/git.lua` | gitsigns の表示と操作 |
| `lua/plugins/editing.lua` | 囲み編集・括弧補完・Previm・ローカル設定 |
| `lua/plugins/tex.lua` | VimTeX・LuaSnip |
| `lazy-lock.json` | プラグインの検証済みコミット |

プラグイン本体は `stdpath('data')/lazy`（通常 `~/.local/share/nvim/lazy`）に置きます。
旧 dein キャッシュは新構成から参照しません。Rust・Lean・Coq・Haskell・Egison などの
専用プラグインは外し、LaTeX と Markdown に絞っています。TOML の色付けとコメント切替は
Neovim 標準機能を使います。

## 検索とキー案内

従来の `,f`・`,b`・`,l` などは fzf-lua で使えます。`,r` はプロジェクト内の全文検索、
`,d` / `,D` は診断、`,s` は文書内のシンボル、`,R` は参照検索です。
`\`・Space・`,` から始まるキーを入力して少し待つと which-key が候補を表示します。
`\?` で現在のバッファに関連するキーを確認できます。

Markdown のブラウザプレビューは `:PrevimOpen`。macOS の既定ブラウザを開きます。
`\c` は標準のコメント切替に接続し、`gcc`・選択中の `gc` もそのまま使えます。
文章中の `j/k/0/$` は折り返し行を考慮し、`3j` などの回数指定とコード中の移動は
原稿の実際の行を基準にします。

## 見た目

ターミナル版 Neovim は、青みのあるグレーの Nord テーマを使います。
ステータスラインとバッファ一覧も同じ配色で、三角形の区切りや重複する表示を省いています。
見た目の調整は `appearance.vim`、Airline の設定は `lua/plugins/appearance.lua` にあります。

- 上部のタブはファイルが1つでも表示します。選択中は水色の太字、背景は暗い青灰色です。
  Neovim では開いているファイルを余白で区切り、未保存のファイルは `●` と黄色で区別します。
  同名ファイルはディレクトリ名を補って表示します。通常の Vim では標準タブに同じ配色を使います。
- 現在行を淡く強調し、行番号と Git の変更記号のための幅を固定します。
- カーソルは淡い黄色にし、暗い背景や本文から見つけやすくします。
- 背景を暗い青灰色、本文を白に近い色にし、コマンド・コメント・行番号も明るくして読みやすくします。
  選択範囲・対応する括弧・折りたたみ表示も、文字と背景の明暗差を確保します。
- 検索中の一致箇所は淡い黄色で区別します。
- スペルチェックは文字色を変えず、控えめな青灰色の波線で表示します。
- 行末の余分な空白を表示し、折り返し行には `↳` を付けます。タブは通常の空白として表示します。
- LaTeX の `\begin`・`\end` を水色の太字、環境名を淡い黄色の太字にします。
  節見出しも太字にし、ラベルや引用の参照先は緑で区別します。
- 補完メニューの高さを抑え、対応する Neovim では浮動ウィンドウの角を丸くします。

変更を反映するには Neovim を再起動してください。通常の Vim では `:source ~/.vimrc` も使えます。
通常の Vim や Nord の取得前は同梱の Hybrid にフォールバックし、同じコントラスト調整を適用します。
True Color と256色の両方に配色を指定しています。VS Code 用設定の配色は VS Code 側のテーマで指定します。

## 普段の操作

以下は TeX バッファで使えます。`\` はバックスラッシュです。

| キー | 操作 |
| --- | --- |
| `\ll` | 継続コンパイルの開始・停止。開始後は保存すると再コンパイル |
| `\lv` / `Ctrl+Alt+j` | 原稿の現在位置を Skim の PDF で表示 |
| `\lt` | 目次から節・章へ移動 |
| `\le` | コンパイルエラーを表示 |
| `\lo` | コンパイラの出力を表示 |
| `\li` | メインファイル・使用コマンドなどの状態を表示 |
| `gd` | ラベルなどの定義へ移動（TexLab を優先。複数候補なら選択） |
| `Ctrl+t` | タグ移動前の位置へ戻る |
| TeX を入力中 | `\cite{`・`\ref{`・コマンドなどの補完候補を自動表示 |
| 補完中に `Ctrl+n` / `Ctrl+p` | 次／前の候補へ移動 |
| 補完中に `Ctrl+y` / `Ctrl+e` | 候補を確定／補完をキャンセル |
| 挿入モードで `]]` | 現在の環境・区切りを閉じる |
| `\lm` | 数式入力用の省略キー一覧を表示 |

補完候補は入力が約120ミリ秒止まると表示され、選ぶまでは本文に挿入しません。
Neovim 標準の `autocomplete` で VimTeX の候補を表示します。
候補の絞り込みでは、大文字・小文字を区別しません。`/`・`?` の検索では区別します。
`Ctrl+x` → `Ctrl+o` で手動表示することもできます。
ラベル補完はコンパイル後の `.aux` を使うため、最初に一度コンパイルしてください。
ラベルへの移動は `\ref{...}` の中のラベル名にカーソルを置いて `gd` を押します。
TexLab の定義検索を優先し、候補がない場合は自動生成する `tags` ファイルにフォールバックします。
`Ctrl+Alt+j` が端末に認識されない場合も `\lv` で同じ操作ができます。
TeX は単語の途中を避けて画面上で折り返し、スペルチェックを有効にします。
折り返しによって原稿に改行を書き込むことはありません。

## Skim のタブで PDF を開く

`\ll` の初回コンパイル後と `\lv` では、Skim を前面にしてから PDF を開きます。
macOS の「書類を開くときはタブで開く」を「常に」にすると、既存ウィンドウに
タブとして追加されます。Skim だけに設定する場合は、Skim を終了してから次を実行します。

```sh
defaults write net.sourceforge.skim-app.skim AppleWindowTabbingMode -string always
```

表示処理は `autoload/vimtex/view/skim_tabs.vim` にあり、VimTeX の Skim ビューアーを
継承しています。保存後の PDF 更新と SyncTeX による往復は引き続き利用できます。
変更を反映するには Neovim を再起動してください。

## Skim から原稿へ戻る

Skim の設定 → Sync → PDF-TeX Sync を Custom にして設定します。

```text
Command:   /opt/homebrew/bin/nvim
Arguments: --headless -c "VimtexInverseSearch %line '%file'"
```

PDF の本文を `Shift+Command+クリック` すると編集中の Neovim に戻ります。
対象の原稿が別タブにある場合も、そのタブとウィンドウを選んで該当行へ移動します。
タブバーに残っている非表示のバッファも対象です。
macOS の Warp 内で起動した Neovim では、ジャンプ成功時に Warp も前面に出します。
`VimtexEventViewReverse` を使うため、対象外の原稿への要求では切り替えません。
`autoload/vimtex/view.vim` で原稿のバッファを選んでから、VimTeX の逆検索を呼びます。
VimTeX は、原稿を開かず起動した Neovim にも逆検索コマンドが必要なので、
プラグインマネージャーによる遅延読み込みをしません。`nvr` は不要です。

## メインファイルとコンパイル方式

分割した原稿には、必要に応じて先頭にメインファイルを指定します。

```tex
% !TeX root = main.tex
```

エンジンはプロジェクトの `.latexmkrc` またはメインファイルの指定に従います。
例えば LuaLaTeX なら以下を使えます。

```tex
% !TeX program = lualatex
```

## スニペット・折りたたみ・TexLab

- **LuaSnip v2.4.1**：`ff`・`ali` など10個の LaTeX 用スニペットを用意しています。
  `Tab` で展開・次の入力欄、`Shift+Tab` で前の入力欄へ移動します。
  数式用のスニペットは数式内だけで展開します。
- **VimTeX の折りたたみ**：最初は全て表示し、`za` で開閉、`zM` / `zR` で全体を閉じる／開きます。
  ファイルを開く際の待ち時間を減らすため、範囲は最初に折りたたみキーを押した時点で計算します。
  以後は手動更新とし、構造の編集後は `zx` で範囲を再計算します。
- **TexLab**：Neovim 標準の LSP クライアントを使います。`gd` と `Ctrl+t` はタグ履歴を保って移動し、
  `grr` で参照検索、`grn` でラベルなどの一括変更ができます。
  コンパイル・PDF 表示は VimTeX、TeX のオムニ補完も VimTeX が担当します。

新しい環境でセットアップする際は `brew install texlab` を実行してください。
LuaSnip は lazy.nvim が取得します。必要なら `:Lazy restore` を実行して Neovim を再起動します。
接続確認は `:checkhealth vim.lsp`。`.tex` は VimTeX のメイン原稿のフォルダを基準に接続します。

設定は `lua/dotfiles/tex.lua` と `lua/dotfiles/tex_snippets.lua`、
折りたたみの有効化は `lua/plugins/tex.lua`、初回計算の制御は `autoload/dotfiles/tex_fold.vim` にあります。
略語一覧や診断メッセージの操作は [KEYBINDINGS.md](KEYBINDINGS.md) を参照してください。

参考：[LuaSnip](https://github.com/L3MON4D3/LuaSnip)、
[TexLab の設定](https://github.com/latex-lsp/texlab/wiki/Configuration)、
[VimTeX](https://github.com/lervag/vimtex)。

## tags の自動生成

Universal Ctags が必要です。未導入なら `brew install universal-ctags` を実行してください。
macOS 標準の `/usr/bin/ctags` は使いません。

- `.tex` を開いたとき、`tags` がなければ生成します。既存ならそのまま使います。
- `.tex` を保存した後、プロジェクト内の TeX ファイルを再走査して更新します。
- 更新はバックグラウンドで行い、生成に成功してから `tags` を置き換えます。
  連続保存中も、最後に保存した内容まで反映します。

生成先は VimTeX が認識するメインファイルのフォルダです。分割原稿から開く場合は
上記の `% !TeX root = ...` でメインファイルを指定できます。
VimTeX がない場合は、現在のファイルから上へ探した最寄りの `tags` または `.git` がある
フォルダを使い、どちらもなければ現在のファイルのフォルダに生成します。
新規ファイルは初回保存後に生成します。TexLab の候補がない場合も、生成後は `gd` でタグ移動できます。
設定本体は `autoload/dotfiles/tex_tags.vim`、実行のタイミングは `after/ftplugin/tex.vim` にあります。

## 復旧と更新

Neovim は swap と永続 undo を使います。保存先は Neovim 標準の
`stdpath('state')` 以下です（通常 `~/.local/state/nvim/swap` と `undo`）。
異常終了時の未保存内容は swap から復旧でき、保存した編集履歴は再起動後も
`u` / `Ctrl+r` でたどれます。

全プラグインのコミットを `lazy-lock.json` で Git 管理します。

- 新しい環境の復元：`:Lazy restore`
- 更新候補を確認して更新：`:Lazy` の画面から対象を選択（全体は `:Lazy update`）
- 設定を開く：`:Vimrc`、プラグイン設定は `:Plugins`
- 状態の確認：`:checkhealth lazy vim.lsp vimtex fzf-lua`

VimTeX は v2.18、LuaSnip は v2.4.1 に固定しています。この2つを更新するときは
`lua/plugins/tex.lua` の `version` を変更し、`:Lazy update` を実行してください。
[VimTeX の要件](https://github.com/lervag/vimtex#requirements) と Neovim のバージョンを
確認し、コンパイル・ラベル補完・数式スニペット・Skim 往復を確認してから
`lazy-lock.json` の差分を採用します。動作に問題があればロックファイルを以前の内容に戻し、
`:Lazy restore` でプラグインを復元できます。

プラグインマネージャーで VimTeX を遅延読み込みしないでください。
また、数式スニペットが VimTeX の構文判定を使うので、TeX のハイライトは VimTeX に任せます。

## 自動検証

通常のリポジトリテストはプラグインの取得なしで実行できます。
実際のプラグインを使った検証は、取得済みの XDG データディレクトリを指定します。

```sh
python3 -m unittest discover -s tests -v
DOTFILES_NVIM_TEST_DATA="${XDG_DATA_HOME:-$HOME/.local/share}" \
  python3 -m unittest discover -s tests -p test_neovim.py -v
```

後者は一時原稿で TexLab・タグ・スニペット・コンパイル・ラベル補完・キー操作を確認します。
GUI は開かないため、Skim の画面上での往復は別途確認してください。
