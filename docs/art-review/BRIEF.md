# BridgeIt vector art review brief

You are reviewing the vector artwork of an educational game. Rate it and say what to improve. **Do not edit any file.** Photos are out of scope.

See every piece in [vector-art-sheet.png](vector-art-sheet.png). If you have the repo, read the SVG sources too; the work is on branch `v2`.

## The project

BridgeIt is an offline, English-only Android game (Flutter) that teaches the seven coordinating conjunctions, FANBOYS: *for, and, nor, but, or, yet, so*. It was built for a client's classroom study. Students in the Philippines use it on phones. The grade level hasn't been confirmed by the client.

The story: a friendly girl guide is on a road trip through Ilocos Norte and needs the student, the "Bridge Builder", to help her cross broken bridges.

1. **Level 1:** the student listens to a theme song three times with a sing-along card, then does a matching activity.
2. **Level 2:** seven bridges, one per conjunction. The student picks the right word to close the gap, then writes sentences that become the bridge's foundations.
3. **Level 3:** she reaches the toll gate, the student picks a real place on a map, watches a photo montage, and writes a travelogue.

Deadline is 21 November 2026, and real-phone testing and client review still have to fit before it. Prefer fixes that are cheap and visible over redraws.

## Rules the art must follow

- **Ownership:** we draw all art, with the client's full permission. The logo is our redraw of their blurry original, and the client hasn't approved it or our other art yet.
- **Format:** hand-written SVG rendered by `flutter_svg`. Allowed: paths, `<use>`, clip paths, gradients. **No `<filter>` or `<mask>`.**
- **Palette, from the logo:** navy `#183870`, teal `#309090`, light teal `#80C0A8`, orange `#D88858`, app background `#E6F5FF`.
- **Style:** flat fills with a navy outline, no shading effects.
- **Reuse:** poses share the same head and body parts as `girl_wave.svg`, so she stays one consistent character.
- **Screen:** phones, tested at 1080×2400. Sizes below are in logical pixels.

## Inventory

| File | What it is | Where it appears | Shown at |
|---|---|---|---|
| `assets/images/logo.svg` | Logo: bridge over open book, wordmark | Start, Welcome, level menu | 260 wide, 120 high, 80 high |
| `assets/images/icon.svg` | Simplified logo, no wordmark | Android launcher icon | Launcher size |
| `assets/images/girl_wave.svg` | Guide waving | Welcome, Level 3 ending | 150 wide, 240 high |
| `assets/images/girl_drive.svg` | Guide in the car, side view | Level 3 toll gate, bridge crossed | 200 high |
| `assets/images/girl_journal.svg` | Guide holding her journal | Level 3 goodbye | 200 high |
| `assets/images/scenes/drive.svg` | Driver's-seat view of the road | Full-screen Level 1 background, cropped from the bottom; cards cover the upper part | Full screen |
| `assets/images/map.svg` | Coast and road; pins are added by the app | Level 3 place map | Most of the screen, stretched to fit |
| `assets/images/lyrics/*.svg` | One picture per conjunction | Level 1 sing-along card, changes with the song | 96 high |
| `lib/widgets/bridge_scene.dart` | Suspension bridge, blue car, water, painted in Dart | Level 2, one per bridge | About 334 wide |

The lyric pictures mean:

| Word | Lyric | Picture |
|---|---|---|
| and | join similar situations | Two alike circles joined by a plus |
| for | give the reason why | Question leads to a light bulb |
| nor | none chosen from the given option | Two options, both crossed out |
| but | two ideas clash | Two arrows meeting head-on |
| or | we have a choice | A road that forks |
| yet | the ending is a surprise | Gift box with a star |
| so | show the result | Seed leads to a plant |

## Feedback already applied

The owner has already asked for these, so don't suggest undoing them:

- **Logo:** real lowercase `e`, spine on the `B`, flat `d` stem, book clear of the wordmark, interlocking rings, even kerning.
- **Girl:** no creases or center seam on the shorts, no vertical line through the body, outlined skin, heavier motion lines.

## Known weak spots

Check these, but don't limit yourself to them:

- The Dart bridge and car have no navy outline, unlike the character, and the bridge's towers are not a palette color.
- The blue car `#3A8FDB`, and the yellow, red and brown in some lyric pictures, are outside the logo palette.
- `girl_drive.svg` puts a front-facing head in a side-view car, and its character outline is thinner than the car's.
- Hands in `girl_drive.svg` and `girl_journal.svg` are plain circles, while `girl_wave.svg` has a full hand.
- `map.svg` pins follow the client's layout, not real geography.
- `and.svg` and `nor.svg` use abstract circles; they may not say much to a student.

## What to return

1. **Overall score** out of 10, with one line on why.
2. **A score out of 10 for each row of the inventory**, and for the seven lyric pictures one by one, each with a one-line reason.
3. **Consistency:** does this read as one art style? Name what breaks it.
4. **Fit:** is it suitable and clear for students on a phone at the sizes shown?
5. **Top improvements**, ranked by value for effort. For each, give the file, the exact change, and an effort of small, medium or large. Changes must respect the rules above.
6. **Leave alone:** what is already good and should not be touched.

Base scores only on what you can see or read in the files. If you could not view something, say so and don't score it.
