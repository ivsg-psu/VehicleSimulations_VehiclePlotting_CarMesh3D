# Design: the V&V GUI (verification and validation of a mesh)

*Started 2026-11-24 23:25 by Claude, from Sean's discussion of 22:54 to 23:23. Replaces the design in `Documentation_CarMesh3D_GUIdesign_reviewVehicle.md`, which now points here (Q51 (A): Sean said "They are all yours" at 23:23 without picking; Claude took the recommended choice; say if you want (B) instead). The general GUI rules and Sean's design principles P1 to P5 are in `Documentation_CarMesh3D_GUIdesign_rules.md`; this file holds only what is particular to the V&V GUI.*

**Status:** DESIGN, marked up by Sean (2026-11-25 01:25); the first round of six assessments agreed (section 5). Nothing is built yet. The current `fcn_CarMesh3D_reviewVehicle` keeps working until the new host replaces it.

## Review now (for Sean)

1. Section 5: check Claude's tidy-up of the table (renumbered, the brake-lights row, the two questions reworded so No means a problem, Q53 (A)).
2. Nothing open: Q47, Q48 and Q56 are answered (section 9).

## 1. What the V&V GUI is for

It answers one question per vehicle: **is the mesh right?** It does so by asking a person a short series of questions that only a person can answer quickly, each taking a few seconds (P4), and recording the answers.

It is a **host**, not a test list (Sean, 23:07 and 23:18): it calls a list of assessment functions, shows what each one draws, records the answer, and moves on. It holds and passes data; it creates none. This is the paradigm of the DebugTools menu. Because the list is a list of functions, an assessment can be added when a problem is found later in the pipeline, or removed when it never fails, by changing one line.

**What it is not** (from P2, P3, P5):
- **Not for building or fixing meshes.** A "No" is recorded; the fix is made elsewhere (the painter, the vehicle script), opened from the browser. The painter is no longer hosted inside the V&V GUI.
- **Not for questions a computer answers exactly.** Numeric dimension agreement, counts of holes, faces outside a bounding box, motion along a path: these are code checks, reported as pass or fail in the build and the summary, never asked of a person. ("Do not ask the user to assess numerical agreement", Sean, 22:54.)
- **Not for checking that code works.** Animations moving the body, turning the wheels or steering test the animator's code; that belongs in its function tests. The one way a correct animator can look wrong is a labeling mistake, and that is asked directly (the tire assessments, section 5).

**Who uses it** (Q47, Sean 2026-11-25 01:53): "myself, other PhD engineers on my team, 2 undergrad senior engineers, and if easy to use, a class of ~100 engineering students." So the questions and tooltips must be clear to a student seeing them for the first time, and every answer records who gave it, from a small helper that gets the user's identity (or just a text box; section 11). Students who only use the library never open it; they see its result, the approval mark in the browser.

## 2. How it works

```
V&V host  --(vehicleFiles, Parent=panel)-->  fcn_CarMesh3D_assess_<name>   (draws, then returns)
          <--(Key, Question, Answers, Help)--
          shows it, records the answer, goes to the next one
```

