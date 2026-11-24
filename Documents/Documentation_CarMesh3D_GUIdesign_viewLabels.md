# Design: the label viewer, `fcn_CarMesh3D_viewLabels`

*The style and layout choices for the label viewer, kept so the window can be rebuilt from this file. Edit it freely: it is the place to change the design, and Claude builds from it. Started 2026-11-23 15:50 by Claude from the window as built (`fcn_CarMesh3D_viewLabels.m`, last changed 2026-11-23 11:00, and its picture `Images/functions/fcn_CarMesh3D_viewLabels.png`, taken 09:23; the window on its own has not changed since the picture).*

**Status:** REVIEWED by Sean 2026-11-23 18:01 (C2S 1 to 6 answered; see the change log). Section 4 describes the window as it is today; section 5 is the agreed design, to be built after the painter is finished. Sections marked **(Sean)** are Sean's words or decisions; **(Claude, to confirm)** marks Claude's fill-ins.

---

## 1. What the window is for

The viewer is for **looking** at a vehicle's labels: the 3D model with each label in its own color (or in the vehicle's own colors), next to photos of the real vehicle picked by viewing angle on a dial. It changes nothing in the vehicle's files. When it is closed, it returns its **view settings** (camera, labels shown, colors, photo, night view and lamps), and "Copy view call" puts a MATLAB call on the clipboard that opens exactly the same view, so one person can send a problem spot to another.

It is used three ways:
- **On its own:** `fcn_CarMesh3D_viewLabels(meshFile)`, where `meshFile` is a vehicle's mesh `.mat` file (or a timestamped copy from the painter), or a mesh variable. It waits until closed and returns the view settings.
- **From the library browser:** the **View** button on a vehicle's row (`fcn_CarMesh3D_browseLibrary`) opens it on that vehicle's mesh file, with its 2D outline, without waiting.
- **Inside the label painter** (`fcn_CarMesh3D_paintLabels`), which builds it into its own window (`Parent=`) and drives it through hooks. The painter is itself built into the Model Reviewer (`fcn_CarMesh3D_reviewVehicle`, Labels check), so the viewer is inside the reviewer only through the painter. A fix to the viewer is a fix in all three places.

## 2. General rules for the whole window

**(Sean)** The painter's general rules apply to this window as written: see [Documentation_CarMesh3D_GUIdesign_paintLabels.md, section 2](Documentation_CarMesh3D_GUIdesign_paintLabels.md#2-general-rules-for-the-whole-window) (rules 1 to 24). They are not repeated here. Sean decided on 2026-11-23 (the painter's Q6, option A, 10:24) that the viewer gets the same menu-and-panels layout and rules as the painter, after the painter is finished, with its own design file: this file.

**(Sean, 2026-11-23) Rules for this window only:**

V1. **The viewer never changes a file.** It has no Undo, no Save, and no question on exit. Its top bar is the pancake menu and Exit (C2S 2).
V2. **Its panels are the painter's viewing panels** (Overall Display, Labels To Display, Lamps To Display, GUI settings), the same controls, in the same order, with the same words and the same pale blue band; there is no Modify Labels panel. The viewing panels are built once, in `fcn_CarMesh3D_viewLabels`; the painter uses them and adds its own panels to the same menu through a hook, so a fix to a panel is a fix in both windows (C2S 1).
V3. **The view settings stay the window's memory.** What the user sets (camera, labels, colors, lamps, photo) is returned by the call and put in the view call, as now; MATLAB preferences hold only GUI settings (rule 17, as changed by the painter's open issue: the window always opens at Overall Display).
V4. **Old view calls keep working.** A view call copied before the change opens the same view after it: the settings keep `Label` and `Hidden` and add `Uncolored` (C2S 3).
V5. **Built into a host, the host decides** which parts show: the tool row (now `ShowTools`), the photo options (`PhotoOptions`), the lists (`LabelListParent`), the hint line (`OnHint`), as today.
V6. **(Sean) Every input argument is shown in the GUI in some way** (painter rule 25, for every window), so what a call can set, the window can show or set too. Photo options are therefore on by default in the viewer's own window (`PhotoOptions` default true); a host can still turn them off. (C2S 4)
V7. **Every label is listed, as in the painter** (rule 13): labels the mesh does not have appear with gray italic names. (C2S 5)
V8. **One starting view for both windows:** a GUI setting, 60 degrees on the dial and 20 degrees down, used to open and by Reset view; opening at a photo or at given view settings still wins. (C2S 6)

## 3. Layout

### 3.1 As built today (2026-11-23)

