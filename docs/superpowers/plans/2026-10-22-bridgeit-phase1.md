# BridgeIt Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the full playable BridgeIt app flow (intro, level menu with unlock codes, Levels 1–3) on placeholder content and a placeholder look, so that only content and art need swapping when the client answers.

**Architecture:** One Flutter Android app. All game content (lyrics, sentences, answers, hints, synonyms, attempt limits, unlock codes) is in `assets/content/levels.json`, which is parsed once at startup into immutable models. Game rules live in small pure-Dart classes (`BlanksRound`, `BridgeRound`, `SynonymRound`) that are unit-tested. Screens only render state and forward taps and drops. Unlocks are saved with `shared_preferences` through `ProgressStore`, a `ChangeNotifier` provided at the root with `provider`.

**Tech Stack:** Flutter 3.47.7 stable, Dart 3.13.5, `provider`, `just_audio`, `shared_preferences`, `flutter_svg`, `flutter_test`, `flutter_lints`.

**Spec:** `BridgeIt-PRD.pdf` (client-facing PRD v0.3, repo root) and `docs/HANDOFF.md` (decisions, palette, open questions). The wireframes are in `BridgeIt-Wireframes.pdf`.

## Global Constraints

- Android only, phones, portrait only, English only. Works fully offline, with no login.
- Content is FANBOYS only: `for, and, nor, but, or, yet, so`. No subordinating conjunctions.
- Packages: only the 4 listed in Tech Stack plus the Flutter SDK. Ask before adding any other.
- All colors come from `AppColors` in `lib/theme/app_theme.dart`. No color literals anywhere else. The palette is a placeholder until the client sends their logo.
- The placeholder palette (hex): primary `#0E7490`, accent `#EC4899`, piece `#9D174D`, sky `#E0F2FE`, ink `#1E293B`, bridge `#B45309`, cliff `#15803D`, vehicle `#F59E0B`, correct `#22C55E`, wrong `#DC2626`.
- Sentences, answers, hints, synonyms, attempt limits and unlock codes are read from `levels.json` only. Never hard-code them in Dart.
- Level 1 allows unlimited retries. In Levels 2–3 a wrong answer cracks the bridge and shows a hint. When the wrong-answer count reaches `maxWrongAnswers` (placeholder 3), the bridge breaks and that sentence restarts. This break rule is a placeholder for client Q5.
- Touch targets are at least 48×48 dp. Right and wrong answers are shown with an icon and text as well as color.
- The UI copy follows the wireframes: "Let's start", "Choose a level", "Got a code from your teacher?", "Unlock", "Next verse", "Next sentence", "Reinforce the bridge".

## Review Focus

1. Unlock code typed with spaces or in lowercase (`"  bridge2 "`): should unlock. Test in Task 3.
2. Song audio not delivered yet (no `audioAsset`, or file missing): the player shows "Song coming soon" and Level 1 can still be completed. Test in Task 5.
3. `levels.json` missing a field or containing a non-FANBOYS answer: the app shows a readable error naming the field instead of crashing. Tests in Tasks 2 and 4.
4. Same wrong piece dropped twice, or a drop after the bridge is built or broken: counted once or ignored, never double-counted. Test in Task 6.
5. App closed and reopened: unlocked and completed levels are kept. Test in Task 3.

---

### Task 1: Project setup, theme and placeholder logo

**Files:**
- Modify: `pubspec.yaml` (assets section), `android/app/src/main/AndroidManifest.xml` (label `BridgeIt`, `android:screenOrientation="portrait"` on the activity), `lib/main.dart`
- Create: `lib/app.dart`, `lib/theme/app_theme.dart`, `assets/images/logo_placeholder.svg` (the cropped colored lotus), `assets/audio/.gitkeep`, `docs/HANDOFF.md`
- Test: `test/app_smoke_test.dart` (replaces the counter `test/widget_test.dart`)

**Interfaces:**
- Produces: `abstract final class AppColors` with the 10 `static const Color` fields named in Global Constraints (`primary, accent, piece, sky, ink, bridge, cliff, vehicle, correct, wrong`); `ThemeData buildAppTheme()`; `class BridgeItApp extends StatelessWidget` (`const BridgeItApp({super.key, Widget? home})`, which Task 4 replaces with routes).

