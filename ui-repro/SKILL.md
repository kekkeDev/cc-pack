---
name: ui-repro
description: "Reproduce UI from screenshots with high fidelity using a verbalization-first workflow. Instead of implementing directly from images, this skill verbalizes the target screenshot into precise specs, implements from text only, then iterates by directly comparing target vs current screenshots side-by-side to extract diffs. Use when asked to match a design, reproduce UI from screenshot, or pixel-match a mockup. Triggers: screenshot, reproduce UI, match design"
---

# UI Repro — Screenshot-Based UI Reproduction Workflow

## Core Rule

**⚠️ Never implement directly from images.**
LLMs produce low-fidelity results when coding directly from screenshots — they fail to capture exact values, drift toward similar-looking UIs, and accumulate errors across iterations.
Always follow the sequence: **Image → Verbalization (text) → Implementation**.
The verbalization text (`_verbalization-original.md`) is the **sole input for implementation**.

### Image Reference Permission Matrix

| Phase | Target Image | Current Screenshot | Permission |
|---|---|---|---|
| Phase 1 (Verbalize) | ✅ View | — | The only phase that extracts values from image |
| Phase 1.5 (Pixel Sample) | ✅ Measure | — | Confirm colors with numeric values (VLM visual inspection is inaccurate) |
| Phase 2 (Implement) | ❌ Forbidden | — | Refer only to verbalization text |
| Phase 3 (Capture) | — | — | Just take a screenshot |
| Phase 4 (Diff Detection) | ✅ View | ✅ View | **Compare 2 images side-by-side to verbalize diffs** |
| Phase 5 (Fix) | ❌ Forbidden | ❌ Forbidden | Refer only to `_diff.md` text |

**Phase 4 Image Reference Rule**:
Compare 2 images and describe only "what's different." Do not re-read absolute values (specific px/color codes) from images — that's Phase 1's job. "Spot the difference" is a task VLMs handle relatively well, serving as the **only safety net** to correct Phase 1 misreadings.

## Pre-flight Checklist

Collect or confirm the following from the user:

1. **Reference screenshot** — file path or image
2. **Target URL** — e.g., `http://localhost:3000/page`
3. **Is the dev server running?**
4. **Target viewport** — width × height (e.g., 1280×800). Estimate from screenshot if unknown
5. **CSS framework** — Tailwind, Chakra UI, etc. If used, map to framework tokens (`text-sm`, `bg-gray-100`) instead of raw px/color codes
6. **Dark mode / Theming** — If CSS variables or theme tokens are used, map to them instead of hardcoding

---

## Phase 1: Verbalize the Target Screenshot

Read the reference screenshot and verbalize it using the format below.
**Vague expressions like "large" or "slightly" are forbidden. Always use specific numeric values.**

### Verbalization Format

```
## Overall Layout
- Screen structure: (e.g., left sidebar 280px + main content)
- Background color: (e.g., #F5F5F5)
- Overall padding: (e.g., padding 24px)
- Content max-width: (e.g., max-width 960px, centered)

## Color Definitions
- Primary color: #XXXXXX (usage: )
- Secondary color: #XXXXXX (usage: )
- Text color: #XXXXXX
- Border color: #XXXXXX
- Background color variations:

## Typography
- Heading 1: font-size XXpx / font-weight XXX / color #XXXXXX / line-height X.X
- Heading 2: font-size XXpx / font-weight XXX / color #XXXXXX / line-height X.X
- Body: font-size XXpx / font-weight XXX / color #XXXXXX / line-height X.X
- Caption: font-size XXpx / font-weight XXX / color #XXXXXX
- Font family: (estimated)

## Component Details
(For each component, describe:)
- Position / size:
- padding / margin:
- border: (e.g., 1px solid #E0E0E0)
- border-radius:
- box-shadow:
- background color:
- text style:
- hover state (estimated):

## Element Relationships
- Layout method: (flex / grid / block)
- flex-direction / justify-content / align-items:
- gap: (e.g., 16px)
- grid definition: (e.g., grid-template-columns: repeat(3, 1fr))
- Element order and spacing:

## Distinctive Elements
- Icons: (type, size, color)
- Images: (size, aspect-ratio, object-fit)
- Animations (estimated):
- Responsive behavior (estimated):

## Structural Decisions (must fill with binary/multiple choices — no ambiguity)
> **Categorically determine** structures that VLMs tend to misread. No "seems like it's wrapped."
> Fill each item for every relevant UI element.

### List-type UIs (for each group of rows)
- Row container: [ ] Individual cards (own border/shadow/radius) / [ ] Rows within shared container (border-bottom/divider only)
- Row gap: [ ] Gap present (rows physically separated) / [ ] No gap (separated by rules only)

### Section Groups (vertically stacked sections)
- Container: [ ] One large card with divider separators / [ ] Separate cards per section (gap between cards)
- Verify whether card boundaries are "continuous outline" vs "physically separated" at the pixel level

### Badges / Tags
- Shape: [ ] Filled (background color + text color) / [ ] Outlined (border + text color, background transparent or same as parent)
- If filled: background color ___ / text color ___ (both required — don't swap foreground/background)
- If outlined: border color ___ / text color ___ / inner background ___

### Region Backgrounds (tab area, message area, content area, etc.)
- Each region's background: [ ] Same white as parent / [ ] Transparent (outer shows through) / [ ] Light gray / [ ] Other color
- "Whitish" is forbidden. Confirm with Phase 1.5 pixel measurements

### Buttons
- [ ] Filled / [ ] Outlined / [ ] Text only
- State: [ ] Enabled / [ ] Disabled (disabled is typically faded)
```

