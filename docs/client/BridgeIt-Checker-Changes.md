# BridgeIt sentence checker: changes for your review

1 November 2026

The sentence checker in Level 2 decides whether a student's sentence can become a bridge foundation. We compared it with published grammar sources and changed it to follow them. Some of these changes go beyond what you asked for, so please review them.

## Why this matters

You asked for simple offline checks with no grammar or meaning checks. Changes 1, 2 and 3 below do check grammar, because your focus is FANBOYS joining independent clauses. Without them, the app would accept sentences that break the rule being taught.

## What changed

| # | Student writes | Before | Now | Why |
|---|---|---|---|---|
| 1 | Because she was sick, and he left. | Accepted | Rejected: the first part is not a full clause | A clause starting with a word like *because* or *although* cannot stand alone |
| 2 | He does not like coffee, nor he drinks tea. | Accepted | Rejected: word order | After *nor*, the helping verb comes before the subject: "nor does he drink tea" |
| 3 | I like tea, nor do I drink coffee. | Accepted | Rejected: needs a negative first | *Nor* follows a negative clause |
| 4 | We stayed home, because it rained. | Accepted | Rejected: remove the comma | No comma when the main clause comes first. This also matches your Quick Facts |
| 5 | Because it rained we stayed home. | Rejected, but with the wrong message | Rejected: add a comma | A comma is needed when the *because* part comes first |
| 6 | Open the door, and come in. | Rejected | Accepted, with a hint | A command has an understood "you", so it is a full clause |

We also fixed some good sentences that were being rejected:

- Short clauses, such as "She smiled, and he waved."
- Clauses starting with a name, such as "Maria sings well, and Ben plays the guitar."
- Questions, such as "Did you eat lunch, or did you skip it?"

## Decisions we need from you

1. **Do you approve changes 1, 2 and 3?** They are stricter than "no grammar checks". If you prefer the simpler version, we can turn them off.
2. **Should *although* and *even though* allow a comma before them?** Purdue OWL allows one for strong contrast, as in "She was still upset, although she had won." Your Quick Facts say no comma, so the app rejects it for now.
3. **Should very short clauses need the comma?** The Chicago Manual of Style lets very short clauses skip it. Purdue OWL does not mention this, and your lesson teaches the comma, so the app requires it for now.
4. **Can a teacher review our test sentences?** We test 76 sentences, and we can send you the list. Published rules can't show how well the checker works with real student writing, so a teacher's review, and if possible a few real student sentences, would help most.

## What the checker still can't do

- It does not check meaning or most grammar. "She go to school, for she want to learn." still passes, and the teacher sees it in the answer report.
- It uses simple rules, not a full grammar analysis. It sometimes mistakes a noun for a verb, so "To the big park, for it was sunny." can pass.
- When it is unsure, it lets the student continue and shows a hint. We chose this so a good sentence is not blocked.

## Sources

Grammar rules:

- [Purdue OWL: Independent and dependent clauses](https://owl.purdue.edu/owl/general_writing/punctuation/independent_and_dependent_clauses/index.html)
- [Purdue OWL: Extended rules for using commas](https://owl.purdue.edu/owl/general_writing/punctuation/commas/extended_rules_for_commas.html)
- [Cambridge Dictionary: Neither, neither … nor and not … either](https://dictionary.cambridge.org/grammar/british-grammar/neither-neither-nor-and-not-either)
- [The Chicago Manual of Style Q&A: Commas](https://www.chicagomanualofstyle.org/qanda/data/faq/topics/Commas/faq0017.html)
- [Southeastern Louisiana University Writing Center: Semicolons](https://www.southeastern.edu/wp-content/uploads/omni-misc-files/acad_research/programs/writing_center/handouts/pdf_handouts/semicolons.pdf)

Word list:

- [WordNet 3.1](https://wordnet.princeton.edu/), Princeton University
- [New General Service List 1.2](https://www.newgeneralservicelist.com/new-general-service-list), Browne, Culligan and Phillips

The verb list used to spot verbs now comes from these two sources instead of our own list.
