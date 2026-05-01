# cc-skills

[Claude Code](https://claude.ai/code) 用のカスタムスキル集。

## スキル一覧

| スキル | 説明 |
|---|---|
| [ui-repro](./ui-repro/) | スクリーンショットからUIを高精度に再現する言語化ファーストのワークフロー |

## インストール

`SKILL.md` をClaude Codeのスキルディレクトリにコピー:

```bash
# 個人（グローバル）スキル — 全プロジェクトで利用可能
mkdir -p ~/.claude/skills/<スキル名>
cp <スキル名>/SKILL.md ~/.claude/skills/<スキル名>/SKILL.md

# プロジェクトスキル — 特定プロジェクトでのみ利用可能
mkdir -p .claude/skills/<スキル名>
cp <スキル名>/SKILL.md .claude/skills/<スキル名>/SKILL.md
```

日本語版は `SKILL.ja.md` として用意しています。

インストール後、Claude Codeを再起動してください。

## 作者

kekkeDev — https://x.com/kekke_dev