```
+------------------------------------------------------------------------------------------------------+
| fcn_CarMesh3D_viewLabels                    (title bar, 50 px: version line | vehicle name)          |
+------------------------------------------------------------------------------------------------------+
| Labels (235 px)       | Colors: (o)Labels ( )Vehicle colors [Reset view] [Copy view call] [ ]Show   |
|  ( ) All labels       |  mesh boundaries [ ]Nighttime view  See-through body: |--o----| [Close]      |
|  ( ) body    [x] [■]  +---------------------------------+-----------------+------------------------+
|  ( ) glass   [x] [■]  |                                 |   photo dial    |  photo                 |
|  ...                  |        3D model                 |   (300 px wide, |  (300 px high at the   |
|  ( ) hidden  [ ] [■]  |   (white, fills the rest)       |    220 px ring, |   start, width by its  |
|  (fills the rest)     |                                 |    level with   |   shape; name top      |
+-----------------------+                                 |    the photo's  |   right; resize grip   |
| Lamps (350 px)        |                                 |    middle)      |   bottom left)         |
|  Headlights           |                                 |                 |                        |
|  [ ] Low beams  ...   |                                 |                 |                        |
|  [All on] [All off]   +---------------------------------+-----------------+------------------------+
|  note                 | hint line (22 px, gray, HTML)                                                |
|                       | fine print (28 px, 10 pt: license, build, review; dark red when not reviewed) |
+-----------------------+------------------------------------------------------------------------------+
```

- Window: `uifigure`, 1500 x 860 pixels at [60 60], named `fcn_CarMesh3D_viewLabels: <vehicle name>`; resizable.
- Title bar: `fcn_CarMesh3D_addTitleBar` (50 px; the function name 22 pt bold; "Version: fcn_CarMesh3D_viewLabels.m, last modified ..." with the vehicle's name after a bar).
- Under it a grid of two columns: **235 px** (the lists) and the rest (the viewer), padding 6, spacing 6.
- The viewer column is four rows: the tool row **34 px** (0 with `ShowTools=false`), the display (rest), the hint line **22 px** (0 when a host takes the hints), the fine print **28 px** (0 with no history).
- The tool row, pale blue `[0.93 0.95 1]`, columns 60, 210, 100, 130, 175, 120, 130, 150, rest, 80 px.
- The display: with photos, three columns: the model (rest), the dial (**300 px**), the photo (its height x its width/height ratio; **300 px** high at the start), white, spacing 4. With no photos, the model alone.
- The list column: the Labels box (rest of the height, scrolls) over the Lamps box (**350 px**, scrolls), spacing 4.

### 3.2 Agreed (2026-11-23)

The painter's layout (its section 3) without the paint parts:

```
+-----------------------------------------------------------------------------------------+
| fcn_CarMesh3D_viewLabels            (title bar: version, vehicle name)                  |
+-----------------------------------------------------------------------------------------+
| [☰ Menu]  [Exit]           status: "Labels colors | 2 labels not shown | night: off"    |
+----------------------+--------------------------------+---------+-----------------------+
| (open panel, e.g.    |                                | spinner |  photo                |
|  Overall Display)    |        3D model                | (dial)  |                       |
|  320 px              |                                |         |  photo options        |
+----------------------+--------------------------------+---------+-----------------------+
| hint line                                                                               |
| fine print                                                                              |
+-----------------------------------------------------------------------------------------+
```

- Window 1500 x 860 as now; top bar 36 px, as the painter's; the left column 320 px when a panel is open, closed otherwise (rule 21).
- The tool row goes away: its controls move into Overall Display (as in the painter).
- The status text is read-only (rule 12) and only says what the view is now. (Claude, to confirm in the mockup: keep it or leave it out.)

## 4. The window as built today

### 4.1 The tool row (top, pale blue)

| Control | Kind | Default | Tooltip | What it does |
|---|---|---|---|---|
| Colors: Labels / Vehicle colors | radio pair in a button group | Labels | (none) | Labels: each label in its own color (from `fcn_CarMesh3D_plotLabels`), with the glass as see-through as the vehicle's own glass. Vehicle colors: the mesh's `FaceColors` and `FaceAlpha`. |
| Reset view | button | | (none) | Back to the view it opened with. The first time, the opening view is made: `view(-40, 20)`, axis equal, vis3d, then the camera frozen. |
| Copy view call | button | | "Put the MATLAB call that opens exactly this view on the clipboard, to send to someone" | Puts the view call on the clipboard, prints it in the command window, and says so in the hint line ("The call that opens this exact view is on the clipboard: paste it into MATLAB, or send it."; if the clipboard fails: "The clipboard is not available; the call is in the command window."). |
| Show mesh boundaries | check box | off | "Draw the edge of every face (the mesh's triangles)" | Draws the faces' edges (dark gray, 35% opaque, 0.25 wide); with labels hidden, the edges fade with their faces. Works at night too (light gray edges on the vehicle, none on the ground). |
| Nighttime view | check box | off | "A night scene: the vehicle in its own colors, its lamps lit, and the light they throw on the ground. The lamp list switches the lamps." | See 4.6. |
| See-through body | slider 0 to 90 (%), ticks 0, 45, 90% | 0 | on its name: "Makes the body see-through, to look at (and click) what is inside it" | Multiplies the body faces' opacity by (1 - value). |
| Close | button | | (none) | Closes the window and returns the view settings. Not shown when built into a host. The window's close box does the same. |

### 4.2 The Labels list (left, top)

A button group titled "Labels", scrolling, one row per label, rows 24 px apart:

```
(o) All labels
( ) body                       [x] [■]
( ) glass                      [x] [■]
...
( ) hidden (not drawn)         [ ] [■]
```

- **The radio button** (160 px wide) picks one label to see **alone**: its faces in their color, every other face light gray `[0.88 0.88 0.88]` and opaque. "All labels" colors every label. Picking **interior** is special: the glass is drawn nearly clear (`[0.80 0.88 0.96]`, 12% opaque) and the interior strong orange `[1.00 0.50 0.05]`, so it can be seen through the windows.
- **The Show box** (tooltip "Show these faces (untick to hide them, to see the faces under them)"): unticked takes that label's faces out of view (opacity 0), not out of the mesh. A face with several labels (a lamp's clear cover, which is light and glass) stays while any of its labels is shown.
- **The swatch** (16 x 16, tooltip "This label's color on the model"): the color most of the label's faces have. The name is drawn bold in the same color, or darker (45%) when the color is too pale to read on white.
- **Rows** (only labels that have faces): the parts other than light, in the mesh's `PartNames` order (body, glass, wheel, trim, interior ...); then each light type that has faces: "headlight (low beam)", "high beam", "turn signal light", "running light", "tail light", "backup light"; then "light with no type" (light faces with no type), if any; then "hidden (not drawn)" for faces in a hidden set (`FaceHiddenSet`), if any and if no host decides the hidden faces.
- **Hidden faces start out of view**: the "hidden" row's Show box starts unticked (unless the call or view settings say otherwise).

