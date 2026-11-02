# Handoff: v2 redesign

Context for picking up this work in a new session. Read the latest session below first, then the older notes, [PRD.md](PRD.md) (client view) and [DEV-PRD.md](DEV-PRD.md) (build plan).

## Latest session: 3 November 2026

**Done:** all 13 tasks of [superpowers/plans/2026-11-03-review-fixes.md](superpowers/plans/2026-11-03-review-fixes.md) (spec [design-review/DECISIONS.md](design-review/DECISIONS.md)), one commit per task, `a0f3310`–`a368443` on `v2`. The release APK was walked Level 1 → Ending on the emulator and `docs/design-review/pairs/` and `sheet-1..4.png` were refreshed (steps 16 and 17 no longer exist). Every deviation from the plan is a `Ruling:` line in the git-ignored ledger `.superpowers/sdd/2026-11-03-review-fixes/progress.md`.

**Shared bridge (wireframe only):** the owner chose one bridge design for every bridge screen, with each accepted sentence becoming a numbered pier under the deck ([spec](superpowers/specs/2026-11-03-shared-bridge-design.md), [plan](superpowers/plans/2026-11-03-shared-bridge-wireframe.md)). Wireframes v3 version 44 has a new "Bridge sheet" board with all six states, plus Start, Welcome, Story, Bridge, Wrong, Write your own, Write with Quick Facts and Ending redrawn. The generator is the session scratchpad's `canvas/bridge.js` (not in the repo). The owner approved it, and the app now has it ([app plan](superpowers/plans/2026-11-03-shared-bridge-app.md)):
- `BridgeScene` draws the new bridge, with `piers`, `piersNeeded` and a `BridgeWobble` shake that stops under reduce-motion.
- Level 2's story shows the broken bridge.
- Start and Welcome use the regenerated `bridge_strip.svg`.
- Level 3 "crossed" adds `bridge_strip_crossed.svg`.
- `ending.svg` has the bridge in place of the road.

Regenerate the art with `node tool/bridge_art/make_assets.js`. Level 2 widget tests turn on reduce-motion in their `_open` helper, because the looping shake never lets `pumpAndSettle` settle. On the emulator, `uiautomator dump` fails while the deck shakes, so tap Level 2's Strengthen, text box and Submit by position.

**Next step:** client task 10 when their files arrive on 7 November; the four deferred minors below if time allows.

**State of `v2`:**
- `flutter analyze` is clean and 298 tests pass. Not pushed since `077a8ac`; the owner pushes only when asked.
- **Still uncommitted:** this file, `docs/art-review/`, and the old reverted grip-hand spec and plan in `docs/superpowers/`. Left for the owner to decide.
- The map is rebuilt (`lib/widgets/place_map.dart`, icons in `assets/images/places/icons/`); `assets/images/map.svg` is gone, but `docs/DEV-PRD.md` and `docs/art-review/BRIEF.md` still mention it. `Place.pinX`/`pinY` are no longer read.
- Bridge clauses now sit on the deck in two lines at most. The current clauses (23 characters at most) fit; check the client's longer sentences when they arrive, since longer ones end in "…".
- The MatchIt fit test loads real Nunito: the test font draws square glyphs, which makes the function chips about twice as tall as on a phone.

**Review:** a fresh reviewer checked the whole branch: no Critical findings, and one Important finding (long place names were cut at 3 lines on the map), fixed in `a368443`. Deferred minors:
- When a conjunction has no MatchIt function, the hint reads "'for'  Another example: …".
- The checklist's capital and end-mark ticks fail when the sentence starts or ends with a quote mark.
- The map doesn't scroll to follow the car while it drives.
- `saveLevel1Plays` is not awaited in the song's `onCompleted`.

These calls are left to the owner: the map road has no centre dashes and the car doesn't turn with the road; the Level 2 header copy; clauses longer than two lines end in "…" on the deck.

**Wireframes v3** (Design canvas): https://claude.ai/artifact/Q2sTzJQrY9WSmuxZHLCU5w, version 40, 20 boards. Local source is the session scratchpad `v3/project/*.dc.html`; a new session should read the boards from the artifact (`Artifact` action `read` with `path`). The owner edits the canvas too: always read the latest version before publishing. The owner asked to remove the 10 extra boards drawn for app-only steps; don't redraw them unasked.

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
