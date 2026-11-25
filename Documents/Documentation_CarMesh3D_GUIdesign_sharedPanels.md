# Design: the shared panels of the CarMesh3D GUIs (`fcn_CarMesh3D_makePanelMenu`, `fcn_CarMesh3D_makeDisplayPanels`, `fcn_CarMesh3D_makeSettingsPanel`)

*The panels every CarMesh3D GUI shows, built once by one helper so that the same interface, and the same tests, serve every window. Kept so the panels can be rebuilt from this file, and to keep the work from drifting. Edit it freely: it is the place to change the design, and Claude builds from it. Started 2026-11-24 16:15 by Claude at Sean's request ("put these ideas into a Documentation_ MD file, just to avoid scope drift, add clarity, track revisions/changelogs").*

**Status:** BUILT, READY FOR SEAN'S REVIEW (2026-11-24, Claude, while Sean was away 16:25 to about 21:00). Q45 and Q46 answered (A) by Sean at 16:25. Waiting on Sean: the T-list below; his marks on the required and optional checks (section 5); the calls Claude made, in section 9 ("Decisions to check").

---

## Review now (for Sean)

*T53 to T59 (section 10). Each starts with its MATLAB commands. The automated tests ran first (section 10).*

---

## 1. Why these panels are shared

Sean, 2026-11-24 16:09: "Nominally, all these GUIs live in the same repo, and we expect users to jump quickly from one to the other. So panel reusability, especially as helper functions to multiple GUIs, should be a top priority." And at 16:12: "...we could grey out areas irrelevant to a particular parent GUI. That way the exact same UI is used throughout, with very few test cases needed once it is working. Let's prioritize this."

The GUIs that use the shared panels:
- the label viewer, `fcn_CarMesh3D_viewLabels`: looking at a vehicle's labels;
- the label painter, `fcn_CarMesh3D_paintLabels`: changing them (it holds the viewer);
- the Model Reviewer (the V&V GUI), `fcn_CarMesh3D_reviewVehicle`: checking a vehicle (it holds the painter in its Labels check). It is the next GUI to rework.
- Later: the library browser, `fcn_CarMesh3D_browseLibrary` (section 7).

Today the viewer and the painter already share Overall Display, Labels To Display, Lamps To Display and the photo options, built by `fcn_CarMesh3D_makeDisplayPanels` (Q33 (A), 2026-11-24 02:41).

## 2. Rules

**Follows `Documentation_CarMesh3D_GUIdesign_rules.md`** (G1 to G38). The rules this design rests on most: G1 (the ☰ menu, two panels at once, the top window owns it), G2 (sparse displays: GUIs side by side), G22 and G23 (settings as preferences, and what is a setting), G26 (built once, greyed out never hidden), G27 (one list in one place), G33 (the shared panels' tests live with the helper: their T-steps here, their automated tests in `script_test_fcn_CarMesh3D_makeDisplayPanels.m`; each GUI's own test checks only what it greys out), G37 (tests restore preferences).

## 3. Two panels open at once

The ☰ Menu can open a **second panel**, stacked under the first, each scrolling on its own. Sean (16:12): "just showing 2 panels at once [is the] simplest and clearest option."

