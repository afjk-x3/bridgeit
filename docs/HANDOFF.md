# BridgeIt – context handoff

Last updated: 22 October 2026

## The project

- **Product:** BridgeIt, an Android phone game that teaches coordinating conjunctions (FANBOYS: for, and, nor, but, or, yet, so). The student builds a bridge between two clauses by choosing the right conjunction, and a vehicle crosses toward a destination.
- **Levels (from the client's brief):**
  1. **Conjunction Song.** Song plus lyrics, then fill in the blanks. Teacher gives code 1.
  2. **Building the Bridge.** Drag a conjunction into the bridge gap between two independent clauses. Teacher gives code 2.
  3. **Strengthening the Bridge.** Same as Level 2, then pick a synonym or equivalent (but→however, so→therefore). Bridge is reinforced and the vehicle reaches its destination.

## Client sources

- Canva design "Intervention Idea", exported to `C:\Users\garaz\Downloads\Intervention Idea.pdf`. It contains the intro text, level menu, song lyrics (4 verses plus outro), the fill-in-the-blanks layout and a Level 2 sample ("I'm very tired / I will sleep." with so, yet, and, but, for, nor). Page 2 is the logo. Only the PDF's text was read (pdftotext), not its images.
- Bare logo (black line-art lotus, no wordmark or play button): `C:\Users\garaz\Downloads\Untitled design.svg`.
- Earlier web prototype by the client: https://conjbridge.vercel.app/. Reference for the bridge mechanic only. It uses 12 conjunctions, including subordinating ones, which are out of scope.

## Decisions made

- **Delivery:** Android APK (client requirement), phones, portrait only, English only.
- **Tech stack (final, same on both machines):**
  - Flutter **3.47.7** stable, Dart **3.13.5** (upgraded 22 Oct 2026). Don't run `flutter upgrade` on one machine only.
  - Android SDK:
    - Platform android-37.2 (android-36 also kept)
    - Build-Tools 37.0.0
    - platform-tools 37.0.1
    - cmdline-tools 23.0
    - emulator 37.2.12
    - all licenses accepted on this PC
  - Android Studio **Quail 4, 2026.1.4.7** on both machines. Its bundled JDK is **Java 25.0.3** (build b508.16), and Flutter uses it. The PC was upgraded from Otter on 22 Oct 2026. Don't move to Rabbit (2026.2.x) on one machine only.
  - Editor: Antigravity IDE with the Flutter and Dart extensions (Dart-Code.flutter, Dart-Code.dart-code 3.144.0, the latest stable; 3.145.x builds are pre-release). Android Studio is installed only for the SDK Manager and emulator.
  - Git, plus a private GitHub repo to sync the two machines. Commit `pubspec.lock`.
  - Packages:
    - `provider` for state
    - `just_audio` for the song
    - `shared_preferences` for progress
    - `flutter_svg` for the logo
    - `flutter_lints` and `flutter_test` (both default)
  - Built-in `Draggable`/`DragTarget` and Flutter animations. No Rive or Lottie unless the client's art needs it.
  - Fonts Nunito and Abril Fatface bundled as asset TTFs (works offline; no `google_fonts` package).
  - `assets/levels.json` for sentences, answers, hints, synonyms, attempt limits and codes.
  - Release: `flutter build apk --release`, signed with a keystore. `key.jks` and `key.properties` stay out of git and are copied to the other machine by hand.
  - Testing on a real Android phone over USB. The emulator is optional.
  - Not needed: Visual Studio, Xcode.
- **Machines:**
  - This PC: Flutter 3.47.7 at `C:\Users\garaz\flutter`, Android Studio Quail 4 (Java 25.0.3), SDK above, Git 2.53. `flutter doctor` is all green except Visual Studio, which isn't needed.
  - HP ProBook laptop: has Android Studio Quail (Java 25.0.3, same build) and Antigravity. Flutter is not installed yet; use the install prompt.
  - winget can't upgrade Android Studio on this PC. Use the official installer from the winget manifest URL and check its SHA256.
- **Backend:** none for now. If the researchers want results logged, choose between Supabase and Firebase later. Keep attempt logging behind one small interface.
- **Wrong answer:** the bridge cracks and a short hint explains why. Level 1 allows unlimited retries. The Level 2–3 attempt limit is pending, and the user is asking the client.
- **Level 1 input:** tap a word, then tap a blank. This is our proposal; the brief says "type or select".
- **Audio:** the client will supply the song later. Use a placeholder until then.
- **Our proposals, not confirmed:** works offline with no login, and a mute button.

## Proposed look (pending client approval)

- **Colored logo:** `BridgeIt-logo-color.svg` / `.png`. The original paths are unchanged, with fills added: pink petals, deep-rose `#9D174D` outlines, green `#15803D` swirls, amber flame and teal `#0E7490` dots. The right swirl and petal were one path, so they are split by clipPaths.
- **Palette:**

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

- **Fonts in wireframes:** Abril Fatface (wordmark), Nunito (body).
- **Client option:** if the client sends their own colored logo or design, its colors replace this palette across the app. This is stated in the PRD.

## Deliverables (this folder)

| File | What |
|---|---|
| `BridgeIt-PRD.pdf` / `.docx` / `.html` | Plain-language PRD v0.3 for a non-IT reader. 11 sections, technical approach removed, 14 client questions in Section 10. The HTML is the source for the PDF; the DOCX is the editable copy. |
| `BridgeIt-Wireframes.pdf` / `.html` | 2 A4-landscape pages: Intro, Level menu, Level 1 / Level 2 wrong, Level 2 correct, Level 3. |
| `BridgeIt-logo-color.svg` / `.png` | Proposed colored logo (full 1920×1080 canvas). |
| `assets/logo-crop.svg` / `.png` | Cropped logo used inside the PRD and wireframes. |
| `wireframes-source/` | Source of the 5 canvas artboards (`.dc.html`) plus `canvas.json`. |
| `tools/build-wireframes.ps1` | Turns `wireframes-source/` into `BridgeIt-Wireframes.html`. |
| `tools/build-prd-docx.js` | Builds the DOCX. It needs the npm `docx` package (installed in `%TEMP%\docxbuild`). |

**Live canvas** (Design artifact, set to anyone with the link): https://claude.ai/artifact/F6zgs95hpfTLpSpZ9B8RJG. The logo asset id there is `9a7c909594e6a2445bb2b4d592deca95`.

## Status

- PRD v0.3, the wireframes PDF and the colored logo are done.
- A casual client message is drafted. It asks the client to review both files, share their thoughts, and answer questions 1–14.
- Waiting on client answers.
- **App repo:** `C:\Users\garaz\Documents\bridgeit` (GitHub `afjk-x3/bridgeit`), work branch `setup/flutter-scaffold`.
- **Plan:** `docs/superpowers/plans/2026-10-22-bridgeit-phase1.md`, 9 tasks.
- **Task 1 done (not committed yet):** Flutter project (`com.bridgeit.bridgeit`, Android only), packages, portrait lock, `AppColors` placeholder theme, placeholder lotus logo and smoke test. `flutter analyze` is clean, the test passes, and the debug APK builds. The first Gradle build auto-installed SDK Platform 35, which Flutter's default compileSdk uses.
- The ProBook setup is not verified yet.

## Client answers so far

- **Q10 (logo and colors):** the client will send their own final logo design. Our colored lotus and its palette are **placeholders** until it arrives, and the final palette will come from their logo. Keep all colors in one theme file so they can be swapped.

## Open questions (PRD Section 10)

1. Grade level.
2. Teacher-guided, self-paced, or both.
3. Who enters the codes, and are they fixed or set by the teacher.
4. Sentences per level (Levels 2–3).
5. Tries before the bridge breaks, and what happens then.
6. Whether a sentence can have more than one right answer.
7. Whether to save student results; this needs a backend.
8. Level 3 synonyms for each conjunction.
9. Whether the logo is used in the app.
10. Whether the client approves the colored logo and palette, or sends their own.
11. Feedback on the wireframes.
12. Art style.
13. Sound effects.
14. When the song audio will be delivered.

Also pending: confirming the meanings in Section 8 (nor = "adds a second not idea", yet = "surprising contrast" are our wording).

**What blocks what:**
- Q4, Q5, Q6 and Q8 block Level 2–3 logic and content.
- Section 8 meanings block the final Level 1 text.
- Q7 should be decided early, because it decides whether a backend is needed.
- Everything else can use placeholders.

## Next steps

1. When the client answers, update the PRD (HTML, then regenerate the PDF; DOCX via the script) and the wireframes if needed.
2. Get the PRD approved. The brainstorming hard gate applies: no app code before approval.
3. Then write the implementation plan (superpowers:writing-plans).
4. Run `flutter doctor` and scaffold the Flutter project in a real project folder, not this scratch folder.

## Environment notes (Windows)

- No Python, pdftoppm, pandoc or LibreOffice. The Read tool can't render PDFs.
- **HTML to PDF:** Chrome headless:
  ```
  chrome.exe --headless=new --no-pdf-header-footer --virtual-time-budget=8000 --print-to-pdf=<out.pdf> file:///<in.html>
  ```
- **Screenshots for checking:** `--screenshot=<png> --window-size=W,H`, then read the PNG.
- `pdftotext` is available in Git Bash (`/mingw64/bin`).
- Long scratchpad paths break Git Bash `chrome.exe` calls ("File name too long"), so use PowerShell for those.
- Node v25 is installed. The `docx` npm package is in `%TEMP%\docxbuild`, a temp folder, so reinstall it if it's missing.

## User preferences

- Likes multiple-choice questions (AskUserQuestion) over open questions.
- Client messages should be short, casual, not too professional, and start with "Hello!".
- Session modes: caveman (terse replies) and ponytail lite.
