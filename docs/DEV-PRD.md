# BridgeIt v2 – developer PRD

Last updated: 1 November 2026

The technical companion to the client PRD ([PRD.md](PRD.md), v2.1). The client PRD says *what* the app does; this file says *how* we build it on top of the Phase 1 code. If the two disagree, the client PRD wins on behaviour and this file gets fixed.

Sources: client PRD v2.0, the design review doc with the client's red answers, and the Canva screens "BridgeIt Pre-design" (39 pages).

## 1. Constraints

| Area | Rule |
|---|---|
| Platform | Android phones, portrait only, English only |
| Network | Fully offline after install. No backend, no accounts, no analytics |
| Toolchain | Flutter 3.47.7 / Dart 3.13.5 everywhere, CI included |
| Content | Every sentence, hint, word list, caption, limit and code lives in `assets/content/levels.json`, never in Dart |
| Colors | Only through `AppColors` in `lib/theme/app_theme.dart` |
| Packages | Current: `provider`, `just_audio`, `shared_preferences`, `flutter_svg`. New ones need a reason (Section 9) |
| Logic | Game rules stay pure Dart in `lib/game/`, with unit tests, no Flutter imports |

## 2. What changes from Phase 1

| Phase 1 code | v2 |
|---|---|
| `IntroScreen` | Split into Start (logo + play) and Welcome (story + name/section form) |
| `LevelMenuScreen`, `UnlockCodeForm`, `ProgressStore.tryUnlock` | Keep. Codes are only entered in the menu |
| `Level1Screen`, `BlanksRound` | **Replace** with song step (play counter, sing-along card) + MatchIt. Delete `BlanksRound` and its tests |
| `SongPlayer` | Keep; add a completed-plays counter and a sync position stream for the lyric card |
| `Level2Screen`, `BridgeRound` | Keep the drag/drop core. Add the 7-bridge sequence, collapse/restart, and the writing steps |
| `Level3Screen`, `SynonymRound` | **Replace** with the Travelogue flow. Delete `SynonymRound` and its tests |
| `BridgeScene`, `PieceTray`, `ConjunctionPiece`, `BridgeGap`, `HintCard` | Reuse; restyle to the Canva art; `BridgeScene` gains foundation layers under the deck |
| `StrengthBar` | Drop unless a screen needs it |
| `LevelDonePanel` | Rework into the end-of-level panel with **Send my answers** |
| `ContentRepository`, `models.dart` | Rewrite for the v2 schema (Section 4) with the same `ContentException` path messages |

## 3. Navigation

Named routes in `app.dart`, as today:

| Route | Screen |
|---|---|
| `/` | `StartScreen` |
| `/welcome` | `WelcomeScreen` (shown once; skipped when a profile exists) |
| `/levels` | `LevelMenuScreen` |
| `/level/1` | `Level1Screen`: song → MatchIt intro → MatchIt → done |
| `/level/2` | `Level2Screen`: story → bridges 1..7 → toll gate → done |
| `/level/3` | `Level3Screen`: toll gate → map → montage → instructions → travelogue → ending |

Steps inside a level are a local state machine (an enum per screen), not routes, so Android back leaves the level instead of stepping back through it. The map icon opens a `JourneySheet` bottom sheet on every level screen.

## 4. Content schema v2 (`levels.json`)

