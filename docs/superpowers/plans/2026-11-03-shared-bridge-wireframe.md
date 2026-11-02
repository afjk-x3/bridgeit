# One Bridge Everywhere: Wireframe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redraw the Wireframes v3 canvas so that every board showing a bridge uses one bridge drawing, with the student's sentences shown as numbered piers. Add a Bridge sheet board that shows all six bridge states.

**Architecture:** A Node script, `bridge.js`, builds the bridge as one inline `<svg>` string for a given state. A second script, `build.js`, writes that SVG into each board between `<!-- bridge -->` and `<!-- /bridge -->` markers, so all boards share one drawing. `check.js` asserts the shared rules on every board. The boards are then published to the canvas with the Artifact tool, in the canvas's own file format.

**Tech Stack:** Node (no packages); the Design canvas `.dc.html` format, read from the canvas's `SKILL.md`; the Artifact tool.

**Spec:** `docs/superpowers/specs/2026-11-03-shared-bridge-design.md`

## Global Constraints

- **Canvas:** https://claude.ai/artifact/Q2sTzJQrY9WSmuxZHLCU5w. Write only under `project/`. Read the latest version of every file you change right before publishing, because the owner edits the canvas too.
- **Colours:** logo colours only: navy `#183870`, teal `#309090`, light teal `#80C0A8`, orange `#D88858`, background `#E6F5FF`. The scene colours stay: deck `#5B6472`, stone `#6F7F9E`, water `#56B9D6`, white `#FFFFFF`, car blue `#3A8FDB` and the car driver's colours.
- **SVG:** no `<filter>` or `<mask>`, so `flutter_svg` can draw it later.
- **Errors:** error outlines are orange `#D88858`, not red.
- **Text:** sentence captions at least 14 px; pier tags at least 13 px bold.
- **Boards:** 390×844 each. Keep every board's other content as it is.
- **Approved scope:** no app code, and no other wireframe change from DECISIONS.md.
- **Repo:** don't commit scratch files. Commit only the plan and the spec, and only when the owner asks.

## Review Focus

- **Owner edits while the work is in progress:** a publish is refused. Re-read the named file, rebuild it with `build.js`, and republish. The owner's edits outside the markers must survive. `build.js` replaces only the region between the markers; checked in Task 1.
- **The longest clauses** ("The test was very hard" / "she finished it early.") on a 150 px slab must fit in 2 lines at 14–15 px; checked in Task 2, on the Bridge sheet.
- **The *nor* centre pier** must not overlap the green joining piece or the caption; checked in Task 2.
- **Wobble lines** must not cover the clause text or the pier tags; checked in Task 2.
- **Height:** a board whose bridge is taller than before (Write: Quick Facts card, bridge, caption, box, Submit) must still keep Submit inside 844 px; checked in Task 4.

---

### Task 1: The bridge generator and its checks