### 4.3 The Lamps list (left, under the labels)

A panel titled "Lamps", 350 px, scrolling:

| Control | Kind | Default | What it does |
|---|---|---|---|
| Headlights | bold heading | | |
| Low beams | check box | off | Lights the headlight faces warm white `[1.00 0.96 0.78]`. |
| High beams | check box | off | Lights the high-beam faces white; a vehicle with no high-beam faces lights its headlights white instead (the box then reads "High beams (in the headlights)"). |
| Running lights | check box | off | Running-light faces `[1.00 0.98 0.90]`. |
| Left turn signal, Right turn signal | check boxes | off | Turn-signal faces amber `[1.00 0.55 0]`, each side alone (left is y > 0); a turn signal that is also a tail light flashes red. |
| Hazards | check box (tooltip "Both turn signals at once") | off | Sets both turn signals; it shows ticked only when both are on. |
| Tail lights | bold heading, then radio buttons Off / On / Brake | Off | On: dark red `[0.70 0.04 0.04]`; Brake: red `[1.00 0.12 0.08]`. |
| Backup lights | check box | off | Backup faces white. |
| All on, All off | buttons | | Every lamp on (tail On), or every lamp off. |
| note | gray text, 11 pt | | "Lit on the model by day; at night, with their light. "no faces": none labeled; its light still shows." |

- A lamp type with no labeled faces keeps its row, with " (no faces)" after its name; it can still be switched (at night its light on the ground still shows).
- By day, lit lamps are drawn in their lit color, solid. When several functions share a face, the later of backup, running, low beam, high beam, tail, turn signal wins.
- The lamps start off. The first time the night view is turned on, all lamps switch on, unless the lamps were already set (by the list or the view settings).

### 4.4 The photo, the dial and the photo options (right)

