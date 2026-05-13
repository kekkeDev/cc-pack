---
name: ui-repro
description: "Reproduce UI from screenshots with high fidelity using a verbalization-first workflow. Instead of implementing directly from images, this skill verbalizes the target screenshot into precise specs, implements from text only, then iterates by directly comparing target vs current screenshots side-by-side to extract diffs. Use when asked to match a design, reproduce UI from screenshot, or pixel-match a mockup. Triggers: screenshot, reproduce UI, match design, スクショに合わせて, UIを再現, デザイン通りに, 見た目を合わせて"
---

# UI Repro — スクリーンショットベースのUI再現ワークフロー

## 核心ルール

**⚠️ 画像を直接見て実装してはいけない。**
Claudeは画像から直接コードを書くと再現精度が低い（数値が拾えず、似たUIに引きずられ、反復するとドリフトする）。
必ず「画像 → 言語化テキスト → 実装」の順を踏むこと。
言語化テキスト（`_verbalization-original.md`）が**実装の唯一のインプット**である。

### 画像参照の許可・禁止マトリクス

| フェーズ | 元画像 | 現状スクショ | 許可・禁止 |
|---|---|---|---|
| Phase 1（言語化）| ✅ 見る | — | 唯一画像から数値を抽出するフェーズ |
| Phase 1.5（ピクセル採取）| ✅ 計測 | — | 数値で色を確定する（VLM 目視は不正確） |
| Phase 2（実装）| ❌ 禁止 | — | 言語化テキストのみを参照 |
| Phase 3（撮影）| — | — | スクショを取るだけ |
| Phase 4（差分検出）| ✅ 見る | ✅ 見る | **2画像を並べて差分そのものを言語化**する |
| Phase 5（修正）| ❌ 禁止 | ❌ 禁止 | `_diff.md` のテキストのみを参照 |

**Phase 4 の画像参照ルールの趣旨**:
2画像を並べて「どこが違うか」だけを記述する。絶対値（具体的px・色コード）を画像から読み直そうとはしない（それは Phase 1 の役割）。"spot the difference" は VLM が比較的得意なタスクで、Phase 1 言語化の誤読を最終段で補正する**唯一のセーフティネット**。

## スキル発火時の確認事項

以下をユーザーから受け取る or 確認する:

1. **参照スクリーンショット** — ファイルパス or 画像
2. **対象URL** — 例: `http://localhost:3000/page`
3. **開発サーバーが起動中か**
4. **対象viewport** — 幅x高さ（例: 1280x800）。不明なら参照スクショから推定
5. **CSSフレームワーク** — Tailwind, Chakra UI等を使っているか。使っている場合は生のpx/色コードではなくフレームワークのトークン（`text-sm`, `bg-gray-100`等）にマッピングして実装する
6. **ダークモード/テーマ** — CSS変数やテーマトークンを使っているか。使っている場合はハードコードせずテーマに従う

---

## Phase 1: 元スクショの言語化

参照スクリーンショットを読み取り、以下のフォーマットで言語化する。
**「大きめ」「少し」等の曖昧表現は禁止。必ず具体的な数値で記述する。**

### 言語化フォーマット

