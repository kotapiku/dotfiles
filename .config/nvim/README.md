# LaTeX 用 Neovim 設定

操作方法とキーの一覧は **[KEYBINDINGS.md](KEYBINDINGS.md)** を参照してください。
コンパイル・PDF との往復に加えて、検索・置換・バッファ操作などもまとめています。

`init.vim` は共有の `../../.vimrc` を読み込みます。LaTeX のプラグイン設定は
`dein/toml/dein.toml`、バッファ固有の設定は `after/ftplugin/tex.vim` にあります。
コンパイルには VimTeX と latexmk、PDF の表示には Skim を使います。

## 見た目

ターミナル版 Neovim は、青みのあるグレーの Nord テーマを使います。
ステータスラインとバッファ一覧も同じ配色で、三角形の区切りや重複する表示を省いています。
見た目の調整は `appearance.vim`、Airline の設定は `dein/toml/dein.toml` にあります。

- 現在行を淡く強調し、行番号と Git の変更記号のための幅を固定します。
- コメントは少し明るくし、検索中の一致箇所は淡い黄色で区別します。
- スペルチェックは文字色を変えず、控えめな青灰色の波線で表示します。
- 行末の余分な空白を表示し、折り返し行には `↳` を付けます。タブは通常の空白として表示します。
- LaTeX の `\begin`・`\end` を水色の太字、環境名を淡い黄色の太字にします。
  節見出しも太字にし、ラベルや引用の参照先は緑で区別します。
- 補完メニューの高さを抑え、対応する Neovim では浮動ウィンドウの角を丸くします。

変更を反映するには Neovim を再起動してください。Nord の取得前は同梱の Hybrid に
フォールバックします。VS Code 用設定の配色は VS Code 側のテーマで指定します。

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
| 挿入モードで `Ctrl+x` → `Ctrl+o` | `\cite{`・`\ref{`・コマンドなどの補完 |
| 挿入モードで `]]` | 現在の環境・区切りを閉じる |
| `\lm` | 数式入力用の省略キー一覧を表示 |

ラベル補完はコンパイル後の `.aux` を使うため、最初に一度コンパイルしてください。
ラベルへの移動は `\ref{...}` の中のラベル名にカーソルを置いて `gd` を押します。
こちらは `.aux` ではなく、自動生成する `tags` ファイルを使います。
`Ctrl+Alt+j` が端末に認識されない場合も `\lv` で同じ操作ができます。
TeX は単語の途中を避けて画面上で折り返し、スペルチェックを有効にします。
折り返しによって原稿に改行を書き込むことはありません。

## Skim から原稿へ戻る

Skim の設定 → Sync → PDF-TeX Sync を Custom にして設定します。

```text
Command:   /opt/homebrew/bin/nvim
Arguments: --headless -c "VimtexInverseSearch %line '%file'"
```

PDF の本文を `Shift+Command+クリック` すると編集中の Neovim に戻ります。
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
  大きな原稿向けに手動更新とし、構造の編集後は `zx` で範囲を再計算します。
- **TexLab**：Neovim 標準の LSP クライアントを使います。`gd` と `Ctrl+t` はタグ履歴を保って移動し、
  `grr` で参照検索、`grn` でラベルなどの一括変更ができます。
  コンパイル・PDF 表示は VimTeX、TeX のオムニ補完も VimTeX が担当します。

新しい環境でセットアップする際は `brew install texlab` を実行してください。
LuaSnip は dein が取得します。必要なら `:call dein#install()` を実行して Neovim を再起動します。
接続確認は `:checkhealth vim.lsp`。`.tex` は VimTeX のメイン原稿のフォルダを基準に接続します。

設定は `lua/dotfiles/tex.lua` と `lua/dotfiles/tex_snippets.lua`、
折りたたみの有効化は `dein/toml/dein.toml` にあります。
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

VimTeX は、Neovim 0.11.3 と組み合わせて検証した既存のコミット
`877de3ba5de5f766e5bfa1c3fb0d2ecfcd18f868` に固定しています。
Neovim と VimTeX を更新する際は、[VimTeX の要件](https://github.com/lervag/vimtex#requirements)
を確認してから `dein.toml` の `rev` を変更してください。
変更後は `:call dein#update(['vimtex'])` → `Enter` で取得し、コンパイル・補完・PDF 往復を確認します。
