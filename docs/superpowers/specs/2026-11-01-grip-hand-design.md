# Gripping hand design

## Why

The guide's hands are plain circles in `girl_journal.svg` and `girl_drive.svg`, while `girl_wave.svg` has a full hand. Both art reviewers marked this down. The goal is that her hands stop looking like circles. They don't have to match the waving hand exactly.

## Goals

- One gripping hand, drawn once, replaces every circle hand.
- It reads as a hand at the 200-high size used in the Level 3 story.

## Non-goals

- Changing `girl_wave.svg`, or the arms in `scenes/drive.svg`.
- Other art review fixes. They are tracked separately.

## Constraints

- Hand-written SVG for `flutter_svg`: no `<filter>` or `<mask>`.
- Same skin fill `#F4C7A1`, navy `#183870` outline and crease color `#D9A27C` as `girl_wave.svg`.

## Approaches

| Approach | Trade-off |
|---|---|
| **A. New gripping hand (picked)** | One small new shape fixes both poses. |
| B. Finger lines on the circles | Smallest edit, but may still look like a ball at 200 high. |
| C. Reshape the wave hand | Closest to `girl_wave.svg`, but its long fingers need redrawing per pose. |

The owner picked A.

## Design

- **Shape:** rounded palm, four finger shapes wrapping forward, one thumb.
- **Journal pose:** one hand on each side of the book, the right one mirrored, with fingers over the cover edge.
- **Driving pose:** one hand on the wheel, with fingers wrapped over the rim.

## Left to the builder

- Exact path, and scale and angle in each pose.
- Whether it stays one `<defs>` shape per file. SVG files can't share `<use>` across files, so the path is copied into both.

## Check

Render both poses on the emulator at app size and compare them with `girl_wave.svg`. Analyzer and tests must still pass.
