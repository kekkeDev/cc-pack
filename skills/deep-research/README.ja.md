# Deep Research Skill

Anthropicの[Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)パターンを再現する深掘り調査スキル。

## 設計思想

- **Lead Researcher (Opus)** がクエリを分析・分解し、全体を統括
- **Subagents (Sonnet)** が `claude -p` サブプロセスとして並列に調査を実行
- 結果をLeadが統合し、引用付きMarkdownレポートを出力

## 使い方

Claude Codeで以下のように依頼するだけ:

```
「2026年のAIコーディングエージェント市場を詳しく調べて」
「React vs Svelte vs Solidの比較検証をして」
「LLMのファインチューニング手法をリサーチして」
```

トリガーワード（日本語）: 「詳しく調べて」「リサーチして」「比較検証して」「深掘りして」「調査して」
トリガーワード（英語）: "research X", "deep dive on Y", "compare A vs B", "investigate X in detail"

## 出力言語

サブエージェントは親タスクの目的の言語に合わせて応答します（spawn.shのシステムプロンプトで強制）。日本語で依頼すれば日本語、英語で依頼すれば英語の出力になります。

## 6フェーズ

1. **Scope** — 調査の方向性と範囲を決定
2. **Plan** — 3〜5個のサブタスクに分解（ユーザー承認）
3. **Retrieve** — サブエージェントを並列起動して調査
4. **Triangulate** — 結果の矛盾・重複・信頼度を整理
5. **Synthesize** — 統合レポートを生成
6. **Package** — `./docs/research/` に保存

## 出力

`./docs/research/YYYYMMDD-HHMMSS-slug.md` に保存される。

## 設定

### 環境変数

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `MAX_AGENTS` | 3 | 最大並列サブエージェント数 |
| `CLAUDE_BIN` | claude | claudeバイナリのパス |

### 必要な権限 (settings.json)

```json
"Bash(claude:*)"
```

その他の権限（`jq`, `mkdir`, `date` 等）は既存設定でカバーされていることが多い。

## インストール

`deep-research/` ディレクトリ全体（`scripts/` 含む）を Claude Code のスキルディレクトリにコピー:

```bash
# 個人（グローバル）スキル
mkdir -p ~/.claude/skills/deep-research
cp SKILL.ja.md ~/.claude/skills/deep-research/SKILL.md
cp -r scripts ~/.claude/skills/deep-research/scripts
chmod +x ~/.claude/skills/deep-research/scripts/spawn.sh

# プロジェクトスキル
mkdir -p .claude/skills/deep-research
cp SKILL.ja.md .claude/skills/deep-research/SKILL.md
cp -r scripts .claude/skills/deep-research/scripts
chmod +x .claude/skills/deep-research/scripts/spawn.sh
```

英語版を使う場合は `SKILL.ja.md` の代わりに `SKILL.md` をコピー。

プロジェクトローカルにインストールする場合は、SKILL.md内のspawn.shパスをプロジェクト相対パスに編集してください（デフォルトは `~/.claude/skills/` を想定）。

インストール後、Claude Codeを再起動。

## ファイル構成

```
deep-research/
├── SKILL.md          — Skill (英語)
├── SKILL.ja.md       — Skill (日本語)
├── README.md         — 英語版
├── README.ja.md      — このファイル
└── scripts/
    └── spawn.sh      — 並列spawnヘルパー
```

## コスト目安

- マルチエージェント調査は単一チャットの**約15倍**のトークンを使用
- サブエージェントはSonnet（低コスト）、LeadはOpus（高品質）で最適化済み
- 概算: 3サブタスク × 10〜15ツールコール ≒ $1〜3/調査

## 参考

- [Anthropic: How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)

## 作者

kekkeDev — https://x.com/kekke_dev
