# Design: lamp units and the lamp-to-function matrix (`fcn_CarMesh3D_editLampFunctions`)

*Words: every file uses the three layers of the README's "Position, meaning, and function" (rule P6): **position** (faces), **meaning** (labels), **function** (signals). Say which layer a section is about; never call a label by a function ("headlamp bulb", not "low beams").*

*Started 2026-11-26 00:55 by Claude, from Sean's Fit review (00:07 to 00:53; Q76 (A)). The general GUI rules are in `Documentation_CarMesh3D_GUIdesign_rules.md`.*

**Status:** DESIGN (2026-11-26, Claude), for Sean's review. Nothing is built.

## Review now (for Sean)

1. Nothing now: T78, Q78 to Q80 answered (01:35); in the change log. Next: plan item 2.

## 1. What it is for

A vehicle's lamps have to answer two questions, and today one label tries to answer both:
- **What is this part?** (layer 2, meaning): a headlamp bulb, a marker bulb, a cover glass.
- **What makes it light?** (layer 3, function): the high-beam signal, the left-turn signal, the running lights (dimmed).

Real vehicles mix these terms freely. The 2009 Fit's daytime running lights are its high-beam bulbs, dimmed. One left-turn signal lights two bulbs, front left and rear left, but is still called "left turn signal". One tail/brake bulb answers two signals at two brightnesses, and is called a brake light and tail light. 

But this mix of function and location can fail. A broken brake lamp is a bulb that no longer answers its signal. A label cannot say any of this since the label only names a physical space; a matrix can fix this, by associating name with function. For example, the area labeled brake light is unchanged, even if the light burns out. But the function is what is failing, not the labeling or position because the brake light did not suddenly become a turn signal nor change location. It simply does not respond to the signal anymore to activate.

This following descriptions present a design that keeps the label for layer 2 only, and adds a **lamp-to-function (L2F) matrix** for layer 3, kept with each vehicle and edited in a window of its own.

## 2. The three layers, for lamps

```
   1. Position  --labels-->  2. Meaning  ---------matrix---------->  3. Function
   (faces)      (painter)    (what it is)  (fcn_CarMesh3D_editLampFunctions)  (what signals light it)
```