- [x] **Step 1: Write the failing test** `app starts and shows BridgeIt title`: pump `const BridgeItApp()`, expect `find.text('BridgeIt')` once and `Theme.of(context).colorScheme.primary == AppColors.primary`.
- [x] **Step 2: Run it**, `flutter test test/app_smoke_test.dart`. Expected: FAIL (no `BridgeItApp`).
- [x] **Step 3: Implement** `AppColors`, `buildAppTheme()` (seeded `ColorScheme` with `primary: AppColors.primary`, `surface: AppColors.sky`, `onSurface: AppColors.ink`), `BridgeItApp`, and `main()`. `main()` locks portrait with `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`. The placeholder home shows the SVG logo and the title.
- [x] **Step 4: Run** `flutter analyze` (No issues found), `flutter test` (all pass), and `flutter build apk --debug` (Built build\app\outputs\flutter-apk\app-debug.apk).
- [x] **Step 5: Commit** `chore: scaffold Flutter app with placeholder theme and logo`.

### Task 2: Content models and loader

**Files:**
- Create: `lib/content/models.dart`, `lib/content/content_repository.dart`, `assets/content/levels.json`
- Test: `test/content/content_repository_test.dart`

**Interfaces:**
- Produces:
  - `const List<String> fanboys = ['for','and','nor','but','or','yet','so'];`
  - `sealed class LyricPart`, with `final class TextPart(String text)` and `final class BlankPart(String answer)`
  - `class Verse { String title; List<List<LyricPart>> lines; }`
  - `class Level1Content { String? audioAsset; List<Verse> verses; }`
  - `class BridgeSentence { String left; String right; List<String> answers; Map<String,String> hints; String defaultHint; List<String> synonymChoices; String? synonymAnswer; }`
  - `class BridgeLevelContent { int maxWrongAnswers; List<BridgeSentence> sentences; }`
  - `class GameContent { Map<int,String> unlockCodes; Level1Content level1; BridgeLevelContent level2; BridgeLevelContent level3; }`
  - `class ContentException implements Exception { final String message; }`
  - `List<LyricPart> parseLyricLine(String line)`: `{word}` marks a blank.
  - `GameContent parseGameContent(String json)`
  - `Future<GameContent> loadGameContent(AssetBundle bundle, {String path = 'assets/content/levels.json'})`

`levels.json` shape (top-level keys are fixed; `_note` keys are ignored):
```json
{
  "_note": "PLACEHOLDER content until the client answers Q4, Q6, Q8.",
  "unlockCodes": {"2": "BRIDGE2", "3": "BRIDGE3"},
  "level1": {"audioAsset": null, "verses": [{"title": "Verse 2: The FANBOYS", "lines": ["F is {for}, and A is {and},", "N is {nor}, now understand!", "B is {but}, O is {or},", "Y is {yet}, S is {so}!"]}]},
  "level2": {"maxWrongAnswers": 3, "sentences": [{"left": "I'm very tired,", "right": "I will sleep.", "answers": ["so"], "hints": {"but": "\"But\" shows a contrast, but sleeping is a result of being tired."}, "defaultHint": "That word doesn't connect these ideas. Think about how they relate."}]},
  "level3": {"maxWrongAnswers": 3, "sentences": [{"left": "I'm very tired,", "right": "I will sleep.", "answers": ["so"], "hints": {}, "defaultHint": "...", "synonymChoices": ["therefore", "however", "also", "or else"], "synonymAnswer": "therefore"}]}
}
```
Fill Level 1 with Verses 2 and 3 of the client's lyrics (from the Canva PDF), with every FANBOYS word as a blank. Level 2 gets 3 sample sentences, including one with two answers (`["but","yet"]`). Level 3 gets 2 sentences that use the known pairs (so→therefore, but→however).

- [ ] **Step 1: Write failing tests**:
  - `parseLyricLine splits text and blanks`: `"B is {but}, O is {or},"` gives `[TextPart('B is '), BlankPart('but'), TextPart(', O is '), BlankPart('or'), TextPart(',')]`.
  - `parseLyricLine throws on unclosed brace`: `"B is {but"` throws `ContentException`.
  - `parses the bundled levels.json`: `loadGameContent(rootBundle)` gives `level2.maxWrongAnswers == 3` and `unlockCodes[2] == 'BRIDGE2'`.
  - `rejects non-FANBOYS answer`: an answer of `"because"` throws `ContentException` whose message contains `level2.sentences[0].answers`.
  - `rejects missing field`: JSON without `level3` throws `ContentException` whose message contains `level3`.
  - `rejects synonymAnswer not in synonymChoices`.
