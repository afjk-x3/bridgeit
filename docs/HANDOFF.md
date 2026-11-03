# Handoff: v2 redesign

Context for picking up this work in a new session. Read the latest session below first, then the older notes, [PRD.md](PRD.md) (client view) and [DEV-PRD.md](DEV-PRD.md) (build plan).

## Latest session: 3 November 2026 (afternoon)

**State of `v2`:** pushed to `origin/v2` with nothing uncommitted. `flutter analyze` is clean and 331 tests pass. The release APK on the [v0.2.0-test.1 release](https://github.com/afjk-x3/bridgeit/releases/tag/v0.2.0-test.1) (`BridgeIt-v0.2.0-test1.apk`) was replaced with a build of `1c3f200`. It is signed with the release key, so it installs over last night's build. The version is still `0.2.0+2`, the tag still points at its older commit, and the release notes don't mention this session's changes.

**Next step:** unchanged, client task 10 when their files arrive on 7 November (see below). Before sending the progress report, add this session's changes and ask the client to confirm the comma rule and approve the new logo.

**Done this session** (commits `68e7cef`, `a6775cf`, `be5ac47`, `1c3f200`):
1. **Logo** (`assets/images/logo.svg`): the owner's Gemini-made SVG traced from the client's resent logo (Google Drive), keeping their wordmark (the `3`-like B, the lunate `Є`). I fixed its ring weave: every arc endpoint now sits on its 30×24.5 ellipse (orange cx 309.5, teal cx 262.5, cy 127.5), so the orange arch redrawn over the teal has no seams. The letters use `C` curves; the owner preferred them to my H/V/A-only version. No `<mask>` or `<filter>` (flutter_svg).
2. **Level 2 story:** a new driver's-view `scenes/broken_bridge.svg` fills the screen behind the bubbles. "Oh no!…" is a white bubble with navy text (new `SpeechBubble.color`); "To cross…" is navy (`strong`).
3. **Deck railing removed** from `BridgeScene`; the main cables now end on the slab.
4. **One bridge everywhere:** `BridgeStrip` now shows `BuiltBridge` (in `bridge_scene.dart`), the same painters in their built state with no words. `bridge_strip*.svg` and `tool/bridge_art/` are deleted. The car loops on Start, Welcome and Level 3 "crossed" (6 s a lap) and stays still under reduce motion or a screen reader.
5. **Welcome on every Play:** a returning student sees "Hi, <name>!" and Next goes to the menu; a new student still gets the form.
6. **Travelogue comma rule kept:** a conjunction counts only with a comma before it and a full clause on each side. A comma-less clause join now shows greyed, without counting; both sides must pass the clause check as `ok`, so "rode and arrived" stays unmarked. The owner agreed; **the client hasn't confirmed it**.
7. **Map Drive button:** it locks once the car sets off. It used to stay enabled, and repeat taps restarted the drive.
8. **Back from the travelogue** (app bar or phone) goes to its instructions; the draft is kept.
9. **Place held after one montage pass:** Map hides and only Next shows. The place id and the draft are saved under prefs key `level3_resume_v1` (`ResultsStore.level3Resume`). Reopening Level 3 goes straight to the instructions until the travelogue is submitted, which clears the key.
10. **Instructions screen:** a numbered "Your entry needs" card (5 to 7 sentences; at least 4 conjunctions, shown as FANBOYS chips; a comma before each, with an example where the comma is orange and "but" is the editor's counted green). The five topics are bold teal.
11. **Montage timer** uses `AnimationBehavior.preserve`. Under the phone's reduce-motion setting, Flutter had been running it 20× faster, so each picture flashed past.

**Open from this session:**
- The Level 3 "crossed" bubble still says "Thank you, Bridge Builder!" rather than the student's name; the owner may want that too.
- `assets/images/icon.svg` (launcher icon) still follows the old logo drawing.
- The Wireframes v3 canvas doesn't show the driver's-view Level 2 story, the new instructions card, the hidden Map after a pass, or the removed railing.
- The client hasn't approved the new logo.
- The round "≡" button over the guide while typing on the emulator is Android's, not the app's.

**Testing notes from this session:**
- `test/support/pump_app.dart` now turns on reduce motion for every app test, because the looping car would stop `pumpAndSettle` from finishing. Anything timed that must not speed up under reduce motion needs `AnimationBehavior.preserve`.
- `openMenu` taps Play, then Next past a returning student's greeting. A new student stays on the greeting.
- **Emulator** (`Medium_Phone_API_36.1`, `emulator-5554`): `flutter run -d emulator-5554` from a terminal tab worked this time, including first launch. adb is at `$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe`. Drive the app with `adb shell input tap X Y`; screen pixels are 1.2× the 900-wide screenshots. In Git Bash, prefix `adb pull /sdcard/...` with `MSYS_NO_PATHCONV=1` and give a Windows-style local path. Local `sleep` is blocked, so wait with `adb shell sleep N`.
- The emulator's progress has a profile (Ana), Level 3 completed, and Saud Beach held with an empty draft.

## Earlier on 3 November 2026

**Next step:** client task 10 when their files arrive on 7 November (the 7 Level 2 sentence pairs, the song MP3 and the lyric timings). Then send the client [client/BridgeIt-Progress-Report-2026-11-03.md](client/BridgeIt-Progress-Report-2026-11-03.md). It lists what changed and what we still need from them.

**Done this session**, each with its plan and a git-ignored ledger of rulings under `.superpowers/sdd/<plan>/progress.md`:
1. **Design review fixes** ([plan](superpowers/plans/2026-11-03-review-fixes.md), spec [design-review/DECISIONS.md](design-review/DECISIONS.md)): 13 tasks, `a0f3310`–`a368443`.
   - readable disabled buttons; 14 px minimum text
   - clearer headers; all seven MatchIt rows fit
   - Quick Facts writing comes straight after the first sentence
   - a wrong piece stays in the gap with a hint about what it does
   - live sentence checklist; travelogue keyboard room and a Submit label that says what's missing
   - song player inside the lyrics card; montage header, dots and Map button
   - clauses on the bridge deck; the map rebuilt north to south
2. **One bridge everywhere** ([spec](superpowers/specs/2026-11-03-shared-bridge-design.md), [wireframe plan](superpowers/plans/2026-11-03-shared-bridge-wireframe.md), [app plan](superpowers/plans/2026-11-03-shared-bridge-app.md)):
   - Wireframes v3 version 44 has a "Bridge sheet" board showing every state.
   - In the app, `BridgeScene` draws it. Each accepted sentence becomes a numbered pier ("1 · for", "2 · because"), with the sentences in a caption.
   - `BridgeWobble` shakes the deck until the piers are in. It stops under reduce-motion or a screen reader.
   - Start, Welcome and Level 3 "crossed" show `BuiltBridge`, the same painters in their built state with no words. The car loops across on all three and stays still under reduce motion.
3. **Owner feedback after that:**
   - The Ending keeps its road and car.
   - The map hint line on Level 3 "crossed" is gone.
   - Wrong tries crack the left, then the right tower support; the third collapses the deck and the car falls in.
   - The car sits on the deck between the towers. The railing was later removed.
   - "1 try left" wording.
   - The small car has light wheel rims, so it shows on navy.
   - The map spreads its stops to fit the screen (no scrolling on a standard phone).
   - The MatchIt board keeps one height.
   - The MatchIt instructions match Wireframes v3.

**Not done / open:**
- **The Wireframes v3 canvas is behind the app** on the Ending (road), the cracked supports and falling car, and the map hint removal.
- **Deferred minors** (each in a ledger):
  - The hint reads "'for'  Another example" when a conjunction has no MatchIt function.
  - Checklist ticks fail around quote marks.
  - The map doesn't follow the driving car.
  - `saveLevel1Plays` isn't awaited.
  - Pier tags are 13 px, and a long tag is clipped at large text sizes.
  - The deck repaints every frame while shaking.
  - Hangers dangle in the collapsed state.
- **Watch when the client's sentences arrive:**
  - Bridge clauses longer than two lines end in "…" on the deck.
  - The second pier's tag shows the Quick Facts word found in that sentence.
- **Docs still mention the deleted `assets/images/map.svg`:** `docs/DEV-PRD.md` and `docs/art-review/BRIEF.md`.
- **Graphify MCP:** added to `~/.claude.json` (backup at `~/.claude.json.bak-graphify`). It isn't verified, since it needs a Claude Code restart. The `claude` CLI isn't installed on this machine.

**Testing notes:**
- **Level 2 widget tests** turn on reduce-motion in their `_open` helper, because the looping shake never lets `pumpAndSettle` settle.
- **Real Nunito in some tests:** a few tests load real Nunito, because the test font's square glyphs make chips and cards about twice as tall as on a phone.
- **Emulator walks:** `uiautomator dump` fails while the deck shakes or the montage plays, so tap those screens by position. The walk scripts are in the session scratchpad and aren't kept.

**Wireframes v3** (Design canvas): https://claude.ai/artifact/Q2sTzJQrY9WSmuxZHLCU5w, version 44, 21 boards (20 screens and the Bridge sheet). Local source is the session scratchpad `v3/project/*.dc.html`; a new session should read the boards from the artifact (`Artifact` action `read` with `path`). The owner edits the canvas too: always read the latest version before publishing. The owner asked to remove the 10 extra boards drawn for app-only steps; don't redraw them unasked.

**Design review:** DeepSeek, Opencode and Gemini reviewed `docs/design-review/pairs/` (app left, wireframe right). Summary and accepted fixes are in DECISIONS.md. Wireframe changes listed there are **not approved yet**.

**Things learned this session:**
- On the emulator, use the **release** build (`flutter build apk --release`). The debug build freezes on the first launch of a freshly booted emulator, which looks like a crash.
- `run-as` only works with the debug build, so prefs can't be injected into the release build; walk the app as a student instead (unlock codes `BRIDGE2`, `BRIDGE3`).
- `uiautomator dump` fails while the montage animates; tap its buttons by position.
- The emulator ran out of storage once; `adb uninstall com.bridgeit.bridgeit` then install fixed it (wipes saved progress).
- Button `textStyle` in the theme must set `fontFamily: 'Nunito'`, or buttons fall back to the system font.
- `node` is available; Python is not. Long Node scripts are safer written to a file than passed through a Bash heredoc.

**Owner preferences:** no Claude attribution in commits; commit and push only when asked; the guide stays small at the wheel of the blue sedan (head inside the front window); pieces carry their comma (", for"); main buttons navy with white text; Ending follows the client's layout and keeps its header. Write a handoff like this one before the owner's usage limit runs out.

---

# Older notes (1 November 2026)

## Where things stand

- **Phase 1 is done** and on `main` (3 levels, unlock codes, 91 tests, CI). See [PROJECT_NOTES.md](PROJECT_NOTES.md).
- **The client sent new screens** (Canva, 39 pages) that change all three levels. We reviewed them with the client and collected their decisions (below).
- **Branch `ccr-44e736fd-ezneqa`** was squashed into `main` as `4220a7d` and deleted.
- **v2 work lives on branch `v2`**, pushed to `origin/v2`. `main` stays runnable until v2 lands. All three levels are playable on `v2` with placeholder art.
- **Done on `v2`:** task 1 (schema v2), the vector logo, the waving character, task 2 (theme, Start, Welcome + profile, menu, journey sheet), task 3 (Level 1: silent song player, play counter, sing-along card, MatchIt), task 4 (`SentenceChecker`, clause check, `assets/lexicon/verbs.txt`; used by a screen from task 6), task 5 (`SpellChecker`, `assets/lexicon/words.txt`), task 6 (Level 2: 7 bridges, Cross the bridge, collapse, writing steps, Quick Facts, foundations, resume), task 7 (Level 3: toll gate, map, montage, `TravelogueAnalyzer`, editor, ending), task 8 (`ActiveTimer`, `results_v1`, PDF report, Send my answers). task 9 (art). Next is task 10, when the client's files arrive.
- **Deadline: 21 November 2026.** About 14 working days remain against 26–34 days of estimate, so cut polish first. Client files are due 7 November.
- **Local checks:** `flutter analyze` is clean and 257 tests pass.
- **Client notice:** `docs/client/BridgeIt-Checker-Changes.md` lists the checker changes and four client decisions. Stricter grammar rules (dependent clauses, *nor*) need the client's OK, since they originally asked for no grammar checks.

## External links

| What | Link |
|---|---|
| Client's Canva screens ("Copy of Copy of BridgeIt Pre-design", 39 pages, unchanged since review) | https://www.canva.com/design/DAHZjd55fu8/p0PZxKDnszexy83KQX9uVg/edit |
| Design review doc (first version, our questions only) | https://docs.google.com/document/d/1mXcJ-6O4Gjt0_UDbLQ4-eMk2aNDPdoc6QGyQsIKUY64/edit |
| Review doc with the client's answers (red text) and our section 6 "Our response to your answers" | https://docs.google.com/document/d/1ZXLgK5SrEQVZvbRLed0KoF2ESCxlD22DekcuNGsjCdg/edit |

The client marks answers in **red text** in the Google Doc. Don't edit the client-facing docs unless asked.

## Client decisions (final)

| Topic | Decision |
|---|---|
| Look | Their Canva screens, colors from the logo. **Full permission on the art: we make it**, including redrawing the logo, because they can't provide a sharp one |
| Level 1 | Song must be played 3 times (counter); sing-along card; then MatchIt (drag **or** tap). On Submit, right pairs stay, wrong go back. Can return to the song without replaying 3 times |
| Level 2 | **7 bridges**, one per FANBOYS. Wrong pieces fade; 3 wrong tries → bridge collapses, that bridge restarts. Each bridge strengthened with student-written sentences: one with the conjunction + one with a similar word (Quick Facts). *nor*/*or*: one sentence only. **12 written sentences total.** Continuous road ending at the toll gate |
| Sentence input | **One free-text box**; student writes the whole sentence including the conjunction. A sentence becomes a bridge foundation only if it passes the checks |
| Checking | Simple offline checks (word, punctuation, clause on both sides, capital/end mark, not copied) **+ spelling warning** (underline, not blocking). No grammar/meaning checks. Their focus: FANBOYS joining **independent clauses** |
| Quick Facts word lists | Confirmed as suggested: for → because, since, as · and → moreover, in addition, furthermore · but → however, although · yet → nevertheless, even though · so → therefore, as a result. Linking words take `; … ,`, joining words take no comma. We loosened this on 2 November (see the client notice, changes 7–9); the client has not approved it yet |
| Level 3 | Toll gate is a story scene (codes entered in the **menu**). Map with 7 places, student chooses **one**. Montage: **5 pictures** per place, **captions**, simple background music. Travelogue: **5–7 sentences**, **at least 4** coordinating conjunctions joining clauses, no app help |
| Map icon | Shows the journey so far |
| Answers to teacher | **"Send my answers"** button → **PDF** via the share sheet (Messenger, email, Drive, Bluetooth). App stays fully offline |
| Report contents | Written sentences, travelogue, MatchIt results, wrong tries per bridge, time spent |
| Privacy | Covered by the study; names in the report are fine |
| Music | Free licensed placeholder (pick something nice); use theirs if they send it |
| Captions | Our placeholders in PRD Appendix A; client to approve/replace later |

## Waiting on the client (due 7 November)

- The 7 Level 2 sentence pairs with explanations and hints
- Song MP3 + the start time of each lyric line

Nothing else is coming from the client. Unlock codes stay `BRIDGE2` / `BRIDGE3` unless they send others.

Still unanswered: grade level, teacher-guided or self-paced, sound effects, approval of the redrawn logo and our art.

## Our proposals not yet confirmed by the client

- The place scene keeps the Canva "Map" button so students *may* view more places; the travelogue opens after the first. Ask whether they meant only one place.
- A finished level can be replayed; the report keeps the **first** completed attempt.
- Sound on/off button; montage Skip after one full pass; name/section max 40 characters.
- Typo fixes in the screens (PRD Section 9). The client never ticked them.
- The welcome form line "Before we go, who is helping me today?" is our wording.
- The code box stays visible while any level is locked, though Canva hides it on the first menu screen, so a teacher can always unlock early.

## Technical notes

- `assets/images/logo.svg` and `girl_wave.svg` are hand-written vector files. Both render in `flutter_svg`, including `<use>`, clip paths and gradients. Don't add `<filter>` or `<mask>`.
- The logo's bridge gets dense below about 64 px, so the app icon needs a simplified icon-only version.
- `girl_wave.svg` keeps head, arms and body in separate groups, so new poses reuse the same parts.
- Draggables must sit outside any scroll view that can overflow, or the scroll takes the vertical drags. `MatchItBoard` scrolls only its slots for this reason.
- Logo colors: navy `#183870`, teal `#309090`, light teal `#80C0A8`, orange `#D88858`. Navy on orange is 4.1:1, so use it only for large bold text.
- Docs still naming `logo_placeholder.svg`: `README.md` (Where things live), `PROJECT_NOTES.md` step 5, the phase 1 plan.
- `docs/client/BridgeIt-PRD-v2.pdf` is still PRD v2.0. `docs/PRD.md` is v2.1, so rebuild the PDF before sending it to the client.
- `pdf`, `share_plus` and `path_provider` are in and pinned. `appVersion` in `answer_report.dart` must match `version` in `pubspec.yaml`.
- Estimate: 30–39 working days in total, with art added as task 9. Tasks 1–9 can run on placeholders.
- No Claude attribution in commits or PRs.

## Art (task 9 done)

Drawn: `scenes/drive.svg` (Level 1 background), the suspension bridge and blue car (`_ScenePainter`, `_CarPainter`), `map.svg`, `icon.svg` with the launcher PNGs rendered from it, `girl_drive.svg` and `girl_journal.svg` (Level 3 story), and one picture per lyric line in `lyrics/`. `map.svg` pins follow Canva's layout, not real geography, and sit on its road, so move them together. The Welcome screen and the ending keep `girl_wave.svg`, since she is greeting and saying goodbye there.

The lyric pictures are set per line in `levels.json`, so keep each `image` when the client's timings replace the placeholder lines.

Photos and music are in, with sources in `docs/MEDIA-CREDITS.md` and the in-app Credits. Commons has only one photo of the Currimao rocks, so that place's set and captions mostly show the beach; the client should send better ones.

An unfinished travelogue is lost on back; only a submitted entry is saved.

Student spelling is American, which matches Philippine English and `words.txt`.

## Next steps

1. When the client's files arrive on 7 November, swap in the song, timings and sentences (task 10).
2. Send the client `docs/client/BridgeIt-Checker-Changes.md` and rebuild `BridgeIt-PRD-v2.pdf` from `PRD.md` v2.1.
3. Update `PROJECT_NOTES.md` status and the old `logo_placeholder.svg` references, and delete this file when it's no longer needed.