- The painter opens with **Labels To Display** (shared, plain background) on top and **Modify Labels** (the painter's own, yellow background) below: viewing and editing together, told apart by color, with no copy of a panel. (This replaces the earlier P2 item that put Labels To Display inside Modify Labels.)
- The viewer gets the same ability (for example Overall Display with Lamps To Display).
- Opening a third panel replaces the lower one; a panel opened again closes.
- Q45 (A), Sean 16:25: only the top window owns the menu when GUIs are nested.

## 4. Shared GUI settings

One panel, **Shared GUI settings**, identical in every GUI. Each GUI passes in the sections it uses; the others are greyed out (rule 2). Each section has its own "Reset to defaults" button, and the panel has one "Reset all to defaults" at the bottom.

| Section | Settings | Used by |
|---|---|---|
| **You** | Your initials (default `SBB`). Used for the reviewer's answers and the painter's change log ("Who"). *Built.* (The browser's Reviewer column and "the reviewer asks once if it is empty": not yet.) | reviewer, painter |
| **View** | The starting view (dial angle 60, looking down 20). *Built.* (Ground: stays in Overall Display, see section 9. The day and night background colors with the color picker: not yet.) | viewer, painter, reviewer |
| ~~**Photos**~~ | *Not a section (section 9):* Turn model with photo?, Turn photo with model? (new, built) and Photo size? stay in Overall Display, and are remembered from there. The photo folder is per vehicle (Browse... in Overall Display). | |
| **Demo vehicle** | The demo vehicle now (yours or the repo's); "Back to the repo's demo". (Choosing one stays in the browser.) *Built.* | all |
| **Editing** | "Timestamped copy at each save?" and "Folder for timestamped copies" (with Browse...). *Built.* Not yet: "At each Apply?", "Every 10 minutes?", the recovery file and its folder. Save as version and Revert to start are actions, not settings: they moved to the foot of Modify Labels ("Saving"). | painter, reviewer (it holds the painter) |
| **Review** | Section 5. *Built* (the check rows; not yet: the check family, "Go to the next item after an answer?", "Show checks already passed?"). | reviewer |

## 5. The Review section: required and optional checks

Sean (16:14): "we need to list as well which review panels are optional and required. This will let the user permanently shut off requested reviews for large numbers of models that they trust that they work on in sequence."

- **One row per review check.** Required checks show On, greyed (they cannot be turned off, but you see them). Optional checks have an Off/On row; Off is kept as a preference, for every vehicle, until turned back on.
- **One list in one place:** the checks, and which are required, in one function (for example `fcn_CarMesh3D_reviewChecks`, with an "EDIT HERE" block). The reviewer and this section both build from it.
- **The record stays honest:** a check turned off is written into the vehicle's review as "skipped (turned off in Shared GUI settings, by SBB)", not left blank. Skipped optional checks do not block approval; required ones must be answered. The reviewer shows a reminder line, such as "3 optional checks are off (Shared GUI settings)".
- Other Review settings: the check family (family 1 by default); "Go to the next item after an answer?"; "Show checks already passed?".

**The checks today** (in `fcn_CarMesh3D_reviewVehicle`, `fcn_INTERNAL_defineChecks`), with Claude's proposal for Sean to mark up:

As built in `fcn_CarMesh3D_reviewChecks` (its EDIT HERE block is the one place to change a mark). The five animation checks were missing from the first proposal (Claude's miss): listed now as optional.

| Check | Proposed | Built as | (Sean's mark:) |
|---|---|---|---|
| Orientation | required | required | |
| Dimensions | required | required | |
| Labels (with the painter) | required | required | |
| Differences (the comparison with the download) | optional | optional | |
| Lights, Body, Steering, Wheels, Drive (the animations) | (missed) | optional | |
| Detail levels | optional | optional | |
| 2D outline | optional | optional | |
| Interior objects (seats and steering wheel; a core mesh requirement since 2026-11-24) | required (to add) | listed, not built; greyed | |
| Photos (a set all around; a core mesh requirement) | required (to add) | listed, not built; greyed | |
| Summary (the decision) | required | required | |

## 6. Other shared-panel edits (from the painter's old P2)

- **Labels To Display in groups,** as in the painter's label list: main panels (body, glass, trim, wheel), interior objects (driver seat, passenger seat, steering wheel), lights, visibility (hidden).
- **Photo options:** "Turn photo with model?" (section 4); the Small photo size no longer cuts off the "Large" button; "?" on every radio question.

**Left to the painter alone (its P2b):** Modify Labels stays the painter's own panel. "Hide as": the hidden set's name asked once at Apply (default "hidden"), in place of the always-shown field and a setting for its default (to confirm with Sean).

## 7. Not now

- **The browser** keeps its own layout for now (it has no ☰ Menu; its demo buttons stay). Later: the same menu, with Shared GUI settings.
- **Window size and position remembered per GUI, and a text size:** easy to add as a section later; left out unless Sean wants them now.
- **Several GUIs open at once** (Sean, 16:16): a Someday item in the work queue; needs live settings (a later change to Q46), a guard against two windows editing one vehicle, and remembered window sizes and positions. Q45 (A) fits it: each open window is its own top window.

## 8. Open questions

- **Q45 (Claude to Sean, 16:12). Nested windows: who owns the menu?** The reviewer holds the painter, which holds the viewer.
  - (A) *Recommended.* Only the top window owns the ☰ Menu, its panels and the one Shared GUI settings panel; a child GUI hands its panels to the top window instead of building its own menu. A settings section is greyed only if nothing in that window uses it.
  - (B) Each GUI keeps its own menu, even when nested.
  - (Sean's answer:) **(A)**, 2026-11-24 16:25.
- **Q46 (Claude to Sean, 16:12). Do open windows follow a settings change at once?**
  - (A) *Recommended.* At the next open, with a note in the panel: "Changes apply to windows opened from now on." Live updates between open windows risk the clash seen in T39 (one window changing a setting under another).
  - (B) Open windows update at once.
  - (Sean's answer:) **(A)**, 2026-11-24 16:25.

## 9. What was built (2026-11-24, 16:25 to 21:00)

**The helpers** (each with its own test script, rule G33):
- `fcn_CarMesh3D_makePanelMenu`: the ☰ Menu and the column of panels (section 3). `AddPanel` and `RemovePanel` let a host hold a child GUI's panels (Q45 (A)).
- `fcn_CarMesh3D_makeSettingsPanel`: Shared GUI settings (section 4), sections greyed with a tooltip naming the GUIs that use them; each section's Reset, and Reset all; the note "Changes apply to windows opened from now on." (Q46 (A)).
- `fcn_CarMesh3D_reviewChecks`: the one list of checks (section 5).
- `fcn_CarMesh3D_makeDisplayPanels`: "Turn photo with model?" added; the three photo options remembered when picked.

**The GUIs:**
- **Viewer:** the shared menu; Shared GUI settings with View and Demo vehicle used.
- **Painter:** the shared menu; opens with Labels To Display over Modify Labels (remembered after, preference `PainterPanels`); Shared GUI settings with You, View, Demo vehicle and Editing used; its old Settings panel gone (the settings to Shared GUI settings, the actions to "Saving" at the foot of Modify Labels); Who is your initials. New option `Menu=`: a host's menu.
- **Reviewer (the V&V GUI):** a ☰ Menu at the top of its tools, its panels in a column beside them; Shared GUI settings with every section used; on the Labels check the painter's panels are in the reviewer's menu (gone when it leaves Labels). Optional checks turned off: greyed in Checks, the reminder "Checks (2 off: Shared GUI settings)", their unanswered questions recorded as skipped ("turned off in Shared GUI settings", by your initials); counted in the summary and the report; asked again when turned back on. The full pancake rework of the reviewer's layout (its tools and right column into panels) is not done: it is the next step for the V&V GUI.

**Decisions to check (Claude's calls while Sean was away):**
1. **No Photos section; the ground stays out of View.** Show ground?, Turn model with photo?, Turn photo with model? and Photo size? stay in Overall Display, where they act at once, and are now remembered from there (preferences `ShowGround`, `TurnWithPhoto`, `TurnPhotoWithModel`, `PhotoHeight`). A copy in Shared GUI settings would show each in two places (rule G2, no repeated information).
2. **The animation checks are optional** (section 5).
3. **Reset all** resets only the sections the window uses; Demo vehicle's Reset forgets your own demo vehicle.
4. **Not built yet** (section 4's "not yet" items; "Hide as" at Apply; the interior objects in Labels To Display, which needs the viewer to color by interior object).

**Seen with the real mouse and screen** (the reviewer and the painter, visible, 17:18 and 17:40): the ☰ list opens beside the tools; two panels stack; a third replaces the lower one. Fixed from it: the required checks' rows drew as nothing (now the text "On (required)"); "Timestamped copy at each save?" and "Folder for timestamped copies" were cut off (now "Copy at each save?" and "Copies go in", the full wording in their tooltips); "Back to the repo's demo" was cut off (now the panel's full width). Greyed sections are faint gray, as rule G26 asks; Sean may want them darker (T59).

**Bug found and fixed on the way:** the menu helper set the column's width while its host was still being built; in the viewer that moved the camera's fit, and the viewer's test "a view, closed and opened again: the same" failed. The column now keeps its starting width until a panel opens or closes.

## 10. Tests

**Automated** (run 2026-11-24 evening, hidden, in a batch MATLAB of their own; results in section 11, the change log):
- `script_test_fcn_CarMesh3D_makePanelMenu.m`: the list; two at once; a third replaces the lower; an open one closes; greyed panels; panels added and taken away; 200 random steps against the rules.
- `script_test_fcn_CarMesh3D_makeSettingsPanel.m`: each setting is its preference, and OnChange hears it; the Review rows; each Reset and Reset all; greyed sections with their tooltips; layout. Every preference saved and put back.
- `script_test_fcn_CarMesh3D_reviewChecks.m`: the list matches the reviewer's checks; required checks stay on; the preference.
- In each GUI's own test, only how it uses them: the viewer (two panels through the menu's buttons, in the random walks' rules; View's Reset; greyed sections; Turn photo with model?), the painter (its starting panels, remembered; Editing; Review greyed), the reviewer (the menu, the painter's panels in it on Labels, skipped checks), the display panels (the photo options remembered).

**For Sean (T53 to T59).** Each starts from a clean MATLAB; anything that saves uses a demo copy.

**T53. Viewer: two panels at once.**
```matlab
close all force; clear functions; clc
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(fcn_CarMesh3D_demoVehicle(Which='guiTest'));
fcn_CarMesh3D_viewLabels(vehicleFiles.MeshFile);
```
It opens with Overall Display. ☰ Menu, Lamps To Display: it opens under Overall Display, each scrolling on its own. ☰ Menu, Shared GUI settings: it replaces Lamps To Display. ☰ Menu, Overall Display: it closes, and Shared GUI settings moves up. The check marks in the list follow.
- (Sean's result:)

**T54. Viewer: Shared GUI settings.** (Same window.) You, Editing and Review are greyed, and their tooltips say which GUIs use them. In View, set "Start: dial angle?" to 120; Overall Display's Reset view goes to 120. View's Reset puts back 60 and 20.
- (Sean's result:)

**T55. Viewer: Turn photo with model?** (Same window.) Overall Display, Turn photo with model? Off: turning the model leaves the dial's arrow and the photo where they are. On: they follow. Close, open again (the command above): it is still as you left it. Leave it On at the end.
- (Sean's result:)

**T56. Painter: its panels and settings.**
```matlab
close all force; clear functions; clc
demoFiles = fcn_CarMesh3D_makeDemoCopy(fcn_CarMesh3D_demoVehicle(Which='guiTest'));
fcn_CarMesh3D_paintLabels(demoFiles.Folder);
```
It opens with Labels To Display (blue) over Modify Labels (yellow). At the foot of Modify Labels: "Saving" (Save as version, Revert to start, the edits file). ☰ Menu, Shared GUI settings: Review is greyed; Editing has "Timestamped copy at each save?" and its folder. Open two other panels, close, open again: the same two open.
- (Sean's result:)

**T57. Reviewer: the ☰ Menu, and the painter's panels in it.**
```matlab
close all force; clear functions; clc
demoFiles = fcn_CarMesh3D_makeDemoCopy(fcn_CarMesh3D_demoVehicle());
fcn_CarMesh3D_reviewVehicle(demoFiles.Folder);
```
☰ Menu at the top left; it lists Shared GUI settings only, with every section usable. Pick the Labels check: the menu now also lists Overall Display, Labels To Display, Lamps To Display and Modify Labels, and the painter in the middle has no ☰ Menu of its own. Open Modify Labels from the menu and paint a face. Go to Dimensions: the painter's panels leave the menu.
- (Sean's result:)

**T58. Reviewer: an optional check turned off.** (Same window.) Shared GUI settings, Review: Detail levels Off (required checks cannot be turned off; Interior objects and Photos are grey, not built yet). Close the reviewer and open it again (the last command). Checks reads "Checks (1 off: Shared GUI settings)", and Detail levels is greyed. The Summary counts "skipped (turned off)". Turn Detail levels back On at the end.
- (Sean's result:)

**T59. Sparse enough?** Any window above, made small (about a third of the screen): is Shared GUI settings readable, and is anything on screen that should be in a panel? (Rules G2, G6.)
- (Sean's result:)

## 11. Change log

- 2026-11-24 16:05 to 16:15 (Sean, Claude): started from the painter's old P2 (its design file, section 9). Sean (16:05): P2 meant aligning the painter with the viewer and showing viewing and modifying panels together; "panel reusability, especially as helper functions to multiple GUIs, should be a top priority." Claude's review (16:09): the grouped labels and the photo fixes fit if built in the helper; showing Labels To Display inside Modify Labels would copy a shared panel; one painter-only settings panel mixes shared and painter-only settings; "When the paint label changes?" is stale since the select / label / Apply change; the Save and Revert renames are partly stale since "Revert to a save..." moved to the top bar. Sean (16:12): two panels at once; "Shared GUI settings" with the parts a GUI does not use greyed out. Sean (16:12 to 16:14): think ahead to the V&V GUI so the panels are not redone for each new GUI; required and optional review checks. This file written (16:15).
- 2026-11-24 16:25 (Claude): section 2 now points to the new `Documentation_CarMesh3D_GUIdesign_rules.md`; several GUIs at once added to section 7; status BUILDING (Sean, 16:23: "Go ahead... Please proceed with the UI edits needed, particularly in setting up and testing the helper functions, integrating them across old GUIs and the new VandV one, and doing the test cases").
- 2026-11-24 16:28 to 17:45 (Claude, Sean away): built and tested (section 9). Automated tests, hidden, in a batch MATLAB of their own: reviewChecks, makePanelMenu, makeSettingsPanel, makeDisplayPanels, findVehicleFiles, makeDemoCopy, checkModels, browseLibrary, reviewVehicle and viewLabels PASS; paintLabels PASS earlier tonight (twice), then a timing flake in its own test fixed (a save in the same second replaced a timestamped copy), rerun in the final batch. The viewer's resize asserts failed now and then in a busy batch MATLAB (the old viewer too, run as a baseline): the test now lets the window settle once more after each resize, and passed in full (518 s). The reviewer's test had been failing since the painter's select / label / Apply change: brought up to date; its known open Differences case is reported, not asserted. Status set to BUILT; T53 to T59 written.