| Layer | For lamps | Example (2009 Fit) | Edited in |
|---|---|---|---|
| 1. Position | the faces | the faces inside the front-left headlamp housing | (the mesh) |
| 2. Meaning | a **label** per face (the lamp part's kind), and the **lamp units** the faces form (section 3) | "headlamp bulb"; unit "front-left headlamp bulb" | the painter |
| 3. Function | the **matrix**: which signals light each unit, and how bright | unit "front-left headlamp bulb": Low beam on, High beam on, Running dim (0.3) | the matrix window |

- **Labels map faces to meaning.** A face is painted a kind; it never learns its function.
- **The matrix maps meaning to signals.** It names units, never faces.
- **What each fixes:** a lamp lit in the wrong place is a wrong label (repaint); the right place lit by the wrong signal is a wrong cell state in the L2F matrix (edit the matrix).

## 3. Lamp units (layer 2): found, never drawn by hand

A **unit** is one connected piece of faces with one lamp label. The 2009 Fit's front-left headlamp housing holds, for example, a headlamp-bulb unit, a turn-signal unit and a marker unit. And the headlamp-bulb itself allows multiple activation levels.

- **Found automatically** each time the mesh or its labels change: faces of one lamp label that share edges form one unit (the connected-piece rule already used to label the Fit's front lamps, 2026-11-23).
- **Named from position (layer 1) and kind (layer 2):** front or rear (from x against the vehicle's middle), left or right (from y; center when it crosses the middle, such as a high brake lamp), then the kind: "front-left headlamp bulb", "rear-center tail/brake bulb". Two units with one name get a number: "front-left marker bulb 2".
- **Cover glass:** a lens over a unit belongs to it (the mesh's `FaceCoverLamp` already records which lamp each cover sits over), and lights with it.
- **What "bulb" means here:** the part of the lamp that lights, not the physical (small) location of the bulb filiment. Most filaments are enclosed within reflectors and lenses, and this entire space lights when the bulb is activated. For labeling, this entire space is considered the bulb. Most downloads do not model bulbs, only the colored section of a lamp assembly (section 7); the colored section is therefore the bulb, in most downloads. However, some downloads may share names across bulbs, for example headlights. If this spans more than 1 assembly and phsical bulb locations - for example, a right and left lamp area - then this is not a bulb description because the bulb-to-lit area convention is violated. The right bulb may be burned out, but that does not mean the left headlight does not activate. This illustrates the need to separate bulb filaments (not used in this work), bulb-lit areas - hereafter called "bulbs", versus bulb functions - highbeams for example. Normal wording often mixes all three of these labels, and this toolset assumes the "lit area by one bulb" meaning only.

## 4. The matrix (layer 3)

Rows are labeled bulbs (right-front fog light for example); columns are signals (fog lights "on", for example); each cell is a brightness from 0 (off) to 1 (full). The matrix allows a bulb to be reused. For example, the fog light bulb may activate 100% with fog lights "on" signaling, at 20% with "parking light" signaling, or 100% with "high beams" signaling. 

| Unit | Low beam | High beam | Running | Parking | Left turn | Right turn | Tail | Brake | Backup | Fog | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|
| front-left headlamp bulb | 1 | 1 | 0.3 | | | | | | | | Honda: DRL is the high-beam filament, dimmed |
| front-right headlamp bulb | 1 | 1 | 0.3 | | | | | | | | (as front-left) |
| front-left turn-signal bulb | | | | | 1 | | | | | | (default) |
| front-right turn-signal bulb | | | | | | 1 | | | | | (default) |
| front-left marker bulb | | | 1 | 1 | | | 1 | | | | (default) |
| front-left fog bulb | | 1 | | 0.2 | | | | | | 1 | (an example of reuse: on with fog lights, 20% as a parking light, on with high beams) |
| front-right fog bulb | | 1 | | 0.2 | | | | | | 1 | (as front-left) |
| rear-left tail/brake bulb | | | | 1 | | | 0.4 | 1 | | | (default) |
| rear-left backup bulb | | | | | | | | | 1 | | (default) |
| ... | | | | | | | | | | | |

*The fog rows show one bulb reused by three signals at two brightnesses (Sean, T78): the fog bulb is the same lit area, in the same place, whichever signal lights it. (The 2009 Fit's own fog bulbs answer the fog signal only; the example is not the Fit.)*

- **A unit's brightness** is the largest of its active cells (tail 0.4 and brake 1 together: 1).
- **The signals are plotVehicle's light states** (LowBeam, HighBeam, Running, Parking (new), TurnLeft, TurnRight, Tail, Brake, Backup, FogLights; and Reflectors, the outside light reaching the reflectors).
- **Hazards is not a column** (Q80 (A)): it is the two turn signals switched together, and the window has a Hazards button above the matrix to switch them so. Hazards flashing is the turn signals switched on and off over time, which is not part of the matrix (next rule).
- **Time is not part of the mesh** (Sean, 2026-11-26 01:35; README and rule P6). The matrix says what lights, and how bright, *when* a signal is on. When a signal comes on, goes off, flashes, or follows a sequence is a choice of whatever drives the signals (AnimateCar3D, or a user's own loop), never part of the vehicle's files. Example: hazard lights flashing on and off change neither the bulbs' position (layer 1), their labels (layer 2), nor which signal lights them and how bright (layer 3); only the signal changes, in time.
- **Defaults** come from the kind and the side, so most vehicles need no edits:

| Kind | Default signals |
|---|---|
| headlamp bulb | Low beam 1, High beam 1 (High beam only when the vehicle also has high-beam bulbs) |
| high-beam bulb | High beam 1 |
| turn-signal bulb | Left turn (left side) or Right turn (right side) 1 |
| running-light bulb | Running 1 |
| marker bulb | Running 1, Parking 1, Tail 1 |
| tail/brake bulb | Parking 1 (at the tail brightness), Tail 0.4, Brake 1; a rear turn signal too when the vehicle has no separate rear turn bulbs (US red rear turns) |
| backup bulb | Backup 1 |
| fog bulb | Fog 1 |
| license-plate bulb | Parking 1, Tail 1 |
| reflector | Reflectors (the outside light) |

## 5. Where it lives, and who reads it

- **With the vehicle** (rule G40): `lampFunctions_<ID>.csv` in the vehicle's folder, **every unit and every cell** (Q79 (A)), the columns of section 4 plus a **Default** column (yes, or edited) and a **Source** column; a rebuild that changes the units keeps the edited rows and remakes the default ones (rule: tables of facts carry their sources). CSV, so it is readable, shows changes clearly in git, and a student can edit it by hand (Q79).
- **Read in one place:** `fcn_CarMesh3D_plotVehicle` lights the lamps from the matrix. The viewer, the painter and the V&V GUI all draw lamps through it, in place of their own copies of the lamp rules today. Those copies are where the painter lit the fog lamps with the high beams (Sean's Fit review, 00:36); one reader fixes that kind of mismatch for good.
- **AnimateCar3D** gets the matrix through `plotVehicle`, with nothing new to do, and can change it at run time for faults: `LampFaults={'rear-left tail/brake bulb'}` makes that unit answer no signal. The library keeps each vehicle as designed; a fault belongs to the scene, not the vehicle.
- **Retired** once the matrix is in: the per-face function table `FaceLightFunctions` and the per-vehicle `LampSwitching`, which each held part of layer 3 inside the mesh. A one-time migration turns them into each vehicle's matrix.

## 6. The window (`fcn_CarMesh3D_editLampFunctions`)

- **The matrix as checkboxes:** a row per unit, a column per signal, one click to switch a cell. A dimmed cell shows its brightness ("0.3") and is set from the cell's right-click menu, so the usual on/off stays one click.
- **Row click:** the unit's faces are outlined on the model, so it is clear which part a row is referring to. The row is highlighted in the matrix to avoid user entry error.
- **Column click:** that signal is switched on in the view, to see what it lights. The column is highlighted as well. The overlap of row/column is highlighted in a background color that matches the the label color (or slight variant as needed for readability).
- **Pop out:** the matrix opens in a window of its own when it is too wide for the panel (about 15 units by 10 signals).
- **Hosted by the painter** as a panel in its ☰ Menu (as the painter hosts the viewer), and also opened alone from the demo menu or the library browser (the tree rule).
- **"Add a lamp kind"**, for a kind the list lacks: it goes into the one list (`fcn_CarMesh3D_lampTypes`), with a default row of section 4.

Default lighting is switched to "nighttime" if not already in this mode, when in-window click is made. If view is not already nighttime mode, user is warned that nighttime view is required for this panel.
(ASIDE to Claude: we need a persistent day/night swich on/off icon in each of the model viewers, basically a clickable (sunIcon)/(moonIcon) somewhere out of the way, where clicking on icon simply switches the day/night state. This lets us also migrate the setting out of panel, other than the default "Day/night setting starts at? ", which is GUI setting (not sure if we expose this already). See image pasted into chat.)

## 7. What the downloads name (2026-11-26)

From the 24 raw downloads in the library (58 lamp-like material and group names):
- they name the **assembly, its position and its material**: "headlight" (4 vehicles), "right_front_light", "headlightglass_..._left", "red_lights", "white_lights", generic "lights" (15 vehicles);
- function words are rare ("brake" in 3, "reverse" in 1; never turn, indicator, fog, DRL or marker); "bulb" never appears.

So the downloads already say what and where (layers 1 and 2), not what switches it (layer 3). Their names are used to guess labels at import (each kind's NameRule in `fcn_CarMesh3D_lampTypes`); the matrix is never guessed from them.

## 8. Someday

- **New signals from the window's menu** (Sean, T78): a user adds a signal the list lacks (a column), such as a work light, a beacon or an aftermarket light bar, with a name and the bulbs it lights.
- **Fades, in time and in space** (Sean, Q80 note). The matrix holds one brightness per bulb per signal; some modern lamps need more:
  - **in space:** many modern turn signals are a bar of many LEDs that lights in a sweep, right to left for a left turn. Lighting each LED as its own bulb quickly becomes unworkable; a bulb with a direction and a sweep would describe the whole bar;
  - **in time:** some modern turn signals do not blink but fade on, then fade off.
  How a sweep or a fade is *played* over time belongs to the driver of the signals (rule above: time is not part of the mesh); what the vehicle must record is the bulb's shape for it (the sweep's direction and length, or that it fades). Not supported by the matrix as designed.

## 9. Plan

1. DONE (01:35): Sean's review (T78 (B), with edits); Q79 (A), Q80 (A), Q78 (A): the saved lamp keys are renamed to bulb names with this work, by one migration.
2. `fcn_CarMesh3D_lampUnits`: units from a mesh, with their names and covers; tested on the Fit and the GUI test vehicle.
3. The matrix: defaults (section 4), read and write `lampFunctions_<ID>.csv`, and the migration from `FaceLightFunctions` and `LampSwitching`.
4. `plotVehicle` lights lamps from the matrix; the viewer and painter draw lamps through it (their own lamp rules removed). The Fit's fog-with-high-beams bug as a test.
5. The window (section 6), hosted in the painter.
6. The Fit: its matrix (DRL from the headlamp bulbs, dimmed, with Honda as the source); Sean re-checks the Headlights question in the V&V GUI.
7. AnimateCar3D: `LampFaults`, and its contract check.
8. The library: every vehicle migrated and checked (face counts per lamp before and after), the saved lamp keys renamed to bulb names (Q78 (A)).
9. Before the window: a day/night icon (sun and moon, Sean's picture, 2026-11-26 01:26) in every model view, out of the way, switching day and night with one click; the window switches to night when it is used (section 6). The start setting stays in Shared GUI settings ("Day or night at start").

## Tests for Sean

*Kept at the bottom, before "Open questions" and the "Change log", so it is easy to jump to; named, not numbered, so it never moves.*

Key:
- **Only what a person must judge** (Sean, 2026-11-25 13:15 and 14:24, for every file): look, feel, clarity, and other human-only checks. Anything of the form "does X show Y" or "does pressing X do Y" is a code test instead; this section names those code tests, so it is clear what is covered.
- **TNN.** A test step. **Every step carries its own exact MATLAB commands, right under it** (G34), beginning with `close all; clear functions; clc` (Q74 (A)), opening the window at what is judged.
- (Sean's results are in parentheses under the step.)
- Expected outcomes are labeled (A), (B) and so on. A bug is marked **BUG**; an uncertain or unexpected outcome **???**.
- Each step is separated by a blank line.
- A finished round moves to the change log, with the results.

(none yet: nothing is built)

## Open questions

*Kept at the bottom, before the "Change log"; named, not numbered.*

Key:
- **QNN.** A question. Q-numbers run on across every file and the chat (Q1 to Q99, then wrap).
- Options are lettered, the recommended one first and marked *Recommended*.
- (Answers are in parentheses.)
- Each question is separated by a blank line.

### Question list

(none)

## Change log

*Always last.* Newest last; each entry: date and time (Eastern), who, what changed, and why.

- 2026-11-26 00:55, Claude: first written, from Sean's Fit review (00:07 to 00:53): the DRL made by the high-beam bulbs, the missed marker bulb, high beams lighting several bulbs and their glass, the painter lighting the fog lamps with the high beams, and Sean's L2F matrix idea (00:35); the three layers (00:43; README and rule P6); Q76 (A), 00:53: "faces map to a specific label name. A separate logic - a matrix - maps names to function."
- 2026-11-26 01:35, Sean, in the answer queue (and in this file):
  - **T78 (B)**: edits made in sections 1, 2, 3, 4 and 6 (a broken brake lamp is a failed function, not a changed label; "bulb" is the area one bulb lights, not the filament; the matrix reuses a bulb for several signals, the fog-bulb example; row and column highlighted in the window; the window switches the view to night; a day/night icon for every model view, with a picture). Asked: section 4's table to match the fog example (done: fog rows, a Parking column); a Someday item for new signals from the menu (section 8).
  - **Q79 (A)**: the file holds every unit and every cell, with a Default column (section 5).
  - **Q80 (A)**: Hazards is not a column: "Hazards, in implementation, are simply a signal change in time. Time-axis events are animator choices, not part of this rep." The rule "time is not part of the mesh" (section 4; README; rule P6). Someday: fades in time and space (section 8).
  - **Q78 (A)**: the saved lamp keys are renamed to bulb names, with this work (plan items 1 and 8).
