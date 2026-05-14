---
name: deep-research
description: Anthropicのmulti-agent research patternを再現する深掘り調査スキル。複雑なクエリを並列サブエージェントで分担調査し、引用付きレポートをMarkdownで出力する。「詳しく調べて」「リサーチして」「比較検証して」「深掘りして」「調査して」などの自然言語で発火する。
allowed-tools: Bash(claude:*), Bash(jq:*), Bash(date:*), Bash(mkdir:*), Bash(cat:*), Bash(echo:*), Write, Read, WebSearch, WebFetch
---

# Deep Research Skill

Anthropicの[multi-agent research pattern](https://www.anthropic.com/engineering/multi-agent-research-system) (Lead Researcher + 並列Subagents) を `claude -p` サブプロセス呼び出しで再現する。

## 動作フロー (6フェーズ)

### Phase 1: Scope

ユーザークエリを分析し、以下を決定する:

- 調査の目的と期待されるアウトプット形式
- 調査範囲の境界（何を含め、何を除外するか）
- 必要なサブタスク数の見積もり（3〜5個）
- 出力ファイルのslug（英語kebab-case、例: `ai-coding-agents-comparison`）

### Phase 2: Plan

クエリをMECE気味に3〜5個の独立したサブタスクに分解する。各サブタスクには以下を定義:

- サブタスク番号とタイトル
- 調査すべき具体的な問い
- スコープ境界（他サブタスクとの重複回避）
- 期待する成果物

分解案をユーザーに提示し、承認を得てから次へ進む。

### Phase 3: Retrieve

`~/.claude/skills/deep-research/scripts/spawn.sh` を使って並列にサブエージェントを起動する。

```bash
bash ~/.claude/skills/deep-research/scripts/spawn.sh \
  "SESSION_ID" \
  "親タスクの全体目的" \
  "サブタスク1の指示" \
  "サブタスク2の指示" \
  "サブタスク3の指示"
```

- 第1引数: セッションID（`date +%Y%m%d-%H%M%S` で生成）
- 第2引数: 親タスクの全体目的（全サブエージェントに共有）
- 第3引数以降: 各サブタスクのプロンプト

**最大並列度**: 環境変数 `MAX_AGENTS` で制御（デフォルト3）

各サブエージェントには以下が自動的に含まれる:
- 親タスクの全体目的
- 担当するサブトピックとスコープ境界
- 出力形式（JSON: `findings` 配列、各findingに `claim`, `source_url`, `confidence` 必須）
- WebSearch/WebFetchを積極的に使う指示
- ツールコール10〜15回程度の制限
- 信頼度マーク（`high`/`medium`/`low`）の付与指示

spawn.sh完了後、`/tmp/deep-research-SESSION_ID/` 配下に各サブタスクの結果JSONが出力される。

### Phase 4: Triangulate

各サブタスクの結果JSONを読み込み、以下を整理する:

```bash
for f in /tmp/deep-research-SESSION_ID/task-*.json; do
  jq -r '.result // empty' "$f"
done
```

整理観点:
- 複数ソースで裏付けられたclaim → 信頼度を上げる
- 矛盾するclaim → 両論併記としてフラグ
- 単一ソースのみのclaim → 信頼度を下げる
- 重複するfindingsの統合
- ソースの信頼度評価（公式ドキュメント > ニュース > ブログ > SNS）

### Phase 5: Synthesize

Lead(自身)が全findingsを統合し、構造化されたMarkdownレポートを生成する。

レポート構成:
```markdown
# [タイトル]

> 調査日: YYYY-MM-DD | サブタスク数: N | ソース数: N

## エグゼクティブサマリー
（3〜5文で結論を先に）

## 1. [セクション1タイトル]
...

## 2. [セクション2タイトル]
...

## 矛盾点・未解決の問い
（Triangulateで見つかった矛盾や追加調査が必要な点）

## 出典
1. [タイトル](URL) — 信頼度: high/medium/low
2. ...
```

### Phase 6: Package

1. 出力ディレクトリを作成:
```bash
mkdir -p ./docs/research
```

2. レポートを保存:
```bash
# ファイル名: YYYYMMDD-HHMMSS-slug.md
```

3. ユーザーにファイルパスを報告し、レビューを促す

## 失敗時の挙動

- サブエージェントが失敗した場合: スキップし、最終レポートに `[サブタスクN: 失敗 — 理由]` として記録。全体は停止させない。
- タイムアウト（5分以上応答なし）: 他のサブエージェントは継続、未完了分は除外してレポート生成。
- 全サブエージェント失敗: ユーザーに報告し、単一エージェントでのフォールバック調査を提案。

## 注意事項

- サブエージェントは `--model sonnet` で起動（コスト最適化）
- Lead(自身)はOpusで動作する想定
- トークンコスト: マルチエージェントは単一チャットの約15倍のトークンを使用する。コスト意識を持つこと。
- 出力言語は親タスクの目的の言語に合わせる（spawn.shのサブエージェントプロンプトで強制）