Once verbalization is complete, save as `_verbalization-original.md` in the project root. Cross-check with Phase 1.5 pixel measurement results before presenting to the user for confirmation.

---

## Phase 1.5: Pixel Color Sampling

> VLM weakness: "white vs transparent vs light gray" and "filled vs outlined" judgments are error-prone.
> Physically sample pixel values from key areas of the target image to **confirm colors with numeric values**.

### What to Do

Generate and run `_pixel-samples.mjs`. Select representative coordinates from key regions and sample pixel colors:

```javascript
// _pixel-samples.mjs
import sharp from 'sharp';
import fs from 'fs';

const IMG = process.argv[2]; // target image path

const samples = [
  // { label, x, y } — one point per element from Phase 1's structural decisions
  { label: 'Page background (outside content)', x: 20, y: 20 },
  { label: 'Tab area background', x: 200, y: 100 },
  { label: 'Main card background', x: 400, y: 250 },
  { label: 'Message box center', x: 300, y: 150 },
  { label: 'Badge center (fill detection)', x: 500, y: 400 },
  { label: 'Badge text area (fill detection)', x: 503, y: 400 },
  { label: 'Badge border top (outline detection)', x: 490, y: 395 },
  { label: 'List row background', x: 300, y: 480 },
  { label: 'List row gap', x: 300, y: 510 },
  // add more as needed
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

### What to Read

- **Confirm same vs different colors** with hex values. `#FFFFFF` and `#F4F4F4` are nearly indistinguishable to VLM visual inspection but instantly different by numbers
- Sample badge center vs edge to determine "filled or outlined": center and edge same color → filled; center matches parent and edge differs → outlined
- List row background vs row gap same color → shared container; different colors (gap = outer page color) → individual cards

### Cross-check

Compare Phase 1's "Structural Decisions" with `_pixel-samples.md`. If contradictions exist, correct Phase 1 before proceeding to Phase 2 (numbers are truth).

---

## Phase 2: Verbalization-Based Implementation

**⚠️ Do NOT reference the original screenshot. Implement solely from the Phase 1 verbalization text (`_verbalization-original.md`).**

- Faithfully translate the values, colors, and layout from Phase 1 text into code
- When using a CSS framework, convert verbalized values to framework tokens (e.g., `16px` → `p-4`)
- When dark mode/theming is in use, map color codes to CSS variables or theme tokens
- Do not guess styles not mentioned in the verbalization — use general defaults
- Ensure the result is viewable on the dev server when done

---

## Phase 3: Capture Current Screenshot

Use Playwright to capture a screenshot of the current implementation.

### Generate and Run Script

