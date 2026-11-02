# One bridge everywhere: wireframe design

Agreed with the owner on 3 November 2026. This covers the **Wireframes v3 canvas only** (https://claude.ai/artifact/Q2sTzJQrY9WSmuxZHLCU5w). The app is changed later, from the finished boards.

## Why

The app draws different bridges on different screens. In Level 2, the student's sentences sit in a grey strip under the bridge and don't look like they strengthen it. The owner wants a single bridge, the Wireframes v3 Level 2 bridge, on every screen that shows one. The student's writing should visibly hold that bridge up.

## Goals

- One bridge design on every bridge screen: Start, Welcome, the Level 2 broken-bridge story, every Level 2 step, the Level 3 "bridge crossed" screen and the Ending.
- Each accepted sentence visibly strengthens the bridge.
- Every sentence stays readable for a Grade 8 student on a phone.

## Non-goals

- No app code in this round.
- The other Wireframes v3 changes in `docs/design-review/DECISIONS.md` are not part of this work.
- No new boards for app-only steps, apart from the bridge sheet below.

## The bridge

The base is the Wireframes v3 "Wrong" and "Write" boards:
- stone bank walls at both edges
- tall orange towers (navy outline, cross-braces, navy caps)
- one sweeping navy cable with hangers
- a thick grey deck slab with an under-deck truss
- stone piers in the water under each tower
- a green bank and blue water

## States

| State | Look | Used on |
|---|---|---|
| Finished | Straight deck, plain stone piers with no writing, car on top | Start, Welcome, Level 3 "bridge crossed" (car on the far side), Ending |
| Broken | Deck split in the middle, jagged ends, rubble falling into the water, clauses on the two slabs | Level 2 story, Bridge (open gap), Wrong (wrong piece tilted in the gap) |
| Built, shaking | Deck joined with the green ", for" piece; wobble lines on both sides of the deck; small crack marks | After the right piece, before any sentence |
| One pier of two | Pier 1 in place under the left tower, tagged "1 · for"; wobble lines halved and marked "½" | After the first sentence |
| Two piers | Pier 2 under the right tower, tagged "2 · because"; no wobble, no cracks | After the second sentence |
| *nor* | One wide centre pier under the joint, tagged "1 · nor"; no wobble | After the only *nor* sentence |

## Sentences

- A pier shows a short tag: its number and the word the sentence used (the conjunction or the Quick Facts word).
- Under the water, a caption lists the sentences in full, numbered to match the piers, in text of at least 14 px.

## Canvas work (approach A)

**Approaches considered:**
- A: a bridge sheet plus redrawn screen boards. **Picked:** it shows every state and becomes the reference for the app build.
- B: redraw the existing screen boards only. Some states would appear on no board.
- C: a reusable bridge part on the canvas. It depends on canvas support that isn't confirmed, and it would change how the owner edits.

**Work:**
- New board **Bridge sheet**: all six states, labelled, side by side.
- Redraw with the new bridge: Start, Main (Welcome), Story, Bridge, Wrong, WriteOwn, Write and Ending.
- The Write board shows two piers.
- WriteOwn shows the built, shaking state.
- Level 3 "bridge crossed" has no board. The sheet's "Finished" state, with the car on the far side, covers it.

## Constraints

- Logo colours only: navy `#183870`, teal `#309090`, light teal `#80C0A8`, orange `#D88858`, background `#E6F5FF`. The existing scene greys and blues stay: deck `#5B6472`, stone `#6F7F9E`, water `#56B9D6`.
- The SVG must stay drawable by `flutter_svg`: no `<filter>` or `<mask>`.
- Error outlines are orange `#D88858`, not red (DECISIONS.md). The Wrong board uses this.
- Read the latest canvas version before publishing, because the owner edits it too.

## Left to the builder

- Exact pier size and the tag's font size; the tag must be legible at phone width.
- How the wobble lines look, as long as they read as shaking and the "½" is clear.
