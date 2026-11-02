# BridgeIt: built app vs. wireframe review brief

You are reviewing an educational phone game. For each screen you get two pictures: the **app as built** (left) and the **wireframe v3** it should follow (right). Rate how closely the app matches, rate the design itself, and say what to improve. **Do not edit any file.**

Files in this folder:

- `pairs/NN-name.png`: one image per screen, app on the left, wireframe on the right. 26 screens.
- `sheet-1.png` to `sheet-5.png`: the same pairs, six per image, for tools that take few images.

Where a screen has no wireframe, the right side says so. Judge that screen against the style of the other wireframes.

## The project

BridgeIt is an offline, English-only Android game (Flutter) that teaches the seven coordinating conjunctions, FANBOYS: *for, and, nor, but, or, yet, so*. It is for a client's classroom study. The students are **Grade 8 (about 13 years old) in the Philippines**, on their own phones.

The story: a girl guide is on a road trip through Ilocos Norte. The student, the "Bridge Builder", helps her cross broken bridges.

1. **Level 1:** listen to a theme song three times with a sing-along card, then a matching activity (MatchIt): each conjunction to its function.
2. **Level 2:** seven bridges, one per conjunction. The student drags the right conjunction into the gap, then writes their own sentence with it. A Quick Facts step shows similar words (because, since, as) and asks for a second sentence.
3. **Level 3:** the toll gate, a map of real places, a photo montage of the chosen place, a travelogue of 5 to 7 sentences with at least 4 conjunctions, then the ending.

Deadline: **21 November 2026**. Phone testing and client review still have to fit before it, so prefer changes that are cheap and visible.

## Design rules

- **Palette, from the logo:** navy `#183870`, teal `#309090`, light teal `#80C0A8`, orange `#D88858`, background `#E6F5FF`, white cards.
- **Style:** flat fills with navy outlines, no gradients or shadows in the art.
- **Font:** Nunito.
- **Art:** hand-written SVG drawn with `flutter_svg` (no `<filter>` or `<mask>`). All art is ours; the client sends only the sentences, the song and its timings.
- **Phone:** tested at 1080×2400 (about 390×867 logical pixels). Touch targets at least 48 px.

## Decisions already made, don't undo

- The bridge pieces carry their comma (", for"), as in the client's own mockup.
- The separate "Now that you know the song" screen is merged into the MatchIt instructions.
- The guide is shown small at the wheel of a blue car; the owner prefers this to a big character in the car.
- The Ending follows the client's layout: logo, three speech bubbles, the guide waving in front of her car on a hill.
- Main buttons are solid navy with white text.

## Known gaps between app and wireframe

Check these, but don't limit yourself to them:

- **Map (21):** the app keeps its old coastal map with label pills; the wireframe has a coast, a winding road, numbered pins with place cards, a "NEXT STOP" tag and a "Drive to…" button.
- **Bridge (12, 13):** the app shows the clauses in a sentence card above the bridge; the wireframe writes them on the bridge deck. After a wrong answer the app clears the piece and shows a hint; the wireframe keeps the red piece in the gap.
- **Sing along (07, 08):** the app has the player as its own box above the lyrics; the wireframe puts it at the top of the lyrics card.
- **Write your own sentence (15):** the wireframe has a live checklist under the box (capital, uses the word, comma, end mark) and a one-time hint after a wrong answer. The app has neither yet.
- **Travelogue (25):** the app screenshot is taken with the keyboard open, as a student would see it while typing. Both highlight the conjunctions they count. The wireframe also draws a notebook with rings, and its Submit button says what is missing ("Write 4 more sentences to submit"); the app has neither.
- **Credits (02):** the wireframe has a "Made by" card; the names aren't known yet.
- **Lyric picture and place photos:** the wireframe shows placeholders; the app has the real art.

## What to return

1. **Overall:** a score out of 10 for how well the app matches the wireframes, and a score out of 10 for the design itself, each with one line on why.
2. **Per screen,** a table with: number and name, match score /10, design score /10, the main difference in one line, and the fix in one line.
3. **Top 10 improvements,** ranked by value for effort. For each: the screen, the exact change, why it matters for a Grade 8 student, and an effort of small, medium or large. Changes must keep the design rules above.
4. **Wireframe ideas to drop or change:** anything in the wireframes that would be worse than what the app already does, with the reason.
5. **Consistency:** do the screens read as one product? Name what breaks it (colours, spacing, buttons, headers, art style).
6. **Accessibility:** contrast, text size, touch targets, anything that relies on colour alone.
7. **Leave alone:** what is already good on both sides.

Base everything only on what you can see in the images. If an image did not load or a screen is unclear, say so and don't score it.