```jsonc
{
  "schemaVersion": 2,
  "unlockCodes": { "2": "BRIDGE2", "3": "BRIDGE3" },

  "level1": {
    "audioAsset": null,                 // "assets/audio/theme_song.mp3" once delivered
    "playsRequired": 3,
    "lyrics": [                         // sing-along card; startMs from the client's timings
      { "startMs": 0,     "text": "And is when we join similar situations", "image": null },
      { "startMs": 12000, "text": "Nor is used when none chosen from the given option", "image": null }
    ],
    "matchIt": [                        // function text = Canva page 8 / PRD Section 8
      { "conjunction": "for", "function": "Expresses a reason or explanation." }
      // ... 7 entries, one per FANBOYS word
    ]
  },

  "level2": {
    "maxWrongAnswers": 3,
    "bridges": [                        // exactly 7, one per FANBOYS word, in play order
      {
        "conjunction": "for",
        "left": "She went to bed early",
        "right": "she was tired.",
        "explanation": "'she was tired' explains why 'She went to bed early', so we use 'for'.",
        "hints": { "so": "'so' is used to show result or consequence." },
        "defaultHint": "That word doesn't connect these ideas. Think about how they relate.",
        "examples": ["I stayed home, for it was raining heavily."]
      }
    ]
  },

  "quickFacts": {                       // no entry (or []) for nor / or = one sentence only
    "for": [ { "word": "because", "rule": "joining" }, { "word": "since", "rule": "joining" }, { "word": "as", "rule": "joining" } ],
    "and": [ { "word": "moreover", "rule": "linking" }, { "word": "in addition", "rule": "linking" }, { "word": "furthermore", "rule": "linking" } ],
    "but": [ { "word": "however", "rule": "linking" }, { "word": "although", "rule": "joining" } ],
    "yet": [ { "word": "nevertheless", "rule": "linking" }, { "word": "even though", "rule": "joining" } ],
    "so":  [ { "word": "therefore", "rule": "linking" }, { "word": "as a result", "rule": "linking" } ]
  },

  "writing": { "minClauseWords": 2 },

  "level3": {
    "musicAsset": "assets/audio/montage_placeholder.mp3",
    "travelogue": { "minSentences": 5, "maxSentences": 7, "minConjunctions": 4 },
    "places": [                         // exactly 7
      {
        "id": "la_paz",
        "name": "Laoag La Paz Sand Dunes",
        "mapPin": { "x": 0.42, "y": 0.18 },   // fraction of the map image
        "pictures": [                          // exactly 5
          { "asset": "assets/images/places/la_paz/1.webp", "caption": "The La Paz Sand Dunes stretch along the coast of Laoag City." }
        ]
      }
    ]
  }
}
```

Validation (in `ContentRepository`, failing with a `ContentException` that names the JSON path):

- 7 `matchIt` entries and 7 `bridges`, each FANBOYS word exactly once.
- Every bridge's `hints` keys are FANBOYS words other than its own.
- `quickFacts` keys are FANBOYS words; `rule` is `joining` or `linking`.
- 7 places with 5 pictures each; `mapPin` values in 0..1.
- `minSentences <= maxSentences`, all limits >= 1.
- Lyric `startMs` strictly increasing.

The placeholder captions are the ones in client PRD Appendix A. Placeholder bridges reuse the Phase 1 sentences where they fit; replace the "I studied for hours," pair (it uses *for* as a preposition).

## 5. Game logic (`lib/game/`, pure Dart)

### 5.1 `MatchItRound`

- State: slot → placed function (nullable) for the 7 conjunctions.
- `place(conjunction, function)` / `remove(conjunction)` handle drag and tap-tap the same way.
- `submit()` returns the wrong slots, clears them (their functions go back to the tray), keeps the right ones, and appends `{attempt, wrong: [...]}` to its log. Done when all 7 are right.

### 5.2 `BridgeRound` (existing)

Keep `drop`, `triedWrong` (drives the fade), `isBroken`, `reset`. The screen adds per-bridge stats: total wrong tries across resets, collapse count, time.

### 5.3 `SentenceChecker`

