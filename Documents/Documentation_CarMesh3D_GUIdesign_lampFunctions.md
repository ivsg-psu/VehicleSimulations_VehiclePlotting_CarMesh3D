# Design: lamp units and the lamp-to-function matrix (`fcn_CarMesh3D_editLampFunctions`)

*Terms (Sean's style guide, 2026-11-26 01:47): a **lamp** is the whole device that lights (its bulb or LEDs, reflector and cover: all that glows when it is on); a **bulb** is only the light source inside it, and a **filament** the part of a bulb that glows. CarMesh3D labels and switches **lamps**; bulbs and filaments are not modeled. Say "lamp" unless the light source itself is meant ("the Fit's DRL is its high-beam filament, dimmed").*

*Words: every file uses the three layers of the README's "Position, meaning, and function" (rule P6): **position** (faces), **meaning** (labels), **function** (signals). Say which layer a section is about; never call a label by a function ("headlamp", not "low beams").*

*Started 2026-11-26 00:55 by Claude, from Sean's Fit review (00:07 to 00:53; Q76 (A)). The general GUI rules are in `Documentation_CarMesh3D_GUIdesign_rules.md`.*

**Status:** DESIGN (2026-11-26, Claude), for Sean's review. Nothing is built.

## Review now (for Sean)

1. Nothing now: T78, Q78 to Q80 answered (01:35); in the change log. Next: plan item 2.

## 1. What it is for

A vehicle's lamps have to answer two questions, and today one label tries to answer both:
- **What is this part?** (layer 2, meaning): a headlamp, a marker lamp (and the cover glass that is part of a lamp).
- **What makes it light?** (layer 3, function): the high-beam signal, the left-turn signal, the running lights (dimmed).

Real vehicles mix these terms freely. The 2009 Fit's daytime running lights are its high-beam lamps, dimmed. One left-turn signal lights two lamps, front left and rear left, but is still called "left turn signal". One tail/brake lamp answers two signals at two brightnesses, and is called a brake light and tail light. 

But this mix of function and location can fail. A broken brake lamp is a lamp that no longer answers its signal (its bulb has burned out). A label cannot say any of this since the label only names a physical space; a matrix can fix this, by associating name with function. For example, the area labeled brake light is unchanged, even if the light burns out. But the function is what is failing, not the labeling or position because the brake light did not suddenly become a turn signal nor change location. It simply does not respond to the signal anymore to activate.

This following descriptions present a design that keeps the label for layer 2 only, and adds a **lamp-to-function (L2F) matrix** for layer 3, kept with each vehicle and edited in a window of its own.

## 2. The three layers, for lamps

```
   1. Position  --labels-->  2. Meaning  ---------matrix---------->  3. Function
   (faces)      (painter)    (what it is)  (fcn_CarMesh3D_editLampFunctions)  (what signals light it)
```

| Layer | For lamps | Example (2009 Fit) | Edited in |
|---|---|---|---|
| 1. Position | the faces | the faces inside the front-left headlamp housing | (the mesh) |
| 2. Meaning | a **label** per face (the lamp part's kind), and the **lamp units** the faces form (section 3) | "headlamp"; unit "front-left headlamp" | the painter |
| 3. Function | the **matrix**: which signals light each unit, and how bright | unit "front-left headlamp": Low beam on, High beam on, Running dim (0.3) | the matrix window |

- **Labels map faces to meaning.** A face is painted a kind; it never learns its function.
- **The matrix maps meaning to signals.** It names units, never faces.
- **What each fixes:** a lamp lit in the wrong place is a wrong label (repaint); the right place lit by the wrong signal is a wrong cell state in the L2F matrix (edit the matrix).

## 3. Lamp units (layer 2): found, never drawn by hand

A **unit** is one connected piece of faces with one lamp label. The 2009 Fit's front-left headlamp housing holds, for example, a headlamp unit, a turn-signal unit and a marker unit. And the headlamp itself allows multiple activation levels.

- **Found automatically** each time the mesh or its labels change: faces of one lamp label that share edges form one unit (the connected-piece rule already used to label the Fit's front lamps, 2026-11-23).
- **Named from position (layer 1) and kind (layer 2):** front or rear (from x against the vehicle's middle), left or right (from y; center when it crosses the middle, such as a high brake lamp), then the kind: "front-left headlamp", "rear-center tail/brake lamp". Two units with one name get a number: "front-left marker lamp 2".
- **Cover glass:** a lens over a unit belongs to it (the mesh's `FaceCoverLamp` already records which lamp each cover sits over), and lights with it.
- **What "lamp" means here:** the whole part that lights, not the physical (small) bulb or filament inside it. Most filaments are enclosed within reflectors and lenses, and this entire space lights when the bulb is activated; for labeling, this entire space is the lamp. Most downloads do not model bulbs at all, only the colored section of a lamp assembly (section 7); the colored section is therefore the lamp, in most downloads. However, some downloads share one name across lamps, for example "headlights" for both sides. A name that spans more than one lamp (a right and a left headlamp) does not describe one lamp: the right bulb may be burned out while the left headlamp still lights. This is why three things are kept apart: bulbs and filaments (the light sources, not modeled in this work), lamps (the area one light source lights: what is labeled), and functions (what signals light a lamp: high beams, for example). Everyday wording mixes all three; this toolset uses "lamp" in the "area lit by one light source" meaning only.

## 4. The L2F matrix (layer 3)

In the lamp-to-function matrix (L2F), rows are labeled lamps (right-front fog light for example); columns are signals (fog lights "on", for example); each cell is a brightness from 0 (off) to 1 (full). The matrix allows a lamp to be reused. For example, the fog lamp may light 100% with fog lights "on" signaling, at 20% with "parking light" signaling, or 100% with "high beams" signaling. 

| Unit | Low beam | High beam | Running | Parking | Left turn | Right turn | Tail | Brake | Backup | Fog | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|
| front-left headlamp | 1 | 1 | 0.3 | | | | | | | | Honda: DRL is the high-beam filament, dimmed |
| front-right headlamp | 1 | 1 | 0.3 | | | | | | | | (as front-left) |
| front-left turn-signal lamp | | | | | 1 | | | | | | (default) |
| front-right turn-signal lamp | | | | | | 1 | | | | | (default) |
| front-left marker lamp | | | 1 | 1 | | | 1 | | | | (default) |
| front-left fog lamp | | 1 | | 0.2 | | | | | | 1 | (an example of reuse: on with fog lights, 20% as a parking light, on with high beams) |
| front-right fog lamp | | 1 | | 0.2 | | | | | | 1 | (as front-left) |
| rear-left tail/brake lamp | | | | 1 | | | 0.4 | 1 | | | (default) |
| rear-left backup lamp | | | | | | | | | 1 | | (default) |
| ... | | | | | | | | | | | |

*The fog rows show one lamp reused by three signals at two brightnesses (Sean, T78): the fog lamp is the same lit area, in the same place, whichever signal lights it. (The 2009 Fit's own fog lamps answer the fog signal only; the example is not the Fit.)*

- **A unit's brightness** is the largest of its active cells (tail 0.4 and brake 1 together: 1).
- **The signals are plotVehicle's light states** (LowBeam, HighBeam, Running, Parking (new), TurnLeft, TurnRight, Tail, Brake, Backup, FogLights; and Reflectors, the outside light reaching the reflectors).
- **Hazards is not a column** (Q80 (A)): it is the two turn signals switched together, and the window has a Hazards button above the matrix to switch them so. Hazards flashing is the turn signals switched on and off over time, which is not part of the matrix (next rule).
- **Time is not part of the mesh** (Sean, 2026-11-26 01:35; README and rule P6). The matrix says what lights, and how bright, *when* a signal is on. When a signal comes on, goes off, flashes, or follows a sequence is a choice of whatever drives the signals (AnimateCar3D, or a user's own loop), never part of the vehicle's files. Example: hazard lights flashing on and off change neither the lamps' position (layer 1), their labels (layer 2), nor which signal lights them and how bright (layer 3); only the signal changes, in time.
- **Defaults** come from the kind and the side, so most vehicles need no edits:

| Kind | Default signals |
|---|---|
| headlamp | Low beam 1; High beam 1 too, unless the vehicle has high-beam lamps of its own on that side |
| high-beam lamp | High beam 1 |
| turn-signal lamp | Left turn (left side) or Right turn (right side) 1 |
| running lamp (DRL) | Running 1 |
| marker lamp | Running 1, Parking 1, Tail 1 |
| tail/brake lamp | Parking 0.4 (the tail brightness), Tail 0.4, Brake 1; a rear turn signal too when the vehicle has no separate rear turn lamps (US red rear turns) |
| backup lamp | Backup 1 |
| fog lamp | Fog 1 |
| license-plate lamp | Parking 1, Tail 1 |
| reflector | Reflectors (the outside light) |
| warning lamp (beacon) | none: switched by the user's own loop |

- **Colors** (`fcn_CarMesh3D_lampColors`) follow the kind and the signal that lights a unit most; when two signals light it equally, the later column wins (high beams on with the low beams: white). `Headlights='high'` in the light states is the low and the high beams together, as it always was.

## 5. Where it lives, and who reads it

- **With the vehicle** (rule G40): `lampFunctions_<ID>.csv` in the vehicle's folder, **every unit and every cell** (Q79 (A)), the columns of section 4 plus a **Default** column (yes, or edited) and a **Source** column; a rebuild that changes the units keeps the edited rows and remakes the default ones (rule: tables of facts carry their sources). CSV, so it is readable, shows changes clearly in git, and a student can edit it by hand (Q79).
- **Read in one place:** `fcn_CarMesh3D_plotVehicle` lights the lamps from the matrix. The viewer, the painter and the V&V GUI all draw lamps through it, in place of their own copies of the lamp rules today. Those copies are where the painter lit the fog lamps with the high beams (Sean's Fit review, 00:36); one reader fixes that kind of mismatch for good.
- **AnimateCar3D** gets the matrix through `plotVehicle`, with nothing new to do, and can change it at run time for faults: `LampFaults={'rear-left tail/brake lamp'}` makes that unit answer no signal. The library keeps each vehicle as designed; a fault belongs to the scene, not the vehicle.
- **Retired** once the matrix is in: the per-face function table `FaceLightFunctions` and the per-vehicle `LampSwitching`, which each held part of layer 3 inside the mesh. A one-time migration turns them into each vehicle's matrix.

## 6. The window (`fcn_CarMesh3D_editLampFunctions`)

*Chosen by Sean, 2026-11-26 03:58 to 04:35, from mockups: five first ideas (A to E), five variations on the two he kept (C, the whole matrix; B, one signal with sliders), then one merged mockup tried by hand. The mockups are Claude's tools `zzN_l2fMockups2` and `zzN_l2fMockups3` (not in the repo).*

**What it is:** the helper panel that opens from the L2F panel's function-settings button, where the matrix's values (each lamp unit by each signal, 0 to 1) are set. The rest of the L2F panel (the units, their names and covers) is plain.

**Layout: a tall column at the left, as every panel in the GUIs** (Sean, 04:27); the live view is the vehicle in the viewer itself, at the right, so the panel holds no picture of its own. From the top:

1. **Editing: [signal ▾]**, the one signal being edited, and a **Table | Tuner** switch (Sean, 04:25: "I like the ability to toggle table view / tuner view").
2. **Also on: [+ add a signal... ▾]**: other signals lit at the same time, to see together and never edited, such as the brake lamps with a turn signal (Sean, 04:25: "the easiest one to show ... brake light activation WITH turn signal lights"). Each signal added shows as a **chip** under it ("Signal 4 ×"); a click on a chip turns it off (Sean, 04:35, Q-less choice between chips and a hide-after-choosing list). The same kind of entry as Editing (a dropdown), and it takes two short rows however many signals there are (20 or more).
3. **Filters:** "Only lamps this signal lights", and the groups shown (Front, Side, Rear; the rows are grouped so, each group able to fold away) for vehicles with many lamps (a tractor-trailer).
4. **Table** (option 5's bar cells): a row per lamp unit (grouped), a column per signal; each cell draws its brightness as a bar (empty is off), so the matrix reads like a chart and no number is typed (Sean, 04:25: "number entry is a bad way to do UIs - too error prone"). The column being edited has a cyan edge. **A click on a cell** makes its signal the one edited and marks its lamp; **a double-click** switches the cell on (1) or off (0).
5. **Tuner** (option B): one **vertical slider per lamp, up is brighter** (Sean, 04:25: "More light is usually an upslider moving up on household lights"), for the signal being edited, in steps of 0.05; under each lamp, in grey, what the "also on" signals already light it to.
6. **Checks**, in words, as the matrix changes (option 4; Sean, 04:25: "really like the idea of the 'Checks' box with prompts to help user"): a signal that lights no lamp; a lamp no signal lights; a signal lighting lamps at both ends of the vehicle, or on one side only where its twin on the other side is off. They warn, never block: odd vehicles (a police cruiser, a tractor-trailer) are allowed.

**In the view (the vehicle in the viewer):** at night (the window switches the view to night when used, as before), lamps light with the signal being edited and the "also on" signals together, each at its brightest; **the lamps the edited signal lights are outlined in cyan**, so it is always clear which signal is being edited while others are lit (Sean, 04:25: "showing multiple signals at the same time makes the one we are editing very unclear"). A click on a row outlines that lamp as well.

**Not chosen, and why** (Sean, 04:07 and 04:25): MATLAB's Variables Editor (no 0-1 checks as one types, no lamp shown on the model, away from the model); checkboxes with brightness on a right-click (easy to make an error); one lamp at a time picked on the model (too hard to carry across vehicle types: passenger cars, police cruisers, tractor-trailers); the matrix and the sliders side by side (too much for a slide-out panel); numbers typed in cells (error prone).

**Hosted by the painter** as a panel in its ☰ Menu (as the painter hosts the viewer), and also opened alone from the demo menu or the library browser (the tree rule). **"Add a lamp kind"**, for a kind the list lacks: it goes into the one list (`fcn_CarMesh3D_lampTypes`), with a default row of section 4. The day/night button on the view (plan item 9) is built (2026-11-26, Q89 (A)).

## 7. What the downloads name (2026-11-26)

From the 24 raw downloads in the library (58 lamp-like material and group names):
- they name the **assembly, its position and its material**: "headlight" (4 vehicles), "right_front_light", "headlightglass_..._left", "red_lights", "white_lights", generic "lights" (15 vehicles);
- function words are rare ("brake" in 3, "reverse" in 1; never turn, indicator, fog, DRL or marker); "bulb" never appears.

So the downloads already say what and where (layers 1 and 2), not what switches it (layer 3). Their names are used to guess labels at import (each kind's NameRule in `fcn_CarMesh3D_lampTypes`); the matrix is never guessed from them.

## 8. Someday

- **New signals from the window's menu** (Sean, T78): a user adds a signal the list lacks (a column), such as a work light, a beacon or an aftermarket light bar, with a name and the lamps it lights.
- **Fades, in time and in space** (Sean, Q80 note). The matrix holds one brightness per lamp per signal; some modern lamps need more:
  - **in space:** many modern turn signals are a bar of many LEDs that lights in a sweep, right to left for a left turn. Lighting each LED as its own lamp quickly becomes unworkable; a lamp with a direction and a sweep would describe the whole bar;
  - **in time:** some modern turn signals do not blink but fade on, then fade off.
  How a sweep or a fade is *played* over time belongs to the driver of the signals (rule above: time is not part of the mesh); what the vehicle must record is the lamp's shape for it (the sweep's direction and length, or that it fades). Not supported by the matrix as designed.

## 9. Plan

1. DONE (01:35): Sean's review (T78 (B), with edits); Q79 (A), Q80 (A), Q78 (A): the saved lamp keys are renamed to lamp names (what each lamp is) with this work, by one migration.
2. DONE (2026-11-26 03:27): `fcn_CarMesh3D_lampUnits`: units from a mesh, with their names and covers; tested on the Fit and the GUI test vehicle.
3. DONE (2026-11-26 04:54): The matrix: defaults (section 4), read and write `lampFunctions_<ID>.csv`, and the migration from `FaceLightFunctions` and `LampSwitching`.
4. DONE (2026-11-26 05:30; `fcn_CarMesh3D_lampSetup`, `fcn_CarMesh3D_lampColors`): `plotVehicle` lights lamps from the matrix; the viewer and painter draw lamps through it (their own lamp rules removed). The Fit's fog-with-high-beams bug as a test.
5. BUILT, for Sean's look (2026-11-26 06:05; `fcn_CarMesh3D_editLampFunctions`, T79 to T82): the window (section 6, as chosen 2026-11-26 04:35), on its own (with a viewer beside it) and as the painter's Lamp Functions panel. Not yet: "Add a lamp kind".
6. The Fit: its matrix (DONE: DRL from the headlamps, dimmed, with Honda as the source); Sean re-checks the Headlights question in the V&V GUI.
7. DONE (2026-11-26 05:17): AnimateCar3D: `LampFaults` (per object in the display list, passed by the scene player), and its contract check.
8. The library: every vehicle migrated and checked (face counts per lamp before and after) (DONE 2026-11-26 06:45: each vehicle's lampFunctions_<ID>.csv written; in every vehicle each lamp face is in exactly one unit; only the Fit had rows to migrate), the saved lamp keys renamed to lamp names (Q78 (A); waits for Q92, the names).
9. DONE (2026-11-26, Q89 (A), Sean 03:52): a sun/moon button in the viewer's model view (so the painter has it too), top right, switching day and night with one click; the window switches to night when it is used (section 6). The start setting stays in Shared GUI settings ("Day or night at start"). The other viewers have no night view.

## Tests for Sean

*Kept at the bottom, before "Open questions" and the "Change log", so it is easy to jump to; named, not numbered, so it never moves.*

Key:
- **Only what a person must judge** (Sean, 2026-11-25 13:15 and 14:24, for every file): look, feel, clarity, and other human-only checks. Anything of the form "does X show Y" or "does pressing X do Y" is a code test instead; this section names those code tests, so it is clear what is covered.
- **TNN.** A test step. **Every step carries its own exact MATLAB commands, right under it** (G34), beginning with `close all; clear functions; clc` (Q74 (A)), opening the window at what is judged.
- (Sean's results are in parentheses under the step.)
- Expected outcomes are labeled (A), (B) and so on. A bug is marked **BUG**; an uncertain or unexpected outcome **???**.
- Each step is separated by a blank line.
- A finished round moves to the change log, with the results.

T79. The window on its own: the Fit's matrix as bar cells, the view at night with the low beams lit and outlined in cyan. Is the layout what you chose (Editing and Table | Tuner, Also on with chips, the filters, the table, Checks, Save / Revert / Hazards)? Is the table easy to read?
`close all; clear functions; clc; fcn_CarMesh3D_editLampFunctions('2009_Honda_Fit_Sport');`

T80. Also on: add Brake, then Left turn; click a chip to take one off; press Hazards. Do the lamps light together, with only the edited signal's lamps outlined in cyan? (Nothing is saved unless you press Save.)
`close all; clear functions; clc; fcn_CarMesh3D_editLampFunctions('2009_Honda_Fit_Sport');`

T81. The Tuner: switch to Tuner and move a headlamp's slider up and down. Does "up is brighter" feel right, with the grey "also" numbers under each slider? Is a double-click on a table cell (on/off) and a single click (pick that signal and lamp) clear?
`close all; clear functions; clc; fcn_CarMesh3D_editLampFunctions('2009_Honda_Fit_Sport');`

T82. In the painter: open the ☰ Menu's Lamp Functions panel. Is the narrow column usable beside the model, and is it clear that it lights the painter's view?
`close all; clear functions; clc; fcn_CarMesh3D_paintLabels('2009_Honda_Fit_Sport');`

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
- 2026-11-26 01:47, Sean: edits to sections 3 and 4 (L2F named; rows are labeled lamps), and the style guide: "bias toward the word 'lamp' rather than 'bulb' - in physical lighting, a lamp is an entire device (bulb, covering, etc) being lit up, but bulb refers to the part holding the filament." Claude: the whole file in those terms (a Terms note at the top; "headlamp", "marker lamp", "tail/brake lamp" ...; "bulb" kept only for the light source itself).
- 2026-11-26 04:50, Claude (Sean 03:58 to 04:35, from mockups): section 6 rewritten as chosen: a tall column at the left; Editing and Table | Tuner; "Also on" signals as chips; filters and groups; the Table as bar cells (click picks, double-click on/off); the Tuner as vertical sliders, up is brighter; Checks in words; the edited signal's lamps outlined in cyan in the view. What was not chosen, and why. Plan item 9 (the day/night button) done.
- 2026-11-26 05:35, Claude: plan items 2, 3, 4 and 7 done; item 6's matrix done. In section 4: a headlamp's High beam default is left out when the vehicle has high-beam lamps of its own on that side (found by plotVehicle's test, whose sample has separate high beams); the tail/brake lamp's Parking default written as it is (0.4); the warning lamp's default (none); how colors are chosen, and `Headlights='high'` kept as both beams. plotVehicle draws lamps by unit, so its test changed with it: the sample's tail lamps light with the turn signals (it has no turn lamps of its own), and a ground pool lights only from a lamp that is lit (no backup pool for a vehicle with no backup lamps).
- 2026-11-26 06:05, Claude: plan item 5 built (`fcn_CarMesh3D_editLampFunctions`, with its test, and the painter's Lamp Functions panel); the viewer has three new hooks for it (SetLampFunctions, SetLampSignals, OutlineFaces); `fcn_CarMesh3D_lampFunctions` takes `Table=` to save the window's matrix. T79 to T82 for Sean.
- 2026-11-26 06:47, Claude: plan item 8's matrix part done (a CSV for each of the 25 library vehicles; the samples and body-style generics have none). The key rename waits for Q92 (which names).