```
## 全体レイアウト
- 画面構成: （例: 左サイドバー280px + メインコンテンツ）
- 背景色: （例: #F5F5F5）
- 全体の余白: （例: padding 24px）
- コンテンツ最大幅: （例: max-width 960px, 中央寄せ）

## 色定義
- プライマリカラー: #XXXXXX（用途: ）
- セカンダリカラー: #XXXXXX（用途: ）
- テキストカラー: #XXXXXX
- ボーダーカラー: #XXXXXX
- 背景色のバリエーション:

## タイポグラフィ
- 見出し1: font-size XXpx / font-weight XXX / color #XXXXXX / line-height X.X
- 見出し2: font-size XXpx / font-weight XXX / color #XXXXXX / line-height X.X
- 本文: font-size XXpx / font-weight XXX / color #XXXXXX / line-height X.X
- キャプション: font-size XXpx / font-weight XXX / color #XXXXXX
- フォントファミリー: （推定）

## コンポーネント詳細
（各コンポーネントについて以下を記述）
- 位置・サイズ:
- padding / margin:
- border: （例: 1px solid #E0E0E0）
- border-radius:
- box-shadow:
- 背景色:
- テキストスタイル:
- ホバー状態（推定）:

## 要素間の位置関係
- レイアウト方式: （flex / grid / block）
- flex-direction / justify-content / align-items:
- gap: （例: 16px）
- グリッド定義: （例: grid-template-columns: repeat(3, 1fr)）
- 要素の並び順と間隔:

## 特徴的な要素
- アイコン: （種類、サイズ、色）
- 画像: （サイズ、aspect-ratio、object-fit）
- アニメーション（推定）:
- レスポンシブ挙動（推定）:

## 構造決定（必ず二択以上で埋める。曖昧 NG）
> VLM が誤読しやすい構造を**カテゴリカルに確定**する。「なんとなく囲ってる」を許さない。
> 該当する UI 要素ごとに各項目を埋める。

### リスト系（行が複数並ぶ UI ごと）
- 各行の容器: [ ] 個別カード（独立した border / shadow / radius を持つ） / [ ] 共有コンテナ内の行（border-bottom や divider のみ）
- 行間: [ ] gap あり（行が物理的に離れている） / [ ] gap なし（罫線で区切られているだけ）

### セクション群（複数セクションが縦に並ぶ UI ごと）
- 容器: [ ] 1つの大カード内で divider 区切り / [ ] セクションごとに別カード（カード間に gap）
- カード境界が「枠線で連続」か「物理的に分離」かを物理ピクセルで確認すること

### バッジ・タグ
- 形状: [ ] 塗り（背景色 + 文字色）/ [ ] 枠（border + 文字色、背景は透過 or 親と同色）
- 塗りの場合: 背景色 ___ / 文字色 ___（両方必須・どちらが主かを取り違えない）
- 枠の場合: border 色 ___ / 文字色 ___ / 内部背景 ___

### 領域背景（タブ領域、メッセージ領域、コンテンツ領域 など）
- 各領域の背景: [ ] 親と同じ白 / [ ] 透過（外側透ける）/ [ ] 薄グレー / [ ] 他色
- 「白っぽい」は禁止。Phase 1.5 のピクセル計測値で確定する

### ボタン
- [ ] 塗り（filled）/ [ ] 枠（outlined）/ [ ] テキストのみ
- 状態: [ ] enabled / [ ] disabled（disabled は通常薄い）
```

言語化が完了したら、`_verbalization-original.md` としてプロジェクトルートに保存し、Phase 1.5 のピクセル計測結果と整合チェックしてからユーザーに提示して確認を取る。

---

## Phase 1.5: ピクセル色サンプリング

> VLM の弱点: 「白 vs 透過 vs 薄グレー」「塗り vs 枠」の判定はミスりやすい。
> 元画像の主要箇所のピクセル値を物理的に取得し、Phase 1 言語化の色判定を**数値で確定**する。

### やること

`_pixel-samples.mjs` を生成して実行する。元画像の主要な領域の代表座標を選び、ピクセル色をサンプリングする:

```javascript
// _pixel-samples.mjs
import sharp from 'sharp';
import fs from 'fs';

const IMG = process.argv[2]; // 元画像パス

const samples = [
  // { label, x, y } — 元画像の代表点を Phase 1 の構造決定で挙げた要素ごとに 1 点ずつ
  { label: 'ページ背景（コンテンツ外側の余白）', x: 20, y: 20 },
  { label: 'タブ領域の背景', x: 200, y: 100 },
  { label: 'メインカード背景', x: 400, y: 250 },
  { label: 'メッセージ箱の中央', x: 300, y: 150 },
  { label: 'バッジの中央（塗り判定）', x: 500, y: 400 },
  { label: 'バッジの文字部（塗り判定）', x: 503, y: 400 },
  { label: 'バッジの border 上（枠判定）', x: 490, y: 395 },
  { label: 'リスト各行の背景', x: 300, y: 480 },
  { label: 'リスト行間の隙間', x: 300, y: 510 },
  // 必要に応じて追加
];

const { data, info } = await sharp(IMG).raw().toBuffer({ resolveWithObject: true });
const ch = info.channels;
const out = ['# Pixel Samples', '', `> Source: ${IMG}`, `> Size: ${info.width}x${info.height}`, ''];
for (const s of samples) {
  const i = (s.y * info.width + s.x) * ch;
  const [r, g, b] = [data[i], data[i + 1], data[i + 2]];
  const hex = '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('').toUpperCase();
  out.push(`- **${s.label}** @(${s.x}, ${s.y}) → ${hex}  (rgb ${r},${g},${b})`);
}
fs.writeFileSync('_pixel-samples.md', out.join('\n'));
console.log('Wrote _pixel-samples.md');
```