**Files** (all scratch, under `<root>` = the session scratchpad's `canvas/` folder):
- Create: `<root>/bridge.js`, `<root>/build.js`, `<root>/check.js`, `<root>/bridge.test.js`
- Create: `<root>/project/`, a copy of the latest canvas files: `canvas.json`, Start, Main, Story, Bridge, Wrong, WriteOwn, Write and Ending (`.dc.html`)

**Interfaces:**
- Produces: `bridgeSvg(opts) -> string` in `bridge.js`, where `opts = { state: 'finished'|'broken'|'shaking'|'onePier'|'twoPiers'|'nor', width = 390, left?, right?, piece?: {text, tone: 'right'|'wrong'|'none'}, piers?: [{n, word}], caption?: [string], car?: 'left'|'middle'|'right'|null, low?: boolean }`. `low: true` draws the short Start/Welcome version, with no clause slabs. The function returns a complete `<svg aria-hidden="true" …>`, plus the caption as a sibling `<div>` when `caption` is given.
- Produces: `node build.js <board> <state-json>`, which rewrites the region between `<!-- bridge -->` and `<!-- /bridge -->` in `project/<board>`.
- Produces: `node check.js`, which exits 0 only when every board passes.

- [ ] **Step 1: Write `bridge.test.js`** (plain `node:assert`):
  - every state returns a string with no `<filter` and no `<mask`
  - every `fill="#…"`/`stroke="#…"` is in the allowed colour list
  - `shaking` contains the wobble group `id="wobble"` and `onePier` contains the "½" mark; `twoPiers` and `nor` contain no `wobble`
  - `twoPiers` with `piers:[{n:1,word:'for'},{n:2,word:'because'}]` contains the text "1 · for" and "2 · because"
  - `nor` draws exactly one pier, centred at x=195
  - `broken` with `piece.tone:'wrong'` uses stroke `#D88858` on the piece, never `#DC2626`
  - `build.js` run twice on a board containing the markers changes only the text between them (compare the text before `<!-- bridge -->` and after `<!-- /bridge -->`)
- [ ] **Step 2:** `node bridge.test.js`. Expected: fails ("Cannot find module './bridge'").
- [ ] **Step 3:** Write `bridge.js` from the Write board's bridge (viewBox 390 wide), with these values:
  - deck line y=108
  - slab 118–176 (58 px), clauses centred in each 150 px half at 15 px w800, 2 lines at most
  - truss 176–194
  - towers x=58 and 304, 28 px wide
  - piers under the towers (x 50–94 and 296–340) from y=194 to the water
  - *nor* pier 64 px wide, centred at x=195
  - **broken:** deck halves 0–150 and 240–390 with jagged inner ends, two rubble stones and splash arcs (as on the Wrong board)
  - **shaking:** three short zig-zag `wobble` strokes above and below each slab end, plus two crack ticks on the slab
  - **onePier:** the same wobble at half length, with a "½" label beside it
  - pier tag: white, 13 px w800, on the pier
  - **low:** the Start board's geometry (deck at y=104 in a 210-high view) with plain piers.

  Write `build.js` (read the board file, replace between the markers, write it back) and `check.js` (run the colour and filter checks on every `project/*.dc.html`, and fail on any text under 13 px inside the markers).
- [ ] **Step 4:** `node bridge.test.js && node check.js`. Expected: `ok`, exit 0.

### Task 2: The Bridge sheet board

**Files:**
- Create: `<root>/project/BridgeSheet.dc.html`
- Modify: `<root>/project/canvas.json`: add a `boards` entry `{"title":"Bridge sheet","w":1640,"h":844,"x":0,"y":3792}` and append the file to `order`. Add a `title1` note "Bridge: one design, every state" at `x:0,y:3492`. Keep every other key.

**Interfaces:**
- Consumes: `bridgeSvg` (Task 1).

- [ ] **Step 1:** Write the board: a 1640×844 root with six 390-wide cells in two rows of three: Finished (car right), Broken (wrong piece ", so"), Shaking (", for"), One pier, Two piers, *nor* (clauses "He does not like coffee" / "does he drink tea.").
  - Each cell has a 15 px w800 label naming the state and its screens, copied from the spec's States table.
  - Use the longest current clauses, "The test was very hard" / "she finished it early.", in the Broken and Two-piers cells.
  - The Two-piers cell gets the caption "1  The test was very hard, but she finished it early." and "2  The test was hard; however, she finished it early."
- [ ] **Step 2:** `node check.js`. Expected: exit 0.
- [ ] **Step 3:** Run a Node check: for each cell, the caption's top is below the pier bottoms, and no `wobble` path's y range overlaps the slab text band (y 118–176). Expected: no overlaps printed.
- [ ] **Step 4:** Re-read `project/canvas.json` from the canvas, re-apply only your keys, and publish `canvas.json` and `BridgeSheet.dc.html` in one Artifact call (`root`, `file_path`, `files`). Expected: published, with no refusal.

### Task 3: Finished bridge on Start, Welcome and Ending

**Files:**
- Modify: `<root>/project/Start.dc.html`, `Main.dc.html`, `Ending.dc.html`. Replace each board's bottom bridge `<svg>` with the markers, and fill them with `bridgeSvg({state:'finished', low:true, car})`.
  - Start: `car:'middle'`, as now.
  - Main: `car:'left'`.
  - Ending: `car:'right'`, sized to the space the board's current scene uses.

- [ ] **Step 1:** Insert the markers and run `build.js` for each of the three boards.
- [ ] **Step 2:** `node check.js`. Expected: exit 0. Also confirm by diff that nothing outside the markers changed.
- [ ] **Step 3:** Re-read the three files from the canvas and publish them. Expected: published.

### Task 4: Level 2 boards

**Files:**
- Modify: `<root>/project/Story.dc.html` (broken, no piece, car left; above the existing story text)
- Modify: `Bridge.dc.html` (broken, empty dashed gap)
- Modify: `Wrong.dc.html` (broken, `piece {text:', so', tone:'wrong'}`, and the hint card's border becomes `#D88858`)
- Modify: `WriteOwn.dc.html` (shaking, ", for")
- Modify: `Write.dc.html` (twoPiers, with `piers` "for" / "because" and the existing caption text split into the two numbered lines)

- [ ] **Step 1:** Insert the markers and run `build.js` for the five boards.
- [ ] **Step 2:** `node check.js`. Expected: exit 0. Also: grep shows no `#DC2626` or `#B91C1C` left in Wrong.dc.html.
- [ ] **Step 3:** Run a Node height check on Write.dc.html: the sum of the fixed heights in its column (header, Quick Facts card, bridge, caption, field, Submit, gaps) is ≤ 844 − 40 (padding). Expected: printed total ≤ 804. If it fails, shorten the bridge view to 210 px tall (cut the sky above the cable), not the caption.
- [ ] **Step 4:** Re-read the five files from the canvas and publish them. Expected: published.

### Task 5: Hand over

- [ ] **Step 1:** Ask the owner to look over the Bridge sheet and the eight boards on the canvas. Per the canvas rules, I don't screenshot it without asking.
- [ ] **Step 2:** Add a line to `docs/HANDOFF.md` "Latest session": the canvas version number, the Bridge sheet as the reference for the app build, and that the app is not changed yet.