- [ ] **Step 2: Run** `flutter test test/content/content_repository_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** the models (immutable, `const` constructors) and the parser. Each `ContentException` message names the JSON path, e.g. `level2.sentences[0].answers`. Register `assets/content/` in `pubspec.yaml`.
- [ ] **Step 4: Run tests.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: content models and levels.json loader`.

### Task 3: Progress and unlock codes

**Files:**
- Create: `lib/progress/progress_store.dart`
- Test: `test/progress/progress_store_test.dart`

**Interfaces:**
- Consumes: `GameContent.unlockCodes` (Task 2).
- Produces: `class ProgressStore extends ChangeNotifier { ProgressStore(SharedPreferences prefs, Map<int,String> unlockCodes); bool isUnlocked(int level); bool isCompleted(int level); bool tryUnlock(int level, String code); Future<void> markCompleted(int level); }`. Level 1 is always unlocked. It persists to prefs keys `unlocked_levels` and `completed_levels` (List<String>).

- [ ] **Step 1: Write failing tests** (use `SharedPreferences.setMockInitialValues({})`):
  - `level 1 unlocked, 2 and 3 locked by default`.
  - `correct code unlocks only that level`: `tryUnlock(2,'BRIDGE2')` returns true; `isUnlocked(3)` stays false.
  - `code is trimmed and case-insensitive`: `tryUnlock(2,'  bridge2 ')` returns true.
  - `wrong code returns false and changes nothing`.
  - `progress survives a new store instance`: unlock 2 and mark 1 completed, then build a new `ProgressStore` on the same prefs and check both persist.
  - `notifies listeners on unlock`.
- [ ] **Step 2: Run** `flutter test test/progress/progress_store_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement `ProgressStore`.**
- [ ] **Step 4: Run tests.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: progress store with teacher unlock codes`.

### Task 4: App shell, intro and level menu

**Files:**
- Modify: `lib/app.dart`, `lib/main.dart`
- Create: `lib/screens/intro_screen.dart`, `lib/screens/level_menu_screen.dart`, `lib/screens/content_error_screen.dart`
- Test: `test/screens/level_menu_screen_test.dart`, `test/screens/content_error_screen_test.dart`

**Interfaces:**
- Consumes: `GameContent`, `ProgressStore`, `loadGameContent`, `ContentException`.
- Produces: named routes `/` (intro), `/levels`, `/level/1`, `/level/2`, `/level/3`. `BridgeItApp({required GameContent content, required ProgressStore progress})` provides both with `MultiProvider`. `ContentErrorScreen({required String message})` is shown by `main()` when loading throws `ContentException`. Level screens are pushed by route, and each calls `context.read<ProgressStore>().markCompleted(n)` when finished.

Layout follows `BridgeIt-Wireframes.pdf` screens 1–2. On the intro, a "[Character art]" placeholder box, the client's greeting text, and a "Let's start" button that goes to `/levels`. The menu has three level cards (done / unlocked / locked with "Ask your teacher for the code") and a code field with an "Unlock" button. Which level a code unlocks: the lowest locked level.

- [ ] **Step 1: Write failing widget tests:**
  - `locked level cannot be opened`: tapping the Level 3 card stays on the menu.
  - `entering the right code unlocks level 2`: enter `BRIDGE2`, tap Unlock, and the Level 2 card shows "Play level 2".
  - `wrong code shows an error`: shows "That code didn't work. Check with your teacher." and the field keeps its text.
  - `content error screen shows the message`: `ContentErrorScreen(message: 'level3 is missing')` shows that text.
- [ ] **Step 2: Run** them. Expected: FAIL.
- [ ] **Step 3: Implement** the screens and routes. `main()` loads prefs and content before `runApp`.
- [ ] **Step 4: Run** `flutter test`. Expected: all PASS.
- [ ] **Step 5: Commit** `feat: intro screen, level menu and unlock flow`.

### Task 5: Level 1, song and fill-in-the-blanks

**Files:**
- Create: `lib/game/blanks_round.dart`, `lib/widgets/song_player.dart`, `lib/screens/level1_screen.dart`
- Test: `test/game/blanks_round_test.dart`, `test/screens/level1_screen_test.dart`