- The list: a cell array of function handles, held in one place (`fcn_CarMesh3D_reviewChecks`, built 2026-11-24, becomes this list). It holds only the handles, in order, with required or optional and on by default; **no wording** (that comes from each function's describe mode, section 3). **The code is the source; this file describes it** (Q52 (A), Sean 2026-11-25 01:15, "almost as a rule"): a test checks that the keys and order in section 5's table match the code's list. A user can also pass a list of their own for one run (`Assessments={@fcn_A, @fcn_B}`) without editing anything. Its order matters: basic assessments first (orientation before the tires), which, with "Stop at the first No?", takes the place of a dependency matrix (Sean, 23:18: a matrix would make new tests hard to add).
- One assessment function may give more than one question (the tire function gives four, one per tire).
- The host never knows what an assessment means. All it keeps is the table of answers.

## 3. The assessment function interface

```matlab
assessments = fcn_CarMesh3D_assess_<name>(vehicleFiles, (Parent=panel), (FigNum=figNum))
descriptions = fcn_CarMesh3D_assess_<name>((Describe=true))      % describe mode
```

**Describe mode** (Sean, 2026-11-25 01:22: "call the functions with a silent call to query what wording the function wants to use"): with `Describe=true` the function needs no vehicle, reads no file, computes nothing and draws nothing; it returns only its key or keys, short title, question, answers and tooltip (the tire function returns four). Shared GUI settings' Review rows and the host's list are built from these, so editing a function's wording changes every menu, and the wording lives in one place, next to the picture it describes. Guards: the settings panel wraps each describe call in `try` / `catch` (a failure shows as a greyed row, "(could not describe: <the error>)"); one test calls every listed function in describe mode and checks it returns in well under a second, opens no figure, and gives a key no other function uses.

| Field returned | Meaning |
|---|---|
| `Key` | Unique name, such as `'orientation'` or `'tire_frontDriver'` |
| `Title` | Short name for the list and Shared GUI settings ("Patchy labels") |
| `Question` | The question, as asked: "Is the orientation correct in this image?" |
| `Answers` | The allowed answers, as radio buttons: `{'Yes', 'No'}`, or `{'Higher', 'Equal', 'Lower'}` for a comparison. **A No always means a problem** (Q53 (A), Sean 2026-11-25 01:32): questions are worded so, since "Stop at the first No?" relies on it. For a comparison, the function also names which answers count as a problem ("Lower") |
| `Help` | One line on what to look at (the tooltip) |

**Rules for every assessment function** (Q49 (A), Sean 23:07, with his concern about errors that travel upward):
1. **All drawing is finished before the function returns.** It never returns draw instructions or function handles for the host to run later, so every drawing error is thrown inside the function or its dependencies, where it is easy to find.
2. **Its pictures are static,** or any interaction lives entirely inside the function. The host never calls back into the function's objects; it only deletes them.
3. **It returns data only** (the table above).
4. **With no `Parent`, it makes its own figure** (`FigNum`, as every function in the repo), so it can be run and debugged by itself at the prompt: `fcn_CarMesh3D_assess_orientation(vehicleFiles)`.
5. **Heavy computing is done in the build step and cached;** the assessment only loads and draws, so it takes well under the few seconds P4 allows.

**What the host does around each call** (Sean, 23:07: "a timer and robust catch for if/when the draw actions might fail"). MATLAB runs the GUI, timers and callbacks on one thread, so a timer cannot stop a function that is drawing; the safeguards are:
- **`try` / `catch` around every call.** A failed assessment shows its error in the panel, with Retry, Skip and Show error, is recorded as "error" (not an answer), and the list goes on.
- **Every call timed.** One slower than a few seconds is listed in the report, so slow assessments are found and fixed.
- **A true timeout only for computing,** never drawing: work that cannot be cached runs in the background (`parfeval` on `backgroundPool`, base MATLAB) and is cancelled after a set time.
- **The next assessment prepared while the current one is answered** (its computing; its drawing happens when it is shown).

## 4. What is recorded (Q50 (A), Sean 23:18)

For each question: the answer, an optional one-line comment, who (your initials, Shared GUI settings), when, and a **fingerprint of what the question was about**: a hash (MD5 or SHA-256, through Java's `java.security.MessageDigest`, base MATLAB) of the data the assessment drew, not of the file. Each assessment computes its own (orientation: the vertices; labels: the faces and their labels), with vertices rounded (to 1e-6 m) before hashing so a rebuild that changes only round-off does not count. So a relabel makes the label answers stale but not the orientation answer. File dates and sizes are not used: copies, git and re-saving change them when the mesh has not changed (Sean, 23:28); a hash of the .mat file's bytes is not used either, since re-saving the same mesh changes them. The V&V GUI captures and reports where the Yes and No answers fell; the report lists each vehicle's No answers as its to-fix list.

**Stale answers** (Claude, 23:18; a computer task under P5): when the mesh has changed since an answer, that answer counts as unanswered, and the report says "mesh changed since this answer".

## 5. The assessments (starting list)

*Required: always asked. Optional: can be turned off in Shared GUI settings, Review, and is then recorded as skipped. **Every human assessment is optional** (Sean, 2026-11-25 00:53): "The only time something should be required is if, in the current usage chain, not passing that will foundationally break a code somewhere"; such a check is a code check in the build, not a question. **First round** (Sean, 01:22 and 01:36, Q55 (A)): keep the list short, work the UI and some real vehicles through it, then add more ("There's probably 20 questions we could ask"). The table is the design for `fcn_CarMesh3D_reviewChecks` and for the assessment functions to write, one per row (Sean, 01:19).*

| Order | Round | Assessment | Question | Answers | Replaces | Sean's choice |
|---|---|---|---|---|---|---|
| 1 | first | Overall | Does this mesh pass a first glance? *(tooltip: A few seconds, before anything else: No if something is plainly wrong, such as the wrong vehicle, missing parts, a scrambled or inside-out mesh, or far too few faces to be usable. No ends the review here when "Stop at the first No?" is on.)* (Sean, 01:13) | Yes / No | (new) | optional |
| 2 | first | Labels | Are the labels on the correct portions of the mesh? (one or two pictures in label colors) | Yes / No | Labels (the painter is no longer inside) | optional |
| 3 | first | Patchy labels | Are the labels clean, with no blotchy or patchy areas? *(tooltip: Patches often mean faces pointing the wrong way, or mixed-up labels.)* (Sean, 01:32: "a perfect example of something a human catches in fractions of a second whereas code takes tons of computations"; a No means the mesh got past the build's guards, or labels were mixed up when it was made, "very common") | Yes / No | Labels (was "Label Directions", Q54) | optional |
| 4 | first | Headlights | Do the headlights go off, low, high as expected in these three pictures? | Yes / No | Lights | optional |
| 5 | first | Brake lights | Do the brake lights come on as expected in these pictures? (off; tail lamps on; braking: tail and brake lamps often share a housing, so this catches one labeled as the other) (Sean, 01:28: "the most important illumination signal in the entire list") | Yes / No | Lights (was "Taillights") | optional |
| 6 | first | Realism | Is the realism of this mesh (Fig 1) higher than, equal to, or lower than this approved mesh (Fig 2)? (Lower counts as the problem answer) | Higher / Equal / Lower | (new) | optional |
| 7 | later | Orientation | Are the x-axis and z-axis labeled correctly in this image? (front and up arrows on the model) | Yes / No | Orientation | optional |
| 8 | later | Dimensioning lines | Are the length, width, height and wheelbase lines placed on the right points? (the numbers are checked by code, not asked) | Yes / No | Dimensions | optional |
| 9 | later | Tires (four questions) | Does Fig 1 show the front driver tire? (its labeled faces highlighted against the body; then the front passenger, rear driver and rear passenger tires) | Yes / No | Body, Steering, Wheels, Drive | optional |
| 10 | later | Blinkers | Do the blinkers go off and on as expected in these two pictures? | Yes / No | Lights | optional |
| 11 | later | Fog lights | Do the fog lights go off and on as expected in these two pictures? | Yes / No | Lights | optional |
| 12 | later | Seats and wheel | Are the seats and the steering wheel found where they are? | Yes / No | (new: a core mesh requirement) | optional |
| 13 | later | Photos | Are the vehicle photos correct all the way around (correct vehicle, correct approximate angle)? | Yes / No | (new: a core mesh requirement) | optional |
| 14 | later | 2D outline | Is the 2D outline representative of an overhead view of the vehicle? | Yes / No | 2D outline | optional |
| 15 | later | 2D interior | Are the 2D outline's interior elements (seats, steering wheel) visually useful? | Yes / No | (new) | optional |
| last | (always) | Summary | (not a question: every answer, and the overall decision) | Approve / Reject | Summary | required |

**Moved to code checks** (Sean, 2026-11-25 00:55): the old 2D outline question (a single closed loop, no holes or self-crossings) is exact, so the build checks it once where the outline is made (`polyshape`: one region, no holes, simplified) and fails with a clear message; downstream code can then run with input checks off and trust it.

**Removed** (Sean, 22:54 to 22:59):
- **Differences** (holes and changes in the mesh): "this is not the point of V&V (it's not even the point of the paint GUI)". A code check, if needed.
- **Body, Steering, Wheels, Drive** (the animations): code correctness, and very costly; what they really tested is whether each tire is labeled right, asked directly in the tires assessment (order 9).
- **Detail levels:** never failed; kept only for exemplars, if anywhere.
- **The painter inside the reviewer:** fixing is not V&V.

**What an approval rests on** (Claude, 2026-11-25 00:53, proposed; Sean is "reluctant to put an approval override flag anywhere in the code. This invites abuse and violates the core GUI principles"): there is no override. Every approval records what it rested on, shown in the report and the browser, for example "approved, all 6 assessments asked, by SBB" or "approved, 0 of 6 asked (all turned off in Shared GUI settings), by SBB". So one Approve per vehicle for a trusted source is allowed and quick, and honest: a mesh reviewed in full and one trusted on its source can be told apart (the browser's Status could show F and T).

## 6. The settings (in Shared GUI settings, Review)

| Setting | Choices | Default | What it does |
|---|---|---|---|
| Each assessment | Off / On (optional ones only) | On | Turned off: skipped for every vehicle, recorded as skipped (built 2026-11-24) |
| Stop at the first No? | Off / On | On (proposed) | After a No, go to the Summary; the questions after it are recorded as "not asked (stopped at the first No)". With the list's order, this replaces a dependency matrix (Sean, 23:18) |
| After an answer, go to | Next always; Next unanswered; Next unanswered or No; Stay here | Next unanswered or No (proposed) | Where the host goes after each answer (Sean, 23:18 and 23:21). "Next always" tooltip: *Go to the next assessment in the list order, even if it was already answered Yes or No. Use this to walk the whole list again from start to end.* "Stop at the first No?" comes first: with it On, a No ends the walk |

"Next" is the next row after the current one, in list order, whose answer is in the chosen set, wrapping around once; when none qualifies, the Summary. "Stay here": the user moves with Previous and Next.

## 7. The window

To be drawn once sections 1 to 6 are agreed. Expected, under the rules (G1 pancake, G2 sparse): the assessment's picture fills the window; under it the question, its radio answers and the comment line; Previous, Next and the progress ("3 of 12") in the top bar; the ☰ Menu holds the list of assessments (with their answers) and Shared GUI settings.

## 8. What happens to the current code

- `fcn_CarMesh3D_reviewVehicle` (about 2,800 lines) becomes a small host. Its drawing code moves into the assessment functions where it still applies (orientation, dimension lines, labels, lights, outline), or is deleted (Differences, the animations, the hosted painter).
- Built 2026-11-24 and kept: the ☰ Menu, Shared GUI settings with its Review section, `fcn_CarMesh3D_reviewChecks` (becomes the list of functions), the skipped-check records.
- Built 2026-11-24 and no longer used by the V&V GUI: the painter's panels held in the reviewer's menu (Q45 (A)). The menu helper's `AddPanel` and `RemovePanel` stay, for other hosts.
- The answer files (`review_<ID>.mat`, the report `.md`): kept, with the fingerprint and comment added. Old answers to removed questions are kept in the file, shown nowhere.

## 9. Questions (answered)

- **Q47. Who reviews, in practice?** Sean, 2026-11-25 01:53: "myself, other PhD engineers on my team, 2 undergrad senior engineers, and if easy to use, a class of ~100 engineering students. We'll need a small helper function to get the user information, or even just a textbox." (Neither (A) nor (B): both.) What follows: student-clear wording (section 1); a user-identity helper (section 11); with many reviewers, each answer keeps its own who and when, and review files may be merged from several people's copies (section 10).
- **Q48. Go from one vehicle to the next?** Sean, 01:53: "(B) behavior is preferred as default, but we probably want to expose this as a GUI setting for batches. Here's the reasoning - at the most sparse level, the GUIs may all eventually live inside another gui as sub-panels: the browser just produces a vehicle name, the viewer just shows what was found, the painter edits as needed, and V&V check-marks the output. The browser's one task is to select the vehicle, and option (A) violates the rule: a GUI should not take another GUI's functional role."
  - **Settled** (Sean, 02:01: "That makes way more sense... Such behavior would only happen if it were passed {7, 8, etc}, right?"; yes): the two halves fit because the V&V GUI never **chooses** vehicles. Its caller (the browser, or the trunk) passes one vehicle (the default) or a list of vehicles picked in the browser (a batch); the V&V GUI plays them in the order given, as it plays the assessments. So "next vehicle" exists only inside a list someone else made, and the browser keeps its one role (P2). The batch is an input (`Vehicles={...}`), not something the V&V GUI decides.
- **Q56. A rule on where vehicle data lives** (Claude, 01:58, from Sean's note in section 10; the proposed rule is there):
  - (A) *Recommended:* adopt it now, as rule G40 and in `claude/how_we_work.md`; check the existing code against it later (Someday).
  - (B) Leave it as a Someday note until the merge question is looked at.
  - **Sean's answer: (A)** (02:08): "Agree - this one is a rough tradeoff between different types of failure." Claude's weighing (02:05): it costs a scan instead of a stored list (a fraction of a second for 40 vehicles, a second or two at 1000, so a cached list is allowed if it knows when it is stale), some data belongs to the library and cannot live in a vehicle (part 3 covers it), and discipline in new code; it buys protection from a failure that is silent, slow to show, and arrives exactly when many people add and merge vehicles (Q47: a class of about 100). In database design this is keeping a single source of truth: each fact stored once, where it belongs, everything else derived from it when needed.

## 10. Later (proposals, not in the first build)

- **Batch sampling for a trusted source** (Claude, 2026-11-25 00:53; Sean's example: FHWA's database of about 1000 vehicles). Review a random sample with every assessment on; if none of n fails, the batch's failure rate is below about 3/n at 95% confidence ("rule of three": 60 with no failure, under about 5%; 300, under about 1%). The rest are approved with the reason recorded ("batch FHWA-2026-11: 60 of 1000 sampled, 0 failed"); any failure sends the batch back for a closer look.
- **Claude as a screener** (Sean, 2026-11-25 01:00: "a definite option if given a large batch of data"): Claude looks at every vehicle's pictures and flags the doubtful ones, so the sample includes them; the approval stays the reviewer's (P5). The first trial also tests the screener: a batch where Sean has reviewed some vehicles by hand, to compare what Claude flags with what he found.
- **The other assessments** (orders 7 to 15), added once the first round has been worked through on real vehicles.
- **Someday: many people editing, and merged vehicle folders** (Sean, 2026-11-25 01:53, verbatim): "if many are editing and we merge edits wherein someone remotely added in their own vehicles, etc, is there any place where code obviosly breaks? If so, we should trigger a rescan of the folders. This gives another possible issue: that information may be stored about the vehilce list in one part of the folder, that doesn't know about additions to the folder. The GUI could be use a long time without ever catching this. Maybe add a rule - weigh in please - variables about a vehilce are stored with the vehicle, not kept separate. And variables about vehicle data should not assume the data is static from run-to-run. This shouldn't take our time now, though."
  - *The rule, adopted as G40 (Q56 (A), Sean 02:08):* (1) **data about a vehicle lives in the vehicle's own folder** (its script, mesh, edits, review answers, photos and change log already do); (2) **a list of vehicles is never stored as the truth**: it is found by scanning the folders when needed (as `fcn_CarMesh3D_findVehicleFiles` does), or, if kept for speed, it carries a fingerprint of the folder listing and is rebuilt when that differs; (3) **anything kept outside a vehicle that names vehicles is checked when read**, and says plainly which named vehicle is missing.
    - *Example of part 3* (for reading this later): `Data/bodyStyles.csv` says the hatchback exemplar is `2009_Honda_Fit_Sport`. A colleague renames that vehicle's folder to fix a typo, and the change is pulled. The CSV still names the old ID, which no longer exists. Without part 3, the browser looks up the exemplar, finds nothing, and either shows no exemplar with no message, or fails deep in plotting code with an error about an empty variable; neither points to the cause. With part 3, whatever reads the CSV checks each vehicle it names as it reads it and says: "bodyStyles.csv names 2009_Honda_Fit_Sport as the hatchback exemplar, but no such vehicle is in Data or DataSomeday." The cause and the fix are in one sentence. The same goes for the demo-vehicle preference naming a vehicle a pull removed. **Someday task:** check the existing code against it. Places to check, from memory (to be confirmed by a scan of the code): `Data/bodyStyles.csv` (names exemplar vehicles), the demo-vehicle preference (names a vehicle a pull may remove), the browser's cached previews, and anything a GUI keeps open across a pull. With many reviewers, two people's `review_<ID>.mat` for one vehicle can conflict in a merge, and git cannot merge .mat files; keeping the answers also as plain text (the report) lets git merge them.

## 11. Plan

0. A small helper for the user's identity (initials and name; Q47), used by the V&V GUI, the painter's change log and Shared GUI settings' You section; it asks once when nothing is set.
1. The host, with the safeguards (section 3), the records (section 4) and the settings (section 6), tested with three dummy assessment functions (one that draws, one that fails on purpose, one that is slow).
2. The six first-round assessment functions, in list order, each with its own test script (rule G33), a stand-alone run and describe mode.
3. The window (section 7), then a T-list for Sean.

## 12. Change log

- 2026-11-24 22:54 to 23:23 (Sean and Claude, in the chat): the V&V GUI becomes a host for a list of assessment functions (Sean, 23:07 and 23:18); Q49 (A) drawing into a panel the host gives, with a try/catch and timing (Sean, 23:07); Q50 (A) Yes / No with an optional comment (Sean, 23:18); "Stop at the first No?" and "After an answer, go to" (Sean, 23:18), with "Next always" (Sean, 23:21); removed: Differences (22:54), the animation checks (22:59), the hosted painter (22:54); stale answers by mesh fingerprint (Claude, 23:18).
- 2026-11-24 23:25 (Claude): this file started; `Documentation_CarMesh3D_GUIdesign_reviewVehicle.md` now points here.
- 2026-11-24 23:30 (Claude, Sean 23:28): the fingerprint is a hash of the data each assessment drew (section 4), not file dates.
- 2026-11-25 00:41 to 01:25 (Sean, in this file): the "(Sean's mark:)" column filled, every assessment optional but the Summary; new and reworded questions (Overall, Labels, Label Directions, taillights, blinkers, fog lights, photos, two 2D outline questions).
- 2026-11-25 00:53 to 01:36 (Sean and Claude, in the chat): every human assessment optional, a required check being a code check (Sean, 00:53); approvals record what they rested on, no override (Claude, 00:53, proposed); the closed-outline check moved to the build (Sean, 00:55); Claude as a screener (Sean, 01:00, Later); Overall worded "Does this mesh pass a first glance?" (Sean, 01:13); Q52 (A) code is the source, a test keeps this table in step (Sean, 01:15); describe mode (Sean, 01:22); the first round kept short (Sean, 01:22, 01:25); Taillights became Brake lights (Sean, 01:28); Q53 (A) a No always means a problem (Sean, 01:32); Q54 Label Directions is the wrong-way-faces check, renamed Patchy labels (Sean, 01:32, 01:34); Q55 (A) Brake lights in the first round (Sean, 01:36).
- 2026-11-25 01:40 (Claude): the table tidied (renumbered; a Round column; the two flipped questions reworded; the copy-paste "Taillights" titles fixed), and sections 2, 3, 5, 10 and 11 brought up to date with the above.
- 2026-11-25 01:53 (Sean, in this file): Q47 and Q48 answered; a Someday note on merged edits and where vehicle data lives.
- 2026-11-25 01:58 (Claude): Sean's answers moved into section 9 verbatim, with Claude's reading of Q48 (the V&V GUI plays a list of vehicles its caller gives, and never chooses one); section 1's audience from Q47; the user-identity helper added to the plan; Sean's note moved to section 10 with Claude's view; Q56 asked.
- 2026-11-25 02:01 to 02:08 (Sean and Claude, in the chat): Q48 settled (the V&V GUI plays a list only when its caller passes one); Q56 (A): the rule on where vehicle data lives adopted as G40, with an example of its part 3 added for later reading.
