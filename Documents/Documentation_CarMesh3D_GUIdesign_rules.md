# GUI design rules for every CarMesh3D window

*The rules every CarMesh3D GUI follows, in one place. Each GUI's own design file keeps only that one GUI's layout and decisions, and its exceptions to these rules. Started 2026-11-24 16:25 by Claude, at Sean's request (16:20: "let's isolate GUI rulesets and guides that are global, versus design layout issues for this one GUI ... Let's make this sharing explicit"). Gathered from the painter's general rules (its design file, section 2, rules 1 to 26), the viewer's and browser's rule sections, the reviewer's file, the shared-panels file, and the project notes `claude/gui_design_notes.md` (which now point here). Each rule keeps Sean's words and date where it came from him. Rules are cited by number: G1, G2 ... Edit freely; Claude builds from it.*



## Design principles to be followed by UIs in this project
The following design principles guide the creation of the rules that follow. They are motivated by Claude Opus 5.5 collaborative development of GUIs to develop meshes for visualization and simulations. Specifically, they arose when developing the V&V GUI, whose purpose is to answer one question: is the mesh right?

There are several questions that arise from this goal:
1. What does "right"  mean, numerically, in terms of metrics, thresholds, and downstream impacts that are important and significant?  
2. Are the metrics of being "right" something we know now, or that we can know right now? 
3. Are the metrics that are important best assessed by a human, a computer, or a hybrid of the two?

In light of these questions, the purpose of the GUI is to present the fastest and most streamlined way to assess something by a human, a computer, or a hybrid of the two - these are three branches, with the last one being the most difficult. Thus, an implication for GUI design is to separate tasks into one of these three paths as quickly as possible and then move toward decisions as fast as possible. For hybrid problem solving where human judgement is ultimately the goal, the GUI should be hosting codes that make the user analysis as fast as possible. But if the ultimate goal is something involving the computer's decisions, then user does analysis that makes the computers computation as fast as possible. Examples may help:
* Asking a human user to visually inspect large numbers of mesh holes to estimate the impact of a particular hole on a rendering or animation occurring several steps down the processing pipe - this is exceptionally hard for the human. It's diverting what should be a code-based assessment into a human base assessment.
* Asking a computer to assess realism of a mesh, correctness of orientations, what object a mesh likely belongs to based on a partial or noisy sample - this is exceptionally hard for the computer. It's diverting what should be a human-based assessment into a code-based assessment.

We want to seek synergy of human-computer interaction. For example, a human user can literally glance at a mesh and in fractions of a second assess the x-axis orientation, whether the mesh is more realistic than another, and the representational meaning implied by the mesh. This is something that would be nearly impossible for a computer to do today, across all the vehicles and objects available, even with very powerful and lengthy computation. Conversely, a computer can almost instantly count the number of vertices that deviate a certain threshold from a bounding box. Yet, this task is nearly impossible for a human to do, even given a lifetime of effort. Consideration of this synergy guides one to the following principles:

### GUI Principles
*(Numbered P1 to P6 so rules and design files can cite them, as in "G9, per P4".)*
* **P1.** Each GUI should have a UI that is similar to the others
  - Inconsistency causes user confusion
  - Confusion leads to error
  - Repetition leads to reuse, and thus less complexity and fewer tests
* **P2.** Each GUI or panel should have one and only one goal
  - A GUI or panel's operations should not repeat the operations of another GUI or panel
  - Simplicity is always prioritized over complexity, if functional outcomes both the same
* **P3.** A GUI's goal clearly needs to land fully on producing exactness or relativism, but not both
  - Example of exactness: 
    * the browse GUI, where user shows list of vehicles to select exactly one identifier to use in computations
    * the paint GUI, where user is asked to select exact vertices to define labels used in computation later
  - Example of relativism: 
    * the view GUI, where the user is assessing relative agreement between photos and meshes under different orientations, lighting conditions, etc.
    * the review GUI, where the user is asked to rank the mesh against others and against an undefinable pass/fail metric
* **P4.** Each GUI decision request of a user should take no more than a few seconds
  - All interactions should be intuitive
  - It should always be the user's decision, not the GUI's requirement, to stay longer than a few seconds
  - Required navigation paths through the GUI structure should be short, no more than a few clicks, for all main features
