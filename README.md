# BridgeIt

An Android phone game that teaches the coordinating conjunctions **FANBOYS**: *for, and, nor, but, or, yet, so*. Students build bridges between two clauses by choosing the right conjunction, so a vehicle can cross to its destination.

BridgeIt is used in class as part of a study. Teacher-researchers give students a code to open each next level.

**Test build:** [Releases](https://github.com/afjk-x3/bridgeit/releases). Download the `.apk` on an Android phone and open it.

## Levels

1. **Conjunction Song:** listen to the song, then type the missing FANBOYS words into the lyrics.
2. **Building the Bridge:** drag the right conjunction into the gap in the bridge. A wrong answer cracks the bridge and shows a hint.
3. **Strengthening the Bridge:** build the bridge, then pick the word with the same meaning (e.g. *so* → *therefore*) to reinforce it.

## Development

Requires Flutter **3.47.7** (stable) and the Android SDK. Keep the same Flutter version on every machine and in CI.

```bash
flutter pub get
flutter run              # on a connected phone or emulator
flutter test
flutter analyze
flutter build apk --release
```

CI (`.github/workflows/ci.yml`) runs `flutter analyze` and `flutter test` on every push and pull request.

### Where things live

| What | Where |
|---|---|
| Sentences, answers, hints, synonyms, lyrics, attempt limit, unlock codes | `assets/content/levels.json` |
| All app colors | `AppColors` in `lib/theme/app_theme.dart` |
| Logo (placeholder) | `assets/images/logo_placeholder.svg` |
| Song audio (not delivered yet) | `assets/audio/`, then set `level1.audioAsset` in `levels.json` |
| Game rules | `lib/game/` |
| Screens and widgets | `lib/screens/`, `lib/widgets/` |

Content, logo, colors and art are placeholders until the client's final versions arrive.

### Release signing

Create a keystore and `android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`). Without it, release builds are signed with the debug key, and Gradle prints a warning. Never commit the keystore or `key.properties`.

## Docs

- [Project notes](docs/PROJECT_NOTES.md): decisions, palette, open questions, next steps
- [Phase 1 plan](docs/plans/2026-10-22-phase1.md)

Fonts: Nunito and Abril Fatface, under the SIL Open Font License (`assets/fonts/*-OFL.txt`).
