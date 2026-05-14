# claude-rules

[Claude Code](https://claude.ai/code) 向けに整理された、実運用ベースの行動ルール集。コミュニケーション規律（前提の明示、トレードオフの透明性、診断ファースト）と安全性（不可逆操作、スコープ付き設定）をカバーします。

[Andrej Karpathy のLLMコーディング観察](https://x.com/karpathy/status/2015883857489522876) と [Forrest Chang による整理](https://github.com/forrestchang/andrej-karpathy-skills) に着想を得つつ、Claude Code の組み込みシステムプロンプトと重複する項目は除いています。

## インストール

`CLAUDE.md`（または日本語版 `CLAUDE.ja.md`）を Claude Code のグローバル設定ディレクトリにコピー:

```bash
cp CLAUDE.ja.md ~/.claude/CLAUDE.md
```

既存ルールがある場合は上書きせず手動でマージしてください。

インストール後、Claude Code を再起動。

## Tip: 自分の環境に合わせて具体化を

このルール集は環境依存性を抑えるため抽象表現で書かれています。**LLMは抽象的な指示よりも具体的な指示の方が安定して従います**。実際に自分の環境で使う際は、抽象表現を自分のスタックの具体名に置き換えることを推奨します。

例：
- 「ユーザー個人やシステム全体に及ぶ設定は変更しない」 → 「`git config --global` を実行しない、`~/.zshrc` を編集しない、環境変数を永続的に export しない」
- 「記録・永続化は別途確認」 → 「`memory/` / `CLAUDE.md` / 保存された `notes/` ファイルの更新は別途確認」

公開版は普遍的なベースライン。具体化することで初めて実際の挙動制御に効きます。

## 言語

- `CLAUDE.md` — English
- `CLAUDE.ja.md` — 日本語

## 作者

kekkeDev — https://x.com/kekke_dev