- **Photos** are the files `ViewInDegrees_<angle>.jpg/.jpeg/.png` in the photo folder (default: the folder `photos` beside the mesh file; `PhotoFolder=` to give another). One photo per angle; other files are ignored. With no photos, there is no dial and no photo; the model takes the whole width.
- **The photo** fills its box, its name in a white box at its top right (13 pt bold). A grip "◣" at its bottom-left corner (tooltip "Drag this corner to resize the photo") resizes it, keeping its shape: the top right corner stays, the photo never shorter than the dial's ring (220 px), never taller than the display, and the model keeps at least 220 px.
- **The dial** (300 px wide, its ring 220 px, kept level with the photo's middle): the vehicle from above (its 2D outline if given with `Outline=`, else the mesh's outline with boxes for the tires), front to the right, a small red triangle for the front; a gray ring with a dot per photo and its angle; the four sides in words ("0° from ahead", "90° from the left", "180° from behind", "270° from the right"); a red arrow for the camera. The photo shown has a red, larger dot.
- **Dragging the arrow** (press anywhere on the dial) shows the nearest photo and turns the model to the same side (elevation kept between 5 and 30 degrees); letting go snaps the arrow to the photo's own angle.
- **Turning the model** moves the arrow and the photo: a timer checks the camera four times a second (rotating sends no event) and is stopped when the window closes.
- **Photo options** (only with `PhotoOptions=true`, as the painter asks): a pale blue panel "Photo" under the photo, three rows of 24 px, columns 150, rest, 80:

| Control | Kind | Default | Tooltip | What it does |
|---|---|---|---|---|
| Photo folder | text (`...\<vehicle>\photos`, full path in its tooltip) and Browse... | the folder found | "Where the ViewInDegrees_<angle> photos are"; Browse: "Pick another folder of ViewInDegrees_<angle> photos" | Loads the photos of another folder; a folder with none is refused with a hint, and the photos are kept. |
| Turn model with photo | radio pair Off, On | On | "On: picking a photo on the dial turns the model to the same side" | Off: the dial changes the photo only. |
| Photo size | radios Small (220), Medium (300), Large (420 px high), and an unseen fourth selected when the corner was dragged to another size | Medium | "The photo's height (its corner can also be dragged)" | Sets the photo's height. |

### 4.5 Mouse and keyboard

- In its own window (CAD-style, the viewer's own handling; MATLAB's axes toolbar and interactions are off): **left-drag rotates** (0.5 degree per pixel, `camorbit` about the vertical axis, so the vehicle stays upright), **right-drag pans**, **the wheel zooms** (x1.15 a click) when the mouse is over the model. Pressing on the photo's grip resizes the photo; pressing on the dial drags the arrow.
- In a host window, the host handles the mouse and calls `GripDown`, `DialMove`, `DialUp`.
- **No keyboard shortcuts.**

### 4.6 The nighttime view

The night scene of the animator's lights check (`fcn_CarMesh3D_animateChecks`): a dark sky `[0.04 0.05 0.09]`; a checkered ground of 2 m squares in two dark shades, 15 m past the vehicle on every side, just under its lowest point; a faint light from above; the vehicle drawn by `fcn_CarMesh3D_plotVehicle` (matte, its own colors, `LightEffects` on) with the lamps as the lamp list says, their glow and their pools of light on the ground. The label model and the day lights are hidden; the camera stays where it was. Labels hidden with the Show boxes are left out of the night vehicle (to take the glass off a lamp). The hint line says: "Nighttime view: switch the lamps in the lamp list; hide a label (its Show box, or Shown? No) to take it away (the glass over a lamp, say). Paint by day: turn the nighttime view off." Turned off, the night objects are deleted and the label colors return.

### 4.7 Hint line and fine print

- Hint line (gray `[0.35 0.35 0.35]`, HTML), at the start: "Mouse: left-drag rotates, right-drag pans, the wheel zooms. Pick a label at the left to see it alone; untick it to hide it. Photos: drag the red arrow around the vehicle; drag the photo's bottom left corner to resize it. "Copy view call" puts this exact view on the clipboard." With `OnHint=`, hints go to the host instead.
- Fine print (10 pt, gray `[0.4 0.4 0.4]`, dark red `[0.6 0.1 0.1]` when not reviewed or the review is out of date): `fcn_CarMesh3D_meshHistory`'s `FinePrint` (license, built date and mesh version, review). From the mesh file's history by default; `History=false` for none.

### 4.8 The call: options (Name=Value)

