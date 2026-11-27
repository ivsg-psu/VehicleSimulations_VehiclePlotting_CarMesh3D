# Design: the main GUI (`fcn_CarMesh3D_main`)

*The one window that takes a vehicle from a download to a reviewed, finished mesh, opening each of the other windows in turn and keeping the steps, their order and their status in view, so the process knowledge lives in the window and not in the user's memory. Started 2026-11-27 by Sean; written with Claude. The general GUI rules are in `Documentation_CarMesh3D_GUIdesign_rules.md`.*

**Status:** step 1 of the plan BUILT 2026-11-27 17:05 (`fcn_CarMesh3D_main` and its test, passing hidden); step 2 next.

## 1. What it is for

This is the main GUI interface for the CarMesh3D library. Its purpose is to have a single GUI interface that calls all the other GUIs, allowing each to be open but keeping the same vehicle. The other GUIs include:

* **The browser** (`fcn_CarMesh3D_browseLibrary`): selects a vehicle from those in the library of downloaded meshes, or starts a new one from a download.

* **The import (first look and import report):** runs the vehicle's script in first-look mode on its download, then shows `fcn_CarMesh3D_importReport`: whether lamps and glass are told apart (the gate), where the glass is, and which lamps are under glass. For a new vehicle, it also makes the vehicle's folder and script from the template (today a manual copy; section 5).

* **The painter** (`fcn_CarMesh3D_paintLabels`): paints part and lamp labels. Used twice: first to separate the lamps and the glass from the body (including lamps underneath glass), so the face directions and covers can be worked out; then again for the full labeling (which lamp is which: headlamp, turn signal, marker ...).

* **The face-direction window** (`fcn_CarMesh3D_fixFaceDirections`): turns inside-out faces the right way, after the first labeling.

* **The build:** runs the vehicle's script in full (fit to the specification, the repairs, the saved edits, detail levels, outline, checks), with a progress bar. Not a window of its own: a step in the main window, with its log one click away.

* **The label viewer** (`fcn_CarMesh3D_viewLabels`): shows the finished mesh's labels and lamps, day and night. It treats the model as read-only, so several can be open at once (section 2).

* **The lamp-functions window** (`fcn_CarMesh3D_editLampFunctions`): which signals light which lamp, and how brightly (L2F), with the sources, the review notes left by the internet search, and the regulation's requirements, with links, beside the sliders.

* **The check viewers:** dimensions (`viewDimensions`), orientation (`viewOrientation`), detail levels (`viewDetailLevels`), the top-down outline (`viewOutline`), and the motion checks (`animateChecks`). Read-only; gathered under one menu item, "Checks".

* **The V&V window** (`fcn_CarMesh3D_reviewVehicle`): the human review that signs a vehicle off. Last, before Commit.

Each of these branch GUIs can be opened and arranged by the user as separate windows.

## 2. The interaction of the main GUI with children GUIs

Because it is the main interface, there are some slight differences in the way the main GUI interacts with and affects the branch GUI behaviors, versus if the branches are run by themselves. Namely:

* **The steps and their order.** The main menu mediates the process to load, modify, and review a vehicle mesh from end to end. Each step in the menu carries a mark (section 3): done, out of date (something before it changed since), or not done. A step that **cannot** work yet, because its input does not exist, is greyed out, and its tooltip names the step that makes that input ("Build the mesh first: step 4"); for example, V&V on a mesh that was never built. A step that is only out of date stays open but shows orange, so a student sees "the lamp functions were set before the last repaint" without being blocked. A step that can run but comes early in the agreed order (the face window before any labels) stays open, with a hint.

* **Exit.** Exiting the main GUI closes the main GUI **and** all the children. Unsaved changes in any child each raise that window's own "Are you sure?". Cancelling one of them stops the exit (the main window stays open). The working model is never lost on exit: it stays in its working folder until committed or discarded, and the main window offers to resume it next time.

* **The working model.** Opening a vehicle creates a working model: a **copy of the vehicle's edits only** (a few hundred kB, not the meshes) in a working folder (section 6). The windows read and save there, and the build runs from there. **Commit** puts them back into the vehicle's folder, with a row in its change log; **Discard** deletes the working folder. So the user can try things across all the windows and throw them away; the vehicle's folder (and git) only ever sees a finished set; and "what have I changed and not committed?" has one answer, shown in the main window.