Input: text, target word, its rule (`fanboys`, `joining`, `linking`), and the strings it must not copy (bridge clauses, examples, the student's earlier sentences). Output:

```dart
sealed class CheckResult {}
final class Passed extends CheckResult { final bool unsureClause; }  // unsure → show hint, still pass
final class Failed extends CheckResult { final CheckFailure reason; } // one message per reason
```

Pipeline; the first failure wins:

| # | Step | Fails when | `CheckFailure` |
|---|---|---|---|
| 1 | Normalise | – (trim, collapse spaces, straight quotes) | – |
| 2 | Shape | empty; no capital at start; no . ! ? at end; more than one sentence | `empty`, `capital`, `endPunctuation`, `oneSentence` |
| 3 | Junk | a run of 4+ same letters; a word over 20 letters; under 60% letters | `notReal` |
| 4 | Target word | whole-word, case-insensitive match missing (phrases like *as a result* allowed) | `missingWord` |
| 5 | Punctuation | `fanboys`: no comma right before. `linking`: no `;` before or no `,` after. `joining`: a comma before the word in mid-sentence, or no comma after a sentence-initial clause | `comma`, `extraComma`, `semicolon` |
| 6 | Split | – left/right of the word. Sentence-initial `joining` word splits at the first comma | – |
| 7 | Clause check | either side fails (5.4). A command on the left allows a command on the right | `leftClause`, `rightClause` |
| 8 | *Nor* | no negative in the left clause, or the right clause isn't inverted | `norNeedsNegative`, `norWordOrder` |
| 9 | Copy | normalised text equals a forbidden string | `copied` |

Rules follow Purdue OWL and Cambridge; the client notice `docs/client/BridgeIt-Checker-Changes.md` lists the sources and open client decisions.

### 5.4 Clause check

For one side:

1. Strip punctuation, tokenise, lowercase.
2. Fewer than `minClauseWords` words → **fail**.
3. Starts with a preposition (`to, in, on, at, with, of, from, by, for, about, into`) and has no verb → **fail** (phrase).
4. Find the first verb: a token in `assets/lexicon/verbs.txt` (common verbs, all forms) or an auxiliary (`am is are was were be been being has have had do does did can could will would shall should may might must`).
   - none, but a token ends in *-ed*/*-s* and isn't a known noun-ish stop word → **unsure**
   - none at all → **fail**
5. A subject token before that verb: pronoun (`i you he she it we they`), determiner/pointer (`the a an my your his her its our their this that these those there some many every each`), or a capitalised word in the original text that isn't sentence-initial.
   - a capitalised sentence-initial word before the verb also counts ("Maria sings")
   - the verb is first but an auxiliary followed by a subject → pass (inverted: "nor does he drink tea", "did you skip it")
   - none and the side is the left side of a sentence-initial verb (imperative, "Hurry, or …") → **unsure**
   - none, the verb is first → **fail**
   - none, but other words come before the verb → **unsure** (a noun the lists can't know: "dogs like me")

A side opening with a dependent marker and holding no comma fails (*although, though, because, if, unless, when, whenever, whether, while, whatever, even though, even if*); *after, before, since, until, as* give **unsure**, since they can be prepositions. A word right after a determiner isn't taken as a verb ("the rain"). `minClauseWords` is 2, since "She smiled" is a clause and phrases already fail on having no verb. Known limit: a noun in the verb list after an adjective reads as a verb, so "To the big park" passes. The check stays lenient on purpose: a good sentence must not be blocked.

### 5.5 `TravelogueAnalyzer`

- Split sentences at `[.!?]` followed by whitespace or end.
- Candidates: each FANBOYS word with a comma right before it.
- A candidate counts when the clause check passes (not unsure-fail) on the text from the previous boundary (sentence start, or the previous counted candidate) to the comma, and from the word to the next candidate or the sentence end.
- Returns sentence count, counted conjunction spans (for green highlight), uncounted spans (grey), and `canSubmit`.
- The screen re-runs it on a 300 ms debounce.

### 5.6 `SpellChecker`

- Dictionary: `assets/lexicon/words.txt`, a lowercase English word list (about 82k words, American spelling, public domain; source in the file header and README).
- Skipped: words with digits and words capitalised mid-sentence (names). The screen passes place names, Quick Facts words and caption words such as *sandboard* in `allowed`.
- A name at the start of a sentence is flagged. That's only a warning, so it stays: skipping it would hide typos in first words.
- Returns misspelt spans for underlining. Never blocks Submit; the count goes into the report.

### 5.7 `ActiveTimer`

Stopwatch per level and per bridge, paused by an `AppLifecycleListener` on `paused`/`inactive` and resumed on `resumed`. The widget layer owns the listener; the timer itself stays pure Dart.

## 6. Persistence

`shared_preferences`, JSON strings, versioned. `ResultsStore` exists with `profile_v1`; `results_v1` and `level2_resume_v1` arrive with tasks 6 and 8.

| Key | Contents |
|---|---|
| `unlocked_levels`, `completed_levels` | As Phase 1 |
| `profile_v1` | `{name, section}` |
| `results_v1` | Level 1/2/3 result objects (Section 7 fields). A level's result is **frozen** at its first completion; replays don't overwrite it |
| `level2_resume_v1` | `{bridgeIndex, step, sentencesSoFar}`, so a student continues at the bridge where they stopped |
| `sound_on` | bool |

Wrap reads in try/catch and treat bad JSON as empty, so a corrupt value can't brick the app. A `ResultsStore` (ChangeNotifier) beside `ProgressStore` owns `profile_v1`, `results_v1` and `level2_resume_v1`.

## 7. Answer report (PDF)

- **Trigger:** **Send my answers** on each end-of-level panel and on the ending screen. Builds the report from `results_v1` (all levels done so far) and opens the system share sheet.
- **Build:** `pdf` package. Embed fonts from TTF, because the `pdf` package can't use the variable Nunito; bundle static Nunito Regular and Bold (OFL), or fall back to the built-in Helvetica.
- **File:** written to the temp dir (`path_provider`), shared with `share_plus` as `BridgeIt_<section>_<name>_<yyyy-mm-dd>.pdf`, with names sanitised to `[A-Za-z0-9_-]`.
- **Contents:**

| Section | Fields |
|---|---|
| Header | name, section, date/time, app version (a build-time constant) |
| Level 1 | song plays, MatchIt attempts with the wrong pairs per attempt, active time |
| Level 2 | per bridge: conjunction, wrong tries, collapses, active time, each written sentence (final text, attempts, spelling warnings, unsure flag) |
| Level 3 | place, travelogue text, sentence count, counted conjunctions, spelling warnings, active time |
| Totals | active time per level and overall |

## 8. Screens

| Screen | Notes |
|---|---|
| Start | Logo + play. Logo is `assets/images/logo.svg` |
| Welcome | Speech bubbles from Canva page 2, then name + section form (both required, trimmed, max 40 chars) |
| Level menu | Canva pages 3/9/18: three cards, tick when completed, code box |
| Level 1 | Driver's-seat background; song card with play counter; sing-along card synced to `startMs`; MatchIt intro (Yes / listen again); MatchIt board with drag targets and tap-select; Submit |
| Level 2 | Story card → per bridge: `BridgeScene` with the two clauses, `PieceTray` (wrong pieces fade), Cross the bridge, hint/explanation card, collapse animation on the 3rd wrong try; then a writing panel (single text field, check result message, spelling underline); Quick Facts popover from tapping the conjunction; foundations stack under the deck; car crosses; resume support |
| Level 3 | Toll gate scene; map with 7 pins (tap → car moves to the pin); montage: 5 images, ~4 s each, Ken Burns zoom + crossfade, caption bar, music via `just_audio`, Skip after the first pass; instructions notebook; travelogue editor with highlight spans, counter, Submit; ending |
| Journey sheet | Levels done + car position along a simple path |

Text from the screens gets the typo fixes in client PRD Section 9.

## 9. Dependencies to add

| Package | Why |
|---|---|
| `pdf` | Build the answer report offline |
| `share_plus` | Open the Android share sheet (Messenger, email, Drive, Bluetooth, Nearby Share) |
| `path_provider` | Temp file for the PDF before sharing |

Pin exact versions that support Dart 3.13 and add them in one commit with a note in `PROJECT_NOTES.md`.

## 10. Assets

| Asset | Path | Status |
|---|---|---|
| Logo | `assets/images/logo.svg` | Done: our vector redraw in the logo colors |
| Character | `assets/images/girl_wave.svg` | Waving pose done; we draw the others as SVG from the same parts |
| App icon | `android/app/src/main/res/mipmap-*` | We make a simplified icon-only logo; hangers get too dense at small sizes |
| Scenes, car, bridge parts | `assets/images/scenes/…` | We make them, SVG, in the same outline style |
| Montage pictures (35) | `assets/images/places/<id>/1..5.webp` | We source free-licensed photos (Wikimedia Commons, Pexels); record source + license in README |
| Map | `assets/images/map.svg` | We make it. `level3` pins are placeholders until then |
| Theme song | `assets/audio/theme_song.mp3` | Client, expected 7 November, with line timings |
| Montage music | `assets/audio/montage_placeholder.mp3` | Free track licensed for apps (e.g. Pixabay); record the source + license in README; replace if the client sends one |
| Lexicons | `assets/lexicon/verbs.txt`, `words.txt` | `verbs.txt` done: WordNet 3.1 verbs filtered by sense counts, forms from NGSL 1.2 (CC BY-SA 4.0), sources in the file header and README. `words.txt` done: 2of12inf from 12dicts 6.0.2 (public domain), about 82k words |

The client owes only the 7 sentence pairs, the song and its timings; the art is ours, with the client's full permission. Use SVG for drawn art and WebP for photos, max 1080 px on the long side, to keep the APK small. Asset paths in `levels.json` name the expected locations until the files exist.

## 11. Theme

- **Colors:** set from the logo: navy `#183870` → `primary`/`ink`, teal `#309090` → `teal`, light teal `#80C0A8` → `lightTeal`, orange `#D88858` → `accent`/`piece`, background `#E6F5FF` → `sky`. `test/theme/app_theme_test.dart` checks text contrast ≥ 4.5:1. Navy on orange is 4.1:1, so use that pair only for large bold text.
- **Logo:** `logo.svg` is pure vector and renders in `flutter_svg`, including `<use>`, clip paths and gradients. Keep new SVGs to those features; no `<filter>` or `<mask>`.
- **Fonts:** Nunito only. The "BridgeIt" text and AbrilFatface are gone, since the logo holds the wordmark.

## 12. Testing

- **Unit:**
  - `MatchItRound`, `BridgeRound` stats, `ActiveTimer` with a fake clock, `ResultsStore` (freeze on first completion, corrupt JSON)
  - `SentenceChecker`: a table of at least 60 sentences covering every `CheckFailure`, every rule type, sentence-initial joining words, imperatives, prepositions after *for*, phrases after *and*, and copies
  - `TravelogueAnalyzer`: counts, spans, limits
  - `SpellChecker`
  - `ContentRepository`: every validation message
- **Widget:**
  - each level's step flow with a test content fixture
  - drag and tap in MatchIt
  - fade and collapse in Level 2
  - Submit enable/disable in the travelogue
  - Send my answers builds a PDF (share mocked)
- **Remove:** the `BlanksRound`/`SynonymRound` tests and the old Level 1/3 screen tests.
- **CI:** unchanged (`flutter analyze`, `flutter test`).
- **Manual on a real phone:** 360×640, text scale 1.3×, keyboard over the writing field, back gesture mid-drag, app backgrounded during the song and the montage (timer pauses), and the share sheet to Messenger and Bluetooth.

## 13. Build order and estimate (working days)

| # | Task | Days | Status |
|---|---|---|---|
| 1 | Schema v2, models, repository + validation, placeholder content | 2 | Done |
| 2 | Theme from logo, Start, Welcome + profile, menu restyle, journey sheet | 2–3 | Done |
| 3 | Level 1: song counter, sing-along card, MatchIt round + screen | 4–5 | Done, needs art |
| 4 | `SentenceChecker`, clause check, lexicons, tests | 3–4 | Done, not wired to a screen until task 6 |
| 5 | `SpellChecker` + word list | 1–2 | Done, not wired to a screen until task 6 |
| 6 | Level 2: 7-bridge flow, collapse, writing steps, Quick Facts, foundations, resume | 4–5 | Next |
| 7 | Level 3: toll gate, map, montage player, `TravelogueAnalyzer`, editor, ending | 4–5 | |
| 8 | `ActiveTimer`, `ResultsStore` results, PDF report, share | 3 | |
| 9 | Art: character poses, scenes, car, bridge parts, map, 35 photos, app icon | 4–6 | Logo and waving pose done |
| 10 | Swap in client song, timings, sentences | 1 | |
| 11 | Real-phone testing, fixes, one client review round | 3–4 | |
| | **Total** | **30–39** | |

**Deadline: 21 November 2026.** That leaves about 14 working days from 1 November, against 26–34 days of estimate remaining, so polish gets cut first (journey sheet detail, Ken Burns zoom, foundation visuals). Tasks 1–9 run on placeholders; only task 10 waits for the client's files, due 7 November.

Level 3 is `LevelStubScreen` until task 7. Without audio, `SongPlayer` plays silently for the length of the placeholder lyrics, so Level 1 stays playable. Lyric images and the driver's-seat background wait for task 9. The play count isn't saved yet: leaving Level 1 before finishing resets it.

## 14. Open items (from client PRD Section 11)

| Item | Placeholder until then |
|---|---|
| Grade level, teacher-guided or self-paced | None needed for the build |
| Unlock codes | `BRIDGE2` / `BRIDGE3` |
| 7 Level 2 sentence pairs, explanations, hints (7 November) | Our sentences, starting with the Canva *for* example |
| 35 captions | Client PRD Appendix A |
| Song MP3 + line timings (7 November) | Silent `SongPlayer`, evenly spaced lyric lines |
| Montage music | Free licensed track |
| Sound effects | None |
| Client approval of the redrawn logo and our art | Current `logo.svg` and `girl_wave.svg` |
