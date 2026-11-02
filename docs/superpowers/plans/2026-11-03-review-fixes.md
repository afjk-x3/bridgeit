# Design Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the accepted fixes from the three design reviews: seven usability fixes, seven behaviour changes, two dropped Level 2 steps and the Ending header.

**Architecture:** Flutter app, one screen file per level (`lib/screens/level{1,2,3}_screen.dart`) built from shared widgets in `lib/widgets/` and pure game logic in `lib/game/`. New logic (checklist, hints, Submit label) goes in `lib/game/` as pure functions with unit tests; screens and widgets only display it. Each task leaves `flutter test` green.

**Tech Stack:** Flutter 3.47.7, Dart, provider, flutter_svg, shared_preferences, just_audio.

**Spec:** `docs/design-review/DECISIONS.md` (with `docs/design-review/BRIEF.md` for context and the Wireframes v3 boards at https://claude.ai/artifact/Q2sTzJQrY9WSmuxZHLCU5w for the look).

## Global Constraints

- Colours only from `AppColors` in `lib/theme/app_theme.dart`; palette navy `#183870`, teal `#309090`, light teal `#80C0A8`, orange `#D88858`, background `#E6F5FF`. New colours are added to `AppColors`, never inline.
- Font Nunito; any `TextStyle` used as a button `textStyle` must set `fontFamily: 'Nunito'`.
- Art is SVG drawn by `flutter_svg`: no `<filter>` or `<mask>`.
- Touch targets at least 48×48 px.
- No new packages.
- Every task ends with `flutter analyze` clean and `flutter test` all green.
- Commit messages: Conventional Commits, no co-author, session or "Generated with" lines.
- Branch `v2`. Do not push.

## Review Focus

- **Saved Level 2 progress from before this change** (a bridge with one sentence written, saved while the old "Tap the conjunction" step existed) must reopen on Write with Quick Facts, not crash. Test in Task 5.
- **A wrong piece left in the gap, then a different piece dropped** must replace it and re-enable "Cross the bridge"; the wrong piece itself stays disabled in the tray. Test in Task 6.
- **"For" capitalised at the start of a sentence, or the word appearing twice** ("For now, I wait, for she is late.") must tick "Comma right before 'for'" when any occurrence has the comma. Test in Task 7.
- **The travelogue at 360×640 with the keyboard open** must not overflow and must keep the journal box visible. Test in Task 8.
- **The map at 360×640** must keep every place card and the "Drive to …" button reachable, with long names wrapping. Test in Task 12.

---

### Task 1: Commit the work already in the working tree

Two finished, tested changes are uncommitted:
- **Wireframe gaps:** Play-3-times stops strip, the "ready" step merged into MatchIt instructions with the drag example, right-aligned Sing along Next, Start clouds (`assets/images/scenes/clouds.svg`), Credits Close button, "n tries left", the Quick Facts card on Write with Quick Facts, the travelogue journal prompt.
- **Level 1 play count kept** when leaving the level (`level1Plays` in `lib/progress/results_store.dart`, test "plays are kept after leaving the level").

- [ ] **Step 1:** Run `flutter analyze` and `flutter test`. Expected: clean, 271 pass.
- [ ] **Step 2: Commit** (code only; the docs folders are committed in Task 13)

```bash
git add lib test assets/images/scenes/clouds.svg
git commit -m "feat: close wireframe gaps and keep Level 1 song plays"
```

---

### Task 2: Disabled buttons and minimum text sizes (decisions 4, 5)

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Modify: `lib/widgets/song_player.dart` (the two time labels)
- Modify: `lib/screens/level2_screen.dart` (the "tries left" label)
- Test: `test/theme_test.dart` (create)

**Interfaces:**
- Produces: `AppColors.disabled = Color(0xFFC9D6E3)`.

- [ ] **Step 1: Write the failing test** `test/theme_test.dart`:

```dart
test('disabled buttons keep a readable navy label', () {
  final style = buildAppTheme().filledButtonTheme.style!;
  const off = {WidgetState.disabled};
  expect(style.backgroundColor!.resolve(off), AppColors.disabled);
  expect(style.foregroundColor!.resolve(off), AppColors.ink);
});

test('character counters are at least 14 px', () {
  expect(buildAppTheme().inputDecorationTheme.counterStyle!.fontSize, 14);
});
```

- [ ] **Step 2:** Run `flutter test test/theme_test.dart`. Expected: FAIL (`AppColors.disabled` undefined).
- [ ] **Step 3:** Add `AppColors.disabled`; in `buildAppTheme` set `disabledBackgroundColor: AppColors.disabled, disabledForegroundColor: AppColors.ink` on the filled and outlined button styles, and `counterStyle: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)` on the input theme. In `song_player.dart` replace `text.labelSmall` on both time labels with `fontSize: 14, fontWeight: FontWeight.w700`. In `level2_screen.dart` set the "tries left" label to `fontSize: 14`.
- [ ] **Step 4:** Run `flutter test`. Expected: all pass.
- [ ] **Step 5: Commit** `fix: readable disabled buttons and 14 px minimum labels`

---

### Task 3: Header titles and button copy (decision 7, Ending header)

**Files:**
- Modify: `lib/widgets/level_app_bar.dart`
- Modify: `lib/widgets/send_answers_button.dart`
- Modify: `lib/screens/level1_screen.dart`, `lib/screens/level2_screen.dart`, `lib/screens/level3_screen.dart`
- Test: `test/screens/level1_screen_test.dart`, `test/screens/level2_screen_test.dart`, `test/screens/level3_screen_test.dart`, `test/screens/level_menu_screen_test.dart`

**Interfaces:**
- Produces: `AppBar levelAppBar(BuildContext context, int level, String title, {String? kicker, bool journey = true, bool dark = false})`. `kicker` replaces the default `'LEVEL $level'` first line; `journey: false` hides the Map button; `dark` gives a navy bar with white text (used in Task 10).
- Produces: `SendAnswersButton({Key? key, String label = 'Send my answers'})`.

- [ ] **Step 1: Write the failing tests**
  - Level 1: on the MatchIt instructions, `expect(find.text('MatchIt'), findsWidgets)` inside the `AppBar` (`find.descendant(of: find.byType(AppBar), matching: find.text('MatchIt'))`, `findsOneWidget`).
  - Level 2: on the first bridge, `find.descendant(of: find.byType(AppBar), matching: find.text('LEVEL 2 · BRIDGE 1 OF 7'))` finds one; after "Strengthen the Bridge", the AppBar shows `'Strengthen the bridge'`.
  - Level 3 Ending: `find.text('Send my answers to my teacher')` finds one and `find.byTooltip('Journey')` finds nothing.
  - Replace every `'PLAY THE SONG'` in tests with `'Play the song'`; replace the Level 2 test's `find.text('BRIDGE 1 OF 7')` with the AppBar kicker above.
- [ ] **Step 2:** Run `flutter test test/screens`. Expected: the new expectations FAIL.
- [ ] **Step 3:** Implement the signatures above. Level 1: title `'MatchIt'` when `_step` is `matchIntro`, `match` or `done`, else `'Conjunction Theme Song'`; intro button label `'Play the song'`. Level 2: kicker `'LEVEL 2 · BRIDGE ${_index + 1} OF ${_content.bridges.length}'` while `_step` is not `story` or `done`; title `'Strengthen the bridge'` for every step after `build`; remove the separate "BRIDGE n OF 7" text row but keep "n tries left" right-aligned under the AppBar. Level 3: `journey: _step != _Step.ending`; Ending uses `SendAnswersButton(label: 'Send my answers to my teacher')`.
- [ ] **Step 4:** Run `flutter test`. Expected: all pass.
- [ ] **Step 5: Commit** `feat: clearer level headers and button copy`

---

### Task 4: MatchIt board fits all seven rows (decision 3)

**Files:**
- Modify: `lib/widgets/match_it_board.dart`
- Test: `test/screens/level1_screen_test.dart`

- [ ] **Step 1: Write the failing test** `'every MatchIt slot is visible without scrolling'`: reach MatchIt with `_reachMatchIt` at the default 411×891 size, then for each pair `expect(find.byKey(ValueKey('slot-${pair.conjunction}')).hitTestable(), findsOneWidget)`.
- [ ] **Step 2:** Run it. Expected: FAIL on `slot-so`.
- [ ] **Step 3:** Remove the board's own "MatchIt" heading (the AppBar now says it) and reduce the slot row bottom padding from 6 to 4. Keep slot `minHeight: 48`.
- [ ] **Step 4:** Run `flutter test`. Expected: all pass, including "MatchIt fits a 360x640 phone".
- [ ] **Step 5: Commit** `fix: show all seven MatchIt rows`

---

### Task 5: Drop the "Tap the conjunction" step and Quick Facts window; keep the comma (decisions 2, 6, flow change)

**Files:**
- Modify: `lib/screens/level2_screen.dart`
- Modify: `lib/widgets/bridge_scene.dart` (`_PlacedWord`, `onTapWord`)
- Test: `test/screens/level2_screen_test.dart`

**Interfaces:**
- Produces: `_Step` without `askFacts`; `_afterSentence()` returns `_Step.writeSimilar` when the first sentence is in and the conjunction has Quick Facts, else `_Step.sturdy`.
- Removes: `_openFacts`, `_QuickFactsDialog`, `BridgeScene.onTapWord`.

- [ ] **Step 1: Write the failing tests**
  - `'the first sentence leads straight to Write with Quick Facts'`: after one accepted sentence, `expect(find.text('Task: Use one of these words to write another sentence.'), findsOneWidget)` and `expect(find.text('Write now'), findsNothing)`.
  - `'saved progress from the old Quick Facts step reopens on Write with Quick Facts'`: open with prefs `level2_resume_v1` = one bridge with one written sentence (`{"bridgeIndex":0,"written":[["I stayed inside, for it was raining."],[],[],[],[],[],[]],"stats":[]}`); expect the Task text above.
  - `'the placed piece keeps its comma'`: after crossing, `expect(find.descendant(of: find.byKey(const ValueKey('placed-word')), matching: find.text(', for')), findsOneWidget)`.
  - Delete every `_tap(tester, 'Quick Facts')` / `_tap(tester, 'Write now')` pair in existing tests.
- [ ] **Step 2:** Run `flutter test test/screens/level2_screen_test.dart`. Expected: the three new tests FAIL.
- [ ] **Step 3:** Implement. On `writeSimilar`, order the list as: `_QuickFactsCard`, `_scene()`, `WritingPanel`; drop the "Use one of the Quick Facts words…" bubble and the "See Quick Facts again" button. `_PlacedWord` shows `', $word'`.
- [ ] **Step 4:** Run `flutter test`. Expected: all pass, including "every step fits a 360x640 phone" with Submit hit-testable after `ensureVisible`.
- [ ] **Step 5: Commit** `feat: go straight to Quick Facts writing and keep the comma`

---

### Task 6: Wrong piece stays in the gap with a specific hint (decision 8)

**Files:**
- Modify: `lib/game/bridge_round.dart`
- Modify: `lib/screens/level2_screen.dart`
- Modify: `lib/widgets/bridge_gap.dart`
- Test: `test/game/bridge_round_test.dart`, `test/screens/level2_screen_test.dart`

**Interfaces:**
- Produces: `String describeWord(String word, String function)` in `lib/game/bridge_round.dart`: `"'$word' "` plus `function` with its first letter lowercased, e.g. `describeWord('nor', 'Connects negative alternatives.')` → `"'nor' connects negative alternatives."`.
- Produces: `BridgeRound(Bridge bridge, {required int maxWrongAnswers, Map<String, String> functions = const {}})`; `hintFor(word)` returns, in order: the bridge's own hint for `word`; else `describeWord(word, functions[word]!)` when present; else `bridge.defaultHint`.
- Produces: Level 2 state field `late final Map<String, String> _functions`, used again in Task 7.
- Produces: `BridgeGap({..., bool wrong = false})`; when `wrong`, a 3 px `AppColors.accent` border and `AppColors.note` fill.

- [ ] **Step 1: Write the failing tests**
  - `bridge_round_test.dart`: `hintFor('nor')` with `functions: {'nor': 'Connects negative alternatives.'}` and no bridge hint for `nor` returns `"'nor' connects negative alternatives."`; a word with a bridge hint still returns the bridge hint.
  - Update `'a wrong piece shows its hint and fades'` → `'a wrong piece stays in the gap with its hint'`: after `_tryPiece(tester, wrong)`, `expect(find.descendant(of: _gap, matching: find.text(', $wrong')), findsOneWidget)`, the hint text is shown, `_enabled(tester, wrong)` is false, `_crossEnabled(tester)` is false.
  - `'another piece replaces the wrong one'`: after the wrong try, tap `_piece(bridge.conjunction)` then `_gap`; the gap shows `', ${bridge.conjunction}'` and `_crossEnabled(tester)` is true.
- [ ] **Step 2:** Run both test files. Expected: new tests FAIL.
- [ ] **Step 3:** Level 2 sets `_functions` in `initState` from `context.read<GameContent>().level1.matchIt` (`{pair.conjunction: pair.function}`) and passes it to every `BridgeRound`. In `_cross`, on `DropResult.wrong` keep `_placed = word`; on `broken` clear it as now. "Cross the bridge" is enabled only when `_placed != null && !_round.triedWrong.contains(_placed!.toLowerCase())`. Pass `wrong: _placed != null && _round.triedWrong.contains(_placed!.toLowerCase())` to `BridgeGap`.
- [ ] **Step 4:** Run `flutter test`. Expected: all pass.
- [ ] **Step 5: Commit** `feat: keep a wrong piece in the gap and say what it does`

---

### Task 7: Live checklist and one-time hint on Write your own sentence (decision 9)

**Files:**
- Create: `lib/game/sentence_checklist.dart`
- Modify: `lib/widgets/writing_panel.dart`
- Modify: `lib/screens/level2_screen.dart`
- Test: `test/game/sentence_checklist_test.dart` (create), `test/screens/level2_screen_test.dart`

**Interfaces:**
- Produces: `class ChecklistItem { const ChecklistItem(this.label, this.met); final String label; final bool met; }`
- Produces: `List<ChecklistItem> sentenceChecklist(String text, String word)` returning, in order: `'Starts with a capital'` (first non-space character is an uppercase letter), `"Uses '$word'"` (whole word, any case), `"Comma right before '$word'"` (some whole-word occurrence is preceded by `,` after trimming spaces), `'Ends with . ! or ?'` (trimmed text ends with one of them).
- Produces: `WritingPanel({..., String? checklistWord, String? hint})`. With `checklistWord`, a strip under the field shows each item with a teal ✓ circle when met or an empty navy circle when not, updating on every change. `hint` appears in an orange-bar note after the first failed submit and stays for that panel.

- [ ] **Step 1: Write the failing tests** in `sentence_checklist_test.dart`:
  - `''` → all four unmet.
  - `'I stayed inside, for it was raining.'` with `'for'` → all four met.
  - `'i stayed inside for it was raining'` → `[false, true, false, false]`.
  - `'For now, I wait, for she is late.'` with `'for'` → comma item met.
  - `'Before dinner, we ate.'` with `'for'` → "Uses 'for'" unmet (no match inside "Before").
  - Widget test `'a wrong sentence shows the hint once'`: on Write your own sentence, submit `'bad'`; `expect(find.textContaining('Another example:'), findsOneWidget)`; typing more keeps it.
- [ ] **Step 2:** Run them. Expected: FAIL (file missing).
- [ ] **Step 3:** Implement. Level 2 passes, on `writeConjunction` only: `checklistWord: conjunction` and `hint: '${describeWord(conjunction, _functions[conjunction]!)} Another example: ${_bridge.examples.first}'` (omit "Another example: …" when `examples` is empty).
- [ ] **Step 4:** Run `flutter test`. Expected: all pass.
- [ ] **Step 5: Commit** `feat: live sentence checklist and a one-time hint`

---

### Task 8: Travelogue keyboard room and a Submit label that says what's missing (decisions 1, 10)

**Files:**
- Modify: `lib/game/travelogue_analyzer.dart`
- Modify: `lib/widgets/travelogue_editor.dart`
- Modify: `lib/screens/level3_screen.dart` (`_JournalPrompt` placement)
- Test: `test/game/travelogue_analyzer_test.dart`, `test/screens/level3_screen_test.dart`

**Interfaces:**
- Produces: `String submitLabel(TravelogueResult result, TravelogueRules rules)`:
  - `canSubmit` → `'Submit'`
  - `sentenceCount < minSentences` → `'Write $n more sentence(s) to submit'` (singular when 1)
  - `sentenceCount > maxSentences` → `'Remove $n sentence(s) to submit'`
  - otherwise → `'Use $n more conjunction(s) to submit'`, `n = minConjunctions - counted.length`

- [ ] **Step 1: Write the failing tests**
  - Unit: 1 sentence, 1 conjunction, rules 5–7/4 → `'Write 4 more sentences to submit'`; 5 sentences, 3 conjunctions → `'Use 1 more conjunction to submit'`; 8 sentences → `'Remove 1 sentence to submit'`; a passing result → `'Submit'`.
  - Widget `'the journal keeps its room while typing'`: on the travelogue at 360×640 set `tester.view.viewInsets = const FakeViewPadding(bottom: 300)`, pump; `expect(tester.takeException(), isNull)`; `expect(find.text('Write about:'), findsNothing)`; the `TextField` is hit-testable.
- [ ] **Step 2:** Run them. Expected: FAIL.
- [ ] **Step 3:** Implement `submitLabel`; the editor's button shows it. In the travelogue step, render `_JournalPrompt` only when `MediaQuery.viewInsetsOf(context).bottom == 0`.
- [ ] **Step 4:** Run `flutter test`. Expected: all pass, including "Submit opens when the counters are met".
- [ ] **Step 5: Commit** `feat: travelogue keeps room while typing and says what is missing`

---

### Task 9: Song player inside the lyrics card (decision 12)

**Files:**
- Modify: `lib/widgets/song_player.dart`
- Modify: `lib/screens/level1_screen.dart` (`_buildSong`)
- Test: `test/screens/level1_screen_test.dart`, `test/widgets/song_player_test.dart`

**Interfaces:**
- Changes: `SongPlayer` returns a light-teal strip with square bottom corners and no outer `Card` or margin; tooltips `'Play'`/`'Pause'` unchanged.

- [ ] **Step 1: Update tests:** replace `expect(find.text('SING ALONG!'), findsOneWidget)` with `expect(find.byKey(const ValueKey('lyric-now')), findsOneWidget)`; add `expect(find.text('SING ALONG!'), findsNothing)`; add `expect(find.descendant(of: find.byType(Card), matching: find.byType(SongPlayer)), findsOneWidget)`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** `_buildSong`: one `Card` (`clipBehavior: Clip.antiAlias`) whose `Column` is `SongPlayer` then the lyrics padding. Upcoming lyric lines use `AppColors.ink.withValues(alpha: 0.75)` for contrast.
- [ ] **Step 4:** Run `flutter test`. Expected: all pass.
- [ ] **Step 5: Commit** `feat: song player sits on top of the lyrics card`

---

### Task 10: Place montage header, dots and Map button (decision 11)

**Files:**
- Modify: `lib/widgets/montage_player.dart`
- Modify: `lib/screens/level3_screen.dart`
- Test: `test/screens/level3_screen_test.dart`

**Interfaces:**
- Consumes: `levelAppBar(..., kicker:, dark: true)` from Task 3.
- Produces: `MontagePlayer({..., required VoidCallback onMap})`.

- [ ] **Step 1: Write the failing tests** `'the montage shows its place, progress and a way back to the map'`: after choosing La Paz, the AppBar shows the place's `name`; `find.bySemanticsLabel('Photo 1 of ${place.pictures.length}')` finds one; tapping `'Map'` shows `"LET'S EXPLORE TOGETHER!"`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Level 3 uses `levelAppBar(context, 3, _place!.name, kicker: 'LEVEL 3', dark: true)` during the montage. `MontagePlayer` shows a dot row (active dot 24×10 white, others 10×10 light teal, `Semantics(label: 'Photo ${_index + 1} of ${_pictures.length}')`) above the caption, and a bottom row: `OutlinedButton('Map', onMap)` always, light-teal `FilledButton('Next', onDone)` once `_passed`.
- [ ] **Step 4:** Run `flutter test`. Expected: all pass.
- [ ] **Step 5: Commit** `feat: montage shows the place, its photos and a way back`

---

### Task 11: Clauses on the bridge deck (decision 13)

**Files:**
- Modify: `lib/widgets/bridge_scene.dart`
- Test: `test/screens/level2_screen_test.dart`

**Interfaces:**
- Keeps: `BridgeScene` constructor (minus `onTapWord` from Task 5). Removes `_SentenceCard`.
- Produces: scene `Semantics` label `'$left, _____ $right'` while open/cracked and `'$left $placed $right'` when built (left already ends with a comma then), so screen readers still hear the sentence.

- [ ] **Step 1: Update the test** `'starts with the story, then the first bridge'`: replace the rich-text finder with `find.bySemanticsLabel('${first.left}, _____ ${first.right}')`; add `find.text(first.left)` and `find.text(first.right)` each finding one widget inside `BridgeScene`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** In `_ScenePainter`, draw the deck as a slab from `_deck` to `_deck + 0.2` of the height (grey `AppColors.deck`, navy outline), split at the gap while not built. Over it, two `Positioned` white bold 14 px texts centred on the left and right slab sections (max 2 lines, `softWrap`), and the gap centred between them. Keep the car on the slab top.
- [ ] **Step 4:** Run `flutter test`; then on the emulator check bridges 1 and 7 (longest clauses) for overflow.
- [ ] **Step 5: Commit** `feat: write the clauses on the bridge deck`

---

### Task 12: Rebuild the place map (decision 14)

**Files:**
- Modify: `lib/widgets/place_map.dart` (rewrite)
- Create: `assets/images/places/icons/{saud,bangui,burgos,la_paz,paoay,pangil,badoc}.svg` (from the Wireframes v3 Map board icons)
- Modify: `pubspec.yaml` (add `assets/images/places/icons/`)
- Delete: `assets/images/map.svg`, `test/widgets/place_map_test.dart`
- Modify: `lib/screens/level3_screen.dart` (`_buildMap` header only)
- Test: `test/widgets/place_map_test.dart` (new), `test/screens/level3_screen_test.dart`

**Interfaces:**
- Keeps: `PlaceMap({required List<Place> places, required ValueChanged<Place> onChosen})`; each place's tap target keeps `ValueKey('pin-${place.id}')`.
- Produces: `const northToSouth = ['saud', 'bangui', 'burgos', 'la_paz', 'paoay', 'pangil', 'badoc'];` and `List<Place> mapOrder(List<Place> places)` (places in that order; unknown ids after, in content order).
- Removes: `roadPoint`, `roadDistanceTo`. `Place.pinX`/`pinY` stay in the model but are no longer read.

- [ ] **Step 1: Write the failing tests** (`place_map_test.dart`):
  - `mapOrder` puts `saud` first and `badoc` last, and keeps an unknown id at the end.
  - Pumped `PlaceMap`: "Drive to" button is disabled with label `'Choose a place'`; tapping `pin-burgos` changes it to `'Drive to Burgos Lighthouse (Cape Bojeador)'`; tapping it and settling calls `onChosen` with burgos.
  - At 360×640, every `pin-*` can be scrolled to with `ensureVisible` and is hit-testable; no exception.
  - Update `level3_screen_test.dart`'s map helper: tap `pin-la_paz`, then tap the "Drive to" button.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement as in the Wireframes v3 Map board: light-green land with a sea strip on the left; a scrollable column of stops 100 px apart; a tan winding road (`CustomPainter`, cubic curves alternating between 38% and 64% of the width) with a numbered navy-outlined orange pin at each stop; a white place card (icon 54×33 + name, 12 px bold, max 3 lines, width 118, ≥48 px tall) on the outer side of each pin; START marker at the top; the selected card gets a 3 px orange border; a pinned bottom `FilledButton` with the car icon. Pressing it animates `car_small.svg` along the road (`PathMetric`, 1600 ms) to the chosen stop, then calls `onChosen`. `_buildMap` keeps the navy title banner from the earlier restyle.
- [ ] **Step 4:** Run `flutter test`; check on the emulator at 1080×2400.
- [ ] **Step 5: Commit** `feat: rebuild the place map north to south`

---

### Task 13: Full check on the emulator

- [ ] **Step 1:** `flutter analyze` and `flutter test`. Expected: clean, all pass.
- [ ] **Step 2:** `flutter build apk --release`, install, and walk Level 1 → Ending (release build: the debug build stalls on a freshly booted emulator). Screenshot each changed screen.
- [ ] **Step 3:** Re-run `scratchpad/pairs.ps1` to refresh `docs/design-review/pairs/` and `sheet-*.png` with the new app screenshots.
- [ ] **Step 4: Commit** `docs: refresh the design review screenshots` (include `docs/design-review/DECISIONS.md` and `BRIEF.md`).
