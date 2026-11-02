# One Bridge Everywhere: App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved shared bridge into the app. The Level 2 bridge gets the Wireframes v3 look, each accepted sentence becomes a numbered pier with its sentence in a caption, and the deck shakes until the piers are in. Start, Welcome, Level 3 "bridge crossed" and the Ending show the finished bridge.

**Architecture:**
- `BridgeScene` stays the one Level 2 widget. It keeps its current approach: a painter for the structure, with widgets on top for the clauses, the gap, the placed piece, the pier tags and the car. It gains `piers` and `piersNeeded`, and the `foundations` beams are removed.
- The short, finished bridge strip is an SVG asset made by a Node generator committed under `tool/`. Start and Welcome already use it through `BridgeStrip`; Level 3 and the Ending start using it.

**Tech Stack:** Flutter 3.47.7, flutter_svg, Node (for the art script only).

**Spec:** `docs/superpowers/specs/2026-11-03-shared-bridge-design.md`. The look is the Wireframes v3 "Bridge sheet" board, version 44: https://claude.ai/artifact/Q2sTzJQrY9WSmuxZHLCU5w (`project/BridgeSheet.dc.html`).

## Global Constraints

- Colours come only from `AppColors`. Add `stone = Color(0xFF6F7F9E)`. `deck`, `water`, `tower`, `cable`, `correct`, `accent` and `note` already exist.
- No `<filter>` or `<mask>` in SVG assets.
- Text: clauses 14 px w800 white, at most 2 lines each; pier tags at least 13 px w800; caption at least 14 px.
- Wrong pieces have an orange outline (`AppColors.accent`) and never red.
- The shaking stops entirely when `MediaQuery.disableAnimationsOf(context)` is true; the half and full states still differ in the `amplitude` value.
- No new packages. Every task ends with `flutter analyze` clean and `flutter test` all green.
- Commits use Conventional Commits, with no co-author, session or "Generated with" lines. Branch `v2`; don't push.

## Review Focus

- **Resume** from a save with one sentence written must show pier 1 and the half shake, not two piers or none. Test in Task 2.
- **The *nor* bridge** (no Quick Facts) must need one pier, show it centred, and show no shake after its only sentence. Test in Task 2.
- **The second pier's tag** must name the Quick Facts word the student used ("2 · because"), and fall back to the conjunction when none is found. Test in Task 2.
- **At 360×640**, the scene with 2 piers plus a 2-sentence caption must not overflow, and Submit must stay reachable by scrolling. Test in Task 2.
- **With animations disabled** (an accessibility setting), the deck must not move. Test in Task 1.

---

### Task 1: The new `BridgeScene`

**Files:**
- Modify: `lib/widgets/bridge_scene.dart` (painter and layout rewritten; `_Foundation` removed)
- Modify: `lib/theme/app_theme.dart` (`AppColors.stone`)
- Create: `test/widgets/bridge_scene_test.dart` (move the "BridgeScene paints and labels every state" test here from `level2_screen_test.dart`)

**Interfaces:**
- Produces: `class BridgePier { const BridgePier(this.word, this.sentence); final String word; final String sentence; }`
- Produces: `BridgeScene({Key? key, required BridgeState state, required String left, required String right, required Widget gap, String? placedWord, List<BridgePier> piers = const [], int piersNeeded = 2, bool crossed = false, VoidCallback? onCrossed})`. `foundations` is removed.
- Produces: `class BridgeWobble extends StatefulWidget { final double amplitude; }`, which wraps the deck layer: amplitude 1.0 when `state == built && piers.isEmpty`, 0.5 when `0 < piers.length < piersNeeded`, and 0 otherwise.
- Keys: each pier is `ValueKey('pier-$n')` (n from 1), the caption is `ValueKey('pier-caption')`, and the wobble is `ValueKey('wobble')`.

**Geometry**, from the sheet's 390×232 cell, scaled to the scene width:
- deck top 108/232
- slab 118–176
- truss 176–194
- towers centred at x 72 and 318 (28 wide)
- tower footings x 50–94 and 296–340
- sentence piers 48 wide, centred at x 122 and 268
- the *nor* pier 64 wide, centred at 195
- water from 196

