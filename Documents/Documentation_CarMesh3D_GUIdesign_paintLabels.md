# Design: the label painter, `fcn_CarMesh3D_paintLabels`

*The style and layout choices for the label painter, kept so the window can be rebuilt from this file. Edit it freely: it is the place to change the design, and Claude builds from it. Started 2026-11-23 10:05 from Sean's guidelines; Claude filled in the lists from the window as built on 2026-11-23 (04:35 version). Last updated 2026-11-23 15:55.*

**Status:** BUILT (11:05) in `fcn_CarMesh3D_paintLabels`, with hooks added to `fcn_CarMesh3D_viewLabels`; approved by Sean from the mockup (10:48: "a great start"; minor changes may come). The layout-only mockup stays in `Desktop\Claude\Project_CarMesh3D\tools\zz_mockup_paintLabels.m`; pictures of the built window are in `Desktop\Claude\Project_CarMesh3D\pictures\painter_build`. Sections marked **(Sean)** are Sean's words or decisions; **(Claude, to confirm)** marks Claude's fill-ins, accepted with the mockup.

---

## Review now (for Sean)

*Updated 2026-11-23 15:55. This section says what to look at in the window as built now, and what Claude could and could not test. P2 will change the layout (section 9), so look mostly at behavior.*

**How to open it.** Use the GUI test vehicle (made up, with every feature) or the Fit. Painting either one saves only when you press Save, into that vehicle's own `labelEdits_<ID>.mat`, which nothing else running today touches; thread B does not change label edits. To get the outputs back when the window closes, pass `Wait=true`:
```matlab
% The GUI test vehicle (every lamp type, covers, interior objects, two hidden sets, its own photos)
[editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels('2026_CarMesh3D_Sample_GUITestVehicle', Wait=true);

% The 2009 Fit (a real download)
[editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels('2009_Honda_Fit_Sport', Wait=true);
```
After the window closes: `editedMesh` is the mesh with every saved and applied edit; `labelEdits` is the list of edits (a cell array of structures, as the vehicle's script applies them); `painter` is the window's handle structure (its functions no longer work once it is closed). Saved edits stay in the vehicle's `labelEdits_<ID>.mat`, so nothing is lost if MATLAB closes. To undo a test painting on a real vehicle: Settings, Revert to start, then Save.

**Tested by Claude (hidden, by script; passes):** opening on a vehicle ID and inside a parent panel; each menu panel opens alone and the last one is remembered; no check boxes left in the panels; Colored? No draws a label gray, and All shows the mixed state; Shown? No hides a label's faces; the lamp buttons follow the lamp states (All off sets Tail to Off); the Paint as radio follows the tool, including none; painting by script (Paint), Apply, Undo by steps, Save, Revert to save and to start; timestamped copies on and off, and the copy folder; hide into a named set and unhide; the photo dial by script; the reviewer's Labels check with the painter inside it (picture checked).

**Needs Sean's hands (Claude cannot test these):**
- **T1. Menu:** click ☰ Menu, pick each panel; pick the open panel again (it should close, and the model widens).
Confirmed. Works as expected.

- **T2. Mouse painting:** pick a label in Modify Labels, then 

Ctrl+drag,
Result: first click face highlighted. No others even if move over. Expected behavior: all dragged items would be selected. Bug?

 Ctrl+Shift+drag (erase), 
 Result: will sometimes deselect highlighted face, but only at first click point. Bug?
 
 a single click (one face;
sometimes works 

  click again to take it off), 
only sometimes works. Bug.

Overall Result: Many mouse clicks required to select, even with single click, and some faces seem unselectable (3+ attempts result in no change. Same is true when deselecting. Noticing that first select and deselect tends to work more than subsequent click attempts on same face. Most face clicks result in no response.
 
 and a double-click (a whole piece). 
  worked once for 2 different objects (tire and body). Won't work for glass. Bug?

Pending paint should show yellow edges until Apply.
Worked, but after apply, cannot select any verticies in any


- **T3. Mirror to the other side? Off/On:** paint one side and check the other side follows only when On.
Cannot test this easily. GUITestVehicle is not symmetric in the mesh about XZ plane. <-- Bug

- **T4. Keyboard:** Ctrl+Z (undo) and Ctrl+S (save), with the mouse over the model.
Does not seem to work. Cannot easily tell however since hit apply.

- **T5. Exit with unsaved paint:** a Save / Discard / Cancel dialog; Cancel keeps the window.
Works

- **T6. Revert to save and Revert to start (Settings):** each asks first.
Revert button is missing at top. Only see Undo, Save, Edit 

- **T7. Browse buttons:** the copy folder (Settings) and the photo folder (Photo panel) open folder pickers; a folder with no `ViewInDegrees_<angle>` photos is refused with a message.
- **T8. Photo panel:** Turn model with photo Off/On (drag the dial's red arrow; the model turns only when On); Photo size Small/Medium/Large; dragging the photo's corner (the size buttons then show none selected). Known: Small cuts off "Large" (fixed in P2).
- **T9. Overall Display:** Labels/Vehicle colors; mesh boundaries Off/On; Nighttime view Off/On (lamps light at night; Lamps To Display buttons follow); Reset view; Copy view call (paste the result into MATLAB: it should open the viewer at the same view); the see-through slider.
- **T10. Labels To Display while painting:** set a label to Shown? No and paint the faces under it; set Colored? No on all but one label.
- **T11. Lamps To Display:** each lamp Off/On, Tail Off/On/Brake, All lamps; by day the lit lamps show lit colors on the model; at night, with their light. On the test vehicle every lamp has faces; on the Fit, running, turn and backup show gray names.
- **T12. Hidden faces:** on the test vehicle, Show hidden faces? On shows the muffler and the roof panel (magenta); unhide one with the unhide label; Hide as a new set name.
- **T13. Look and feel:** anything cut off, misaligned or unclear, at the window's normal size and when resized.

Note anything you find in section 9 (Open issues), as before.

## 1. What the window is for

The painter fixes a finished vehicle's labels by hand. The user picks a label (body, glass, a lamp type, hide, ...), paints faces of the 3D model with the mouse, applies the paint, and saves. The saved edits (`labelEdits_<ID>.mat`, in the vehicle's folder) are applied by every later build of the vehicle, so a fix is never lost. Photos of the real vehicle, picked by viewing angle on a dial, sit beside the model for comparison.

It is called on its own, `fcn_CarMesh3D_paintLabels('2009_Honda_Fit_Sport')`, or built into the Model Reviewer (`fcn_CarMesh3D_reviewVehicle`, Labels check), which gives it a panel to build into (`Parent=`). The model view, the photo, the dial and the label and lamp lists are the label viewer (`fcn_CarMesh3D_viewLabels`) built inside it, so a fix to the viewer is a fix here; the rules below apply to both windows (see open question Q6).

## 2. General rules for the whole window

**(Sean)**
1. **Working options for the mesh are on the left**, next to the mesh, which is on the left.
2. **Working options for the photos are on the right**, next to the photos.
3. **The spinner** (the dial that picks the photo by viewing angle) **stays between the two, near the top.**
4. **The main menu is a pancake menu** (a "☰" button, top left) that lists the panels. Clicking a panel's name opens it below the pancake, against the left side of the window; clicking another closes the open one and opens the new one. One panel is open at a time.
5. **Only three buttons along the top in normal use: Undo, Save, Exit.** Exit without saving asks whether to save.
6. **On/off selections always use radio buttons.**
7. **A label choice is written:** `(colored box) Name   radioOption1 radioOption2 radioOption3 ...`
8. **A lamp choice is written:** `(colored box) Name   Off On 3rdState 4thState ...` (Off always first).

**(Claude, to confirm: added general rules)**

9. **Columns, with a header row.** In any list of label or lamp choices the radio buttons line up in columns, and the column names are written once, as a header row above the list (for example `Colored  Shown`), rather than beside every button. The colored box is 14 x 14 pixels, with a thin dark border, in the color the label or lamp has on the model.
10. **An on/off choice is an Off/On pair**, side by side, Off first (MATLAB radio buttons cannot be clicked off once on, so a single radio button cannot turn something off again). See Q5.
11. **Buttons are only for actions** that happen once when pressed (Undo, Save, Exit, Apply, Reset view, Browse...). Anything that stays on or off, or picks one of several, is a radio button.
12. **Read-only information is text, never a text box** (from `claude/gui_design_notes.md`). Text boxes are only for typing (a hidden set's name, a folder).
13. **Missing items are shown, not removed:** a label or lamp the mesh has no faces for keeps its row, its name in **gray italics**, with one note under the list ("Gray names: no faces have this label yet"), and its controls still work (a lamp with no faces still casts its light at night). (The mockup showed that "(no faces)" after each name does not fit the 320-pixel panel.)
14. **Every control has a tooltip** that says what it does in a sentence.
15. **The title bar** is the standard one (`fcn_CarMesh3D_addTitleBar`): the function's name, large; its file's last change; and the vehicle's name.
16. **Colors of the bands:** paint work (Modify Labels) on a pale yellow background `[1 0.96 0.85]`; viewing work (Overall Display, Labels, Lamps) on a pale blue `[0.93 0.95 1]`; Settings on light gray `[0.94 0.94 0.94]`. The color says which kind of work a panel does.
17. **The window remembers** the open panel, the photo folder and the timestamped-copy folder for next time (MATLAB preferences, group `CarMesh3D`).
18. **Panels scroll** when they are taller than the window; nothing is cut off.
19. **Keyboard:** Ctrl+Z is Undo and Ctrl+S is Save, the same as the top buttons.
20. **A row that sets several others** ("All labels", "All lamps") shows no button selected when the rows under it differ. MATLAB always keeps one radio button of a group selected, so such a row has an unseen third button that is selected in that case (found in the mockup, 10:20).
21. **Panel width 320 pixels**; a control that does not fit beside its name goes on its own line under it (the mockup's View and Revert buttons), never cut off.
22. **A radio-button choice is asked as a question** and its name ends with "?" ("Turn model with photo?", "Show mesh boundaries?"), so it reads as something to answer (Sean, 13:12).
23. **A text box that has a default shows the default under it**, in gray ("(default is "hidden")"), so the user never has to remember it; defaults are set in GUI settings (Sean, 13:12).
24. **Every GUI setting can be put back:** GUI settings ends with "Reset to defaults" (Sean, 13:12).
25. **Every input argument is shown in the GUI in some way:** what a call can set, the window can show or set too (a control, or text in the subtitle, status line or a panel). This rule applies to every CarMesh3D window; the viewLabels and browseLibrary design files refer to it (Sean, 18:01 and Q20, 18:02).
26. **Anything that can take more than 2 or 3 seconds shows a progress bar** (a `uiprogressdlg` in the window; indeterminate when the length is not known), and the window says when it is done or what went wrong; it never just stops responding. An error in a callback is shown in the window, not only in the command window. This rule applies to every CarMesh3D window (Sean, 22:15, from the library browser's slow re-sort).

## 3. Layout

```
+-----------------------------------------------------------------------------------------+
| fcn_CarMesh3D_paintLabels            (title bar: version, vehicle name)                 |
+-----------------------------------------------------------------------------------------+
| [☰ Menu]  [Undo]  [Save]  [Exit]     status: "12 faces painted, not applied | saved 09:58"|
+----------------------+--------------------------------+---------+-----------------------+
| (open panel, e.g.    |                                | spinner |  photo                |
|  Modify Labels)      |        3D model                | (dial)  |  (name on the photo,  |
|                      |  (left-drag rotates,           |         |   resize grip at its  |
|  ...                 |   right-drag pans,             |         |   bottom-left corner) |
|                      |   wheel zooms,                 |         |                       |
|                      |   Ctrl+drag paints)            |         |  photo options        |
|                      |                                |         |                       |
+----------------------+--------------------------------+---------+-----------------------+
| hint line (what the mouse does now)                                                     |
| fine print: license, built date and mesh version, reviewed or not                       |
+-----------------------------------------------------------------------------------------+
```

**(Claude, to confirm)**
- Window: 1500 x 900 pixels at [60 60], resizable.
- Top bar: 36 pixels high; the pancake button 90 pixels wide with the text "☰ Menu"; Undo, Save and Exit 80 pixels each; Save bold, with a pale green background `[0.85 0.95 0.85]`; the status text fills the rest, read-only, 11 point.
- Left column (the open panel): 320 pixels wide, against the left edge, from under the top bar to the hint line. With no panel open, the column closes and the model takes its width.
- Model: fills the space between the left column and the spinner, white background.
- Spinner: about 190 pixels wide, its top level with the photo's top (as now).
- Photo column: the photo at its saved size (resizable with the grip), the photo options under it.
- Hint line: one line, gray `[0.35 0.35 0.35]`. Fine print: 10 point, gray `[0.4 0.4 0.4]`, red when the mesh is not reviewed.

## 4. The top bar

| Control | Kind | What it does |
|---|---|---|
| ☰ Menu | button | Opens the list of panels: Overall Display, Labels To Display, Lamps To Display, Modify Labels, Settings. The open panel's name has a check mark. Clicking the open panel's name again closes it. |
| Undo | button | Takes back the last click or stroke of paint (press again to go further back, newest first). Ctrl+Z. |
| Save | button | Applies the pending paint and saves the edits (`labelEdits_<ID>.mat`, used by the vehicle's script). The saved mesh becomes the working mesh: painted faces take their new label's look. With "Timestamped copy at each save" on (Settings), also keeps a timestamped copy. Ctrl+S. |
| Exit | button | Closes the window. With unsaved changes it asks first: "The label edits have changes that are not saved. Save them?" with **Save**, **Discard**, **Cancel** (Save is the default; Cancel keeps the window open). Built into the reviewer, Exit is not shown (the reviewer closes it). |
| status | text | How many faces are painted and not applied, how many changes since the last save, and the time of the last save. |

## 5. The panels

### 5.1 Overall Display

**(Sean)** The overall display choices for the mesh:
- **Colors:** label colors or vehicle colors: two radio buttons side by side, only one selected.
- **Show mesh boundaries?**
- **Nighttime view?**
- **See-through body** slider at the bottom.

**(Claude, to confirm)**

```
Colors                 (o) Labels   ( ) Vehicle
Show mesh boundaries   (o) Off      ( ) On
Nighttime view         (o) Off      ( ) On
View                   [Reset view     ]
                       [Copy view call ]
See-through body       |----o--------------------| 0 .. 90 %   (ticks 0, 45, 90)
```

| Control | Kind | Default | What it does |
|---|---|---|---|
| Colors | radio pair: Labels, Vehicle | Labels | Labels: each face in its label's color (body near-white, glass light blue, lamps in their colors). Vehicle colors: the colors the vehicle is drawn in by the animator. |
| Show mesh boundaries | radio pair: Off, On | Off | Draws the edges of the faces of the label picked in Labels To Display (all labels when all are shown), so the pieces can be seen. Works at night too. |
| Nighttime view | radio pair: Off, On | Off | The animator's night scene: dark checkered ground, dim light, lamps glowing with their pools of light on the ground. The first time it is turned on, all lamps switch on (unless a lamp was already set in Lamps To Display). |
| Reset view | button | | Puts the camera back to the starting view. (Moved here from the old tool row.) |
| Copy view call | button | | Copies to the clipboard a MATLAB call that opens the viewer with the current settings. (Moved here.) |
| See-through body | slider, 0 to 90% | 0 | Makes the body see-through, to see the interior and faces under it. |

### 5.2 Labels To Display

**(Claude, filled in from the current Labels list)** The list today: a radio button per label that shows that label alone (the others gray), a "Show" checkbox that hides that label's faces (to reach faces under them), and a colored swatch. Rows: All labels; body; glass; wheel; trim; interior; headlight (low beam); tail light; high beam; and, when the mesh has them, running light, turn signal, backup light, and hidden (not drawn).

**Proposed, in the rule-7 format** (see Q4 from the chat, carried here as open question Q7):

```
                          Colored?      Shown?
                          Yes   No     Yes   No
All labels                (o)   ( )    (o)   ( )
[■] body                  (o)   ( )    (o)   ( )
[■] glass                 (o)   ( )    (o)   ( )
[■] wheel                 (o)   ( )    (o)   ( )
[■] trim                  (o)   ( )    (o)   ( )
[■] interior              (o)   ( )    (o)   ( )
[■] low beam              (o)   ( )    (o)   ( )
[■] high beam             (o)   ( )    (o)   ( )
[■] running light         (o)   ( )    (o)   ( )      (gray italics: no faces)
[■] turn signal           (o)   ( )    (o)   ( )      (gray italics: no faces)
[■] tail light            (o)   ( )    (o)   ( )
[■] backup light          (o)   ( )    (o)   ( )      (gray italics: no faces)
[■] hidden (not drawn)    (o)   ( )    ( )   (o)
Gray names: no faces have this label yet.
```

- **Colored (Yes/No):** Yes draws that label's faces in its label color; No draws them plain light gray, so the colored ones stand out. Setting only one label to Yes is the old "show this label alone".
- **Shown (Yes/No):** No takes that label's faces out of view (not out of the mesh), to reach the faces under them. The hidden set is Shown = No by default.
- **All labels** sets every row at once; its buttons show the common setting (none selected when the rows differ: rule 20).
- Row order: the parts first (body, glass, wheel, trim, interior), then the lamps front to back (low beam, high beam, running, turn signal, tail, backup), then the hidden set(s), one row per hidden set name.
- The "Show mesh boundaries" edges (Overall Display) are drawn for every shown face (as built; edges for the Colored = Yes labels only can come later if wanted).

### 5.3 Lamps To Display

**(Claude, filled in from the current Lamps list)** The list today: Headlights (Low beams, High beams checkboxes), Running lights, Left turn signal, Right turn signal, Hazards (checkboxes), Tail lights (Off / On / Brake radios), Backup lights (checkbox), All on and All off buttons, and the note "Lit on the model by day; at night, with their light. 'no faces': none labeled; its light still shows."

**Proposed, in the rule-8 format:**

```
                          Status?
                          Off   On    3rd
[■] Low beams             (o)   ( )
[■] High beams            (o)   ( )
[■] Running lights        (o)   ( )               (gray italics: no faces)
[■] Left turn signal      (o)   ( )               (gray italics: no faces)
[■] Right turn signal     (o)   ( )               (gray italics: no faces)
[■] Hazards               (o)   ( )               (both turn signals)
[■] Tail lights           (o)   ( )   ( ) Brake
[■] Backup lights         (o)   ( )               (gray italics: no faces)
    All lamps             ( )   ( )
Lit on the model by day; at night, with their light too. Gray names: no faces have this lamp yet; its light still shows.
```

- The colored box is the lamp's lit color (low beam warm white, high beam cool white, running amber, turn amber at the front, tail and brake red, backup white).
- **All lamps** (Off/On) replaces the All on and All off buttons; neither is selected when the lamps differ (rule 20).
- Hazards On sets both turn signals On; turning either turn signal Off turns Hazards Off.
- More lamp types (fog, brake as its own lamp, license plate, marker, warning) join this list with task 8.

### 5.4 Modify Labels

**(Claude, filled in from the yellow tool rows, buttons turned into radio choices; save items moved to Settings as Sean asked)**

```
Paint as                       (pick one)
Main labeling:
[■] body                       ( )
[■] glass                      ( )
[■] trim                       ( )
[■] interior                   ( )
[■] wheel                      ( )
Bulb labeling:
[■] low beam                   ( )
[■] high beam                  ( )
[■] tail                       ( )
[■] running                    ( )
[■] turn signal                ( )
[■] backup                     ( )
Visibility labeling:
[■] hide                       ( )     Hide as: [hidden        ]
[■] unhide                     ( )
    none (rotate only)         (o)

Labeling behavior?
Mirror to the other side       ( ) Off  (o) On
Show hidden faces              (o) Off  ( ) On
[Apply]
How to paint: Ctrl+drag paints; Ctrl+Shift+drag erases; a click paints one face (click again to take it off);
a double-click paints a whole piece. Paint is pending (yellow edges) until Apply or Save. Hiding takes faces
out of view, never out of the mesh. To reach faces under others, set their label to Shown = No.
```

| Control | Kind | Default | What it does |
|---|---|---|---|
| Paint as | one radio button per label, one picked at a time | none (rotate only) | The label the mouse paints. With "none", the mouse only turns the view. The colored box is the label's color on the model; hide is magenta, unhide green. |
| Hide as | text box, beside "hide" | `hidden` | The hidden set the hide tool puts faces in (such as `hard top`); the animator can show a set again by name. |
| Mirror to the other side | radio pair Off, On | On | Paints the mirror-image faces on the other side too. Off for one-sided parts (a fuel door). |
| Show hidden faces | radio pair Off, On | Off | Shows the hidden faces (magenta), so they can be unhidden; they cannot be painted while out of view. |
| Apply | button | | Makes the pending paint part of the working mesh (hidden faces go out of view). |
| How to paint | text | | The mouse instructions above, always shown at the bottom of the panel. |

### 5.5 Settings

**(Sean: Save as version, Revert to save, the timestamped copy, and where copies go move here.)** **(Claude, to confirm: Revert to start joins them.)**

```
Save as version                [Save as version]
Timestamped copy at each save  ( ) Off  (o) On
Timestamped copies go in       [C:\...\meshVersions                  ] [Browse...]
Revert                         [Revert to save ]
                               [Revert to start]
Edits file                     C:\...\labelEdits_2009_Honda_Fit_Sport.mat   (text)
```

| Control | Kind | Default | What it does |
|---|---|---|---|
| Save as version | button | | Saves, and also keeps a timestamped copy (`<mesh name>_YYYYMMDDHHMMSS.mat`: the edits and the edited mesh) in the folder below. |
| Timestamped copy at each save | radio pair Off, On | On when the painter has an edits file | Every save also keeps a timestamped copy (two saves in the same second: the newer is kept). |
| Timestamped copies go in | text box and Browse... | the vehicle's `meshVersions` folder | Where the copies go; made if it does not exist; remembered for next time. |
| Revert to save | button | | Goes back to the last save; pending and applied paint since then is taken off. Asks first. |
| Revert to start | button | | Goes back to the mesh before any edits (Save makes it stick). Asks first. |
| Edits file | text | | The file Save writes (read-only). |

With no edits file (a mesh given as a variable), the save-related controls are grayed out.

## 6. The photo side (right)

**(Claude, to confirm)** As now, with its working options under the photo:
- The photo, named on its top edge (`ViewInDegrees_240.jpg`); a grip at its bottom-left corner resizes it, keeping its shape; the dial follows its edge.
- The spinner (dial): the vehicle from above with the photos' angles as dots; drag the red arrow around, or click a dot, to pick a photo; the model turns to the same angle.
- Photo options, under the photo: **Photo folder** (text, with Browse...), **Turn model with photo** (Off/On, default On), **Photo size** (Small/Medium/Large radios, beside the grip).

## 7. Behavior kept from the current window

- Mouse: left-drag rotates, right-drag pans, the wheel zooms (CAD-style, own handling, not MATLAB's rotate tool); Ctrl+drag paints; Ctrl+Shift+drag erases; click paints one face; double-click paints a piece.
- Pending paint shows yellow edges until applied.
- Edits are saved as Points (face centers), so they survive a rebuild of the mesh; Hide and Unhide are saved the same way.
- Built into the reviewer: the window is the reviewer's panel; the top bar keeps Undo and Save, and the reviewer's own Close replaces Exit.
- Hidden test hooks in the figure's `UserData` (for scripted tests without showing the window).

## 8. Open questions

**(Sean to Claude)**
S2C 1: The edits herein pertain to the GUI design itself primarily. But when this is done, please remind me to return to the question of how the interior mesh is generated. Most of the discrepancies in the Honda Fit appear to be in the interfaces between the Interior, Trim, and Body, and sometimes even with Glass. If we are the ones creating this definition in an earlier processing step, that step needs to be revisited, ideally to fix them before the user is put into this paintLabels interface.

Re **C2S 7**: Agree. Lets queue this change.

Re **C2S 8**: Agree with suggested changes (off/on option list) and let's add a warning text, if user selects all off: "All Off means never. No autosaves will be generated." Feel free to reword.

Re **Agreed order of work**: Agree with this ordering. Merge in changes from C2S 7 and 8 appropriately into these tasks or as new tasks, please.

**(Claude to Sean)**
- *Re S2C 1 (stays open as a reminder):* Claude will remind Sean when this GUI's edits are done. It now ties in with C2S 7 below: if "interior" keeps only the objects inside the cabin, the step that labels it changes too.

**(Claude to Sean)** No questions open from Claude (C2S 1 to 8 are closed into the change log). S2C 1 stays open above as a reminder.

**Plan of work** (agreed by Sean, 15:39; C2S 7 and 8 merged in):
- **P1. The GUI test vehicle**, the painter's test on it, the demo menu's two items. *(Started 15:39.)*
- **P2. The GUI edits** of section 9, including: Labels To Display in groups, with the interior group shown as "objects within interior" (C2S 7); timestamped copies as Off/On rows ("At each save?", "Every 10 minutes?", "When the paint label changes?"), with the warning "All off: no timestamped copies will be made." when all are off (C2S 8); the recovery file of unsaved paint and its folder (C2S 4); then a T1, T2 ... test list for Sean.
- **P3. Body color** (saved with the vehicle's edits, C2S 1), the color picker, the contrast shift, GUI colors.
- **P4. Lamp covers:** clear covers, glowing with the lit lamp under them (C2S 6).
- **P5. Interior objects** (C2S 7): sub-labels seat, steering wheel, console under `interior` (`FaceSubPart`, `SubPartNames`); cabin surfaces no longer labeled interior; automatic interior labeling off by default; later rewritten to find only the seats, wheel and console (with S2C 1, the interior review, and task 9, the steering wheel). Needs a library rebuild, so it waits until P1 to P4 are done.

## 9. Open issues

**(Sean to Claude)**
For the GUI testing, the Honda Fit is missing some key elements (hidden faces, certain light bulbs, etc.). Can you create a generic test vehicle that has all the features, only for the purpose of exercising the GUI? We should keep that mesh somewhere and incorporate it as part of the unit tests for the GUI. The Fit model does not seem completely suited for this. Make a note, in an upcoming task, to do the same for the viewer. In the main script_demo menu interface for the repo, please edit the script_demo menu items to change the current option to one that repeats the paintLabels test calls as two menu choices - one for the generic test vehicle, and one for the Honda Fit.

In the "Overall Display" panel:
- When GUI opens, have Overall Display open by default.
- Under the vehicle radio button, we should list: "Body color string: [textbox] [buttonColorWheelSelector]. The colorstring is an editable box that allows the user to specify normalized [R G B] vector, e.g. [0 0 1] for all blue. Whatever the current body color is, should be shown there. Because the user may not know this string, the buttonColorWheelSelector throws up a small GUI interface (we should make this a helper function, and push this into DebugTools or similar, as an action item later). That GUI shows a standard color wheel, and lets the user select a color to use. If user accidentally picks a color that is equal to the mesh boundary, wheel, trim, etc., then the color for the mesh boundary, wheel, trim, etc. is shifted slightly but sufficiently so that the associated element is still visible against the body color background, if the user chooses such visibility.
- In the "Reset View", the default view should be from the vehicle's 60-degree perspective. In the settings Pancake, we can allow the user to change this, a setting that affects the GUI behavior and is set across all models thereafter. Add a "Someday" option to use the mesh alongside the photographs to attempt to align the mesh exactly to a photo view. If this is easy, move this request into the top-most tasking list item and as well assess the ability to use the same match to automatically correct and assign mesh labels using the images.
- If the user hits "Copy view call", a small text response should appear under the button that confirms the button press by describing where the copy results went.

In the "Labels to Display" panel:
- If possible, add subsection titles that group the labels listed matching these to the "Modify Labels". Subsections would be: main body panels (body, glass, wheel, trim), interior (interior), lights (low beam, high beam, etc.), visibility (hidden). The visibility and interior only have one member each, but this is likely to change. For example, in interior labels, we already know that we want or may need the steering wheel, to animate it turning. Other obvious items would be 'seat' labeling, as this determines driver / passenger / rear passenger viewpoints. For perspectives from the driver view, which may be used in virtual reality versions of this tool, we may need as well 'driver console' labels. In the 2009 Fit for example, the driver console mesh is clearly there as part of the import mesh, just not labeled clearly.

In the "Lamps to Display" panel:
- See queestion to Claude in "Open Questions"

In the "Modify Labels" panel:
- Let's reopen, at the top part of the sidebar, the Labels to Display. The reasoining: these will often be used for modifications to the painting. Underneath, as a separate panel (with the current off-yellow background), open the "Paint as" panel. The reason for displaying them both with different colors is that we want to differentiate normal viewing versus editing, while still exposing both functions at the same time. The yellow background of the "Modify" panel makes this very clear.  
- The "Hide as" text box is very unclear in its functionality. The mouse-over instructions are confusing. And once this is edited, it does not seem possible to go back to defaults. The "Hide as:" text could be renamed: "Hidden faces inheret the following label name:  ". 
- For the hidden text box, to not force the user to memorize the default value, the default entry (e.g. the suggested entry) should be shown as text underneath this entry box, for example " (default is "hidden") ".  Note: the default here should be settable for all GUI instances in the "Settings" menu.

In the "Photo" panel:
- The "Turn model with photo" radio button works but suggests we need it's dual one also: Turn photo with model. 
- Stylistically, radio box questions should end with "?". So "Turn model with photo" --> "Turn model with photo?". This instruction needs to be merged with the MD style guidelines, and as well fixed in the GUI throughout
- When "Photo size" is set to small, the panel itself gets cut off to where the "Large" radio button text is no longer visible.

In the "Settings" panel:
- Name should be "GUI settings" to disambiguate to the user that these are settings that set the GUI functionality thereafter. Bottom-most button should be "Reset to defaults", so that a user can revert to normal behavior after making changes across many edits.
- Should expose options to the user that are used in the GUI such as background colors for day view, for night view, etc. Use the colorwheel interface where appropriate to guide the user to correct RGB color strings.
- Let's rename "Save" as "Save behavior", and "Revert" to "Revert behavior" . This suggests we need to add a top-level button that is "Revert to prior save" - this could be a very useful functionality when using the GUI.
- In the "Timestamped copies go in:", let's clarify this a bit and say something like "Folder for timestamped copies". We should put all the folder-save locations in the exact same format, stacked right next to each other. We should expose and let the user select as well, the "Folder for temp save of mat files". Please add any others as appropriate.
- For the "Timestamped copy each save" prompt, this is confusing. Something better would be: "Timestamped saves are made every?" and then list radio button options that are obvious: Each save, each switch to a different label paintbrush, every 10 minutes, (etc)

Please review each of the above selections critically, and suggest improvements as appropriate.

**(Claude to Sean)** Review of the open issues, item by item. "Agree" means Claude builds it as written; anything else is a suggestion or a question (C2S, in section 8).

*GUI test vehicle.* Agree, and it is the right first step: the Fit has no running, turn or backup faces and only 7 hidden faces. Proposal: a vehicle folder `Data/Samples/2026_CarMesh3D_Sample_GUITestVehicle`, made by a script from the built-in sample sedan (`fcn_CarMesh3D_fillSampleMesh`), with every part (body, glass, wheel, trim, interior), all six lamp types on both sides (low and high beams, running, turn, tail, backup), a glass cover over a lamp, a lamp with two functions, two hidden sets ('hidden' and 'hard top'), and its own photos: pictures of the test vehicle itself rendered every 30 degrees as `ViewInDegrees_<angle>.jpg`, so the dial and photo options are exercised too. Its files are small and made by its script, so they can live in git and the tests can always rebuild them. The painter's test then runs on it (the Fit stays as a second, real case), and a matching task is queued for the viewer. The demo menu gets two items: "paintLabels: GUI test vehicle" and "paintLabels: 2009 Honda Fit".

*Overall Display.*
- Open by default: agree. This replaces "remember the open panel" (rule 17): the painter always opens at Overall Display.
- Body color: agree with the text box plus a picker button. Suggestion: use MATLAB's own color picker, `uisetcolor`, now (it is built in and works from a uifigure), and build the color-wheel helper for DebugTools as a later item; the button calls whichever exists. The box takes `[r g b]` from 0 to 1 and refuses anything else with a message. Contrast: when the body color is close to the trim, wheel, glass or mesh-boundary color (closer than a set color distance), those are shown lighter or darker by just enough to stand out, by day only, in this window only; the saved mesh is not changed by that shift. Where the body color itself goes is C2S 1.
- Reset view at 60 degrees: agree; the angle is a GUI setting. What "60-degree" means is C2S 2.
- Photo-to-mesh alignment (Someday): not easy. Matching a photo needs the camera's position, aim and focal length found from the picture, which needs the vehicle's outline found in the photo (cars against real backgrounds are hard to cut out without a trained model). A manual version is easy, though: drag the model until it lies over the photo (a see-through overlay), as `fcn_CarMesh3D_plotSideImage` already does for side photos. Correcting labels from photos is harder still (colors in photos change with light and reflections). Claude suggests: Someday for automatic alignment and label correction; the manual overlay as a possible near-term item. Not moved to the top.
- Copy view call: agree: a gray line under the button, "Copied to the clipboard (and printed in the command window).", for a few seconds.

*Labels To Display.* Agree with the four groups (main body panels, interior, lights, visibility). Steering wheel, seats and driver console are new interior sub-labels; how the mesh stores them is C2S 3. The rows for them appear in gray ("no faces") until a vehicle has them.

*Lamps To Display.* The question here is S2C 2 (answered above).

*Modify Labels.*
- Labels To Display on top, Paint as underneath on yellow: agree. With about 30 rows the panel scrolls; Claude will make the label rows in it compact (the same controls, 20 pixels a row).
- "Hide as": agree it is unclear. Claude's suggestion for the wording: it is not a label but the name of a group of hidden faces, so "Put hidden faces in the set named:" with a box below, and under it "(default is "hidden"; sets can be shown again by name)". Better still, an editable drop-down (`uidropdown` with Editable on): it lists the sets the vehicle already has, and a new name can be typed. The default is a GUI setting.

*Photo panel.*
- "Turn photo with model?": agree; it already happens (turning the model moves the arrow and the photo), so this makes it a switch. Both are questions now: "Turn model with photo?" and "Turn photo with model?".
- "?" at the end of radio-button questions: agree; rule 22, applied everywhere.
- Small photo cuts off "Large": the options panel is as wide as the photo. Fix: the photo column never narrower than the options need (about 360 pixels); a small photo sits centered in it.

*Settings, renamed "GUI settings".*
- Agree with the name and "Reset to defaults" at the bottom.
- Colors (day background, night sky, night ground, mesh-boundary color): agree, each with the color picker.
- "Save behavior" and "Revert behavior" as headings: agree. A top-bar button "Revert to prior save": agree; the top bar becomes Undo, Save, Revert to prior save, Exit (rule 5 updated). It asks first.
- Folders, stacked in one format (a heading, a box, Browse, and the default under it in gray): edits file, timestamped copies, photos, and the temp-save folder (what this holds is C2S 4). Claude suggests also the vehicle's cache folder, read-only, since a stale cache explains odd results.
- "Timestamped saves are made every?": agree with the question. Claude's suggestion for the choices: "Never", "Each save", "Each save and every 10 minutes". Each switch of the paint label would make many copies quickly (a copy is the whole edited mesh, about 2 MB for the Fit). See C2S 5.

*Rules for questions in these files.* Added to `claude/how_we_work.md` (the S2C and C2S numbering, closing answered questions into the change log with their thread, and the T1, T2 ... test sequence after GUI changes).

**(Claude to Sean)** Proposed order of work (Claude will start with P1 once Sean agrees, or with Sean's changes to it):
- **P1. The GUI test vehicle**, the painter's test on it, the demo menu's two items (about 1.5 hours).
- **P2. The GUI edits above**, except the color picker and colors (about 2.5 hours), then a test sequence T1 ... for Sean.
- **P3. Body color, color picker, contrast shift, GUI colors** (about 1.5 hours).
- **P4. Lamp covers:** clear covers (Q1 (A)) and covers glowing with the lit lamp under them (S2C 2) (about 2 hours).
- **Then:** the interior-labeling review (S2C 1, a reminder to Sean); the viewer's own design file and test vehicle; Someday: automatic photo alignment and label correction; the DebugTools color wheel.



As a process, please add this ruleset to the project: when working with MD files to pose questions back and forth, use section highlights as **(Claude to Sean)** and **(Sean to Claude)** for open questions. Feel free to include comments within the questions area to frame questions and add clarifications. The questions section can include comments about past questions or new questions. Be sure to number the questions in Sean-to-Claude (S2C) or Claude-to-Sean (C2S) formats when posting or replying to prior questions, so Claude questions to Sean would appear as: (C2S 1, C2S 2, etc.) . Do not take questions off the open questions list until they are answered, and when taking them off put the question, context (including thread back/forth), and final answer into the change log. For GUI design work, fter making changes, Clause should clearly list what specific items should be reviewed in terms of functionality in a listed test sequence (T1, T2, T3, etc.). This ensures clarity of the items Claude can test, and which things require Sean's interaction testing.

## 10. Change log

- 2026-11-23 10:05: started (Sean's guidelines; Claude's fill-ins from the 04:35 window).
- 2026-11-23 10:24 (Sean's review):
  - Column headers as questions: "Colored?" and "Shown?" (Labels To Display), "Status?" (Lamps To Display).
  - Paint as grouped under headings: **Main labeling** (body, glass, trim, interior, wheel), **Bulb labeling** (the lamps), **Visibility labeling** (hide, unhide, none); the switches under them headed **Labeling behavior?**
  - **Q5 closed, (A):** Off/On radio pairs everywhere, Show mesh boundaries and Nighttime view included. (A single MATLAB radio button cannot be clicked off: setting a lone radio button's Value to false gives "'Value' cannot be set to false because it is the only component of class RadioButton in the container"; checked in MATLAB R2025b, 10:07.)
  - **Q6 closed, (A), later:** `fcn_CarMesh3D_viewLabels` gets the same panels and rules, after this window is finished, with its own design file (Documentation_CarMesh3D_GUIdesign_viewLabels.md), made once this one is confirmed.
  - **Q7 closed, (A):** Labels To Display has two columns, Colored? (Yes/No) and Shown? (Yes/No).
- 2026-11-23 10:29 (Claude, the mockup): built `zz_mockup_paintLabels.m` and pictures of each panel. Changes it led to: the left column 320 pixels (rule 21); "(no faces)" shown as gray italic names with one note under the list (rule 13); rows that set others use an unseen third button for the mixed state (rule 20); View and Revert buttons stacked, one per line.
- 2026-11-23 10:48 (Sean): mockup approved ("a great start"); build the window.
- 2026-11-23 11:05 (Claude, the build):
  - `fcn_CarMesh3D_paintLabels` rebuilt to this file: the menu and five panels, the top bar (Undo, Save, Exit; Exit asks to save), radio pairs throughout (no check boxes left in the panels), Colored?/Shown? per label (All with the mixed state), Status? per lamp, Paint as in three groups with "none (rotate only)", Settings with revert asking first, Ctrl+Z and Ctrl+S, the open panel remembered (preference `CarMesh3D`/`PainterPanel`).
  - `fcn_CarMesh3D_viewLabels` got hooks for it (labels drawn plain gray, boundaries, single lamps, label kinds, lamp types, copy view call, a lamp-change callback) and the photo options under the photo (`PhotoOptions=true`: folder with Browse, Turn model with photo, Photo size Small 220 / Medium 300 / Large 420 pixels, with an unseen fourth button when the corner is dragged to another size). The viewer on its own is unchanged until its own design file.
  - Differences from the text above: "Vehicle colors" is shown as "Vehicle" (the longer text did not fit the 320-pixel panel); mesh boundaries are drawn on every shown face; inside the Model Reviewer the panels start closed (its display area is narrow, and the model had no room with a panel open), and Exit is not shown there.
  - New painter hooks for scripts and tests: `OpenPanel`, `Panel`, `SetMirror`, `Mirror`, `SetVersions`, `Versions`, `SetShowHidden`, `ShowHidden`.
- 2026-11-23 13:12 to 15:23 (questions closed; each with its thread):
  - Sean's answers of 15:23, as he wrote them:

    **(Sean to Claude)**
    - *Re C2S1: option (A) seems best
    - *Re C2S2: option (A) is what was meant, e.g. as read on the dial and between ahead and from the left views
    - *Re C2S3: option (B) because we do not want to force user to always label interior. The automatic tool separating out interior might not be working correctly, and errors are caused at interfaces between body, glass, trim and interior. Seats, console, and steering wheel are only items of interest, and except for console, all are far away from edge boundaries. A compromise solution (A+B) would be to create a sub-label but allow interior to include only these robustly-defined elements, e.g. renaming "interior" to "objectsWithinInterior", since the interior label would otherwise be incorrect.
    - *Re C2S4: option (B) is what was meant, but (A) could encompass (B) and if so, is better suggestion.
    - *Re C2S5: option (A) plus "Each time a paintbrush is switched" (suggest better wording please). Also, the options might be in an OR logic ladder format: Timestamped copies made by any of the following events: (never), "Each save", "Every 10 minutes", "Each swich of a label paint". I don't see how to do this well without using checkboxes. This can be a rare violation of the "no checkboxes" rule, however.
    - *Re C2S6: option (A) yes, let's solve this now

  - **S2C 2 → C2S 6, closed (A):** Sean (13:12): when the lights are on, the glass over a bulb glows with the bulb's color; let the glass inherit the color of the nearest lit bulb under it; is it easy? Claude (13:15): moderately; each glass face over a lamp records the lamp it covers when labeled; when that lamp is lit the cover is tinted its lit color, about 35% see-through, day and night; about 2 hours with the clear covers. C2S 6: now (A) or Someday (B)? **Sean (15:23): (A), solve it now** (task P4).
  - **C2S 1, closed (A):** where a body color typed or picked in Overall Display goes. **Sean: (A), saved with the vehicle's edits (`labelEdits_<ID>.mat`)**, so later builds and animations use it.
  - **C2S 2, closed (A):** what "the vehicle's 60-degree perspective" is for Reset view. **Sean: (A), 60 degrees on the dial, between "ahead" and "from the left"** (Claude adds: looking 20 degrees down; both a GUI setting).
  - **C2S 3, answered (B) with a compromise, continued as C2S 7:** how to store interior sub-labels (steering wheel, seats, console): (A) a new sub-part field; (B) new part names. **Sean: (B), because users should not be forced to always label the interior, and the automatic interior step errs at the borders with body, glass and trim. Seats, console and steering wheel are the only items of interest, and except for the console all are far from those borders. Compromise (A+B): sub-labels, with "interior" holding only these well-defined objects, e.g. renamed "objectsWithinInterior", since the interior label would otherwise be wrong.**
  - **C2S 4, closed (A, including B):** what the "temp save" folder holds. **Sean: (B), the vehicle's cache folder, was meant; (A), a recovery file of unsaved paint, can include it and is better.** So GUI settings show the recovery folder (editable) and the cache folder (read-only).
  - **C2S 5, answered, continued as C2S 8:** choices for timestamped copies. **Sean: (A) plus a copy each time the paint label is switched (better wording wanted), as events joined by OR: never, each save, every 10 minutes, each switch of paint label; check boxes may be a rare exception to the no-check-box rule.**
- 2026-11-23 15:27 to 15:39 (closed):
  - Sean's answers of 15:39, as he wrote them:

    Re **C2S 7**: Agree. Lets queue this change.

    Re **C2S 8**: Agree with suggested changes (off/on option list) and let's add a warning text, if user selects all off: "All Off means never. No autosaves will be generated." Feel free to reword.

    Re **Agreed order of work**: Agree with this ordering. Merge in changes from C2S 7 and 8 appropriately into these tasks or as new tasks, please.

  - **C2S 7, closed (A):** Claude (15:27): `interior` keeps its code name (saved meshes, `fcn_CarMesh3D_plotVehicle` and AnimateCar3D keep working) but is shown as "objects within interior" and means only objects inside the cabin, with sub-labels seat, steering wheel, console; cabin surfaces go back to their download labels; automatic interior labeling off by default, rewritten later to find only those objects. (A) as above; (B) also rename the key to `objectsWithinInterior`. **Sean (15:39): "Agree. Lets queue this change."** Queued as P5.
  - **C2S 8, closed (A):** Claude (15:27): one Off/On row per event in place of check boxes ("At each save?", "Every 10 minutes?", "When the paint label changes?"; all off means never), keeping rule 10. **Sean (15:39): agreed, with a warning when all are off: "All Off means never. No autosaves will be generated." (reword freely).** Worded in P2 as "All off: no timestamped copies will be made."
  - **Order of work: Sean (15:39): agreed, with C2S 7 and 8 merged in** (P2 and P5 above).
- 2026-11-23 18:02 (Sean, Q20 (A)): rule 25 added, from Sean's viewLabels answer to C2S 4 ("All input arguments should be in some way presented in the GUI"), made a rule for every CarMesh3D window.
- 2026-11-23 22:20 (Sean, 22:15): rule 26 added (a progress bar for anything over 2 or 3 seconds; errors shown in the window), for every CarMesh3D window.