**Interfaces:**
- Consumes: `Level1Content`, `BlankPart`, `fanboys`, `ProgressStore.markCompleted`.
- Produces:
  - `enum BlankResult { correct, wrong, alreadyFilled }`
  - `class BlanksRound { BlanksRound(List<Verse> verses); int get blankCount; String? filledAt(int blankIndex); BlankResult place(int blankIndex, String word); bool get isComplete; }`. Blank indexes run across all verses in order.
  - `SongPlayer({String? assetPath})`

Interaction (wireframe screen 3): tap a word in the 7-word bank, then tap a blank. A correct word fills the blank in green with a check icon. A wrong word flashes red and shows the hint "Not quite. Try again!"; the blank stays empty and retries are unlimited. "Next verse" moves between verses. After the last blank, call `markCompleted(1)` and show "Level 1 done! Ask your teacher for the code."

- [ ] **Step 1: Write failing tests:**
  - `correct word fills blank`.
  - `wrong word leaves blank empty and can retry forever`: 10 wrong tries, then the correct one works.
  - `filled blank reports alreadyFilled`.
  - `isComplete after all blanks`.
  - Widget test `song player without audio shows Song coming soon`: `SongPlayer(assetPath: null)` shows "Song coming soon". Level 1 can still be completed by filling every blank.
- [ ] **Step 2: Run** them. Expected: FAIL.
- [ ] **Step 3: Implement.** `SongPlayer` uses `just_audio` `AudioPlayer.setAsset`. If the path is null or `setAsset` throws, it shows "Song coming soon" and no controls. It disposes the player in `dispose()`.
- [ ] **Step 4: Run tests.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: level 1 song player and fill-in-the-blanks`.

### Task 6: Bridge and synonym game rules

**Files:**
- Create: `lib/game/bridge_round.dart`
- Test: `test/game/bridge_round_test.dart`

**Interfaces:**
- Consumes: `BridgeSentence`.
- Produces:
  - `enum DropResult { correct, wrong, broken, ignored }`
  - `class BridgeRound { BridgeRound(BridgeSentence sentence, {required int maxWrongAnswers}); DropResult drop(String word); int get wrongCount; bool get isBuilt; bool get isBroken; Set<String> get triedWrong; String hintFor(String word); void reset(); }`
  - `class SynonymRound { SynonymRound(BridgeSentence sentence, {required int maxWrongAnswers}); DropResult choose(String option); bool get isReinforced; bool get isBroken; Set<String> get triedWrong; void reset(); }`

Rules:
- A word in `answers` returns correct and builds the bridge.
- Any other word adds 1 to `wrongCount` and is added to `triedWrong`. It returns wrong, or broken once `wrongCount == maxWrongAnswers`.
- A word already in `triedWrong` returns ignored.
- Any drop after built or broken returns ignored.
- `hintFor` returns `hints[word]` if present, else `defaultHint`.
- `reset()` clears everything.
- `SynonymRound` follows the same rules, using `synonymAnswer` instead of `answers`.

- [ ] **Step 1: Write failing tests:**
  - `correct answer builds`.
  - `either of two answers builds` (answers `['but','yet']`).
  - `wrong answers crack then break at max`: with max 3, the results are wrong, wrong, broken.
  - `same wrong word twice is ignored and counted once`.
  - `drop after built is ignored`.
  - `hint falls back to defaultHint`.
  - `reset restores a fresh round`.
  - `synonym correct reinforces`.
  - `synonym wrong breaks at max`.
- [ ] **Step 2: Run** `flutter test test/game/bridge_round_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run tests.** Expected: PASS.
- [ ] **Step 5: Commit** `feat: bridge and synonym round rules`.

### Task 7: Level 2 screen, building the bridge

**Files:**
- Create: `lib/widgets/bridge_scene.dart`, `lib/widgets/conjunction_piece.dart`, `lib/widgets/hint_card.dart`, `lib/screens/level2_screen.dart`
- Test: `test/screens/level2_screen_test.dart`

**Interfaces:**
- Consumes: `BridgeLevelContent`, `BridgeRound`, `DropResult`, `fanboys`, `ProgressStore.markCompleted`.
- Produces:
  - `enum BridgeState { open, cracked, built, broken, reinforced }`
  - `BridgeScene({required BridgeState state, required String left, required String right, String? placedWord, required Widget gap})`: cliffs, river, bridge and vehicle, drawn with `CustomPainter`. The vehicle moves with `AnimatedAlign` to the far side when built.
  - `ConjunctionPiece({required String word, required bool enabled, VoidCallback? onTap})`: a `Draggable<String>` with a 48 dp minimum.
  - `HintCard({required String text, required bool correct})`