**Paint order:** water, bank walls, cable, hangers, towers, deck, footings, piers, then (as widgets) clauses, piece, tags and car.

**States:**
- `open` and `cracked` draw the split deck with jagged ends and two rubble stones.
- `broken` keeps today's collapse tilt animation (`_fallTime`, `_fallAngle`).
- `built` draws the whole deck.

- [ ] **Step 1: Write the failing tests** in `bridge_scene_test.dart`. Pump `BridgeScene` at 390 wide, `left: 'She went to bed early'`, `right: 'she was tired.'`:
  - `'built with no piers shakes fully'`: `tester.widget<BridgeWobble>(find.byKey(const ValueKey('wobble'))).amplitude == 1.0`.
  - `'one of two piers shakes half and tags the pier'`: `piers: [BridgePier('for', 'I stayed in, for it rained.')]`. Expect amplitude `0.5`, `find.descendant(of: find.byKey(const ValueKey('pier-1')), matching: find.text('1 · for'))` finds one, and the caption contains `'I stayed in, for it rained.'`.
  - `'all piers in: still, two tags, numbered caption'`: two piers (`for`, `because`). Expect amplitude `0`, `pier-1` and `pier-2` found, and `pier-3` not found.
  - `'nor needs one centred pier'`: `piersNeeded: 1`, one pier `nor`. Expect amplitude `0`; `tester.getCenter(find.byKey(const ValueKey('pier-1'))).dx` within 2 px of the scene's centre.
  - `'no movement when animations are off'`: wrap the scene in `MediaQuery(data: MediaQueryData(disableAnimations: true))`, with built and no piers. Over `tester.pump(Duration(milliseconds: 300))` the deck layer's `getTopLeft` stays the same.
  - The moved state-label test keeps its four `Bridge <state>` labels and its sentence label.
- [ ] **Step 2:** `flutter test test/widgets/bridge_scene_test.dart`. Expected: compile failure (`BridgePier` undefined).
- [ ] **Step 3:** Implement the interfaces, geometry and states above, plus `AppColors.stone`.
  - The wobble is a looping `AnimationController`: 1200 ms, `Transform.translate` of `sin(t·2π)·2·amplitude` px on x and y, on the deck layer only.
  - The caption is a navy `Container` under the scene: white 14 px w700 lines, each "n  sentence" with the number in `AppColors.lightTeal`.
- [ ] **Step 4:** Point Level 2's `_scene()` at the new parameter so the app compiles: `piers: [for (final s in _foundations) BridgePier(_bridge.conjunction, s)]` (Task 2 picks the right words). Then run `flutter test`. Expected: all pass, except any Level 2 test that expects the old foundation beams; update those to the caption key `pier-caption`.
- [ ] **Step 5: Commit** `feat: the shared bridge with sentence piers`

### Task 2: Level 2 wiring

**Files:**
- Modify: `lib/screens/level2_screen.dart`: `_scene()` passes `piers` and `piersNeeded`; `_buildStory()` shows `BridgeScene(state: BridgeState.open, left/right: the first bridge's clauses, gap: SizedBox.shrink())` above the story bubble instead of `broken_bridge.svg`.
- Delete: `assets/images/scenes/broken_bridge.svg`, if nothing else uses it (check with grep).
- Test: `test/screens/level2_screen_test.dart`

**Interfaces:**
- Consumes: `BridgePier` and `BridgeScene(piers:, piersNeeded:)` from Task 1.
- Produces: `List<BridgePier> _piers` in `_Level2ScreenState`. Sentence i=0 has the word `_bridge.conjunction`. Sentence i=1 has the word `findQuickFact(text, _facts)?.word ?? _bridge.conjunction`. `piersNeeded` is `_facts.isEmpty ? 1 : 2`.

