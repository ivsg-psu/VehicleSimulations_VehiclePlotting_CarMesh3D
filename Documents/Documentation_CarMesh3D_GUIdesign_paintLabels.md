# Design: the label painter, `fcn_CarMesh3D_paintLabels`

*The style and layout choices for the label painter, kept so the window can be rebuilt from this file. Edit it freely: it is the place to change the design, and Claude builds from it. Started 2026-11-23 10:05 from Sean's guidelines; Claude filled in the lists from the window as built on 2026-11-23 (04:35 version). Last updated 2026-11-23 11:05.*

**Status:** BUILT (11:05) in `fcn_CarMesh3D_paintLabels`, with hooks added to `fcn_CarMesh3D_viewLabels`; approved by Sean from the mockup (10:48: "a great start"; minor changes may come). The layout-only mockup stays in `Desktop\Claude\Project_CarMesh3D\tools\zz_mockup_paintLabels.m`; pictures of the built window are in `Desktop\Claude\Project_CarMesh3D\pictures\painter_build`. Sections marked **(Sean)** are Sean's words or decisions; **(Claude, to confirm)** marks Claude's fill-ins, accepted with the mockup.

---

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

*(none open)*

## 9. Change log

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
