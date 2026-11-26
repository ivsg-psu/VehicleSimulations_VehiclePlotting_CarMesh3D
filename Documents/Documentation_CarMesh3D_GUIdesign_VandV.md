# Design: the V&V GUI (verification and validation of a mesh)

*Started 2026-11-24 23:25 by Claude, from Sean's discussion of 22:54 to 23:23. Replaces the design in `Documentation_CarMesh3D_GUIdesign_reviewVehicle.md`, which now points here (Q51 (A): Sean said "They are all yours" at 23:23 without picking; Claude took the recommended choice; say if you want (B) instead). The general GUI rules and Sean's design principles P1 to P5 are in `Documentation_CarMesh3D_GUIdesign_rules.md`; this file holds only what is particular to the V&V GUI.*

**Status:** BUILT, first round (2026-11-25 02:50, Claude): the host `fcn_CarMesh3D_reviewVehicle` (it replaced the old Model Reviewer, whose last version is in git and in Claude's backups), the six first-round assessment functions, `fcn_CarMesh3D_reviewChecks` as their list, and the Review settings in Shared GUI settings. Tests pass. Sean's first review (T60 to T68, 2026-11-25 12:16) passed, with changes asked; the two-row top bar built 12:22 (T69 passed, 14:24).

## Review now (for Sean)

1. Nothing to judge now (T74 to T77 answered 23:09 to 23:27; in the change log).
2. Next in the plan (section 10): the Headlights and Brake lights pictures as 2 x 3, far views over close-ups of the left lamp (T76 (B)); a Start option (Q70 (A)); one window per vehicle (Q71 (A)).

## 1. What the V&V GUI is for

It answers one question per vehicle: **is the mesh right?** It does so by asking a person a short series of questions that only a person can answer quickly, each taking a few seconds (P4), and recording the answers.

It is a **host**, not a test list (Sean, 23:07 and 23:18): it calls a list of assessment functions, shows what each one draws, records the answer, and moves on. It holds and passes data; it creates none. This is the paradigm of the DebugTools menu. Because the list is a list of functions, an assessment can be added when a problem is found later in the pipeline, or removed when it never fails, by changing one line.

**What it is not** (from P2, P3, P5):
- **Not for building or fixing meshes.** A "No" is recorded; the fix is made elsewhere (the painter, the vehicle script), opened from the browser. The painter is no longer hosted inside the V&V GUI.
- **Not for questions a computer answers exactly.** Numeric dimension agreement, counts of holes, faces outside a bounding box, motion along a path: these are code checks, reported as pass or fail in the build and the summary, never asked of a person. ("Do not ask the user to assess numerical agreement", Sean, 22:54.)
- **Not for checking that code works.** Animations moving the body, turning the wheels or steering test the animator's code; that belongs in its function tests. The one way a correct animator can look wrong is a labeling mistake, and that is asked directly (the tire assessments, section 5).

**Who uses it** (Q47, Sean 2026-11-25 01:53): "myself, other PhD engineers on my team, 2 undergrad senior engineers, and if easy to use, a class of ~100 engineering students." So the questions and tooltips must be clear to a student seeing them for the first time, and every answer records who gave it, from a small helper that gets the user's identity (or just a text box; `fcn_CarMesh3D_userInfo`, built). Students who only use the library never open it; they see its result, the approval mark in the browser.

## 2. How it works

```
V&V host  --(vehicleFiles, Parent=panel)-->  fcn_CarMesh3D_assess_<name>   (draws, then returns)
          <--(Key, Question, Answers, Help)--
          shows it, records the answer, goes to the next one
```

- The list: a cell array of function handles, held in one place (`fcn_CarMesh3D_reviewChecks`, built 2026-11-24, becomes this list). It holds only the handles, in order, with required or optional and on by default; **no wording** (that comes from each function's describe mode, section 3). **The code is the source; this file describes it** (Q52 (A), Sean 2026-11-25 01:15, "almost as a rule"): a test checks that the keys and order in section 5's table match the code's list. A user can also pass a list of their own for one run (`Assessments={@fcn_A, @fcn_B}`) without editing anything. Its order matters: basic assessments first (orientation before the tires), which, with "Stop at the first No?", takes the place of a dependency matrix (Sean, 23:18: a matrix would make new tests hard to add).
- One assessment function may give more than one question (the tire function gives four, one per tire).
- The host never knows what an assessment means. All it keeps is the table of answers.
- **Batches** (Q48, Sean 2026-11-25 01:53 and 02:01): the V&V GUI never **chooses** vehicles, since choosing is the browser's one task (P2: a GUI does not take another GUI's role). Its caller (the browser, or the trunk) passes one vehicle (the default) or a list picked in the browser (`Vehicles={...}`), and the V&V GUI plays them in the order given, as it plays the assessments. "Next vehicle" exists only inside a list someone else made. Sean's longer view: "the GUIs may all eventually live inside another gui as sub-panels: the browser just produces a vehicle name, the viewer just shows what was found, the painter edits as needed, and V&V check-marks the output."

## 3. The assessment function interface

```matlab
result = fcn_CarMesh3D_assess_<name>(vehicleInput, (Mode=mode), (Key=key), (Parent=panel), (FigNum=figNum))
described = fcn_CarMesh3D_assess_<name>([], Mode='describe')       % describe mode
result = fcn_CarMesh3D_assess_<name>(vehicle, Mode='fingerprint')  % the fingerprint only, nothing drawn
```

`vehicleInput` is a vehicle ID or folder, or the structure `fcn_CarMesh3D_reviewInput` makes; the host loads the vehicle once and passes that structure to every function. A function with several questions is called once per question, with its `Key`.

**Describe mode** (Sean, 2026-11-25 01:22: "call the functions with a silent call to query what wording the function wants to use"): with `Mode='describe'` the function needs no vehicle, reads no file, computes nothing and draws nothing; it returns only its key or keys, short title, question, answers and tooltip (the tire function returns four). Shared GUI settings' Review rows and the host's list are built from these, so editing a function's wording changes every menu, and the wording lives in one place, next to the picture it describes. Guards: the settings panel wraps each describe call in `try` / `catch` (a failure shows as a greyed row, "(could not describe: <the error>)"); one test calls every listed function in describe mode and checks it returns in well under a second, opens no figure, and gives a key no other function uses.

| Field returned | Meaning |
|---|---|
| `Key` | Unique name, such as `'orientation'` or `'tire_frontDriver'` |
| `Title` | Short name for the list and Shared GUI settings ("Patchy labels") |
| `Question` | The question, as asked: "Is the orientation correct in this image?" |
| `Answers` | The allowed answers, as radio buttons: `{'Yes', 'No'}`, or `{'Higher', 'Equal', 'Lower'}` for a comparison. **A No always means a problem** (Q53 (A), Sean 2026-11-25 01:32): questions are worded so, since "Stop at the first No?" relies on it. For a comparison, the function also names which answers count as a problem ("Lower") |
| `ProblemAnswers` | The answers that mean a problem: `{'No'}`, or `{'Lower'}` for a comparison |
| `Help` | What to look at (the question's tooltip) |
| `Detail` | (optional) A second line under the question, smaller and not bold: what to do when unsure (Sean, T62: "Do not select Yes if unsure"). An assessment without one shows no second line |
| `GroupKey`, `GroupTitle`, `GroupHelp` | The function's own key (its name after `fcn_CarMesh3D_assess_`), title and tooltip, for the list and Shared GUI settings |
| `Score` | (optional) The range of a score asked with the answer, such as `[0 10]` (Normals: 0 bad, 10 perfect; Sean, 2026-11-26 04:41). The host shows a score box beside the answers and records it |
| `Examples` | (optional) true: the host offers "Compare with examples" (saved pictures of other reviews, best first) and "Save as an example" (Q90 (A), Q91 (A): a PNG of the pictures as turned, and a one-line text file beside it, in `Data/VandV/Examples/<GroupKey>/`, named `<GroupKey>_s<score>_<accept or reject>_<vehicle>_<initials>_<date>.png`, so an example is re-ranked by renaming it) |
| `Fingerprint` | (not in describe mode) The fingerprint of the data it draws (section 4) |
| `Skip` | (not in describe mode) '' or why the question cannot be asked for this vehicle (realism with no exemplar): recorded as skipped, with the reason |
| `Note` | (not in describe mode) One line for the status line, such as the number of headlight faces |

**Rules for every assessment function** (Q49 (A), Sean 23:07, with his concern about errors that travel upward):
1. **All drawing is finished before the function returns.** It never returns draw instructions or function handles for the host to run later, so every drawing error is thrown inside the function or its dependencies, where it is easy to find.
2. **Its pictures are static,** or any interaction lives entirely inside the function. The host never calls back into the function's objects; it only deletes them.
3. **It returns data only** (the table above).
4. **With no `Parent`, it makes its own figure** (`FigNum`, as every function in the repo), so it can be run and debugged by itself at the prompt: `fcn_CarMesh3D_assess_orientation(vehicleFiles)`.
5. **Heavy computing is done in the build step and cached;** the assessment only loads and draws, so it takes well under the few seconds P4 allows.

**What the host does around each call** (Sean, 23:07: "a timer and robust catch for if/when the draw actions might fail"). MATLAB runs the GUI, timers and callbacks on one thread, so a timer cannot stop a function that is drawing; the safeguards are:
- **`try` / `catch` around every call.** A failed assessment shows its error in the panel, with Retry, Skip and Show error, is recorded as "error" (not an answer), and the list goes on.
- **Every call timed.** One slower than a few seconds is listed in the report, so slow assessments are found and fixed.
- **A true timeout only for computing,** never drawing: work that cannot be cached runs in the background (`parfeval` on `backgroundPool`, base MATLAB) and is cancelled after a set time. *Not in the first build* (no first-round assessment computes anything slow; each draws in 0.2 to 0.6 s): section 9.
- **The next assessment prepared while the current one is answered** (its computing; its drawing happens when it is shown). *Not in the first build either:* section 9.

## 4. What is recorded (Q50 (A), Sean 23:18)

For each question: the answer, an optional one-line comment, who (your initials, Shared GUI settings), when, and a **fingerprint of what the question was about**: a hash (MD5 or SHA-256, through Java's `java.security.MessageDigest`, base MATLAB) of the data the assessment drew, not of the file. Each assessment computes its own (orientation: the vertices; labels: the faces and their labels), with vertices rounded (to 1e-6 m) before hashing so a rebuild that changes only round-off does not count. So a relabel makes the label answers stale but not the orientation answer. File dates and sizes are not used: copies, git and re-saving change them when the mesh has not changed (Sean, 23:28); a hash of the .mat file's bytes is not used either, since re-saving the same mesh changes them. The V&V GUI captures and reports where the Yes and No answers fell; the report lists each vehicle's No answers as its to-fix list.

**Stale answers** (Claude, 23:18; a computer task under P5): when the mesh has changed since an answer, that answer counts as unanswered, and the report says "mesh changed since this answer".

**As built** (2026-11-25): SHA-256 (`fcn_CarMesh3D_fingerprint`); numbers rounded to 1e-6 before hashing. The file `review_<ID>.mat` holds `vvAnswers` (one row per question: Assessment, Key, Title, Question, Answer, Problem, Comment, Who, When, Fingerprint, Status, Note, Seconds), `vvSummary` (the decision, its comment, who, when, the counts, and `RestedOn`: every answer at that moment, stale ones marked), `reviewTable` (the same in the older format, which the library browser reads: approved for an answer that is not a problem, rejected for a problem, skipped, error, or blank), and `reviewTableOld` (an older reviewer's answers, kept, shown nowhere). Statuses: answered, skipped (with why), turned off, error, not asked (after the first No), and stale (shown, not stored).

## 5. The assessments (starting list)

*Required: always asked. Optional: can be turned off in Shared GUI settings, Review, and is then recorded as skipped. **Every human assessment is optional** (Sean, 2026-11-25 00:53): "The only time something should be required is if, in the current usage chain, not passing that will foundationally break a code somewhere"; such a check is a code check in the build, not a question. **First round** (Sean, 01:22 and 01:36, Q55 (A)): keep the list short, work the UI and some real vehicles through it, then add more ("There's probably 20 questions we could ask"). The table is the design for `fcn_CarMesh3D_reviewChecks` and for the assessment functions to write, one per row (Sean, 01:19).*

| Order | Round | Assessment | Question | Answers | Replaces | Sean's choice |
|---|---|---|---|---|---|---|
| 1 | first | Overall | Does this mesh pass a first glance? *(tooltip: A few seconds, before anything else: No if something is plainly wrong, such as the wrong vehicle, missing parts, a scrambled or inside-out mesh, or far too few faces to be usable. No ends the review here when "Stop at the first No?" is on.)* (Sean, 01:13) | Yes / No | (new) | optional |
| 2 | first | Labels | Are the labels on the correct portions of the mesh? (one or two pictures in label colors) | Yes / No | Labels (the painter is no longer inside) | optional |
| 3 | first | Patchy labels | Are the labels clean, with no blotchy or patchy areas? *(tooltip: Patches often mean faces pointing the wrong way, or mixed-up labels.)* (Sean, 01:32: "a perfect example of something a human catches in fractions of a second whereas code takes tons of computations"; a No means the mesh got past the build's guards, or labels were mixed up when it was made, "very common") | Yes / No | Labels (was "Label Directions", Q54) | optional |
| 4 | first | Normals | Do all faces point outward, with no face in the opposite color to its neighbors? (each face colored by its unit normal, RGB = (n+1)/2, in two views turned with the CAD mouse; Sean, 02:35: "the errors stand out dramatically") *(with a score from 0, bad, to 10, perfect; examples to compare with, and "Save as an example": Sean, 04:41; Q90 (A), Q91 (A))* | Accept / Reject | (new) | optional |
| 5 | first | Headlights | Do the headlights go off, low, high as expected in these pictures? | Yes / No | Lights | optional |
| 6 | first | Brake lights | Do the brake lights come on as expected in these pictures? (off; tail lamps on; braking: tail and brake lamps often share a housing, so this catches one labeled as the other) (Sean, 01:28: "the most important illumination signal in the entire list") | Yes / No | Lights (was "Taillights") | optional |
| 7 | first | Realism | Is the realism of this mesh (Fig 1) higher than, equal to, or lower than this approved mesh (Fig 2)? (Lower counts as the problem answer) | Higher / Equal / Lower | (new) | optional |
| 8 | later | Orientation | Are the x-axis and z-axis labeled correctly in this image? (front and up arrows on the model) | Yes / No | Orientation | optional |
| 9 | later | Dimensioning lines | Are the length, width, height and wheelbase lines placed on the right points? (the numbers are checked by code, not asked) | Yes / No | Dimensions | optional |
| 10 | later | Tires (four questions) | Does Fig 1 show the front driver tire? (its labeled faces highlighted against the body; then the front passenger, rear driver and rear passenger tires) | Yes / No | Body, Steering, Wheels, Drive | optional |
| 11 | later | Blinkers | Do the blinkers go off and on as expected in these two pictures? | Yes / No | Lights | optional |
| 12 | later | Fog lights | Do the fog lights go off and on as expected in these two pictures? | Yes / No | Lights | optional |
| 13 | later | Seats and wheel | Are the seats and the steering wheel found where they are? | Yes / No | (new: a core mesh requirement) | optional |
| 14 | later | Photos | Are the vehicle photos correct all the way around (correct vehicle, correct approximate angle)? | Yes / No | (new: a core mesh requirement) | optional |
| 15 | later | 2D outline | Is the 2D outline representative of an overhead view of the vehicle? | Yes / No | 2D outline | optional |
| 16 | later | 2D interior | Are the 2D outline's interior elements (seats, steering wheel) visually useful? | Yes / No | (new) | optional |
| last | (always) | Summary | (not a question: every answer, and the overall decision) | Approve / Reject | Summary | required |

**Realism's reference** (Q58 (A), Sean 2026-11-25 12:16): the approved exemplar of the vehicle's body style (`Data/bodyStyles.csv`, Exemplars column), another vehicle than the one reviewed; skipped, with why, when the style has none or the vehicle is its only exemplar. This gives exemplars a further purpose. Sean: an exemplar is (1) a template to build other vehicles of its style parametrically, (2) the mesh for the visibility (detail-level) ladders, and now (3) the reference for realism. *To do:* check that the body-style documentation states all three (`claude/body_styles.md`, the README).

**Moved to code checks** (Sean, 2026-11-25 00:55): the old 2D outline question (a single closed loop, no holes or self-crossings) is exact, so the build checks it once where the outline is made (`polyshape`: one region, no holes, simplified) and fails with a clear message; downstream code can then run with input checks off and trust it.

**Removed** (Sean, 22:54 to 22:59):
- **Differences** (holes and changes in the mesh): "this is not the point of V&V (it's not even the point of the paint GUI)". A code check, if needed.
- **Body, Steering, Wheels, Drive** (the animations): code correctness, and very costly; what they really tested is whether each tire is labeled right, asked directly in the tires assessment (order 10).
- **Detail levels:** never failed; kept only for exemplars, if anywhere.
- **The painter inside the reviewer:** fixing is not V&V.

**What an approval rests on** (Claude, 2026-11-25 00:53, proposed; Sean is "reluctant to put an approval override flag anywhere in the code. This invites abuse and violates the core GUI principles"): there is no override. Every approval records what it rested on, shown in the report and the browser, for example "approved, all 6 assessments asked, by SBB" or "approved, 0 of 6 asked (all turned off in Shared GUI settings), by SBB". So one Approve per vehicle for a trusted source is allowed and quick, and honest: a mesh reviewed in full and one trusted on its source can be told apart (the browser's Status could show F and T).

## 6. The settings (in Shared GUI settings, Review)

| Setting | Choices | Default | What it does |
|---|---|---|---|
| Each assessment | Off / On (optional ones only) | On | Turned off: skipped for every vehicle, recorded as skipped (built 2026-11-24) |
| Stop at the first No? | Off / On | On | After a No, go to the Summary; the questions after it are recorded as "not asked (stopped at the first No)". With the list's order, this replaces a dependency matrix (Sean, 23:18) |
| After an answer, go to | Next always; Next unanswered; Next unanswered or No; Stay here | Next unanswered or No | Where the host goes after each answer (Sean, 23:18 and 23:21). "Next always" tooltip: *Go to the next assessment in the list order, even if it was already answered Yes or No. Use this to walk the whole list again from start to end.* "Stop at the first No?" comes first: with it On, a No ends the walk |

"Next" is the next row after the current one, in list order, whose answer is in the chosen set, wrapping around once; when none qualifies, the Summary. A question skipped by its function (nothing to ask) or turned off is passed over. "Stay here": the user moves with Previous and Next. As built: preferences `ReviewStopAtNo` and `ReviewGoTo` (`'next'`, `'nextUnanswered'`, `'nextUnansweredOrNo'`, `'stay'`), read at each answer, so a change applies at once.

## 7. The window

As built (2026-11-25), under the rules (G1 pancake, G2 sparse):
- **The title bar.**
- **The top bar, in two rows** (Sean, 12:16, after T64 and T65: "Previous" and "Next" read as moving between vehicles), so moving between vehicles never looks like moving between questions:
  - *the vehicle row:* two picture buttons, a vehicle with a - and a vehicle with a + (no words: the only "Next" in the window is the questions'), greyed with greyed pictures when there is no vehicle that way (both, for one vehicle), and "Vehicle 1 of 3: <name>";
  - *the question row:* Previous and Next (the questions; Next after the last one is the Summary), Summary (on the Summary page it reads Questions, back to the first question not answered, else the first), and the progress ("Question 2 of 6 · 1 answered (0 a problem), 5 not answered, 0 skipped, 0 error(s)");
  - ☰ Menu at the left, the height of both rows; its last line is Exit (Q62 (A), Sean 2026-11-25 14:31: "put the Exit button as option (last) in Menu - this cleans up visuals"; the window's own X closes it too).
  The pictures come from `fcn_CarMesh3D_icons` (rule G41, a goal: pictures before words).
- **The assessment's title** as a heading, and its **pictures**, filling the window. The two label pictures (Labels, Patchy labels) have a **legend** under them: a bordered square of each label color the mesh uses, then its name (`fcn_CarMesh3D_plotLabels`' second output, drawn by `fcn_CarMesh3D_assessAxes`' `Legend=`; Sean, T62).
- **The question,** with a second line under it, smaller and not bold, of guidance from the assessment's `Detail` (on the Summary: approve only if every answer is right; if unsure, Reject and say why); its radio answers and a comment box.
- **A status line:** the function's note, then who answered and when, or that the mesh changed since. Not the drawing time (Q61 (A), Sean 12:42; it stays in the saved record, `Seconds`).
- **The ☰ Menu** holds Shared GUI settings (You and Review) and Questions (every question with a mark: ✓ answered, ✗ a problem, ? not answered, - skipped, ! error; click to go there).
- **The last page is the Summary:** the counts, a table of every answer (with each one's note), and Approve or Reject with a comment.

The picture of it is in the README.

## 8. What happens to the current code

- `fcn_CarMesh3D_reviewVehicle` (about 2,800 lines) became a host of about 1,000 lines, half of it comments (2026-11-25). The old version is in git (the commit before `_25a`) and in Claude's `backups\vv_swap_2026_11_25`. Its helper windows (`fcn_CarMesh3D_viewOrientation`, `_viewDimensions`, `_viewOutline`, `_viewDetailLevels`, `_animateChecks`) stay in the repo, with their tests, for the later assessments to draw from; the V&V GUI no longer calls them.
- **The name stays `fcn_CarMesh3D_reviewVehicle`** (Q57 (A), Sean 2026-11-25 12:16): the browser, `openTool`, the demo menu and the review files use it.
- Built 2026-11-24 and kept: the ☰ Menu, Shared GUI settings with its Review section, `fcn_CarMesh3D_reviewChecks` (becomes the list of functions), the skipped-check records.
- Built 2026-11-24 and no longer used by the V&V GUI: the painter's panels held in the reviewer's menu (Q45 (A)). The menu helper's `AddPanel` and `RemovePanel` stay, for other hosts.
- The answer files (`review_<ID>.mat`, the report `.md`): kept, with the fingerprint and comment added. Old answers to removed questions are kept in the file, shown nowhere.

## 9. Later (proposals, not in the first build)

- **Batch sampling for a trusted source** (Claude, 2026-11-25 00:53; Sean's example: FHWA's database of about 1000 vehicles). Review a random sample with every assessment on; if none of n fails, the batch's failure rate is below about 3/n at 95% confidence ("rule of three": 60 with no failure, under about 5%; 300, under about 1%). The rest are approved with the reason recorded ("batch FHWA-2026-11: 60 of 1000 sampled, 0 failed"); any failure sends the batch back for a closer look.
- **Claude as a screener** (Sean, 2026-11-25 01:00: "a definite option if given a large batch of data"): Claude looks at every vehicle's pictures and flags the doubtful ones, so the sample includes them; the approval stays the reviewer's (P5). The first trial also tests the screener: a batch where Sean has reviewed some vehicles by hand, to compare what Claude flags with what he found.
- **The other assessments** (orders 8 to 16), added once the first round has been worked through on real vehicles.
- **Timeouts for computing, and the next picture drawn ahead** (section 3): when an assessment needs them.
- **Someday: pre-flight unit-normal tests, as another panel** (Sean, 2026-11-26 03:12 and 03:14; plan item 15). On the 2009 Fit, Sean found and judged wrong-way faces with a 2 x 2 window: the mesh colored by unit normal, and gray by each face's mean dot product with its edge neighbors (backward faces dark), before and after flipping the faces below a cutoff, with a slider for the cutoff (-1 to 1), "Start from" (the original, or after `fcn_CarMesh3D_orientFaces`) and "Sweeps" (repeat the flip, eroding a backward patch from its border). It chose `orientFaces`' rules: the patch rule, then one sweep at -0.5 ("caught almost everything"; what remains are seams between panels, ill-conditioned where meshes join at very thin curvature, which barely show in renders). As a panel: the reviewer sets the cutoff and sweeps for a vehicle and sees the result, and the choice is kept with the vehicle (rule G40). The working code is kept so the idea is not lost: `Documents/SomedayCode/starter_CarMesh3D_normalsSlider.m` (off the MATLAB path; its header says how to run it and what it lacks).
- **Someday: many people editing, and merged vehicle folders** (Sean, 2026-11-25 01:53, verbatim): "if many are editing and we merge edits wherein someone remotely added in their own vehicles, etc, is there any place where code obviosly breaks? If so, we should trigger a rescan of the folders. This gives another possible issue: that information may be stored about the vehilce list in one part of the folder, that doesn't know about additions to the folder. The GUI could be use a long time without ever catching this. Maybe add a rule - weigh in please - variables about a vehilce are stored with the vehicle, not kept separate. And variables about vehicle data should not assume the data is static from run-to-run. This shouldn't take our time now, though."
  - *The rule, adopted as G40 (Q56 (A), Sean 02:08):* (1) **data about a vehicle lives in the vehicle's own folder** (its script, mesh, edits, review answers, photos and change log already do); (2) **a list of vehicles is never stored as the truth**: it is found by scanning the folders when needed (as `fcn_CarMesh3D_findVehicleFiles` does), or, if kept for speed, it carries a fingerprint of the folder listing and is rebuilt when that differs; (3) **anything kept outside a vehicle that names vehicles is checked when read**, and says plainly which named vehicle is missing.
    - *Example of part 3* (for reading this later): `Data/bodyStyles.csv` says the hatchback exemplar is `2009_Honda_Fit_Sport`. A colleague renames that vehicle's folder to fix a typo, and the change is pulled. The CSV still names the old ID, which no longer exists. Without part 3, the browser looks up the exemplar, finds nothing, and either shows no exemplar with no message, or fails deep in plotting code with an error about an empty variable; neither points to the cause. With part 3, whatever reads the CSV checks each vehicle it names as it reads it and says: "bodyStyles.csv names 2009_Honda_Fit_Sport as the hatchback exemplar, but no such vehicle is in Data or DataSomeday." The cause and the fix are in one sentence. The same goes for the demo-vehicle preference naming a vehicle a pull removed. **Someday task:** check the existing code against it. Places to check, from memory (to be confirmed by a scan of the code): `Data/bodyStyles.csv` (names exemplar vehicles), the demo-vehicle preference (names a vehicle a pull may remove), the browser's cached previews, and anything a GUI keeps open across a pull. With many reviewers, two people's `review_<ID>.mat` for one vehicle can conflict in a merge, and git cannot merge .mat files; keeping the answers also as plain text (the report) lets git merge them.

## 10. Plan
NOTE: this section notes planned current and future steps. If all are done, or amount of content in completed sections overwhelm focus on understanding the plan, then summarize. Purpose of this section is not to host documentation itself - that is for the sections above. The purpose is to show the planned activities and docuemnt the current ordering and structure to these, particularly upcoming items.

0. DONE (02:15): `fcn_CarMesh3D_userInfo`, with `fcn_CarMesh3D_fingerprint` and `fcn_CarMesh3D_reviewInput`.
1. DONE (02:27): the host, with the safeguards (section 3), the records (section 4) and the settings (section 6), tested with four test assessments (one that draws two questions, one that fails on purpose, one that is slow, one that skips).
2. DONE (02:33): the six first-round assessment functions, in list order, each with its own test script (rule G33), a stand-alone run and describe mode; `fcn_CarMesh3D_assessAxes` for their pictures.
3. DONE (02:45): the window (section 7); the test that this file's table matches the code (Q52 (A), in `script_test_fcn_CarMesh3D_reviewChecks`); then the T-list for Sean (T60 to T68: passed 12:16, with changes asked, in the change log).
4. DONE (12:22): the two-row top bar, the Summary and back (Sean, 12:16), with `fcn_CarMesh3D_icons`.
5. DONE (12:55): the status line without the drawing time (Q61 (A)).
6. DONE (17:20): a second line under each question, smaller and not bold, with guidance (Sean, T62), from each function's describe mode as a new field, `Detail` (section 3); the tests check every listed assessment has one, and that the host shows it.
7. DONE (17:26): a simple legend of the label colors under the label pictures (Sean, T62): only the colors the mesh uses, parts then lamp types (section 7).
8. DONE (17:30): the headlights' beams on a dark ground plane in front of the vehicle (plotVehicle's light pools, `FlagLightEffects=true`), seen from above the front left and zoomed so the vehicle stays large (Sean, T63). The body is still lit as by day (the scene lights): T76 asks whether it should be darker.
9. DONE (23:22): the second line shorter, with no function names, and a "Show the commands" link beside it that prints, in the Command Window, the commands to open the vehicle in the viewer and the painter (Sean, T74: "a mouse-click detection that triggers an fprintf command"; T77 (A)).
10. DONE (2026-11-26 05:55, Claude; `fcn_CarMesh3D_assessAxes`' Rows= and RowLabels=): the Headlights and Brake lights pictures as a 2 x 3 grid: the far views on top (side label "Far view"), close-ups of the left (driver's side) lamp below ("Close-up of left headlight", "Close-up of left tail light") (Sean, T74 note, moved to T76 (B)).
11. DONE (2026-11-26 06:00): `Start=` (Q70 (A)): open at a given question, such as `Start='labels'`, so test commands go straight to what is judged.
12. DONE (2026-11-26 06:00; shown windows only, so tests' hidden windows are unaffected): one V&V window per vehicle (Q71 (A)): a second call on the same vehicle brings the open window to the front.
13. Then: work real vehicles through the first round, starting with the Fit (Sean: at or near pass; the Transit Connect has many errors); add the later assessments (section 5, orders 8 to 16) one at a time.
14. DONE (2026-11-26, Claude; Sean 03:12 and 04:41, Q90 (A), Q91 (A)): a **Normals** assessment in the first round: the mesh with each face colored by its unit normal, RGB = (n+1)/2, in views that turn and zoom with the CAD mouse (`fcn_CarMesh3D_addCadMouse`). A face pointing the wrong way shows in the opposite color to its neighbors (Sean, 02:35: "the errors stand out dramatically. I could spot them instantly"). Its row is in section 5's table (order 4, after Patchy labels) and in `fcn_CarMesh3D_reviewChecks`. Accept / Reject, with a score from 0 to 10 (the interface's new `Score` field, recorded in `vvAnswers.Score`); "Compare with examples" and "Save as an example" (the interface's new `Examples` field), kept in the repo in `Data/VandV/Examples/normals/` as a PNG and a one-line text file.
15. Someday (Sean, 03:12 and 03:14): **pre-flight unit-normal tests as another panel**, from the 2 x 2 window Sean used to choose `fcn_CarMesh3D_orientFaces`' rules (section 9). Its code is kept in the repo as starter code: `Documents/SomedayCode/starter_CarMesh3D_normalsSlider.m`.



## Tests for Sean

*Kept at the bottom, before "Open questions" and the "Change log", so it is easy to jump to; named, not numbered, so it never moves.*

Key:
- **Only what a person must judge** (Sean, 2026-11-25 13:15 and 14:24, for every file): look, feel, clarity, and other human-only checks. Anything of the form "does X show Y" or "does pressing X do Y" is a code test instead; this section names those code tests, so it is clear what is covered.
- **TNN.** A test step. **Every step carries its own exact MATLAB commands, right under it** (G34; Sean, 2026-11-25 14:24), beginning with `close all force; clear functions; clc`, even when they repeat the step before: never "same window as above". T-numbers are unique across every file (G35); use them little outside this section.
- (Sean's results are in parentheses under the step.)
- Expected outcomes are labeled (A), (B), (both) and so on, as answers are, so a review can be quick: "confirm (A)". A bug is marked **BUG**; an uncertain or unexpected outcome **???**.
- Each step is separated by a blank line, so the steps are easy to tell apart in a plain-text editor.
- A finished round (every step with a result) moves to the change log, with the results.

*Only what a person must judge is here: look, feel, and clarity (Sean, 2026-11-25 13:15). What the window does is tested by code, in `script_test_fcn_CarMesh3D_reviewVehicle.m`, which presses the real buttons:*
- *the two rows: the vehicle picture buttons greyed, with greyed pictures, when there is no vehicle that way; no words on them; "Vehicle 1 of N";*
- *Previous and Next through every question in order, Next after the last to the Summary, Previous from the Summary to the last question;*
- *the Summary button there and back, reading Questions on the Summary, back to the first question not answered;*
- *a batch: + and - between vehicles, greyed at each end, each vehicle's answers kept;*
- *the status line: who answered and when, and no drawing time (Q61 (A)).*

*Pressing the real buttons found a bug the hooks had hidden: Previous and Next went only to questions 1 and 2 (their callbacks kept the page they were made with). This is what Sean met in T65 ("I cannot figure out how to advance"). Fixed 2026-11-25 13:21.*

- *the legend: only the label colors the mesh uses, each square in its color (`script_test_fcn_CarMesh3D_plotLabels.m`, `script_test_fcn_CarMesh3D_assessAxes.m`);*
- *the second line: the assessment's Detail shown under the question, and none for an assessment without one; every listed assessment has a Detail (`script_test_fcn_CarMesh3D_reviewChecks.m`);*
- *"Show the commands": the real link pressed, and the viewer and painter commands printed.*

T83. Normals (plan item 14): turn the Fit with the mouse in both views. Do faces pointing the wrong way stand out as they did in your 2 x 2 window? Then answer, give a score, and "Save as an example": does the score and the examples list feel right? (Your example is saved into the repo's Data/VandV/Examples/normals/.)
`close all; clear functions; clc; fcn_CarMesh3D_reviewVehicle('2009_Honda_Fit_Sport', Start='normals');`

T84. Headlights and Brake lights (plan item 10): far views on top, close-ups of the left lamp below. Are the close-ups close enough, and on the right lamp?
`close all; clear functions; clc; fcn_CarMesh3D_reviewVehicle('2009_Honda_Fit_Sport', Start='headlights');`

T85. One window per vehicle (plan item 12): with the window from T84 open, run the command again. Does the open window come to the front, at Brake lights?
`fcn_CarMesh3D_reviewVehicle('2009_Honda_Fit_Sport', Start='brakeLights');`

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

*Always last.*

- 2026-11-24 22:54 to 23:23 (Sean and Claude, in the chat): the V&V GUI becomes a host for a list of assessment functions (Sean, 23:07 and 23:18); Q49 (A) drawing into a panel the host gives, with a try/catch and timing (Sean, 23:07); Q50 (A) Yes / No with an optional comment (Sean, 23:18); "Stop at the first No?" and "After an answer, go to" (Sean, 23:18), with "Next always" (Sean, 23:21); removed: Differences (22:54), the animation checks (22:59), the hosted painter (22:54); stale answers by mesh fingerprint (Claude, 23:18).
- 2026-11-24 23:25 (Claude): this file started; `Documentation_CarMesh3D_GUIdesign_reviewVehicle.md` now points here.
- 2026-11-24 23:30 (Claude, Sean 23:28): the fingerprint is a hash of the data each assessment drew (section 4), not file dates.
- 2026-11-25 00:41 to 01:25 (Sean, in this file): the "(Sean's mark:)" column filled, every assessment optional but the Summary; new and reworded questions (Overall, Labels, Label Directions, taillights, blinkers, fog lights, photos, two 2D outline questions).
- 2026-11-25 00:53 to 01:36 (Sean and Claude, in the chat): every human assessment optional, a required check being a code check (Sean, 00:53); approvals record what they rested on, no override (Claude, 00:53, proposed); the closed-outline check moved to the build (Sean, 00:55); Claude as a screener (Sean, 01:00, Later); Overall worded "Does this mesh pass a first glance?" (Sean, 01:13); Q52 (A) code is the source, a test keeps this table in step (Sean, 01:15); describe mode (Sean, 01:22); the first round kept short (Sean, 01:22, 01:25); Taillights became Brake lights (Sean, 01:28); Q53 (A) a No always means a problem (Sean, 01:32); Q54 Label Directions is the wrong-way-faces check, renamed Patchy labels (Sean, 01:32, 01:34); Q55 (A) Brake lights in the first round (Sean, 01:36).
- 2026-11-25 01:40 (Claude): the table tidied (renumbered; a Round column; the two flipped questions reworded; the copy-paste "Taillights" titles fixed), and sections 2, 3, 5, 10 and 11 brought up to date with the above.
- 2026-11-25 01:53 (Sean, in this file): Q47 and Q48 answered; a Someday note on merged edits and where vehicle data lives.
- 2026-11-25 01:58 (Claude): Sean's answers moved into section 9 verbatim, with Claude's reading of Q48 (the V&V GUI plays a list of vehicles its caller gives, and never chooses one); section 1's audience from Q47; the user-identity helper added to the plan; Sean's note moved to section 10 with Claude's view; Q56 asked.
- 2026-11-25 02:01 to 02:08 (Sean and Claude, in the chat): Q48 settled (the V&V GUI plays a list only when its caller passes one); Q56 (A): the rule on where vehicle data lives adopted as G40, with an example of its part 3 added for later reading.
- 2026-11-25 02:15 to 02:50 (Claude, Sean's "Let's build V&V!", 02:10): built (section 11); the swap made in the repo; this file brought up to date with the code (G39): the interface in section 3, the record in section 4, the settings in section 6, the window in section 7, the old code in section 8, Q57 and Q58 in section 9, the timeouts moved to section 10. The wording of each question is Sean's, from section 5's table.
- 2026-11-25 03:02 to 03:15 (Claude): the window fixes after the full test run (a question with nothing to ask is passed over; times in the format the browser reads; no dialog from a hidden window); T60 to T68 written for Sean.
- 2026-11-25 12:16 (Sean, in this file): **T60 to T68 reviewed** (round closed here). T60 (works). T61 (works; "do not think tooltip should include time": the status line's drawing time, removed by Q61 (A)). T62 (works; asked: a smaller second line of guidance under each question, and a label legend in the figures: plan items 6 and 7). T63 (asked: headlight cones on a ground plane, plan item 8; "No" on Headlights went to the Summary, as set). T64 and T65 (**BUG**: "The Previous and Next buttons are confusing ... My first take was that this meant 'Previous review item' ... I cannot figure out how to advance to the summary menu, the next question, or previous question ... Had to exit GUI to get back to queries." Fixed 12:22: section 7). T66, T67, T68 (works). Also: the bottom sections laid out as tests, open questions and change log; the Plan's purpose stated.
- 2026-11-25 12:16 (Sean): **Q47** (who reviews: Sean, PhD engineers on his team, 2 undergraduate seniors, and possibly a class of about 100; asked by Claude in design; answered 01:53) moved into section 1 and `fcn_CarMesh3D_userInfo`. **Q48** (going from one vehicle to the next; asked by Claude in design; answered 01:53, settled 02:01: the V&V GUI plays a list only when its caller passes one) moved into section 2, "Batches". **Q56** (a rule on where vehicle data lives; asked 01:58 in design; answered (A) 02:08) is rule G40 in the rules file, with its example in section 9. **Q57 (A)** (asked 02:10 while building; the name stays `fcn_CarMesh3D_reviewVehicle`; Sean: "Agree") in section 8. **Q58 (A)** (asked 02:10 while building; Realism compares with the body style's approved exemplar; Sean: agree, and an exemplar now has three purposes) in section 5.
- 2026-11-25 12:22 (Claude, Sean's "QUEUE: do the navigational button fixes", 12:17): the two-row top bar and the Summary button (section 7); `fcn_CarMesh3D_icons`; tests pass.
- 2026-11-25 12:42 (Sean): **Q60 (A)** (asked by Claude in the chat after Sean's layout suggestion: named bottom sections, numbered middle sections cited by number and fixed when they move, and a template file) and **Q61 (A)** (asked by Claude in the chat, from T61: the drawing time out of the status line, kept in the record).
- 2026-11-25 12:45 to 12:55 (Claude, Q60 (A)): this file laid out by `Documentation_CarMesh3D_template.md` (rule G42): the bottom sections named "Tests for Sean", "Open questions", "Change log"; the answered questions moved into the sections above (Q47 to section 1, Q48 to section 2, Q57 to section 8, Q58 to section 5; Q56 is rule G40); section citations fixed after Sean's removal of the old section 9 (the old 10, Later, is 9; the old 11, Plan, is 10). Q61 (A) built (section 7).
- 2026-11-25 13:21 (Claude, Sean 13:15: "Only leave tests for me regarding look/feel ... or other human-specific items"): T70 to T72 (the Summary and back, a batch, the status line) became code tests, and T69 asks only whether the top bar is clear. The code tests press the real buttons, and found that Previous and Next went only to questions 1 and 2 (the cause of Sean's T65); fixed.
- 2026-11-25 14:24 (Sean, in this file): **T69 (A)**: the two-row top bar is clear at a glance. Round closed.
- 2026-11-25 17:20 (Claude, while Sean was away; Q69 (A)): plan item 6 built: the second line of guidance (`Detail`) in each first-round assessment and in the host; T74 asks Sean to judge it.
- 2026-11-25 17:26 (Claude, while Sean was away): plan item 7 built: the label-color legend (first tried as HTML in a label, which draws no color squares; now small bordered panels); T75 asks Sean to judge it.
- 2026-11-25 17:30 (Claude, while Sean was away): plan item 8 built: the headlight beams on a dark ground (first try: 9 m of ground made the vehicle too small to judge; now 5 m, zoomed); the Labels and Patchy labels tests updated for the legend; T76 asks Sean to judge it.
- 2026-11-25 23:09 to 23:27, Sean, in the answer queue (first real use of it on V&V items; development):
  - **T74 ???**: replace the function names in the small print with a click that prints the commands, for the current vehicle, in the Command Window. Built 23:22 (plan item 9). Also asked (moved to T76): Headlights and Brake lights as 2 x 3, with close-ups of the left lamp below; and debug with the Fit. **Mistake (Claude):** T74 to T76's commands used `fcn_CarMesh3D_demoVehicle`, which gives Sean's chosen demo vehicle (the Transit Connect, with many mesh errors), not the Fit, against rule G34 (name the vehicle by its ID). Commands now name `2009_Honda_Fit_Sport`.
  - **T75 (A)**: the legend is right.
  - **T76 (B)**: see T74's note (the 2 x 3 grid: plan item 10).
  - **T77 (A)**: the shorter line and "Show the commands": "Works great, very nice feature. Fit opened up this time."
- 2026-11-26 03:15 (Claude; Sean 03:12 and 03:14): plan item 14, a Normals assessment (the mesh colored by unit normal, with the CAD mouse), and plan item 15 and a section 9 Someday item, pre-flight unit-normal tests as a panel, with its starter code kept in `Documents/SomedayCode`. Context: the white slivers at the Fit's driver door handle were faces pointing into the car (Q86 (A)); `fcn_CarMesh3D_orientFaces` turns such faces, with rules Sean chose by eye.
- 2026-11-26 05:50, Claude: plan item 14 built (Sean, 03:12 and 04:41; Q90 (A), Q91 (A)): `fcn_CarMesh3D_assess_normals`, order 4 in the first round (later rows renumbered); two new optional fields in the assessment interface (section 3): `Score` (a score asked with the answer, recorded in `vvAnswers.Score`) and `Examples` (the host's "Compare with examples" and "Save as an example"). The score and the examples are the host's, so the assessment function still only draws and returns data (rules 2 and 3).
- 2026-11-26 06:10, Claude: plan items 10, 11 and 12 built (the lamp pictures in two rows with close-ups of the left lamp; Start=; one shown window per vehicle). Headlights' question now says "these pictures" (there are six). T83 to T85 for Sean.