- [ ] **Step 1: Write the failing tests:**
  - `'an accepted sentence becomes pier 1'`: after the first sentence, `find.text('1 · for')` finds one.
  - `'resume with one sentence shows pier 1 and half shake'`: open with prefs `{"bridgeIndex":0,"written":[["I stayed inside, for it was raining."]]}`. Expect `pier-1` found, `pier-2` not found, and wobble amplitude `0.5`.
  - `'the second pier names the Quick Facts word'`: write the first sentence, then `'The dog ran far because the cat sat down.'`. Expect `find.text('2 · because')` and amplitude `0`.
  - `'nor bridge: one pier, then still'`: resume at `bridgeIndex: 2`, play `nor`, and write one sentence. Expect `pier-1`, no `pier-2`, and amplitude `0`.
  - `'the story shows the broken bridge'`: `find.byType(BridgeScene)` finds one on the story step, and `find.bySemanticsLabel('Bridge open')` finds one.
  - Extend `'every step fits a 360x640 phone'`: after both sentences on bridge 1, `tester.takeException()` is null, and the "Cross the Bridge" button can be scrolled to and is hit-testable.
  - Replace old expectations on foundation text under the bridge with the caption key `pier-caption`.
- [ ] **Step 2:** `flutter test test/screens/level2_screen_test.dart`. Expected: the new tests fail.
- [ ] **Step 3:** Implement the interfaces above.
- [ ] **Step 4:** `flutter analyze` and `flutter test`. Expected: clean, all pass.
- [ ] **Step 5: Commit** `feat: sentences hold up the Level 2 bridge`

### Task 3: Finished bridge art on Start, Welcome, Level 3 and the Ending

**Files:**
- Create: `tool/bridge_art/bridge.js` (a copy of the wireframe generator; its `low()` is the source of truth for the strip) and `tool/bridge_art/make_assets.js`. The second script writes:
  - `assets/images/scenes/bridge_strip.svg`: finished, car in the middle
  - `assets/images/scenes/bridge_strip_crossed.svg`: finished, car on the right
- Modify: `assets/images/scenes/ending.svg`. Replace its road and car with the finished low bridge (car right), placed so the water ends above the bottom sheet.
- Modify: `lib/screens/start_screen.dart`: `BridgeStrip({super.key, this.crossed = false})` picks the asset.
- Modify: `lib/screens/level3_screen.dart`: `_Story` gets an optional `Widget? footer`, drawn full width at the bottom. The `crossed` step passes `footer: const BridgeStrip(crossed: true)`.
- Test: create `test/art_test.dart`; extend `test/screens/level3_screen_test.dart`

**Interfaces:**
- Consumes: nothing from Tasks 1 and 2.
- Produces: `BridgeStrip({bool crossed = false})`.

- [ ] **Step 1: Write the failing tests:**
  - `art_test.dart`, for `bridge_strip.svg`, `bridge_strip_crossed.svg` and `ending.svg`: the file has no `<filter` or `<mask`, contains `#6F7F9E` (stone piers), and each colour it uses is in the logo palette or `AppColors`.
  - `level3_screen_test.dart` `'the crossed step shows the finished bridge'`: after the toll gate's Next, `find.byWidgetPredicate((w) => w is BridgeStrip && w.crossed)` finds one.
- [ ] **Step 2:** `flutter test test/art_test.dart test/screens/level3_screen_test.dart`. Expected: fail.
- [ ] **Step 3:** Copy the generator, write the assets with `node tool/bridge_art/make_assets.js`, edit `ending.svg`, and add `footer` and `crossed`.
- [ ] **Step 4:** `flutter analyze` and `flutter test`. Expected: clean, all pass.
- [ ] **Step 5: Commit** `feat: the finished bridge on Start, Level 3 and the Ending`

### Task 4: Check on the emulator

- [ ] **Step 1:** `flutter build apk --release`, install, and walk:
  - Start
  - Welcome
  - Level 2: story, wrong try, built (shaking), one sentence (half shake), two sentences (still)
  - the *nor* bridge, by resuming at bridge 3 through play
  - Level 3 crossed
  - Ending

  Screenshot each.
- [ ] **Step 2:** Compare each screenshot with the Bridge sheet. Fix anything that differs in what the spec pins (states, pier tags, caption, orange wrong piece). Ledger any other difference as a ruling.
- [ ] **Step 3:** Update `docs/HANDOFF.md` "Latest session", and commit `docs: hand off the shared bridge`.
