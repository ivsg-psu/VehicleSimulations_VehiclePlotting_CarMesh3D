# Design: <the GUI or topic> (template for every Documentation_CarMesh3D_*.md file)

*How every CarMesh3D design file is laid out (Sean, 2026-11-25 12:16 and 12:42; Q60 (A)). Copy this file to start a new one. Started 2026-11-25 by Claude. The general GUI rules are in `Documentation_CarMesh3D_GUIdesign_rules.md`; a GUI's file holds only what is particular to that GUI.*

**Status:** DESIGN, BUILT or ARCHIVED, with the date and who.

## Review now (for Sean)

A short list of what Sean should look at now, pointing to the sections below (T-steps live in "Tests for Sean", questions in "Open questions"). Empty when nothing waits.

## 1. What it is for

## 2. ...

*(Numbered sections in the middle: what it does, how it works, its layout, its settings, what is built. Sections are cited by number ("section 3"); when one is added, removed or moved, every citation of the numbers after it is fixed in the same edit, in this file and in any other file or code that cites it.)*

## N. Plan

NOTE: this section notes planned current and future steps. If all are done, or the completed items crowd out the plan, summarize them. It does not hold documentation (that is in the sections above); it shows the planned work and its order, particularly what comes next.

## Tests for Sean

*Kept at the bottom, before "Open questions" and the "Change log", so it is easy to jump to; named, not numbered, so it never moves.*

Key:
- **Only what a person must judge** (Sean, 2026-11-25 13:15 and 14:24, for every file): look, feel, clarity, and other human-only checks. Anything of the form "does X show Y" or "does pressing X do Y" is a code test instead; this section names those code tests, so it is clear what is covered.
- **TNN.** A test step. **Every step carries its own exact MATLAB commands, right under it** (G34; Sean, 2026-11-25 14:24), beginning with `close all force; clear functions; clc`, even when they repeat the step before: never "same window as above". T-numbers are unique across every file (G35); use them little outside this section.
- (Sean's results are in parentheses under the step.)
- Expected outcomes are labeled (A), (B), (both) and so on, as answers are, so a review can be quick: "confirm (A)". A bug is marked **BUG**; an uncertain or unexpected outcome **???**.
- Each step is separated by a blank line, so the steps are easy to tell apart in a plain-text editor.
- A finished round (every step with a result) moves to the change log, with the results.

## Open questions

*Kept at the bottom, before the "Change log"; named, not numbered.*

Key:
- **QNN.** A question. Q-numbers run on across every file and the chat (Q1 to Q99, then wrap).
- Options are lettered, the recommended one first and marked *Recommended*.
- (Answers are in parentheses.)
- Each question is separated by a blank line.

When a question is answered, its content moves into the right section above, and a summary of it goes to the change log: the question, the context in which it came up (in development, in an automated test, in use), the answer, when, and by whom. This section then lists only the questions still open.

### Question list

(none)

## Change log

*Always last.* Newest last; each entry: date and time (Eastern), who, what changed, and why.
