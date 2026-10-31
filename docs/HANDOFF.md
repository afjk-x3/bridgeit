# Handoff: v2 redesign (31 October 2026)

Context for picking up this work in a new session. Read this first, then [PRD.md](PRD.md) (client view) and [DEV-PRD.md](DEV-PRD.md) (build plan).

## Where things stand

- **Phase 1 is done** and on `main` (3 levels, unlock codes, 91 tests, CI). See [PROJECT_NOTES.md](PROJECT_NOTES.md).
- **The client sent new screens** (Canva, 39 pages) that change all three levels. We reviewed them with the client and collected their decisions (below).
- **Branch `ccr-44e736fd-ezneqa`** was squashed into `main` as `4220a7d` and deleted. The intro logo works on `main`; `logo.svg` renders fine through `flutter_svg`, so the PNG fallback isn't needed.
- **v2 work lives on branch `v2`.** `main` stays runnable until v2 lands. Levels 1 and 3 are `LevelStubScreen` until DEV-PRD tasks 3 and 7.
- **Deadline: 21 November 2026.** Client files are due 7 November.

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
| Look | Their logo, character, Canva screens. Colors from the logo |
| Level 1 | Song must be played 3 times (counter); sing-along card; then MatchIt (drag **or** tap). On Submit, right pairs stay, wrong go back. Can return to the song without replaying 3 times |
| Level 2 | **7 bridges**, one per FANBOYS. Wrong pieces fade; 3 wrong tries → bridge collapses, that bridge restarts. Each bridge strengthened with student-written sentences: one with the conjunction + one with a similar word (Quick Facts). *nor*/*or*: one sentence only. **12 written sentences total.** Continuous road ending at the toll gate |
| Sentence input | **One free-text box**; student writes the whole sentence including the conjunction. A sentence becomes a bridge foundation only if it passes the checks |
| Checking | Simple offline checks (word, punctuation, clause on both sides, capital/end mark, not copied) **+ spelling warning** (underline, not blocking). No grammar/meaning checks. Their focus: FANBOYS joining **independent clauses** |
| Quick Facts word lists | Confirmed as suggested: for → because, since, as · and → moreover, in addition, furthermore · but → however, although · yet → nevertheless, even though · so → therefore, as a result. Linking words take `; … ,`, joining words take no comma |
| Level 3 | Toll gate is a story scene (codes entered in the **menu**). Map with 7 places, student chooses **one**. Montage: **5 pictures** per place, **captions**, simple background music. Travelogue: **5–7 sentences**, **at least 4** coordinating conjunctions joining clauses, no app help |
| Map icon | Shows the journey so far |
| Answers to teacher | **"Send my answers"** button → **PDF** via the share sheet (Messenger, email, Drive, Bluetooth). App stays fully offline |
| Report contents | Written sentences, travelogue, MatchIt results, wrong tries per bridge, time spent |
| Privacy | Covered by the study; names in the report are fine |
| Music | Free licensed placeholder (pick something nice); use theirs if they send it |
| Captions | Our placeholders in PRD Appendix A; client to approve/replace later |

## Waiting on the client (due 7 November)

- The 7 Level 2 sentence pairs with explanations and hints
- Art files as separate PNG/SVG, including 35 montage pictures and the map
- Song MP3 + the start time of each lyric line
- Unlock codes, or confirmation that the teacher sets them
- Still unanswered: grade level, teacher-guided or self-paced, sound effects
- Asked: a real vector logo or transparent PNG ≥1024 px, an icon-only version, exact color codes

## Our proposals not yet confirmed by the client

- The place scene keeps the Canva "Map" button so students *may* view more places; the travelogue opens after the first. Ask whether they meant only one place.
- A finished level can be replayed; the report keeps the **first** completed attempt.
- Sound on/off button; montage Skip after one full pass; name/section max 40 characters.
- Typo fixes in the screens (PRD Section 9). The client never ticked them.

## Technical notes

- `assets/images/logo.svg` is a Canva export: an embedded bitmap plus `<filter>`/`<mask>`. `flutter_svg` may render it badly; the fallback is to extract the bitmap to PNG (DEV-PRD Section 11).
- Logo colors (approximate): navy `#183870`, teal `#309090`, light teal `#80C0A8`, orange `#D88858`.
- The intro screen still shows the "BridgeIt" text under the logo, which now duplicates the wordmark. Remove it during the theme work.
- Docs still naming `logo_placeholder.svg`: `README.md` (Where things live), `PROJECT_NOTES.md` step 5, the phase 1 plan.
- New packages planned: `pdf`, `share_plus`, `path_provider` (DEV-PRD Section 9).
- Estimate: 27–35 working days. Tasks 1–8 can run on placeholders.

## Next steps

1. Start DEV-PRD task 2 (theme from logo, Start, Welcome, menu, journey sheet). Task 1 (schema v2 + placeholder content) is done on `v2`.
2. When the client's files arrive, swap in art, song, timings, sentences and captions.
3. Update `PROJECT_NOTES.md` status, and delete this file when it's no longer needed.
