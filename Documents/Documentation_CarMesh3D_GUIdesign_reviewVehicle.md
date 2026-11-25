# Design: the model reviewer, `fcn_CarMesh3D_reviewVehicle`

> **Replaced (2026-11-24 23:25):** the V&V GUI is redesigned as a host for a list of assessment functions; see **`Documentation_CarMesh3D_GUIdesign_VandV.md`**. This file is kept as the record of the old Model Reviewer (its open items, tests and change log); new work goes in the new file.

*Started 2026-11-24 01:45 by Claude, at Sean's request (01:40: "let's keep using the MD files for review notes, documentation, etc. ... We cannot rely on the chat to track details"). Until now the reviewer's design lived in the project doc `claude/model_reviewer.md` (its history from 2026-11-21) and its open work in `claude/work_queue.md`; this file gathers what is still to do, with the questions and tests, as the other GUIs' design files do. Each side writes under (Sean to Claude) or (Claude to Sean); questions are numbered S2C / C2S.*

```matlab
fcn_CarMesh3D_reviewVehicle('2009_Honda_Fit_Sport');
```

## Review now (for Sean)

*(Nothing to test yet. **Archived** (Sean, 2026-11-24 01:48): the reviewer's tests (T12) and the work in section 3 wait until the V&V workflow is finished, "which is actually nearly where we are now.")*

## 1. What the window is for

One vehicle's review: a list of checks (Orientation, Dimensions, Labels, Lights, Body, Steering, Wheels, Drive, Detail levels, 2D outline, Differences, Summary), each shown by its own tool inside the window; each item is approved or rejected, with a severity and a comment; the answers are saved per vehicle (`checks\review_<ID>.mat` and `.md`). The full description of the window as built is in `claude/model_reviewer.md` (layout, answering, how the mesh passes to each check).

## 2. Rules

- **Follows `Documentation_CarMesh3D_GUIdesign_rules.md`** (rules G1 to G38, every CarMesh3D window), including the tree rule (G25: it holds the painter, the animation checks and the view tools inside its window, and never opens a sibling), and the shared panels of `Documentation_CarMesh3D_GUIdesign_sharedPanels.md` (its Review settings section is there, with the required and optional checks).

## 3. Work agreed and not yet done

These were agreed on 2026-11-23 (the V&V simplification, `claude/vandv_simplification.md`, Sean 00:58 to 01:28; work queue tasks 6 and 7). Sean, 2026-11-24 01:28: "many of the fix items we mentioned earlier are not updated in this GUI yet."

**3.1 Task 6: the reviewer by family**
- The main checks: Orientation, Dimensions, Labels (with lamp types), 2D outline, Summary.
- "More checks" for the rest: Differences, Lights, Body, Steering, Wheels, Drive, Detail levels.
- Differences as one overview picture, and only for meshes that were changed (reduced, mirrored, a floor panel added, faces deleted).
- The question, in Sean's words (01:28): "If rotating is not smooth here, this mesh is almost certainly too large for real-time animation on this computer."
- A review older than the mesh's last "built" row (meshHistory) is flagged "built since review".
- The light check folded into Labels: a "lights on" switch in the labels view rather than a separate check (V&V proposal 6).

**3.2 Task 7: the GUI rules applied**
- Read-only text shown as text, not in text boxes; controls in the order used; tooltips; radio questions ending in "?".

**3.3 Found 2026-11-24**
- **The tree rule:** the reviewer builds a hidden painter to get "the mesh with its saved label fixes" (search `savedPainter` in the code); the animation checks do the same. **Done 2026-11-24 02:05** (chat Q32 (A), Sean 01:55): a plain function with no window, `fcn_CarMesh3D_meshWithLabelEdits`, that both now call; it gives the same mesh as the vehicle's script (checked on the Fit: light types, parts, covers and colors identical) in 0.1 s.
- **Short windows** (Sean, 01:28): "we may need to check if panels disappear if user's vertical resizing shrinks." The Question panel's grid now scrolls (2026-11-24 01:00); the Checks and Items lists already did. To test by shrinking the window.

## 4. Open questions

**(Claude to Sean)**

**C2S 1. Order of the work in section 3.**
- (A) *Recommended.* 3.1 (by family) first, then 3.2 (the GUI rules), with one test round at the end. (The plain function of 3.3 is done.)
- (B) 3.1 first: it changes what a student sees most.

**(Sean to Claude)**

*(None open.)*

## 5. Open issues

*(Sean adds issues here.)*

## 6. Change log

- 2026-11-24 01:28 (Sean, T12): the Question panel had room enough that no scroll was needed; the Checks panel scrolls. Many agreed fixes are not in this GUI yet (section 3).
- 2026-11-24 01:45 (Claude): this file started.
- 2026-11-24 01:48 (Sean): T12 archived until the V&V workflow is finished; section 3 waits with it.
- 2026-11-24 02:05 (Claude): `fcn_CarMesh3D_meshWithLabelEdits` (new) replaces the hidden painters in the reviewer and the animation checks (Q32 (A)). Their test scripts not yet rerun (they open hidden windows; waiting for Sean to be away).
- 2026-11-24 02:00 to 02:20 (Claude; Sean away for the tests): the reviewer's test suite, run after tonight's changes:
  - **A stopped run overwrote the Fit's label fixes** (02:06): the test painted and saved on the real Fit and put the files back only at its end. Restored at once from the test's own backup (identical to the 00:47 file, 13 fixes) and the review answers from git. The test now works on a temporary copy of the Fit with no saved fixes (`fcn_CarMesh3D_makeDemoCopy`), and puts files back through `onCleanup`; checked: 0 of the real Fit's files change.
  - Brought up to date: the painter's mirror switch is an Off/On pair (was a tick box); its delete tool is now hide (2026-11-23); its own trim fix is found among the vehicle's fixes. A crash with no difference spots yet (`compareSpots` empty) is guarded in the reviewer.
  - **Still failing, left for the archived work:** line 272, 'no new spot for the deleted roof faces'. Hiding part of the roof no longer makes a Differences spot (hidden faces are not deleted). Question for when the reviewer work resumes: should hidden faces show in Differences, and does Differences stay at all for family-1 meshes (section 3.1)?
- 2026-11-24 16:25 (Claude, Sean 16:20 to 16:23): section 2 now points to `Documentation_CarMesh3D_GUIdesign_rules.md`.
- 2026-11-24 23:25 (Claude, Sean 22:54 to 23:23): replaced by `Documentation_CarMesh3D_GUIdesign_VandV.md` (the V&V GUI as a host for assessment functions); this file kept as the record.
