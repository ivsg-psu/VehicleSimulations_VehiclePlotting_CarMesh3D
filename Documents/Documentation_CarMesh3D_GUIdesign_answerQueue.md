# Design: the answer queue (`fcn_CarMesh3D_answerQueue`)

*A small window for answering open questions and human-judgment tests by clicking. Started 2026-11-25 by Claude, from Sean's idea (2026-11-25 14:36 to 14:40; Q64 (A), Q65 (B), 16:49). The general GUI rules are in `Documentation_CarMesh3D_GUIdesign_rules.md`.*

**Status:** BUILT 2026-11-25 17:00 (Claude); the test `script_test_fcn_CarMesh3D_answerQueue` passes.

## Review now (for Sean)

(none: T73 and Q67 answered in the window itself, 2026-11-25 17:10 to 17:11)

## 1. What it is for

The back-and-forth between Sean and Claude, made fast: Claude lists the open questions and the tests that need a person; Sean answers each with a click (and a comment if needed); Claude reads the answers and merges them into the design files. It is the V&V GUI's pattern applied to the work itself (Sean, 16:23: "That's what inspired the idea!").

Why (Sean, 14:36 to 14:40): orders-of-magnitude faster than editing MD files; clear notation; (A)/(B) questions as click boxes; no need to ask "is that MD file closed?", since the two sides never write the same file.

It is meant to outlive this project: see section 6.

## 2. The two files

Both live in the queue folder: Claude's working folder, `Desktop\Claude\Project_CarMesh3D\answerQueue`, out of git (Q67 (A): answers are working notes, merged into the design files anyway). The window remembers the folder used last (a preference, `CarMesh3D/AnswerQueueFolder`). A third file, `lastDone.txt`, holds when Done was last pressed.

- **`openItems.json`**, written by Claude: `{"Written": "<time>", "Items": [...]}`; each item has `ID` (Q67, T73), `Kind` (question or test), `Title`, `Text`, and optionally `Context`, `File`, `Section`, `Options` (each `Key`, `Text`, `Recommended`), `Commands` (the MATLAB commands for a test step), `CodeTests` (test scripts by short name, such as `reviewVehicle`).
- **`answers.jsonl`**, written by the window: one JSON line per click (`ID`, `Choice`, `Comment`, `Who`, `When`, `ItemsWritten`). It is only ever added to, never rewritten; the last line for an ID is its answer. A broken line (a power cut mid-write) is passed over.

## 3. The window

- **Top bar:** ☰ Menu (Shared GUI settings: You; Exit last), Previous, Next, the progress ("Item 2 of 5 · 1 answered"), **Done: copy the answers** (green), and **NOW** (big, red).
- **Left:** every item with its mark: ✓ answered, ✗ BUG, ? open, ?? unsure, … later. Click one to go there.
- **Middle:** the item's heading, text, context and where it belongs; for a test, its commands, **Run the commands**, **Run the code tests**, and what they printed.
- **Bottom:** the answers as buttons, across the full width: the lettered options (the recommended one marked right after its letter, "(A, recommended)", in bold, so the mark is never cut off; a test's outcomes carry no recommendation), then BUG and ??? for a test, and Later for both; a comment box; who answered and when.

## 4. Done and NOW

- **Done** puts on the clipboard the answers made since the last Done, in this window or an earlier one (`lastDone.txt`), one line each (`Q67 (A): comment`), headed by the answers file's path. Paste it into the chat.
- **NOW** is for an answer that must change what Claude is doing at once, or for when something breaks hard (Sean, 16:49: "the big red button"). It copies `NOW: <ID> (<title>): <answer>: <comment>` and the last error the window saw (from Run). Paste it into the chat.

## 5. Running

- **Run the commands** runs the item's commands in the base workspace, as if typed at the prompt. `close all force` and `close all` are taken out, and every other figure except answer-queue windows is closed instead (T73 BUG); `clear functions` is left out (it would clear the window's own code). The window keeps `HandleVisibility` off, so a `close all` inside a test script leaves it open. The output, or the error, is shown.
- **Run the code tests** runs each named `script_test_fcn_CarMesh3D_<name>.m` in the base workspace and shows PASS (with seconds) or FAIL (with the message) for each.

## 6. Plan

1. DONE 2026-11-25: the function and its test.
2. DONE 2026-11-25 17:11: Sean tried it on the first real items (T73, Q67); fixed what he found (Run closing his window; the recommended mark cut off; Done repeating old answers).
3. Claude writes each round's open items to `openItems.json` as a habit, and reads `answers.jsonl` when Sean pastes Done.
4. **Archive for other projects** (Sean, 16:49; work queue, "End-of-project return-to"): make the answer queue, the V&V host pattern, the design-file template and the test rules project-independent, most likely as a skill set, coordinated with Sean's other session on rules, suggestions and skills.

## Tests for Sean

Key: as in `Documentation_CarMesh3D_template.md`. The code tests (`script_test_fcn_CarMesh3D_answerQueue`) cover the buttons, the files, Done, NOW and both Run buttons.

(none open)

## Open questions

Key: as in `Documentation_CarMesh3D_template.md`.

### Question list

(none)

## Change log

- 2026-11-25 17:00, Claude: first written, with the function and its test (Q64 (A), Q65 (B); Done and NOW, Sean 16:49).
- 2026-11-25 17:03, Sean (T73 in the window): **BUG**: "Invalid or deleted object" in doRunCodeTests. The item's code test is the queue's own test, which opens a second, hidden queue; its Run closed every other figure, Sean's window among them. Fixed 17:05 (Claude): Run never closes an answer-queue window, and writes nothing to a window that has gone; a BUG case in the test.
- 2026-11-25 17:10, Sean: the recommended mark was not seen (it was added at the end of the label, which was cut off). Fixed (Claude): "(A, recommended)" right after the letter, in bold; answers across the full width. A test's outcomes carry no recommendation, by design.
- 2026-11-25 17:10, Sean: Done in a new window repeated an old answer. Fixed (Claude): Done's time is kept in the queue folder (`lastDone.txt`).
- 2026-11-25 17:11, Sean, in the window: **T73 (A)**, the look and feel is right (first use, during development). **Q67 (A)**: the queue folder lives in Claude's working folder, out of git (where it came up: the first use of the queue).