```bash
npm i -D sharp
node _pixel-samples.mjs path/to/original.png
```

### 何を読み取るか

- 「親と同色か違う色か」を **hex の数値で確定**する。`#FFFFFF` と `#F4F4F4` は VLM 目視ではほぼ区別できないが、数値だと一発で違いが分かる
- バッジの中央 vs 端でサンプリングして「塗り or 枠」を判定: 中央と端が同色 → 塗り、中央が親と同色で端が違う → 枠
- リスト各行の背景 vs 行間の隙間が同色 → 共有コンテナ、違う色（隙間が外側ページ色）→ 個別カード

### 整合チェック

Phase 1 の「構造決定」と `_pixel-samples.md` を照合する。矛盾があれば Phase 1 を修正してから Phase 2 へ進む（数値が真）。

---

## Phase 2: 言語化ベースの実装

**⚠️ 元スクリーンショットは参照しない。Phase 1 の言語化テキスト（`_verbalization-original.md`）だけを見て実装する。**

- Phase 1 のテキストに書かれた数値・色・レイアウトを忠実にコードに反映
- CSSフレームワーク使用時は、言語化の数値をフレームワークのトークンに変換して実装（例: `16px` → `p-4`）
- ダークモード/テーマ使用時は、色コードをCSS変数やテーマトークンにマッピング
- 言語化に記載のないスタイルは推測で補わず、一般的なデフォルトを使用
- 実装完了後、開発サーバーで表示確認可能な状態にする

---

## Phase 3: 現状スクショ撮影

Playwrightを使って現在の実装のスクリーンショットを撮影する。

### スクリプト生成・実行

`_screenshot.mjs` を生成して実行する:

```javascript
import { chromium } from 'playwright';
const browser = await chromium.launch();
const page = await browser.newPage();
await page.setViewportSize({ width: WIDTH, height: HEIGHT });
await page.goto('TARGET_URL');
await page.waitForLoadState('networkidle');
await page.screenshot({ path: `_current-${process.env.LOOP_NUM || 1}.png`, fullPage: false });
await browser.close();
```

```bash
LOOP_NUM=1 node _screenshot.mjs   # ループ回数に応じてインクリメント
```

スクショは `_current-1.png`, `_current-2.png`, ... と連番で保存され、改善の経過を追跡できる。

### Playwrightが未インストールの場合

```bash
npm i -D playwright && npx playwright install chromium
```

### file:// フォールバック

localhostが使えない場合は、HTMLファイルを `file://` で直接開く:

```javascript
await page.goto(`file://${process.cwd()}/index.html`);
```

---

## Phase 4: 差分の言語化（2画像直接比較）

**元スクショと最新の現状スクショ（`_current-N.png`）を並べて比較**し、両者の差分そのものを言語化する。
結果は `_diff.md` に保存する（毎ループ上書き）。

### やること

1. 元スクショを Read で開く
2. `_current-N.png`（最新ループ）を Read で開く
3. 2画像の**差分のみ**を観察し、HIGH/MEDIUM/LOW 分類で `_diff.md` に書き出す

### 観察すべき構造項目（必ず元 vs 現で埋める）

> VLM が見落としやすい項目。**「該当なし」「同じだから書かない」を許さない**。
> 各項目について「元: ___ / 現: ___ / 一致 or 差分」を**全項目必須で**書き出す。書かないと気付けない。

| 項目 | 元 | 現 | 一致/差分 |
|---|---|---|---|
| **カードの境界**（独立枠か、1大カード+divider か） | | | |
| **リスト各行の容器**（個別カード or 共有コンテナの行） | | | |
| **タブ領域の背景**（白カード一部 or 透過 or 別色） | | | |
| **メッセージ/インライン箱の背景**（親と同色 or 別色） | | | |
| **バッジ/タグの形状**（塗り bg+文字 or 枠 border+文字） | | | |
| **バッジの色の主従**（背景色 ___ / 文字色 ___） | | | |
| **要素の幅**（full-width / max-width / hug-content） | | | |
| **角丸の系統**（pill / rounded 8-16 / square / circle） | | | |
| **背景色の系統**（white / light-gray / dark） | | | |
| **配置・揃え**（左/中央/右、縦位置の揃い） | | | |
| **要素の有無**（元にあって現にない・逆も） | | | |
| **アイコン形状**（線画 / 塗り / 枠付き） | | | |
| **ボタンの状態系統**（filled / outlined / disabled 風） | | | |

### 出力フォーマット

```
## 差分リスト（Loop N）

### 構造項目スキャン（必須・全項目埋める）
| 項目 | 元 | 現 | 判定 |
|---|---|---|---|
| カードの境界 | 1大カード+divider | 1大カード+divider | 一致 |
| リスト各行の容器 | 個別カード（border あり） | 共有コンテナの行 | **差分** |
| ... | | | |

### HIGH（レイアウト崩れ、構造の不一致、要素の欠落）
- [ ] 差分の説明 — 元: XXX / 現状: YYY
  - **修正方針**: ...

### MEDIUM（サイズ違い、余白の差、フォントウェイトの差）
- [ ] 差分の説明 — 元: XXX / 現状: YYY
  - **修正方針**: ...

### LOW（微細な色差、1-2pxのズレ、推定値のブレ）
- [ ] 差分の説明 — 元: XXX / 現状: YYY
```

### Phase 4 の重要ルール

- **「どこが違うか」だけを記述する**。元画像から絶対値を読み直して `_verbalization-original.md` を上書きしない（数値ドリフトを防ぐ）
- 絶対値の修正が必要な差分（例: 「色が #C8161D のはずが #B81C22 になっている」）が出た場合は、**`_verbalization-original.md` を読み返して原本側の数値を確認**してから修正方針を決める
- 構造項目スキャンは**毎ループ全項目必須**（同じだから省略は不可）。一致を「一致」と書くこと自体が VLM の盲点を顕在化させる
- 構造系の差分（カード境界・タグ形状・背景色系統）が見つかった場合は HIGH 扱い。サイズ違いより構造優先で修正する
- 色判定で迷ったら `_pixel-samples.md` を参照する（数値が真）

---

## Phase 5: 差分ベースの修正

1. **HIGHの差分**から順に修正する
2. 修正は `_diff.md` の差分リストに基づいて行う（画像を見て修正しない）
3. 修正完了後、**ループカウンタをインクリメント**して**Phase 3に戻る**

## ループ管理

ループ回数はスクショの連番で管理する:
- `_current-1.png` → 1ループ目
- `_current-2.png` → 2ループ目
- ...

各ループで以下のファイルが更新される:
- `_current-N.png` — 新規追加（連番）
- `_diff.md` — 上書き

なお `_verbalization-original.md` は **Phase 1 で1回作成して以降は基本不変**。差分修正で原本数値の確認が必要になった時だけ Read して参照する。

---

## 終了条件

以下のいずれかを満たしたらループを終了する:

1. **差分がすべてLOW以下** — 実用上の再現が達成された状態
2. **ユーザーがOKを出した** — ユーザー判断で十分と判断
3. **5ループを超えた** — 一旦停止してユーザーに相談。残りの差分を提示し、続行するか打ち切るかを判断してもらう
