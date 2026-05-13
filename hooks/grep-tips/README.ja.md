# grep-tips

[Claude Code](https://claude.ai/code) の **PreToolUse hook**。`grep` / `rg` / `Grep` 実行前に「grep の盲点」を注意するスニペットを context に注入する。

「grep にヒットしない = 存在しない」の誤推論を防ぐ。grep が見逃すもの:

- catch-all 系の一括公開 / re-export / autoload / 動的読み込み
- 生成・トランスパイル・minify 等の変換成果物
- 検索範囲外（バイナリ、`.gitignore` 配下、別パッケージ・別 layer）
- 表記揺れ（case・encoding・パス階層）

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

## スニペットのカスタマイズ

`~/.claude/snippets/grep-tips.md` を直接編集する。hook script は触らなくて良い。スニペットは呼び出し毎に読み直される。

## このパターンの意義

Hook は **prompt engineering と fine-tuning の間の interface layer** にある。モデルは変えない、リスクのある action の直前にモデルが見る context を変える。小さく、焦点を絞り、version-controlled。

この hook は特定の盲点 1 つを狙ったもの。同じパターンで他の tool / 失敗パターンに対しても guidance を注入できる。

## 作者

kekkeDev — https://x.com/kekke_dev
