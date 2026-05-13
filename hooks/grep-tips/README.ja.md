# grep-tips

[Claude Code](https://claude.ai/code) の **PreToolUse hook**。`grep` / `rg` / `Grep` 実行前に「grep の盲点」を注意するスニペットを context に注入する。

grep にまつわる 2 種類の False Negative を Claude（と自分）にリマインドする:

1. **「ヒットしない」=「存在しない」ではない** — テキスト検索は re-export / 生成・トランスパイル成果物 / 検索範囲外（archive / binary / `.gitignore` 配下）/ 表記揺れ等を見逃す
2. **「利用箇所を grep していない」=「副作用は無い」ではない** — provider / 定義 / 設定値 / fixture 等を、利用側を先に洗わずに編集するのは、同じ未検証の飛躍

スニペットには検索範囲の実践的チェック（archive 含む / binary 除外 / pipe 上流の事前絞り / stderr 混入）と、「使えるか / 変えたいか / 消して良いか」の意思決定ルールも含まれる。

## ファイル

- `grep-tips-inject.sh` — hook script（bash 約 20 行）
- `grep-tips.md` — `additionalContext` として注入されるスニペット本体

スニペットは script から意図的に分離してある。コードを触らずに guidance だけ編集できる。

## インストール

1. hook script とスニペットをコピー:

   ```bash
   mkdir -p ~/.claude/hooks ~/.claude/snippets
   cp grep-tips-inject.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/grep-tips-inject.sh
   cp grep-tips.md ~/.claude/snippets/
   ```

2. `~/.claude/settings.json` の `hooks.PreToolUse` 配列に登録（既存の同 array にマージ）:

   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "if": "Bash(grep *)",
               "command": "$HOME/.claude/hooks/grep-tips-inject.sh",
               "timeout": 5
             },
             {
               "type": "command",
               "if": "Bash(rg *)",
               "command": "$HOME/.claude/hooks/grep-tips-inject.sh",
               "timeout": 5
             }
           ]
         },
         {
           "matcher": "Grep",
           "hooks": [
             {
               "type": "command",
               "command": "$HOME/.claude/hooks/grep-tips-inject.sh",
               "timeout": 5
             }
           ]
         }
       ]
     }
   }
   ```

3. Claude Code を再起動。

## 仕組み

Claude Code は登録された matcher / 条件にマッチする tool 実行前に PreToolUse hook を発火する。本 hook script はスニペットファイルを読み、以下の JSON を出力する:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "<snippet content>"
  }
}
```

Claude はこの `additionalContext` を受け取り、tool 実行の判断材料に使う。

スニペットファイルが無い場合は status 0 で静かに終了し何も出力しないので、tool 実行は通常通り進む（graceful degradation）。

### Defense-in-depth filtering

hook script は `tool_input.command` 内の subcommand 先頭を自前で正規表現チェックする。`grep` / `rg` が **subcommand の頭にある時のみ** snippet を注入する。commit message / echo の引数 / その他クォートされた文字列に `grep` という単語が含まれていても発火しない。これにより `if:` matcher の edge case に対しても堅牢になる。

検出ルール（正規表現）:
```
(^|(&&|||;||&||))[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*(grep|rg)([[:space:]]|$)
```

pipeline の先頭、または subcommand separator (`&&`, `||`, `;`, `|`, `|&`) の直後にある `grep` / `rg` のみマッチする（オプションで `VAR=value` 環境変数代入を許容）。

## スニペットのカスタマイズ

`~/.claude/snippets/grep-tips.md` を直接編集する。hook script は触らなくて良い。スニペットは呼び出し毎に読み直される。

## このパターンの意義

Hook は **prompt engineering と fine-tuning の間の interface layer** にある。モデルは変えない、リスクのある action の直前にモデルが見る context を変える。小さく、焦点を絞り、version-controlled。

この hook は特定の盲点 1 つを狙ったもの。同じパターンで他の tool / 失敗パターンに対しても guidance を注入できる。

## 作者

kekkeDev — https://x.com/kekke_dev