| Option | Default | What it does |
|---|---|---|
| `meshInput` (required) | | A mesh `.mat` file (the variable `vehicleMesh`, else the first labeled mesh in it), or a mesh variable. A vehicle ID is not accepted. |
| `ViewSettings` | [] | View settings returned before: open at that view (missing fields keep their defaults). |
| `Colors` | '' ('labels') | 'labels' or 'vehicle'; wins over ViewSettings. |
| `Label` | '' ('all') | The label shown alone (a key such as 'part_trim', 'light_tail'); wins over ViewSettings. |
| `Hidden` | [] | Label keys not shown; wins over ViewSettings. |
| `PhotoFolder` | [] (`photos` beside the file) | Folder of `ViewInDegrees_<angle>` photos. |
| `Outline` | [] | 2D outline (or its file) for the dial. |
| `Parent` | [] (own window) | A panel or grid to build into. |
| `LabelListParent` | [] | Where the lists go; default the left column in its own window, none inside a Parent. |
| `ShowTools` | true | false leaves out the tool row (the painter). |
| `OnHint` | [] | Function called with each hint (HTML). |
| `ColorFilter` | [] | `[colors, alpha] = f(colors, alpha)`, called at each redraw before hidden faces are cleared (the painter's paint). |
| `HiddenFaces` | [] | `flagHidden = f(keys)`: a host's own hidden faces (then no "hidden" row). |
| `History` | [] (the file's) | The mesh's history for the fine print; false for none. |
| `PhotoOptions` | false | The photo options under the photo (the painter sets true). |
| `OnLamps` | [] | Function called with the lamp states each time they change (the painter's lamp panel). |
| `Wait` | true in its own visible window | Wait until closed and return the settings then. |
| `Visible` | true | false builds it hidden (tests). |
| `FigNum` | [] | -1: fast mode, no input checks. |

### 4.9 Outputs and hooks

**`viewSettings`**: `MeshFile` ('' for a variable), `Camera` (CameraPosition, CameraTarget, CameraUpVector, CameraViewAngle, Projection, XLim, YLim, ZLim), `Label`, `Hidden`, `Colors`, `PhotoAngle` (NaN for none), `SeeThrough` (0 to 0.9), `MeshBoundaries`, `NightView`, `NightLights` (LowBeam, HighBeam, Running, TurnLeft, TurnRight, Tail 'off'/'on'/'brake', Backup), `PhotoHeight`. The view call is `fcn_CarMesh3D_viewLabels('<file>', ViewSettings=struct(...));` (numbers to 8 digits; `vehicleMesh` in place of the file for a mesh variable).

**`viewer`** (also in the figure's `UserData` in its own window):

| Group | Hooks |
|---|---|
| Handles | `Figure`, `Axes`, `Patch` |
| View settings | `GetView()`, `SetView(settings)`, `ViewCall()`, `CopyViewCall()`, `ResetView()` |
| Labels | `ShowLabel(key)`, `Label()`, `SetHidden(keys)`, `Hidden()`, `SetUncolored(keys)`, `Uncolored()`, `LabelKinds()` (keys and names in list order) |
| Drawing | `SetColors(mode)`, `Colors()`, `Redraw()`, `SetBoundaries(flag)`, `Boundaries()`, `SetSeeThrough(f)`, `SeeThrough()`, `SetMesh(mesh, labelColors, labelAlpha)` (new labels, same faces: the painter after a save), `SetHistory(history)` |
| Night and lamps | `SetNightView(flag)`, `NightView()`, `SetNightLights(states)`, `NightLights()`, `SetNightLamp(name, value)` (name also 'Hazards' or 'All'), `LampTypes()` |
| Photo | `SetPhotoAngle(angle)`, `PhotoAngle()`, `SetTurnWithPhoto(flag)`, `TurnWithPhoto()`, `SetPhotoHeight(h)`, `PhotoHeight()`, `SetPhotoFolder(folder)`, `PhotoFolder()`, `PlacePhoto()` |
| A host's mouse | `GripDown()`, `DialMove()`, `DialUp()` (each says whether it used the event) |
| End | `Stop()` (the timer), `Close()` |

### 4.10 What the painter drives today

The painter calls `fcn_CarMesh3D_viewLabels(baseMesh, Parent=..., ShowTools=false, PhotoFolder=..., Outline=..., OnHint=@setHint, ColorFilter=@paintedColors, HiddenFaces=@hiddenFaces, History=..., PhotoOptions=true, OnLamps=@markLamps, FigNum=-1)`. So inside the painter: no tool row and no lists from the viewer (the painter's panels replace them), the photo options under the photo, the hints in the painter's hint line, and the painter's own paint colors and hidden sets. The painter's panels drive the viewer through `SetColors`, `SetBoundaries`, `SetNightView`, `SetSeeThrough`, `ResetView`, `CopyViewCall`, `SetUncolored` ("Colored? No"), `SetHidden` ("Shown? No"), `SetNightLamp` and `NightLights` (Status?), `LabelKinds` and `LampTypes` (to build its rows), `SetMesh` and `SetHistory` (after a save), and the mouse hooks. The viewer on its own still shows the old tool row and lists (section 4.1 to 4.3).

### 4.11 What is remembered

Nothing is saved to disk or to MATLAB preferences. The view is returned (`viewSettings`) and can be given back (`ViewSettings=`) or sent (the view call).

## 5. Agreed design (2026-11-23; to be built after the painter)

The painter's panels, minus painting, in the painter's words, so a user who knows one window knows the other. Everything below follows the painter file's section 5 as built; only the differences are spelled out.

### 5.1 The top bar

| Control | Kind | What it does |
|---|---|---|
| ☰ Menu | button, 90 px | Lists the panels: Overall Display, Labels To Display, Lamps To Display, GUI settings. One open at a time; the window opens at Overall Display. |
| Exit | button, 80 px | Closes the window and returns the view settings. Nothing is saved, so it never asks. Not shown inside a host. (Today "Close": renamed to match the painter; C2S 2.) |
| status | text | What is shown now (to confirm, or left out). |

### 5.2 Overall Display (pale blue)

```
Colors?                     (o) Labels   ( ) Vehicle
Show mesh boundaries?       (o) Off      ( ) On
Nighttime view?             (o) Off      ( ) On
View                        [Reset view     ]
                            [Copy view call ]
                            Copied to the clipboard (and printed in the command window).   (gray, a few seconds)
See-through body            |----o--------------------| 0 .. 90 %   (ticks 0, 45, 90)
```

The same controls, defaults and actions as the tool row today (section 4.1), as radio pairs (rules 10, 22), each with a tooltip (rule 14; Reset view: "Back to the starting view"; the Colors pair: "Labels: each label in its own color. Vehicle: the colors the animator draws."). Reset view goes to the same starting view as the painter (its C2S 2: 60 degrees on the dial, 20 degrees down; V8).

### 5.3 Labels To Display (pale blue)

The painter's list: in groups (main body panels; objects within interior; lights; visibility, as agreed for the painter's P2), columns **Colored?** (Yes/No) and **Shown?** (Yes/No), a colored box per row, "All labels" with the mixed state (rule 20), and gray italic names for labels with no faces (rule 13, V7).

```
                          Colored?      Shown?
                          Yes   No     Yes   No
All labels                (o)   ( )    (o)   ( )
Main body panels
[■] body                  (o)   ( )    (o)   ( )
[■] glass                 (o)   ( )    (o)   ( )
[■] wheel                 (o)   ( )    (o)   ( )
[■] trim                  (o)   ( )    (o)   ( )
Objects within interior
[■] interior              (o)   ( )    (o)   ( )
Lights
[■] low beam ... backup   (o)   ( )    (o)   ( )
[■] light with no type    (o)   ( )    (o)   ( )      (only when the mesh has such faces)
Visibility
[■] hidden (not drawn)    (o)   ( )    ( )   (o)
Gray names: no faces have this label yet.
```

- "See one label alone" (today's radio button) becomes: that label Colored? Yes, all others No. `ShowLabel(key)`, `Label=` and the view settings' `Label` keep working that way (V4).
- The interior's special look (glass nearly clear, interior orange) is kept when interior is the only label Colored? Yes (to check: how the painter shows it now).
- The Show boxes become Shown? Yes/No; `SetHidden` and `Hidden=` are unchanged.

### 5.4 Lamps To Display (pale blue)

The painter's list (its 5.3): one row per lamp with a colored box, **Status?** columns Off / On (and Brake for the tail lights), Hazards, "All lamps" Off/On with the mixed state in place of All on / All off, gray italic names for "no faces", and the note under the list. "High beams (in the headlights)" keeps its meaning as a note under the list (to confirm wording). The lamp states, `NightLights` and `SetNightLamp` are unchanged.

### 5.5 GUI settings (light gray)

Only settings the viewer uses (the painter's save, revert and folder items do not apply):

```
Starting view               on the dial: [ 60 ] degrees   looking down: [ 20 ] degrees
                            (default is 60 and 20)
Colors                      day background [1 1 1] [Pick...]   night sky [0.04 0.05 0.09] [Pick...]
                            (defaults shown under each, gray)
Mesh file                   C:\...\2009_Honda_Fit_Sport_mesh.mat      (text, read-only)
[Reset to defaults]
```

- The starting view and colors are the same preferences as the painter's (group `CarMesh3D`), so setting them in one window sets them in both (to confirm with the painter's P2 and P3).
- "Mesh file" is the file shown (read-only, rule 12), or "(a mesh variable)".

### 5.6 The photo side (right)

As in the painter: the photo, the dial between the model and the photo, and the photo options under the photo (folder with Browse, **Turn model with photo?** Off/On, **Turn photo with model?** Off/On, **Photo size?** Small/Medium/Large), shown by default in the viewer's own window too (V6). The photo column never narrower than its options (about 360 px), as agreed for the painter.

### 5.7 Kept as now

The mouse (4.5), the night view (4.6), the hint line and fine print (4.7; the night hint's words "Shown? No" and "Paint by day" fit the painter only and become "set its Shown? to No" in the viewer), all options (4.8; `ShowTools=false` hides the top bar's menu inside a host), the outputs and all hooks (4.9), the timer, and "nothing saved" (4.11).

## 6. Test vehicle

As noted in the painter file's open issues (Sean): the viewer gets the same generic GUI test vehicle as the painter (`2026_CarMesh3D_Sample_GUITestVehicle`, task P1), so every row, lamp and hidden set is exercised. To be added to `script_test_fcn_CarMesh3D_viewLabels.m` once the test vehicle exists.

## 7. Differences found between the code, the help text and the README

(For Sean's information; Claude changed no code.)
- `fcn_CarMesh3D_viewLabels.m` line 1184: the comment says the starting view is "from the front left", but `view(-40, 20)` puts the camera behind the vehicle on its right (dial angle 230 degrees, by the code's own conversion at lines 1292 and 1856). (To check on screen.)
- Line 1001: a viewer opened without photos cannot be given a photo folder later; the hint then says "No folder ..." even when the folder exists.
- Lines 466-467: the comment beside `photoFolderLabel` belongs to `flagLampsSet`. Lines 663-665: "one shown at a time" is out of date (both lists are shown).
- Lines 23-30 and 123-140: the FORMAT line leaves out `History`; the list of hooks leaves out about 20 that exist (section 4.9 has them all). Line 337: `OnLamps` is not checked to be a function handle like the other callbacks.
- README line 764: `fcn_CarMesh3D_viewLabels('2009_Honda_Fit_Sport')` gives a vehicle ID, which the viewer refuses ("The mesh file ... does not exist"); it needs the mesh file (`fcn_CarMesh3D_findVehicleFiles(ID).MeshFile`).

## 8. Open questions

**(Claude to Sean)**

*(None open.)*

**(Sean to Claude)**

*(None open.)*

## 9. Open issues

*(Sean adds issues here.)*

## 10. Change log

- 2026-11-23 15:50: started by Claude (thread C) from the window as built (code last changed 11:00, for the painter's hooks) and its picture; the painter file's rules referred to, not repeated; proposal and C2S 1 to 6 for Sean's review. No code changed.
- 2026-11-23 18:01: reviewed by Sean; C2S 1 to 6 answered and closed (thread below). Rules V1 to V5 confirmed; V6 to V8 added from the answers; sections 3.2 and 5 marked agreed and their references updated. Sean's C2S 5 note (a global, user-editable list of labels that MATLAB reads, perhaps an MD file) is put on the Someday list. No code changed yet.

  **Closed questions (2026-11-23), with Sean's answers as written:**

  **C2S 1. One set of viewing panels for both windows?** The painter already has the four viewing panels; the viewer needs the same ones.
  - (A) *Recommended.* The viewing panels (menu, Overall Display, Labels To Display, Lamps To Display, GUI settings) move into `fcn_CarMesh3D_viewLabels`; the painter uses them and adds its own panels (Modify Labels and its save settings) to the same menu through a hook. One code for both windows; a fix to a panel is a fix in both.
  - (B) The painter keeps its panels; the viewer gets a copy of the code. Faster now; the two can drift apart.
  - (C) A third, shared helper function builds the panels for both.

  (A)

  **C2S 2. The viewer's top bar.** The viewer saves nothing.
  - (A) *Recommended.* ☰ Menu and Exit only (Exit returns the view settings and never asks); Copy view call stays in Overall Display, as in the painter.
  - (B) ☰ Menu, Copy view call, Exit (Copy view call is the viewer's main action, so on top).
  - (C) Keep the name "Close" in place of "Exit".

  (A)

  **C2S 3. Old view settings and view calls.** Today the settings hold `Label` (one label shown alone) and `Hidden`.
  - (A) *Recommended.* Keep `Label` and `Hidden`, and add `Uncolored` (the labels set Colored? No). An old call opens as before: its `Label` becomes "only this label Colored? Yes".
  - (B) Replace `Label` by `Uncolored`; old view calls lose the label shown alone (they still open).

  (A)

  **C2S 4. Photo options in the viewer's own window.** Today they appear only inside the painter (`PhotoOptions=true`).
  - (A) *Recommended.* On by default in every window (the default of `PhotoOptions` becomes true); a host can still turn them off.
  - (B) Off by default, as now.

  (A) All input arguments should be in some way presented in the GUI

  **C2S 5. Labels the mesh does not have.** Today the viewer lists only labels that have faces; the painter lists every label (gray italic names, rule 13).
  - (A) *Recommended.* Every label, as in the painter (rule 13 for both windows); the lamp list already does this.
  - (B) Only the labels the mesh has: the viewer is for looking, and a shorter list is quicker to read.

  (A) As well, I'm wondering if we need to somewhere keep a global list of labels - in an MD file perhaps? - that MATLAB can read, the user can edit, that defines which global labels exist. Let's put that on the Someday. Increasing use of the tools will ID this as a real issue or not.

  **C2S 6. The starting view and Reset view.** Today the viewer opens at `view(-40, 20)` (from behind on the right, dial 230 degrees); the painter's Reset view is to be 60 degrees on the dial, 20 degrees down (its C2S 2).
  - (A) *Recommended.* The same GUI setting for both windows: open and reset at 60 on the dial, 20 down. Opening at a photo or at given view settings still wins.
  - (B) Keep the viewer's own starting view.

  (A)
- 2026-11-23 18:02 (Sean, Q20 (A)): V6 made a rule for every window, as painter rule 25; V6 now refers to it.
- 2026-11-24 00:48 to 01:15 (Claude; Sean's tests in the chat, recorded here at 01:45):
  - **Q29 (A), Sean 00:48:** in label colors, a lamp's clear cover (`FaceCoverLamp`) is drawn as glass, 40% opaque, so the glass layer shows and the lamp shows through it; it is glass, so the glass Colored? and Shown? switches act on it. Vehicle colors unchanged (nearly clear).
  - **Turn signals at night, Sean 00:57** ("the activation and deactivation of the turn signals isn't shutting the lights or ground lighting correctly"): Hazards stayed on when one turn signal was unticked, and plotVehicle lights both turn signals while Hazards is on. Now Hazards is on only while both turn boxes are; a host setting Hazards ticks both. Tests T5 to T9: **all pass** (Sean 01:03); T9 (by day) passed "but the signal is VERY dim".
  - **Lit lamps by day, Sean 01:03:** a lit lamp's clear cover now glows in the lamp's lit color (at least 55% opaque), as at night; the Q29 glass had washed it out. T14 (left turn by day clearly orange) and T15 (low beam: headlamp glass warm white): **pass** (Sean 01:11). Note: in label colors the rear turn signal's label color and lit color are both orange, so it looks the same on and off.
  - **Scrolling, Sean 00:58** ("Can we have a rule to make all panels scrollable up/down?"): the Lamps panel cut off All on / All off. The panel was scrollable but the grid inside it fills the panel and squeezes its rows; now the grid scrolls (Lamps and Photo options). T10: **pass** (Sean 01:28). Rule added to how_we_work; and (Sean 01:28) a GUI's tests include making the window short, to check no panel vanishes.
  - **Tires at night, Sean 01:03** (a starburst on the tire sides): the normals were right; the tire's texture-sampled face colors alternated. Q30 (A): tires drawn in one color (fcn_CarMesh3D_labelParts). **Confirmed** by Sean 01:15.
- 2026-11-24 01:41 (Sean, "Agree"): **a "Driver's view" option** to come, from the driver's eye point. Agreed method: (1) estimated from the glass and roof (height: the roof's inside minus about 0.12 m; along the car: from the A-pillar back to just ahead of the B-pillar; across: about 22% of the width toward the driver's side, by a left- or right-hand-drive setting), with (3) an override `DriverEye = [x y z]` in the vehicle's script (and later a "Set driver's eye" click on the headrest). (2) from a found steering wheel replaces (1) once Task 9 is done. Not started. Context (Sean 01:35): the agreement on the interior was found at 02:40 in the painter's design file: plan item P5 (C2S 7), interior objects as sub-labels seat, steering wheel and console under `interior`, cabin surfaces no longer labeled interior; and Sean's reminder S2C 1 there, to return to how the interior mesh is made. Not built yet (the build still labels the interior by voxels).