* **One vehicle.** The same vehicle is used by every child at once; no child can work on a different model from another.

* **Changing vehicle.** The vehicle is chosen only in the browser, or by closing the main GUI and calling it again with another vehicle. Choosing another vehicle in the browser while a working model has changes asks first: Commit, Discard, or Keep it for later (the working folder stays, and the main window lists it as unfinished work).

* **One editor at a time.** The editors are the painter, the face-direction window and the lamp-functions window; they save to the working model. Only one editor may be open at a time: a change saved in one editor (perhaps through its "Are you sure?" on closing) can change or break what another editor holds, including what that one would save. Opening a second editor asks to close the first (saving or not). Opening any editor also closes the V&V window: V&V may not run while edits are being made. Its answers are saved as they are given, and reopening it starts at the first question not yet answered, or out of date because of the edits.

* **Viewers: any number, turning together.** The viewers (the label viewer and the check viewers) change nothing, so any number can be open at once, of the same kind or different kinds, beside an editor or not: a day view and a night view side by side, or a labels view beside a colors view. When an editor saves, every open viewer redraws. With the setting **"Turn all views together globally"** (on by default), turning the model in any window turns every other window's model to the same viewing direction, while each keeps its own pan and zoom, so a zoomed-in viewer stays on its detail. The editors' views turn with them. The windows never talk to each other: each tells the main window, which passes it on. A second flag option within the GUI settings panel, **Unlink this view from global view settings** visible from the main GUI and many child GUIs, allows that child GUI to be "unlinked" from the synchronized view setting affecting other children GUIs. Thus, a person editing the labels can, in their label GUI, turn the model to a different side and zoom into different regions, while all the open viewers still linked together keep showing the whole vehicle from the angle they share. (Pan and zoom are never shared, linked or not; unlinking is what lets a window also turn on its own.) Unticking **Unlink this view from global view settings** relinks that window: it turns to the linked windows' current direction (the others do not turn to it). The box is in each child's own settings, and in the main window's settings as a list of the open windows, each with its box. Any subsequent click of the **"Turn all views together globally"** setting either "off" or "on" de-links or re-links all windows again (respectively), and automatically resets the **Unlink this view from global view settings** to off across all children GUIs.

* **No children on their own.** While the main GUI is open, a child cannot be opened outside it: calling `browseLibrary`, `viewLabels`, etc. by itself says so and offers to bring the main window forward instead. The main GUI manages the working model's relation to the saved vehicle, and the windows were not designed or tested for separate copies working on it at the same time. (Programmers can switch this off; section 7.)

## 3. The main GUI window interface

The main interface is intentionally simple: it is a "pancake" menu where each item on the menu calls one of the helper children. One of the pancake options opens a settings panel for all GUIs; another lets the user save the results (Commit).

The menu is the process, top to bottom, in the order agreed 2026-11-27 04:03 (import, first labels, directions, the parts worked out from them, full labels, L2F). Each step shows a mark: **done** (green check), **out of date** (orange: something before it changed), **not done** (gray circle), **cannot start yet** (greyed; the tooltip says why). The window's title bar names the vehicle, and a line under it says "Working model: 3 changes not committed" (or "No changes").

