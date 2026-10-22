# BridgeIt – project notes

Last updated: 23 October 2026

## The project

BridgeIt is an Android phone game that teaches the coordinating conjunctions FANBOYS: *for, and, nor, but, or, yet, so*. The student builds a bridge between two clauses by choosing the right conjunction, and a vehicle crosses toward a destination. It is used in class as part of a research intervention, and teacher-researchers give students the code for each next level.

**Levels** (from the client's brief):

1. **Conjunction Song:** the song with its lyrics, then fill in the blanks. The teacher gives code 1.
2. **Building the Bridge:** drag a conjunction into the bridge gap between two independent clauses. The teacher gives code 2.
3. **Strengthening the Bridge:** as Level 2, then pick a synonym or equivalent (e.g. *but* → *however*, *so* → *therefore*). The bridge is reinforced and the vehicle reaches its destination.

The client's earlier web prototype (https://conjbridge.vercel.app/) is a reference for the bridge mechanic only. Its subordinating conjunctions are out of scope.

## Decisions

- **Delivery:** Android APK, phones, portrait only, English only, works offline with no login.
- **Stack:**
  - Flutter 3.47.7 stable / Dart 3.13.5, the same on every dev machine and in CI. Upgrade all of them together.
  - Android SDK platform android-37.2, Build-Tools 37.0.0.
  - Android Studio Quail 4 (2026.1.4.7), whose bundled Java 25 Flutter uses.
- **Packages:** `provider`, `just_audio`, `shared_preferences`, `flutter_svg`, plus `flutter_lints`/`flutter_test`. Don't add others without a reason.
- **Fonts:** Nunito and Abril Fatface are bundled in the app (no network fonts).
- **Content:** sentences, answers, hints, synonyms, lyrics, attempt limit and unlock codes are in `assets/content/levels.json`, not in Dart code.
- **Colors:** only through `AppColors` in `lib/theme/app_theme.dart`.
- **Backend:** none. If the researchers want results recorded (Q7), choose between Supabase and Firebase then.
- **Unlock codes:**
  - Placeholders `BRIDGE2` / `BRIDGE3`. Level 1 is always open.
  - A code is tried against every locked level, lowest first, and the first match unlocks. So a Level 3 code works while Level 2 is locked.
  - A code for an already-unlocked level counts as wrong.
  - Case and surrounding spaces are ignored.
  - The code can be entered on the level menu, or on the done screen after Levels 1 and 2, which then offers "Play level N".
- **Wrong answers:**
  - Level 1 allows unlimited retries.
  - In Levels 2–3, a wrong answer cracks the bridge and shows a hint. When the wrong answers reach `maxWrongAnswers` (placeholder 3), the bridge breaks and that sentence restarts.
  - The limit waits on the client (Q5).
- **Level 1 input (client review 1):**
  - Students type the missing word straight into each blank. There is no word bank and no pop-up menu.
  - A whole FANBOYS word is judged as soon as it is typed, ignoring case and spaces. A right answer moves to the next blank.
  - The header takes its verse number from the card title, e.g. "LEVEL 1 · VERSE 2".
- **Levels 2–3 sentence (client review 1):** both clauses in one card with an inline `_____` blank, which shows the placed word once the bridge is built.
- **Audio:** the client will supply the song. Until then the player shows "Song coming soon".

## Proposed look (placeholder)

The client will send their own final logo. The colored lotus and this palette are placeholders, and the final palette will come from the client's logo.

| Role | Hex |
|---|---|
| Primary | `#0E7490` |
| Accent | `#EC4899` |
| Pieces / outlines | `#9D174D` |
| Sky background | `#E0F2FE` |
| Text / main button | `#1E293B` |
| Bridge | `#B45309` |
| Cliffs | `#15803D` |
| Vehicle / hints | `#F59E0B` |
| Correct | `#22C55E` |
| Wrong | `#DC2626` |
| Cards | `#FFFFFF` |

## Status

- Phase 1 is done and on `main`: all 3 levels, the unlock flow, bundled fonts and the release build config.
- Client review 1 fixes are in.
- 91 tests pass, and CI runs analyze and tests on every push.
- **Test build:** pre-release `v0.1.0-test.1` on GitHub, signed with the debug key.
- **Client answers so far:** Q10. The client will send their own final logo, so the current look is a placeholder.

## Open questions for the client (PRD Section 10)

1. Grade level.
2. Teacher-guided, self-paced, or both.
3. Who enters the codes, and are they fixed or set by the teacher.
4. Sentences per level (Levels 2–3).
5. Tries before the bridge breaks, and what happens then.
6. Whether a sentence can have more than one right answer.
7. Whether to save student results (this needs a backend).
8. Level 3 synonyms for each conjunction.
9. Whether the logo is used in the app.
10. ~~Colored logo and palette~~ (answered: the client sends their own logo).
11. Feedback on the wireframes.
12. Art style.
13. Sound effects.
14. When the song audio will be delivered.

Also pending: confirm the meanings in PRD Section 8. The wording for *nor* ("adds a second not idea") and *yet* ("surprising contrast") is ours.

## Next steps

1. Test on a real phone:
   - a small (360×640) screen
   - the on-screen keyboard in Level 1
   - dragging while the list scrolls
   - OS text scale 1.3×
   - the Android back gesture during a drag
   - TalkBack
   - the song pausing in the background, once the song exists
2. Before a real release:
   - settle `applicationId` (currently `com.bridgeit.bridgeit`)
   - create the release keystore and `android/key.properties`

   Testers must uninstall debug-signed test builds before installing it.
3. **Song:** put the file in `assets/audio/` and set `level1.audioAsset` in `levels.json`.
4. **Content answers (Q4, Q5, Q6, Q8):** edit `assets/content/levels.json`. Replace the placeholder sentence "I studied for hours," (it uses *for* as a preposition).
5. **Final logo and colors:** change `AppColors` and replace `assets/images/logo_placeholder.svg`.

## Commands

```bash
flutter test
flutter analyze
flutter build apk --release
flutter build apk --release --split-per-abi   # smaller APKs, one per CPU type
```
