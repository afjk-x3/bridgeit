# Decisions from the three design reviews

Reviews by DeepSeek, Opencode and Gemini of `pairs/` (app vs. Wireframes v3), 2 November 2026. The owner accepted the items below on 3 November 2026. This file is the spec for `docs/superpowers/plans/2026-11-03-review-fixes.md`.

## App: usability fixes

1. **Travelogue keyboard.** While the keyboard is open, the guide portrait and "Write about" prompts are hidden so the journal box keeps at least 5 lines.
2. **Write with Quick Facts.** The Submit button is never cut off; the duplicate top bubble goes.
3. **MatchIt board.** All 7 rows fit without being clipped; the duplicate "MatchIt" title inside the board goes.
4. **Disabled buttons.** Navy text on the grey `#C9D6E3` fill.
5. **Small text.** Character counters, song times and the bridge counter are at least 14 px.
6. **Comma after building.** The placed piece keeps its comma (", for") on every Level 2 step.
7. **Titles and copy.**
   - Level 1 header reads "MatchIt" on the MatchIt instructions and board.
   - Level 2 header line 1 reads "LEVEL 2 · BRIDGE n OF 7"; line 2 reads "Building Bridges" while building and "Strengthen the bridge" afterwards.
   - "▶ Play the song" in sentence case.
   - The Ending button reads "Send my answers to my teacher".

## App: behaviour changes

8. **Wrong answer.** The wrong piece stays in the gap with an orange `#D88858` outline, and the hint names what that word does (e.g. "'so' is used to show result or consequence."). Words with no hint of their own use their MatchIt function from Level 1.
9. **Write your own sentence.** A live checklist under the box: "Starts with a capital", "Uses 'for'", "Comma right before 'for'", "Ends with . ! or ?". After the first wrong answer a hint shows: what the word does, plus the bridge's example sentence.
10. **Travelogue Submit.** The disabled button says what is missing ("Write 2 more sentences to submit", "Use 1 more conjunction to submit", "Remove 1 sentence to submit").
11. **Place montage.** Navy header with the place name, one dot per photo, and a "Map" button beside "Next".
12. **Sing along.** The player is the top strip of the lyrics card; the "SING ALONG!" title goes.
13. **Bridge.** The two clauses sit on the bridge deck either side of the gap; the sentence card above the bridge goes.
14. **Map.** Rebuilt as in Wireframes v3: places north to south (Saud Beach, Bangui, Burgos, Laoag La Paz, Paoay, Currimao, Badoc), numbered pins on a winding road, a card with an icon per place, and a "Drive to …" button. The student picks one place, so there is no "visited" count or "NEXT STOP" tag.

## Flow changes

- **Drop Level 2 steps 16 and 17.** "Tap the coordinating conjunction" and the Quick Facts window go. After the first sentence, the student goes straight to Write with Quick Facts, where the Quick Facts card sits above the bridge.
- **Ending header.** Keep the header and its back button (Opencode's view); hide the Map button there.

## Wireframes v3 (not yet approved for work)

- Start the Write-your-own-sentence box empty; show the example as grey hint text, without the "jaket" misspelling.
- Use orange `#D88858` for error outlines, not red.
- Navy story banner on the broken-bridge story.
- Hide the "Made by" credits card until the client sends names.
- Drop the notebook rings on the travelogue; keep the ruled lines.
- Map: no "1/7 visited" or "NEXT STOP"; a "Drive to …" button that appears once a place is picked.