| # | Menu item | Opens | Done when |
|---|---|---|---|
| 0 | **Vehicle...** | the browser (pick a vehicle, or start a new one from a download) | a vehicle is loaded |
| 1 | **Import** | first look and the import report | the import report passes its gate |
| 2 | **First labels** | the painter (lamps and glass apart from the body) | lamps and glass are told apart |
| 3 | **Face directions** | the face-direction window | the face flips were saved after the last change to the labels |
| 4 | **Build** | runs the vehicle's script (progress bar; log) | the mesh is built from the current edits |
| 5 | **Full labels** | the painter (which lamp is which) | every lamp has a kind |
| 6 | **Lamp functions (L2F)** | the lamp-functions window | every lamp has a row; no open review notes |
| 7 | **Checks** | a submenu: labels, dimensions, orientation, detail levels, outline, motion; each pick opens a new viewer | (viewed; no mark of its own beyond the build's check results) |
| 8 | **V&V review** | the V&V window | every assessment answered Yes, or No with a note |
| 9 | **Commit** | puts the working model into the vehicle's folder | nothing left uncommitted |
| | **Discard changes** | deletes the working model (asks first) | |
| | **Save view...** | saves the window layout and settings (section 4, call 3) | |
| | **Settings** | the settings panel for all windows: turn all views together globally (on), and the open windows each with its "Unlink this view" box; night view, colors, brush sizes, the vehicle to start with (the default, or the last used) ... | |
| | **Help: the process** | a short page on the steps, why they come in this order, and what each mark means | |
| | **Exit** | closes the main window and every child (section 2) | |

## 4. Method of calling the main GUI, and forbidden calls

The main GUI can be called in several ways:

1) a "plain call", a call with no arguments: `fcn_CarMesh3D_main`. This loads the default vehicle (currently the 2009 Honda Fit). An option in the main menu's settings instead loads the last vehicle used in this menu. The last vehicle is computer-specific and is not passed on with the code (it is not archived in GitHub). If an uncommitted working model exists, the plain call offers to resume it first, so unsaved changes are not lost. An input flag, `Resume=false`, starts without offering. The old working model is then **set aside**, neither resumed nor deleted:

   1. **Set aside:** its folder `Working\<ID>\` is renamed `Working\<ID>_setAside_<yyyy_MM_dd_HHmmss>\`, with nothing inside it changed.
   2. **Start fresh:** a new working model is started in `Working\<ID>\`, from the vehicle's committed files.
   3. **Kept visible:** set-aside models are listed in the main window as unfinished work, to open, commit, or discard later.

   Why not simply start fresh in the same folder: that would overwrite the old work, a discard without asking. Discarding is only ever the menu's Discard, which always asks the user first.

   Technical note: the last vehicle is kept as a MATLAB preference (`getpref('CarMesh3D', ...)`), which is per computer and per user and outside the repo.

2) a "vehicle-specified call". This uses an input argument specifying the vehicle to load, bypassing the browser and the default vehicle. For example:

   ```matlab
   fcn_CarMesh3D_main('2009_Honda_Fit_Sport');          % by ID
   fcn_CarMesh3D_main(Vehicle='2017_Mazda_CX3_Sport');  % the same, named
   ```

   (An ID, or a vehicle's folder, as `fcn_CarMesh3D_findVehicleFiles` takes.)

3) a "view-specified call". This is a call with the interface's desired view state and vehicle passed in as a structure. The structure lets the GUI load exactly the children's on-screen layout and positions, each child's settings (such as night view), and the vehicle to edit. The structure is returned when the main GUI closes, and is automatically saved with date-time versioning in **`CarMesh3D\Working\views\`**, as `mainView_<ID>_<yyyy_MM_dd_HHmmss>.mat`.

   The `Working` folder is in the repo's folder, so users can find it, but it is listed in `.gitignore`, so it is never committed. This kind of call is useful to return to work partially completed earlier (but saved), or to save a view that is in question and share it with others later. If the screen differs from the one the structure was saved on (smaller or larger), the code resizes the windows using screen fractions as a guide (the structure stores positions as fractions of the screen); users may need to adjust them again, so it should not be expected to be exact. The structure names its working model, so a view shared with someone else opens the committed vehicle when that working model is not on their computer (and says so). For example:

   ```matlab
   viewState = fcn_CarMesh3D_main('2009_Honda_Fit_Sport');   % returned when the window closes
   fcn_CarMesh3D_main(viewState);                            % the same windows, places and settings
   fcn_CarMesh3D_main(fullfile('Working','views','mainView_2009_Honda_Fit_Sport_2026_11_27_150500.mat'));
   ```

Forbidden calls include:
* opening a child on its own while a main window is open (section 2, last bullet);
* a second main window (the call brings the open one forward);
* a Commit while an editor or the V&V window has unsaved changes (it asks that window to save or discard first).

## 5. The process the window carries (the Fit's end-to-end run)

This section is not expected to be understood by all users; it documents how the code works at a slightly deeper level. The table relates actions that can be done without the GUI (what a user does today, and must remember) to what the GUI does for them (the steps of section 3). The left column is the "user memory" the GUI window takes over.

| Today (from memory) | In the main window |
|---|---|
| Copy `Data\script_CarMesh3D_vehicle_TEMPLATE.m` into a new folder under `DataSomeday`, rename it, fill in its settings | Vehicle... > New from a download: makes the folder and script, asks for the settings it needs (model file, axes, part rules) |
| Run the script with `flagFirstLook = 1`; read the console | Import: runs it, then shows the import report and its gate |
| Open the painter with the right ID and edits file | First labels |
| Open the face window; know that it comes after the labels | Face directions (marked out of date if the labels change after) |
| Rerun the script with the right flags; know which caches go stale | Build (the marks show what is out of date) |
| Paint the lamp kinds; open the lamp-functions window; find the manual | Full labels; Lamp functions (with the staged sources and review notes) |
| Open each viewer; know which check pictures to look at | Checks |
| Run V&V; remember which answers are stale | V&V review |
| Commit and push the right files | Commit (to the vehicle's folder); git stays outside (section 8) |

## 6. The working model

- **Where:** `CarMesh3D\Working\<ID>\` (gitignored), one per vehicle being worked on.
- **What is copied in:** the vehicle's whole folder: its edit files (labels, face flips, lamp functions with their sources and review notes, the review answers), its script, and its built mesh, levels and outline, which the viewers show before the first build (as built: the vehicle's folder is a few MB; the download, in `LargeData`, is not copied). The build writes into the working folder (Q111 (A): a copy of a vehicle's folder named by its ID builds in place, reading the download from the vehicle's own folder), so the vehicle's own folder does not change until Commit.
- **What counts as a change:** every file of the working copy that is new or differs from the vehicle's, except its cache, its change log and the build log. (Opening V&V writes its review record, which counts.)
- **Commit:** checks that no window has unsaved changes; copies the edit files and script back; copies the built outputs (mesh, detail levels, outline, checks) across when the working build is current, or builds the vehicle again when it is not; adds a row to the vehicle's change log ("committed from the main window by SBB: labels, face flips"); and deletes the working folder.
- **Discard:** deletes the working folder (to the Recycle Bin), after asking.
- **Resume:** a working folder left from before is listed when the window opens, and so are set-aside ones (`Working\<ID>_setAside_<time>\`, section 4, call 1).
- **Where the marks come from:** from the files themselves (rule G40: the item's data is the truth), using the fingerprints the build's cache already keeps. For example, face flips saved after the mesh was built make Build "out of date", and every step after it orange too.

## 7. What the children need (changes to existing windows)

1. Each editor takes the file it saves to (DEVELOPMENT NOTE, remove when done: most already do, `EditsFile`, `FlipsFile`; the lamp-functions window and V&V need the same option).
2. Each child takes a `Main` option (the main window's handle): with it, it tells the main window when it saves and when its model is turned, and skips its own "open another window" offers.
3. Each viewer gets a `Redraw` hook (most have one for tests already), and every window with a 3D view a `SetViewDirection` hook, which the main window calls.
4. Each child, called on its own, checks whether a main window is open (section 2). For programmers only, documented in each function's header and not in the GUI: the check is skipped for windows built hidden (tests and batches), and when the environment variable `MATLABFLAG_CARMESH3D_FLAG_ALLOW_STANDALONE` is set to 1 (debugging).
5. The browser, inside the main window, returns the chosen vehicle instead of opening anything (the trees rule).

## 8. Not in the main window (for now)

Common process actions the GUI does not do:

* Git: a separate review is good practice, and git provides it.
* The answer queue: a separate tool for Claude and Sean's work together.
* AnimateCar3D: a separate repo, developed alongside this one, with more on animation, examples, etc. (DEVELOPMENT NOTE, remove when done: a "Play in AnimateCar3D" item could come later, as the `vehicleTest` example does today.)

## 9. Plan

1. The main window with the menu, the marks and the working model, with the children opened as they are today (no blocking or rotation sync yet). Tested on a demo copy of the Fit.
2. The children's changes (section 7), one window at a time, each with its test; then the rotation sync.
3. Sean's end-to-end run on the Fit, through the main window (this closes out 1G).
4. Starting a new vehicle from a download (step 0's "New from a download").

## Tests for Sean

Key: as in `Documentation_CarMesh3D_template.md`.

(none yet: they come with the first build)

## Open questions

Key: as in `Documentation_CarMesh3D_template.md`.

### Question list

(none)

## Change log

- 2026-11-27 (before 14:54), Sean: sections 1 to 4 written (the main GUI as the trunk of the process: one vehicle for every child, children opened from a pancake menu, exit closes all, children blocked on their own, three ways to call it).
- 2026-11-27 14:56, Claude: replies to Sean's inline questions; sections 1, 3 and 4 filled in where asked; sections 5 to 9 and questions Q107 to Q110 added; the answer queue's plan and change log (copied in from its design file) removed.
- 2026-11-27 15:25 to 15:32, Sean (chat): any number of viewers at once (a day and a night view; labels beside colors), with a setting, on by default, to turn every view together (rotation only, not pan or zoom). V&V is neither viewer nor editor; Sean then decided (in section 2) that opening any editor closes V&V.
- 2026-11-27 16:02, Sean, in this file: the questions closed:
  - **Q107 (A):** a working model, a copy of the edit files only; Commit and Discard (where it came up: Sean's question on "working model" vs. editing the vehicle directly, section 1).
  - **Q108 (A):** grey out only what cannot work yet; out-of-date steps stay open, marked orange (section 2, first bullet).
  - **Q109 (A), extended:** one editor at a time, required; any number of viewers, turning together; any editor closes V&V (section 2).
  - **Q110 (A):** `CarMesh3D\Working\`, gitignored (sections 4 and 6).
  - Also: the exceptions to "no children on their own" are for programmers only, behind a debugging flag documented in the function headers, not in the user text; the plain call's flag to start without resuming.
- 2026-11-27 16:04, Claude: the discussion merged into clean text (no drafts or highlights left); the painter's two uses described as Sean put them; "Coarse/Fine labels" renamed "First/Full labels" to match; Face directions' "done when" made checkable (flips saved after the last label change); five points for Sean in "Review now"; spelling fixed in Sean's text (vehicle, available, simultaneously, `fcn_CarMesh3D_main`).
- 2026-11-27 16:09, Sean (chat): asked what "leave the working model on disk" meant; Claude's first wording hid that starting fresh in the same folder overwrites the old work. Now: `Resume=false` sets the old working model aside (renamed, untouched), starts a new one, and lists the set-aside one as unfinished work (section 4, call 1, steps 1 to 3).
- 2026-11-27 16:23, Sean, in this file: accepted Claude's points from 16:04 (V&V resumes at the first open question; `Resume=false` sets aside; Commit copies the working build instead of building again; the marks' source moved to section 6). Added a per-window **Unlink this view from global view settings** box beside the global "Turn all views together globally" setting, which resets every Unlink box when it is switched (section 2, "Viewers").
- 2026-11-27 16:26, Claude: the unlink merged with three details for Sean to confirm (unlinking frees the turning, since pan and zoom are never shared; relinking a window turns it to the group; where the boxes are).
- 2026-11-27 16:25, Sean (chat): the three details accepted; "Review now" removed.
- 2026-11-27 17:05, Claude: step 1 built: `fcn_CarMesh3D_main` (the steps and marks, the working copy with resume, set aside, Discard and Commit, one editor at a time, any number of viewers, the saved view) and `script_test_fcn_CarMesh3D_main` (passes hidden, on a demo copy of the Fit, with a build). Q111 (A): every vehicle script builds in a copy of its folder (3cb1128). Q112 (A): the lamp-functions window and V&V needed no new option: given the working copy's folder, they save there. Q113 (A): `script_demo_CarMesh3D` starts with option m, the main window, for students; every other option is marked FOR DEVELOPERS. Section 6 corrected: the working copy is the whole vehicle folder (its meshes too, for the viewers), not only the edit files.