* **P5.** The GUI should integrate the strength of computers and humans working together
  - Computers count well; computers should do GUI tasks involving computation, error-free detail, retrieval, precision, and repetition
  - Humans perceive well; humans should do GUI tasks involving approximation and incompleteness, nuance and discernment, valuation, intuition, and aesthetics
  - For tasks that do not fall clearly into one or the other, ask: is the final answer being sought relative, or exact? 
    * Exact answers should have interfaces where humans help the computer
    * Relative answers should have interfaces where computers help the human
* **P6.** Keep the three layers apart: **position** (faces), **meaning** (labels: what a part *is*), and **function** (what signals make it act) (Sean, 2026-11-26 00:43; README, "Position, meaning, and function")
  - Labels connect position to meaning; functions connect meaning to signals. Each map is edited in its own place: labels in the painter, functions in the lamp-to-function matrix
  - A window shows one layer, or one map, at a time, and says which: a panel that mixes them (a list of labels named for what switches them, such as "low beams") teaches the wrong model and leads to errors in use and in code
  - A label never names a function; a function never moves a label
  - Time is not part of the mesh: when signals switch, flash or follow a sequence is decided by what drives them (AnimateCar3D, a user's loop), never stored with the vehicle; hazards flashing changes no position, label or function (Sean, 2026-11-26 01:35)
  - "Lamp" means the whole device that lights (its bulb or LEDs, reflector and cover); a "bulb" is only its light source, not modeled (Sean, 2026-11-26 00:57 and 01:47; Q83 (A)). Labels name lamps: "headlamp", "fog lamp", never "low beams"

## How the design files fit together

| File | What it holds |
|---|---|
| **This file** (`Documentation_CarMesh3D_GUIdesign_rules.md`) | The rules for every window (G1 ...) |
| `Documentation_CarMesh3D_GUIdesign_sharedPanels.md` | The panels every GUI shares, built once by `fcn_CarMesh3D_makeDisplayPanels`: Overall Display, Labels To Display, Lamps To Display, Shared GUI settings |
| `Documentation_CarMesh3D_GUIdesign_viewLabels.md` | The label viewer: its own layout and decisions (V1 ...) |
| `Documentation_CarMesh3D_GUIdesign_paintLabels.md` | The label painter: its own layout and decisions (Modify Labels, the top bar) |
| `Documentation_CarMesh3D_GUIdesign_reviewVehicle.md` | The Model Reviewer (the V&V GUI) |
| `Documentation_CarMesh3D_GUIdesign_browseLibrary.md` | The library browser: a list window (B1 ...) |

Each GUI file's section 2 says: "Follows `Documentation_CarMesh3D_GUIdesign_rules.md`", then lists only its own rules and its exceptions (with the reason).

---

## A. Layout

- **G1. The pancake (☰) menu, whenever possible** (Sean, 2026-11-23 and 2026-11-24 16:17: "Add pancake design, when possible, to the ruleset"):
  - The main view (the model, the photo, the list) takes most of the window.
  - The panels are opened from a **☰ Menu** button at the top left.
  - **At most two panels are open at once,** stacked against the left side, each scrolling on its own (Sean, 2026-11-24 16:12). A panel opened again closes; opening a third replaces the lower one. (Until 2026-11-24 one panel at a time.)
  - **When GUIs are nested, only the top window owns the ☰ Menu,** its panels and the settings; a child GUI hands its panels to it (Q45 (A), Sean 2026-11-24 16:25).
  - An exception (the library browser's toolbar above its table) is noted in that GUI's file, with the reason.
- **G2. Seek sparse displays** (Sean, 2026-11-24 16:18: "Seek more sparse displays... A purpose in keeping each GUI visually 'empty' is that it facilitates having all of them open side-by-side."):
  - The main view and little else on screen; controls live in the ☰ panels and stay closed until wanted.
  - Each GUI works in a small window, about a third of the screen or less; its tests check the layout at small sizes, and its design file names the smallest size it supports.
  - Fewer, quieter words: short labels, the explanation in the tooltip; hint and status lines one line long.
  - No repeated information: a fact is shown once in a window.
  - When adding a control, ask what can go: a new control goes into a panel unless it is used all the time.
- **G3. Mesh on the left, photos on the right** (Sean, 2026-11-23, painter rules 1 to 3): working options for the mesh are on the left, next to the mesh; working options for the photos are on the right, next to the photos; the spinner (the dial that picks the photo by viewing angle) stays between the two, near the top. (For windows with a model and photos.)
- **G4. Few buttons along the top** (Sean, painter rule 5): in normal use only the actions of the window, such as Undo, Save, Exit (the viewer: Exit only, since it changes nothing). Exit with unsaved changes asks whether to save. A top-bar button added later is agreed first (for example "Revert to a save...", 2026-11-24).
- **G5. The title bar is the standard one** (`fcn_CarMesh3D_addTitleBar`): the function's name, large; its file's last change as its version; and the vehicle's name when there is one (Sean, 2026-11-22 14:31 and 14:40).
- **G6. Panels 320 pixels wide;** a control that does not fit beside its name goes on its own line under it, never cut off (painter rule 21).
- **G7. Every panel scrolls,** and does not vanish or collapse when the window is made short (Sean, 2026-11-24 00:58 and 01:28). How: `'Scrollable','on'` on the `uigridlayout` holding the controls, with fixed or 'fit' row heights (see `claude/how_we_work.md`).
- **G8. The colors of the bands say the kind of work** (painter rule 16): viewing panels pale blue `[0.93 0.95 1]`; editing (Modify Labels) pale yellow `[1 0.96 0.85]`; settings light gray `[0.94 0.94 0.94]`.

## B. Controls and words

- **G9. On/off is a radio-button pair, Off first** (Sean, painter rule 6; rule 10: a MATLAB radio button cannot be clicked off once on). An exception is stated in the GUI's file (the browser's Select check box, B6).
- **G10. Buttons are only for actions** that happen once when pressed (Undo, Save, Apply, Reset view, Browse...); anything that stays on or off, or picks one of several, is a radio button (painter rule 11).
- **G11. A radio-button question ends with "?"** ("Turn model with photo?", "Show mesh boundaries?"), in every GUI (Sean, 2026-11-23 13:12; painter rule 22).
- **G12. Lists of choices in columns, with a header row** (painter rules 7 to 9): a label row is `(colored box) Name   option1 option2 ...`; a lamp row is `(colored box) Name   Off On 3rdState ...` (Off first); the options line up in columns named once in a header row (`Colored?  Shown?`); the colored box is 14 x 14 pixels, thin dark border, in the color the label or lamp has on the model.
- **G13. Missing items are shown, not removed** (painter rule 13): a label or lamp with no faces keeps its row, its name in gray italics, with one note under the list; its controls still work.
- **G14. A row that sets several others** ("All labels") shows no button selected when the rows under it differ, through an unseen extra button (painter rule 20).
- **G15. Read-only information is text, never a text box;** text boxes are only for typing (Queensland CUE standard; NSW design system; painter rule 12; browser B3). Selectable text the user may want is given a Copy button.
- **G16. A text box with a default shows the default under it, in gray** ("(default is "hidden")"), so the user never has to remember it (Sean, 2026-11-23 13:12; painter rule 23).
- **G17. Every control has a tooltip** that says what it does in a sentence (painter rule 14).
- **G18. The primary action is set apart:** bold, at the end of its row ("Done: close and return", "Save").
- **G19. Keyboard:** Ctrl+Z is Undo and Ctrl+S is Save, as the top buttons; Esc clears a selection (painter rule 19; 2026-11-24).
- **G41. A goal, not a requirement: pictures before words on buttons** (Sean, 2026-11-25 12:16: "For the GUIs, I'd like to start transitioning buttons with text to buttons with very simple images (icons). The reason: many of the students have English as 2nd language, so GUIs as they are now may be difficult to understand."). Buttons move over time from text to very simple icons; an inactive button shows a greyed version of its icon (Sean's example: a small vehicle picture with a + on it for the next vehicle, a - for the previous one). *Claude's proposals for how, not yet agreed:* while a button moves over, it shows its icon with one short word, and the icon alone once its meaning is settled; the tooltip (G17) always keeps the full words; the same action has the same icon in every GUI (P1), and the icons come from one function (G27), drawn in code so no image files have to be kept in step.

## C. Behavior

- **G20. Every input argument is shown in the GUI in some way:** what a call can set, the window can show or set too (Sean, 2026-11-23 18:01, Q20 18:02; painter rule 25).
- **G21. Anything that can take more than 2 or 3 seconds shows a progress bar** (`uiprogressdlg`; indeterminate when the length is not known), and the window says when it is done or what went wrong; it never just stops responding. An error in a callback is shown in the window, not only in the command window (Sean, 2026-11-23 22:15; painter rule 26).
- **G22. Settings are the user's MATLAB preferences, in the one group `CarMesh3D`,** shared by every GUI and every MATLAB on the computer (painter rule 17). They are set in the shared **Shared GUI settings** panel, and every setting can be put back ("Reset to defaults", per section and for all; Sean, 2026-11-23 13:12, painter rule 24). A settings change applies to windows opened afterward (Q46 (A), Sean 2026-11-24 16:25). A window that must open the same way every time keeps no settings (the browser, B8).
- **G23. A setting is a tool's behavior or look, nothing else.** Anything about a vehicle or its checks (dimension tolerances, which checks a vehicle needs) goes in the vehicle's files or the V&V rules (2026-11-24, shared-panels file).
- **G24. A window's timer stops itself** when its window is gone, and closing a window is fast (under a second); tests check that no timer is left.

## D. Structure

- **G25. GUIs form a tree** (Sean, 2026-11-24 01:28: "follow a clean tree paradigm where entry in/out of a branch is mediated by the trunk, not via other branches"): only the trunk (the demo menu) opens tools; a tool may hold child tools inside its own window, data going down as inputs and results coming back through callbacks; a tool never opens a sibling and never builds a hidden copy of another GUI to compute something; shared work lives in a plain function with no window.
- **G26. A panel used by more than one GUI is built once, by the shared helper** (`fcn_CarMesh3D_makeDisplayPanels`), never copied into a GUI. A part a GUI does not use is **greyed out, never hidden**, with a tooltip naming the GUI that uses it, so every GUI shows the same panel and it is tested once (Sean, 2026-11-24 16:09 and 16:12). See the shared-panels file.
- **G27. One list in one place:** a list used by a panel and by a GUI (the review checks, the label groups, the lamp types) lives in one function with an "EDIT HERE" block, and both build from it.
- **G39. Code is the source; documents describe it** (Q52 (A), Sean 2026-11-25 01:15: "almost as a rule"): a list that code uses lives in code (one EDIT HERE block, G27). Documents describe it and never feed it, so a formatting slip in a document cannot break a GUI. Where a document repeats the list (a design file's table), a test checks that the two match. Wording a GUI shows comes from the function that owns it (as the V&V assessments' describe mode does), not from a copy kept elsewhere.
- **G40. Data about a vehicle lives with the vehicle; lists of vehicles are found, not stored** (Q56 (A), Sean 2026-11-25 02:08: "a rough tradeoff between different types of failure"; from Sean's note of 01:53: "variables about a vehicle are stored with the vehicle, not kept separate. And variables about vehicle data should not assume the data is static from run-to-run"). (1) Data about one vehicle is kept in its own folder. (2) A list of vehicles is never stored as the truth: it is found by scanning the folders when needed, or, if kept for speed, it carries a fingerprint of the folder listing and is rebuilt when that differs. (3) Anything kept outside a vehicle that names vehicles (`Data/bodyStyles.csv`, the demo-vehicle preference) is checked when read, and says plainly which named vehicle is missing. Why: with many people adding and merging vehicles, a stored copy goes stale silently, and the failure shows up far from its cause. An example is in the V&V design file, section 9.

## E. List windows (the browser, and any later list)

- **G28. Controls in the order they are used, left to right:** group, then sort within the groups, then filter, each in its own titled, numbered box (SAP Fiori; Sean, 2026-11-22 23:33; browser B1).
- **G29. Filters are applied with a button** (batch filtering), not while typing; the applied filters are shown next to the count; "Clear filters" shows all again (NN/g, UK DWP, Maersk; browser B2).
- **G30. A filter never empties the list:** one that matches nothing is refused, with a message (browser B2).
- **G31. Filters sit above or to the left of the results** (UK DWP; Baymard).

## F. Tests and reviews

- **G32. Every control has a unique Tag,** and every GUI has hooks (`State`, `SetState`, `Press`, `Key`, `CheckLayout`, and the mouse at a face or point) so scripts drive it through its real callbacks (Q39, 2026-11-24). Automated tests cover every value of every control, random walks with the window's rules checked after every step, and the layout at several sizes, the smallest first (G2).
- **G33. A test for a function lives in that function's documentation only** (Sean, 2026-11-24 14:47: "Rare exceptions to this may be allowed, for example a common helper function that is not otherwise exposed to the user"). A behavior two GUIs share gets a T-step in each one's file; the shared panels' steps are in the shared-panels file.
- **G34. Every test step for Sean carries its own exact MATLAB commands, right under it** (Sean, 2026-11-24 14:40 and 14:43; 2026-11-25 14:24: "keep the commands next to the T items ... a rule across all Documentation_ MD files"), beginning with `close all; clear functions; clc` (Q74 (A), 2026-11-26: plain `close all` leaves the answer queue open), naming the vehicle by its ID (not the demo vehicle, which a user may change), and using a demo copy (`fcn_CarMesh3D_makeDemoCopy`) for anything that saves. **The commands open the window at the thing to judge** (Sean, 2026-11-25 23:16, "the code that goes straight to the issue in question"; Q70 (A)): through the GUI's `Start=` option, so the step's words say only what to look at, never how to get there. **The commands are on one line**, separated by semicolons (Sean, 2026-11-26 02:23: "easier to up-arrow and rerun quickly"), in the chat as in the files. A step never relies on another step's commands ("same window"), so any step can be run alone. **Steps for Sean are only what a person must judge** (look, feel, clarity, human-only checks; Sean, 2026-11-25 13:15 and 14:24); what a window does is tested in code, and the design file names those tests.
- **G35. T-step numbers are unique** across every design file (Sean, 2026-11-24 03:43). Sean's results go in parentheses under each step, marked as in the "Tests for Sean" key (an expected outcome as a letter, **BUG**, **???**; Sean, 2026-11-25 12:16); a finished round moves to the change log.
- **G36. GUIs are tested on a purpose-made test vehicle** with every feature (`2026_CarMesh3D_Sample_GUITestVehicle`), as well as on real ones (Sean, 2026-11-23 13:12).
- **G37. Tests never change a real vehicle's files or a user's setting:** they work on demo copies, and save each preference they touch and put back the value they found; no such test runs while Sean is testing a GUI (2026-11-24 02:06 and 14:36).
- **G38. The design files are the record** (Sean, 2026-11-24 01:40): questions (S2C / C2S, numbered by direction; closed ones moved to the change log), test steps and results, decisions. Claude writes to a design file only after Sean says he is done with it.
- **G42. Every design file has the same layout** (Sean, 2026-11-25 12:16 and 12:42; Q60 (A)): `Documentation_CarMesh3D_template.md`. At the top, "Review now (for Sean)"; in the middle, numbered sections (cited by number; when one is added, removed or moved, every citation of the numbers after it is fixed in the same edit, in every file and in code); at the bottom, always in this order and named, not numbered: "Tests for Sean", "Open questions", "Change log". An answered question's content moves into the sections above, and its summary into the change log.

## G. MATLAB notes (from building these windows)

- An anonymous function copies variables when it is made: a callback that must see current values is a nested function.
- A scrollable `uipanel` around a grid does not scroll; make the `uigridlayout` scrollable.
- A visible app window covered by another can stop drawing for about 60 s; keep pictures on screen few.
- In `uilabel` HTML, `&nbsp;` can show as nothing, and a space between a closing tag and a colored span is dropped: put the space inside the bold.
- Anonymous callbacks cannot name a control made later in the code: take the value from `source.Value`.
- `exportapp(figureHandle, file)` saves a uifigure as a picture; uifigures are hidden from `gcf`.
- The 3D axes' CurrentPoint is off by hundreds of pixels in nested layouts: build the mouse's line from the window's pointer and the camera.

## Where the old rule numbers went

| Old rule | Now |
|---|---|
| Painter 1, 2, 3 | G3 |
| Painter 4 (one panel at a time) | G1 (now up to two) |
| Painter 5 | G4 |
| Painter 6, 10 | G9 |
| Painter 7, 8, 9 | G12 |
| Painter 11 | G10 |
| Painter 12 | G15 |
| Painter 13 | G13 |
| Painter 14 | G17 |
| Painter 15 | G5 |
| Painter 16 | G8 |
| Painter 17 | G22 |
| Painter 18 | G7 |
| Painter 19 | G19 |
| Painter 20 | G14 |
| Painter 21 | G6 |
| Painter 22 | G11 |
| Painter 23 | G16 |
| Painter 24 | G22 |
| Painter 25 | G20 |
| Painter 26 | G21 |
| GUI design notes 1 to 4 (lists) | G28 to G31 |
| GUI design notes 5, 6, 7 | G15, G5, G18 |
| GUI design notes 8 to 13 (2026-11-24) | G1, G2, G26, G7, G11, G25 |
| Browser B3, B4 | G15, G5 (B1, B2 also G28 to G30; the browser's other rules stay in its file) |

## Tests for Sean

*(This file describes rules, not a window: its rules are tested in each GUI's own file, G33.)* The key is in `Documentation_CarMesh3D_template.md`.

(none)

## Open questions

The key is in `Documentation_CarMesh3D_template.md`.

### Question list

(none)

## Change log

*Always last.*

- 2026-11-24 16:25 (Claude, Sean's request 16:20 to 16:23): this file started; the global rules gathered and numbered G1 to G38; the four GUI files' rule sections trimmed to point here; the project notes `claude/gui_design_notes.md` point here. Two rules changed in the gathering, both from Sean's decisions of the day: up to two panels open at once (G1, was one), and settings in the shared panel (G22). Q45 (G1, nested windows) and Q46 (G22, when a change applies) were answered (A) by Sean at 16:25.
- 2026-11-24 23:00 (Claude, Sean 23:00 "Please edit"): Sean's design principles (added 22:54) numbered P1 to P5; typos fixed (significant, implication, perceive, vertices, GUI's).
- 2026-11-25 01:40 (Claude): G39 added (Q52 (A), Sean 01:15).
- 2026-11-25 02:10 (Claude): G40 added (Q56 (A), Sean 02:08).
- 2026-11-25 12:18 (Claude): G41 added as a goal (Sean, 12:16), with Claude's proposals for how marked as not yet agreed.
- 2026-11-25 12:50 (Claude, Q60 (A), Sean 12:42): G42 added (every design file's layout, from `Documentation_CarMesh3D_template.md`); G35 takes Sean's test-result marks; the bottom sections added here; G40's example now cites the V&V file's section 9 (its sections were renumbered).
- 2026-11-25 14:25 (Claude, Sean 14:24): G34 covers every design file: commands with every test step, and Sean's steps only for what a person must judge; the template's key says the same.
- 2026-11-25 23:30 (Claude; Sean 23:16, Q70 (A)): G34: a step's commands open the window at what is judged (a `Start=` option on each GUI). Context: T74 to T76 told Sean to "go to" questions, and their commands opened the wrong vehicle (the demo preference, against G34's own "name the vehicle").
- 2026-11-26 00:44 (Claude; Sean 00:35 to 00:43): **P6**, the three layers (position, meaning, function), and the two maps between them (labels, functions), also at the top of the README. Context: the Fit's review found running lights made by the high-beam bulbs, a missed marker bulb, and high beams lighting several bulbs and their glass; all came from labels that named functions.
- 2026-11-26 00:55 (Claude; Sean 23:51, Q74 (A)): G34's commands begin with `close all; clear functions; clc` in place of `close all force; ...`: the answer queue hides itself from `close all`, so it stays open (Sean: "close all force ... closed my answer GUI"); checked that `clear functions` leaves an open queue working (23:59).
- 2026-11-26 02:24 (Claude; Sean 02:23): G34: a step's commands go on one line, separated by semicolons, so one up-arrow reruns them all.