Interaction (wireframe screens 4a and 4b):
- The gap is a `DragTarget<String>`. Tapping a piece then tapping the gap also works, as an accessibility fallback.
- Pieces in `triedWrong` are greyed out and disabled.
- A wrong drop cracks the bridge and shows `hintFor(word)`.
- A broken bridge shows "The bridge broke! Let's try this sentence again." and a "Try again" button that calls `reset()`.
- After a correct drop, the vehicle crosses and "Next sentence" appears.
- After the last sentence, call `markCompleted(2)` and show "Level 2 done! Ask your teacher for the code."
- A bridge-strength bar shows `maxWrongAnswers - wrongCount` segments.

- [ ] **Step 1: Write failing widget tests** (use the bundled content):
  - `dragging the correct piece builds the bridge`: shows "Next sentence".
  - `wrong piece shows the hint and greys out`.
  - `three wrong pieces break the bridge`: shows "Try again", and tapping it re-enables all pieces.
  - `finishing all sentences marks level 2 completed`.
- [ ] **Step 2: Run** them. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test`. Expected: all PASS.
- [ ] **Step 5: Commit** `feat: level 2 bridge building screen`.

### Task 8: Level 3 screen, strengthening the bridge

**Files:**
- Create: `lib/screens/level3_screen.dart`
- Test: `test/screens/level3_screen_test.dart`

**Interfaces:**
- Consumes: `BridgeScene`, `ConjunctionPiece`, `HintCard`, `BridgeRound`, `SynonymRound`, `ProgressStore.markCompleted`.

Interaction (wireframe screen 5):
- Step 1, "Build", works like Level 2.
- Step 2, "Strengthen": the bridge is drawn as "wobbly" (dashed supports), with the question "Pick the word that means the same as "<answer>"." The `synonymChoices` appear as a 2×2 grid of buttons.
- A wrong choice cracks the bridge and shows a hint, using the same break rule.
- A correct choice sets the state to reinforced and shows the "Reinforce the bridge" button.
- After the last sentence, call `markCompleted(3)` and show "You reached the destination!"

- [ ] **Step 1: Write failing widget tests:**
  - `build then pick synonym reinforces`.
  - `wrong synonym shows hint`.
  - `finishing marks level 3 completed`.
- [ ] **Step 2: Run** them. Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test`. Expected: all PASS.
- [ ] **Step 5: Commit** `feat: level 3 strengthen-the-bridge screen`.

### Task 9: Bundled fonts and release APK

**Files:**
- Create: `assets/fonts/Nunito-Regular.ttf`, `Nunito-Bold.ttf`, `Nunito-ExtraBold.ttf`, `AbrilFatface-Regular.ttf`, plus their `OFL.txt` license files. Download them from the official google/fonts GitHub repo after the user approves the download.
- Modify: `pubspec.yaml` (`fonts:`), `lib/theme/app_theme.dart` (`fontFamily: 'Nunito'`, title style `'AbrilFatface'`), `android/app/build.gradle.kts` (release `signingConfig` read from `android/key.properties` when present, falling back to the debug key), `.gitignore` (`android/key.properties`, `*.jks`).

- [ ] **Step 1: Write failing test** `theme uses bundled Nunito`: `buildAppTheme().textTheme.bodyMedium!.fontFamily == 'Nunito'`.
- [ ] **Step 2: Run** it. Expected: FAIL.
- [ ] **Step 3: Implement.** Do not create the real keystore; that is the user's step, and the key is never committed.
- [ ] **Step 4: Run** `flutter test` and `flutter build apk --release`. Expected: PASS, and `app-release.apk` is built.
- [ ] **Step 5: Commit** `chore: bundle fonts and release build config`.

---

**Not in this plan (waiting on the client):**
- Final sentences and synonyms (Q4, Q6, Q8): edits to `levels.json` only.
- The final break rule (Q5): may change `BridgeRound`.
- Final logo, palette and art (Q10, Q12): `AppColors` and `BridgeScene`.
- The song file (Q14): set `level1.audioAsset`.
- Result logging and backend (Q7).