Generate `_screenshot.mjs` and run it:

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
LOOP_NUM=1 node _screenshot.mjs   # increment per loop iteration
```

Screenshots are saved as `_current-1.png`, `_current-2.png`, ... to track improvement over iterations.

### If Playwright Is Not Installed

```bash
npm i -D playwright && npx playwright install chromium
```

### file:// Fallback

If localhost is unavailable, open the HTML file directly:

```javascript
await page.goto(`file://${process.cwd()}/index.html`);
```

---

## Phase 4: Diff Verbalization (Side-by-Side Image Comparison)

**Compare the target screenshot and the latest current screenshot (`_current-N.png`) side by side**, and verbalize the differences.
Save results to `_diff.md` (overwritten each loop).

### What to Do

1. Open the target screenshot with Read
2. Open `_current-N.png` (latest loop) with Read
3. Observe **only the differences** between the 2 images and write to `_diff.md` with HIGH/MEDIUM/LOW classification

### Required Structural Item Scan (must fill target vs current for every item)

> Items VLMs tend to miss. **"N/A" and "same so I'll skip" are not allowed.**
> For each item, write "Target: ___ / Current: ___ / Match or Diff" — **all items mandatory**. Skipping means not noticing.

| Item | Target | Current | Match/Diff |
|---|---|---|---|
| **Card boundaries** (independent outline vs 1 large card + divider) | | | |
| **List row containers** (individual cards or rows in shared container) | | | |
| **Tab area background** (part of white card, transparent, or different color) | | | |
| **Message/inline box background** (same as parent or different color) | | | |
| **Badge/tag shape** (filled bg+text or outlined border+text) | | | |
| **Badge color roles** (background color ___ / text color ___) | | | |
| **Element width** (full-width / max-width / hug-content) | | | |
| **Border radius style** (pill / rounded 8-16 / square / circle) | | | |
| **Background color style** (white / light-gray / dark) | | | |
| **Alignment** (left/center/right, vertical alignment) | | | |
| **Element presence** (exists in target but not in current, or vice versa) | | | |
| **Icon shape** (line / filled / outlined) | | | |
| **Button style** (filled / outlined / disabled-looking) | | | |

### Output Format

```
## Diff List (Loop N)

### Structural Item Scan (mandatory — fill all items)
| Item | Target | Current | Verdict |
|---|---|---|---|
| Card boundaries | 1 large card + divider | 1 large card + divider | Match |
| List row containers | Individual cards (border) | Rows in shared container | **Diff** |
| ... | | | |

### HIGH (layout breakage, structural mismatch, missing elements)
- [ ] Diff description — Target: XXX / Current: YYY
  - **Fix approach**: ...

### MEDIUM (size differences, spacing gaps, font-weight differences)
- [ ] Diff description — Target: XXX / Current: YYY
  - **Fix approach**: ...

### LOW (subtle color differences, 1-2px misalignment, estimated value variance)
- [ ] Diff description — Target: XXX / Current: YYY
```

### Phase 4 Critical Rules

- **Describe only "what's different."** Do not re-read absolute values from images to overwrite `_verbalization-original.md` (prevents numeric drift)
- When a diff requires absolute value correction (e.g., "color should be #C8161D but is #B81C22"), **re-read `_verbalization-original.md` to confirm the original value** before deciding the fix approach
- Structural item scan is **mandatory every loop** (no skipping even if items match). Writing "Match" itself surfaces VLM blind spots
- Structural diffs (card boundaries, tag shape, background color style) are HIGH priority. Fix structural issues before size differences
- When uncertain about color judgment, refer to `_pixel-samples.md` (numbers are truth)

---

## Phase 5: Diff-Based Fixes

1. Fix **HIGH diffs** first
2. Base fixes on `_diff.md` diff list (do not look at images to fix)
3. After fixes, **increment the loop counter** and **return to Phase 3**

## Loop Management

Track loop count via screenshot numbering:
- `_current-1.png` → Loop 1
- `_current-2.png` → Loop 2
- ...

Files updated each loop:
- `_current-N.png` — new (numbered)
- `_diff.md` — overwritten

Note: `_verbalization-original.md` is **created once in Phase 1 and remains unchanged**. Only Read it for reference when a diff fix needs to confirm original values.

---

## Exit Conditions

Stop the loop when any of the following is met:

1. **All diffs are LOW or below** — practical reproduction quality achieved
2. **User approves** — user judges it sufficient
3. **Exceeded 5 loops** — pause and consult the user. Present remaining diffs and let them decide whether to continue or stop
