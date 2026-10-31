# Handoff: v2 redesign (1 November 2026)

Context for picking up this work in a new session. Read this first, then [PRD.md](PRD.md) (client view) and [DEV-PRD.md](DEV-PRD.md) (build plan).

## Where things stand

- **Phase 1 is done** and on `main` (3 levels, unlock codes, 91 tests, CI). See [PROJECT_NOTES.md](PROJECT_NOTES.md).
- **The client sent new screens** (Canva, 39 pages) that change all three levels. We reviewed them with the client and collected their decisions (below).
- **Branch `ccr-44e736fd-ezneqa`** was squashed into `main` as `4220a7d` and deleted.
- **v2 work lives on branch `v2`**, pushed to `origin/v2`. `main` stays runnable until v2 lands. Levels 1 and 3 are `LevelStubScreen` until DEV-PRD tasks 3 and 7.
- **Done on `v2`:** task 1 (schema v2), the vector logo, the waving character, task 2 (theme, Start, Welcome + profile, menu, journey sheet). Next is task 3.
- **Deadline: 21 November 2026.** About 14 working days remain against 26–34 days of estimate, so cut polish first. Client files are due 7 November.
- **Local checks:** `flutter analyze` is clean and 94 tests pass.

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
- Logo colors: navy `#183870`, teal `#309090`, light teal `#80C0A8`, orange `#D88858`. Navy on orange is 4.1:1, so use it only for large bold text.
- Docs still naming `logo_placeholder.svg`: `README.md` (Where things live), `PROJECT_NOTES.md` step 5, the phase 1 plan.
- `docs/client/BridgeIt-PRD-v2.pdf` is still PRD v2.0. `docs/PRD.md` is v2.1, so rebuild the PDF before sending it to the client.
- New packages planned: `pdf`, `share_plus`, `path_provider` (DEV-PRD Section 9).
- Estimate: 30–39 working days in total, with art added as task 9. Tasks 1–9 can run on placeholders.
- No Claude attribution in commits or PRs.

## Next steps

1. Start DEV-PRD task 3 (Level 1: song counter, sing-along card, MatchIt), then tasks 4–9.
2. When the client's files arrive on 7 November, swap in the song, timings and sentences (task 10).
3. Update `PROJECT_NOTES.md` status, and delete this file when it's no longer needed.
