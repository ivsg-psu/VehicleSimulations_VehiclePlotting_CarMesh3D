# Design: the library browser, `fcn_CarMesh3D_browseLibrary`

*The style and layout choices for the library browser, kept so the window can be rebuilt from this file. Edit it freely: it is the place to change the design, and Claude builds from it. Started 2026-11-23 16:20 by Claude from the window as built (`fcn_CarMesh3D_browseLibrary.m`, last changed 2026-11-22 23:38, and its picture `Images/functions/fcn_CarMesh3D_browseLibrary.png`).*

**Status:** REDESIGN PROPOSED (2026-11-23 23:05). The list version (sections 4 and 5) was built and pushed as a return point (commit "Library browser, list version (return point before the table redesign)", 23:01). Sean chose (Q23 (A), 22:59) to replace the list of picture rows with a text table and a preview panel: section 3.3 is Claude's proposal, with C2S 9 to 12 for Sean. Not built.

---

## Review now (for Sean)

*Updated 2026-11-24 07:15. Almost everything is now tested by script (automated GUI tests, Q39: Agent D, 06:06 to 07:01; checked by Claude 07:04: all pass). What is left needs your eyes only.*

**First:** close any browser window and run `clear functions`, then open it from the demo menu.

- **T38. The Demo column:** the demo vehicle has a ★ in a new "Demo" column, next to the exemplar ★ column. Is it clear which ★ means what?
(Sean's result:)

- **T39. The demo buttons:** in the preview, "★ Use as demo vehicle" and "Back to the repo's demo". Pick a vehicle with photos: it becomes the demo vehicle (★ moves). Pick one without photos: a red hint says why, nothing changes. Their place and wording?
(Sean's result:)

- **T40. Narrow window:** make the window about 640 wide and 400 tall: the table, preview and buttons stay usable (shorter button words). Looks right?
(Sean's result:)

- **T41. The highlight follows the preview:** after sorting, filtering or clicking a group header, the highlighted row is the previewed vehicle. Feels right?
(Sean's result:)

---

## 1. What the window is for

The browser shows every finished vehicle in the library, one row each, in a scrolling list: a picture of the labeled 3D mesh, a picture of the 2D overhead outline, the vehicle's name and MATLAB name (vehicle ID), and its details (class, size, processing and score, review, license). The user groups, sorts and filters the list, ticks **Select** on the vehicles wanted, and closes the window: the selected vehicles' MATLAB names are returned, in the order shown. With none selected, a fresh temporary copy of the default test vehicle is returned (so a tool tried on it changes only the copy).

Each row can also open the vehicle in the viewer (**View**, `fcn_CarMesh3D_viewLabels`), the label painter (**Edit labels**, `fcn_CarMesh3D_paintLabels`) or the Model Reviewer (**Review**, `fcn_CarMesh3D_reviewVehicle`).

It is called on its own, `selectedNames = fcn_CarMesh3D_browseLibrary()`, often with options (`Vehicles=`, `SortBy=`, `GroupBy=` ...); scripts use it to pick vehicles (for example `fcn_CarMesh3D_runDemoExample`). It is never built into another window.

## 2. General rules for the whole window

The painter's general rules apply where they fit a list window: see [Documentation_CarMesh3D_GUIdesign_paintLabels.md, section 2](Documentation_CarMesh3D_GUIdesign_paintLabels.md#2-general-rules-for-the-whole-window). They are not repeated here. The rules about the mesh and photo sides, the spinner, the pancake menu, label and lamp rows, and paint (painter rules 1 to 5, 7 to 9, 13, 16, 18 to 21) do not apply: this window has no model, no photos and no panels.

**(Sean) Rules already set for this window** (2026-11-22, from the code's revision history):
- B1. **Group, Sort, Filter, left to right, each in its own box, numbered in the order they are used** ("1. Group by", "2. Sort within each group by", "3. Filter ..."). (23:33: the sort box, read first, was taken for the main order.)
- B2. **A filter is applied only with its button**, not while typing; filters stack on what is shown; "Clear filters" shows all again; **a filter that matches none of the vehicles shown is not applied**, and the user is told, so the list is never emptied. (14:56)
- B3. **Read-only text is text, not a text box**: the selection to be returned is shown as text, with a **Copy names** button. (23:35; painter rule 12)
- B4. **The title bar** is the standard one: the function's name and its version (`fcn_CarMesh3D_addTitleBar`; 14:31, 14:40; painter rule 15).
- B5. **Only the vehicles given** (`Vehicles=`): every sort, group, filter and selection works on them alone. (16:32)

**(Sean, 2026-11-23) Rules from the painter file that this window follows too:** buttons only for actions (rule 11: already so); every control with a tooltip (rule 14: several are missing, section 5.4); radio choices asked as questions ending in "?" (rule 22).
- B6. **A stated exception to rules 6 and 10 (on/off choices as radio pairs): the Select check box on each row stays a check box.** (C2S 2. The Descending check box, kept by C2S 1, was replaced by the Order? drop-down: C2S 6.)
- B7. **Group by sets the order of the groups; Order? orders only the vehicles within each group.** Groups are always in their own order: classes A to Z, years oldest first, reviewed first, exemplars first. (C2S 3)
- B8. **Nothing is remembered between calls:** each call opens at its options or the defaults, so there is no Reset to defaults button (rules 23, 24 do not apply). Scripts open this window often and expect the same list each time. (C2S 4)
- B9. **Enter in the filter box applies the filter**, the same as Apply filter; typing alone still does nothing (B2). (C2S 5)
- B10. **Every input argument is shown in the GUI in some way** (painter rule 25, Sean 18:02): `Vehicles=` in the subtitle (as now), `Selected=` as the ticked rows (as now), `DefaultVehicle=` in the selection text when none is selected (as now), and `SortBy=`, `GroupBy=`, `Descending=` in boxes 1 and 2 (as now). (Claude, to confirm in the build: `DataFolder=`, now shown nowhere, goes in the subtitle when it is not the default.)
- B11. **The order within each group is chosen in words that fit the sort** (Sean, C2S 6, 21:22): an **Order?** drop-down beside the sort, with two choices, the sort's own default first, and each new sort opening at its default:
  - Make, Class: **A to Z** / Z to A
  - Year, Date built, Date reviewed: **Newest first** / Oldest first
  - Length: **Longest first** / Shortest first
  - Score: **Highest first** / Lowest first
  - Review (% approved): **Most approved first** / Least approved first

  The call takes the same words (`Order=`); `Descending=` still works for old calls.

- B12. **No "Name" sort** (Sean, 21:54, C2S 7): the name begins with the year, so a sort by name looked random by make; Make covers it. `SortBy='name'` in old calls sorts by make. **Text sorts ignore upper and lower case.**
- B13. **Ties are ordered by make, then name; for a text sort (Make, Class) in the order chosen, for the others A to Z** (Sean's screenshot, 22:05: sorting by Class within Class groups, Z to A, should give the coupes Honda, Ford, CarMesh3D).
## 3. Layout

### 3.1 As built today (2026-11-22 23:38)

```
+------------------------------------------------------------------------------------------------------+
| fcn_CarMesh3D_browseLibrary     (title bar, 50 px: version line | "The vehicle library: tick ...")   |
+------------------------------------------------------------------------------------------------------+
| +1. Group by------+ +2. Sort within each group by-+ +3. Filter: keep the vehicles shown ...-+  39 of 39|
| |[Class (body) v] | |[Class (body style) v][ ]Desc| |[part of a name, year, ...][Apply][Clear]|[Done: ]|
| +-----------------+ +-----------------------------+ +---------------------------------------+ close.. |
| Returned when closed:   (none selected: closing returns a fresh copy of ...)  [Copy names][Select all |
| the selected, in order                                                         shown][Clear]         |
+------------------------------------------------------------------------------------------------------+
| Compact cargo van   (2)                                       (group header, 30 px, white on blue)   |
| +--------------------------------------------------------------------------------------------------+ |
| | [3D picture 270] [2D picture 270]  ★ 2014 Ford TransitConnect XLTCargoLWB      [ ] Select        | |
| |                                    2014_Ford_TransitConnect_XLTCargoLWB        [View       ]     | |
| |                                    Class / Size / Processed / Review / License [Edit labels]     | |
| |                                                                                [Review     ]     | |
| +--------------------------------------------------------------------------------------------------+ |
| ...  (rows 210 px, scrolling)                                                                        |
+------------------------------------------------------------------------------------------------------+
```

- Window: `uifigure`, 1400 x 900 pixels (smaller if the screen is: screen width - 80, screen height - 120), centered; background `[0.97 0.97 0.97]`; named `fcn_CarMesh3D_browseLibrary: the vehicle library`.
- Title bar (`fcn_CarMesh3D_addTitleBar`, 50 px). Its subtitle: "The vehicle library: tick "Select" on the vehicles wanted; their MATLAB names are returned when this window is closed", or, with `Vehicles=`, "Part of the vehicle library: the N vehicles given (Vehicles option). Tick ..."
- Under it a grid of three rows: **66 px** (the controls), **44 px** (the selection), the rest (the list); padding 10 left and right, 8 top and bottom; spacing 6.
- Control row: four columns, **220, 290, rest, 175 px**, spacing 8.
- Selection row: five columns, **215, rest, 110, 120, 80 px**, spacing 6.
- List: scrolling, rows 4 px apart; a group header **30 px**, a vehicle row **210 px**; a vehicle the filter hides has a row of 0 px and is invisible.

### 3.2 Agreed (2026-11-23)

The same layout: it already follows B1 to B5 and suits a list. No pancake menu (nothing here is used seldom enough to hide). Changes are small (section 5): Descending stops reversing the groups (B7), Enter applies the filter (B9), the missing tooltips are added, and "Clear" is renamed.

### 3.3 Proposed: a text table and a preview panel (Claude, 2026-11-23 23:05; for Sean's review)

**Why** (measured 22:26 to 22:51, see the change log): the browser's own code takes about 0.1 s for any re-sort, but in a visible window the screen could stop updating for about 60 s; the stall came from the list's 80 pictures (with none, or 40, it did not happen), most likely when the window was covered by another. With hundreds to thousands of vehicles, a list of picture rows (about 15 controls per vehicle: 607 for 40) also gets slow to open. Sean (22:54): "switch the list to only text, and give some type of click-to-see option for the images".

```
+---------------------------------------------------------------------------------------------------------------+
| fcn_CarMesh3D_browseLibrary        (title bar: version | "The vehicle library: tick Select ...")             |
+---------------------------------------------------------------------------------------------------------------+
| +1. Group by------+ +2. Sort within each group by-----------+ +3. Filter ...-----------------------+ 40 of 40 |
| |[Class       v]  | |[Year          v] Order? [Newest first v]| |[ part of a name ...][Apply][Clear] | [Done]   |
| +-----------------+ +-----------------------------------------+ +------------------------------------+          |
| Returned when closed: selectedNames = {'2009_Honda_Fit_Sport'};   % 1 vehicle(s)   [Copy][Select all][Clear] |
+--------------------------------------------------------------------------+------------------------------------+
| Sel | * | Vehicle                    | Year | Make  | Length | Score | Rev. | PREVIEW: 2012 Honda Civic Si   |
|-----+---+----------------------------+------+-------+--------+-------+------|  [3D picture, 420 x 300]          |
| COUPE (3)                                         (tinted group row)       |  [2D picture, 420 x 300]          |
| [ ] | * | 2012 Honda Civic Si        | 2012 | Honda |  4.46  | 100.0 |  0 % |  Class: Coupe  * exemplar        |
| [ ] | * | 2006 Ford Mustang GT       | 2006 | Ford  |  4.78  | 100.0 |  0 % |  Size: 4.46 x 1.75 x 1.40 m ...  |
| [ ] |   | 2026 CarMesh3D Generic ... | 2026 | CarM..|  4.62  | 100.0 |  0 % |  Processed / Review / License    |
| CROSSOVER OR COMPACT SUV (5)                                               |  [ ] Select                       |
| ...   (a uitable: scrolls; fast for thousands of rows)                     |  [View] [Edit labels] [Review]    |
+--------------------------------------------------------------------------+------------------------------------+
```

- **The table** (`uitable`, about 60 % of the width): one row per vehicle, text only, no pictures. Proposed columns (C2S 11): **Select** (a tick box, the only editable column), **★** (exemplar), **Vehicle** (the name), **Year**, **Make**, **Class** (when not grouped by class), **Length (m)**, **Score**, **Review (% approved)**, **License** (short). The MATLAB name shows in the preview and in a tooltip.
- **Groups** (C2S 10): a tinted, bold row per group ("COUPE (3)"), as the list's headers today; it cannot be ticked or previewed.
- **The preview panel** (right, about 40 %, 440 px or more): the vehicle of the row clicked (C2S 12): its 3D and 2D pictures (the same cached pictures as now, one vehicle at a time), its name and MATLAB name, the full details (the same text as today's rows), its own Select tick box (the same as the table's), and View, Edit labels and Review. With nothing clicked: the first vehicle shown.
- **Controls above the table stay as built** (Group by, Sort, Order?, Filter, the selection row, Done): rules B1 to B13 keep their meaning. Whether clicking a column heading also sorts is C2S 9.
- **Keyboard:** up and down arrows move through the rows and the preview follows (the table does this by itself).
- **Rule 26:** opening (reading the library) keeps its progress dialog; a re-sort of a text table should take well under a second, so it needs none.
- **Kept:** every option, output and hook (section 4.5); the question before Edit labels and Review; the pictures' cache. New hooks for tests: `Preview(name)` (show this vehicle in the preview) and `Previewed()`.
- **Scale check before building it fully** (Claude): a table of 2,000 made-up rows, sorted and regrouped in a visible window, timed (needs Sean's OK for a visible window).

## 4. The window as built today

### 4.1 Control row (top)

| Control | Kind | Default | Tooltip | What it does |
|---|---|---|---|---|
| **1. Group by** | box (bold title) with a drop-down: Class (body style), Make, Year, Review status, Exemplars first, License, (no groups) | Class (or `GroupBy=`) | "The headings the list is divided under" | Divides the list under headings, one per group. |
| **2. Sort within each group by** | box with a drop-down: Make, Year, Class (body style), Length, Score, Review (% approved), Date built, Date reviewed | Class (or `SortBy=`) | "The order of the vehicles under each heading" | Orders the vehicles in each group; ties by name, A to Z. Missing values (no review date, say) go last. |
| Descending | check box, 95 px, in box 2 | off (or `Descending=`) | (none) | Reverses the order. **It reverses the order of the groups too** (see C2S 3). |
| **3. Filter: keep the vehicles shown whose name, MATLAB name or class holds** | box with a text box | empty; placeholder "part of a name, year, make, class" | "Type, then press Apply filter: each filter narrows what is shown; Clear filters shows them all again" | Where the filter text is typed. |
| Apply filter | button, 90 px | | (none) | Applies the text as a filter (B2): a vehicle matches when every word of the text is in its name, MATLAB name, class name or class key (case ignored). Empty text: a warning "Type part of a name, year, make or class in the filter box, then press Apply filter." Text that matches none of the vehicles shown: not applied, and a warning "No vehicle now shown has "..." in its name, MATLAB name, or class, so the filter was not applied." The box is emptied after a filter is applied. |
| Clear filters | button, 90 px | | (none) | Removes every filter and empties the box. |
| count | gray text | | | "39 of 39 vehicles shown", or with filters "12 of 39 shown; filters: "2014" + "honda"". |
| Done: close and return | button, bold, 30 px high | | (none) | Closes the window and returns the selection (section 4.5). The window's close box does the same. |

Warnings appear in a `uialert` (in the command window when the window is hidden).

### 4.2 Selection row

| Control | Kind | Tooltip | What it does |
|---|---|---|---|
| "Returned when closed: / the selected, in the order shown" | bold text, two lines | | Says what the next text is. |
| the selection | text, Courier New 12, dark blue `[0.10 0.25 0.55]`, wraps | | `selectedNames = {'2009_Honda_Fit_Sport', ...};   % 2 vehicle(s)`, or "(none selected: closing returns a fresh copy of 2009_Honda_Fit_Sport)". |
| Copy names | button, 110 px | "Copy the line shown, a MATLAB cell array, to the clipboard" | Copies the text shown, as it is. |
| Select all shown | button, 120 px | (none) | Ticks Select on every vehicle the filters show. |
| Clear | button, 80 px | (none) | Unticks Select on every vehicle the filters show. |

### 4.3 The list

- **Group header** (when grouped): `  <group>   (<count shown>)`, 16 pt bold, white on `[0.25 0.35 0.5]`. Group names: the class name; the make; the year; "Reviewed", "Partly reviewed", "Not reviewed"; "★ Exemplars of their class" and "Other vehicles"; the license name. Groups are ordered A to Z (years by number; review as reviewed, partly, not; exemplars first), reversed by Descending.
- **Vehicle row** (a white panel; an exemplar's has a gold border `[0.85 0.65 0]`, 2 px), four columns **270, 270, rest, 120 px**, padding 6, spacing 10:

| Part | What it shows |
|---|---|
| 3D picture | The mesh in its label colors (`fcn_CarMesh3D_plotLabels`, drawn by `fcn_CarMesh3D_plotVehicle`), seen from the front left and a little above (`view(135, 18)`, perspective), 420 x 300 at 96 dpi. "no 3D picture" on gray when missing. |
| 2D picture | The overhead outline, front to the right: body dark blue `[0.10 0.22 0.55]`, interior tan, windows light blue, lights by type (headlight yellow, tail red, turn orange, running cyan, backup green, others magenta), wheels near-black. "no 2D outline" when missing. |
| Name | 22 pt bold; an exemplar gets "★ " and gold-brown `[0.6 0.4 0]`. |
| MATLAB name | Courier New 13, gray. |
| Details (HTML, 12 pt) | **Class:** the class name, "★ exemplar of its class" (bold, gold), "(generic: made by CarMesh3D from the class)". **Size:** length, width, height in m; faces with thousands commas. **Processed:** date and time (or "not yet"), mesh version and status; **score**; checks failed. **Review:** "not reviewed by a person" in red, or the status, items answered of total, % approved, rejected, the logged decision, reviewers, last date. **License:** name, "model by" author; "none needed (made by CarMesh3D from its body style)" for generic vehicles; "(not found)". |
| Select | check box, 15 pt bold, "Select" (no tooltip). |
| View | button, tooltip "Open in fcn_CarMesh3D_viewLabels (changes nothing)". Opens the viewer on the vehicle's mesh file (with its outline), without waiting. |
| Edit labels | button, tooltip "Open in fcn_CarMesh3D_paintLabels". |
| Review | button, tooltip "Open in fcn_CarMesh3D_reviewVehicle". |

- **Edit labels and Review ask first** (`uiconfirm`, warning icon): "Changes made in the mesh editor (fcn_CarMesh3D_paintLabels) are saved to <vehicle> itself. Open the vehicle, or a fresh demo copy of it (changes not saved)?" with **Open the vehicle**, **Open a demo copy** (the default), **Cancel**. A demo copy is `fcn_CarMesh3D_makeDemoCopy` (in the temporary folder). In a hidden window, the demo copy is used without asking.

### 4.4 Behavior

- **Opening:** a progress dialog ("Reading the library...", then "Reading <ID> (k of N)...") while the vehicles are read (`fcn_CarMesh3D_browseVehicles`, `fcn_CarMesh3D_findVehicleFiles`, `fcn_CarMesh3D_meshHistory`, the review file `review_<ID>.mat`).
- **Pictures** are drawn once and kept in `<tempdir>\CarMesh3D_thumbnails` as `<ID>_3D_<file time>.png` and `<ID>_2D_<file time>.png`; a new mesh or outline file gets a new picture.
- **Review status:** "not reviewed" (no item answered), "partly reviewed" (some answered and no logged decision), "reviewed".
- **Selection order:** the order shown; vehicles selected but hidden by a filter come last.
- **Mouse:** the list scrolls with the wheel; nothing else special. **Keyboard:** none (Enter in the filter box does not apply it).
- **Remembered:** nothing (no MATLAB preferences); each call opens at its options or the defaults.

### 4.5 The call, its outputs and hooks

| Option | Default | What it does |
|---|---|---|
| `Vehicles` | {} (the whole library) | Only these MATLAB names; names not finished are listed in a warning (`CarMesh3D:notInLibrary`) and left out. |
| `SortBy` | 'class' | 'make', 'year', 'class', 'length', 'score', 'review', 'built', 'reviewDate'. |
| `GroupBy` | 'class' | 'class', 'make', 'year', 'review', 'exemplar', 'license', 'none'. |
| `Order` | '' (the sort's own default) | The order within each group, in the Order? words (B11). |
| `Descending` | [] | The older way to give the order, kept for old calls; `Order` wins. |
| `Selected` | {} | Names ticked at the start. |
| `DefaultVehicle` | '2009_Honda_Fit_Sport' | Copied and returned when none is selected. |
| `Wait` | true when visible | Wait until closed. |
| `Visible` | true | false builds it hidden (tests). |
| `DataFolder` | [] (the one next to Functions) | The library's Data folder. |
| `FigNum` | [] | -1: fast mode, no input checks. |

**`selectedNames`**: the selected MATLAB names in the order shown; with none, `{<folder of a fresh copy of DefaultVehicle>}` (a message in the command window says so). With `Wait=false`: the selection when the window opened.

**`browser`**: `Figure`, `Vehicles` (one element per vehicle: ID, Name, Year, Make, Model, Trim, Folder, class, size, score, build, license, review fields, picture files), `Order()`, `SetSort(key, (flagDescending))`, `SortOrder()`, `SetGroup(key)`, `ApplyFilter(text)` (true if applied), `ClearFilters()`, `Filters()`, `Open(name, tool, (flagUseCopy))` ('view', 'edit', 'review'), `Select(names)`, `Deselect(names)`, `Selected()`, `Result()`, `Close()`.

## 5. Agreed design for the list version (2026-11-23; built 22:06, return point 23:01)

### 5.1 What already follows the rules (keep)

- The three numbered boxes, left to right (B1); the filter button, stacking, and the never-empty list (B2); the selection as text with Copy names (B3); the title bar (B4); `Vehicles=` (B5).
- Buttons only for actions (rule 11); warnings in the window; the question before Edit labels and Review, with the demo copy as the default (a safe default).
- The pictures kept between calls; the exemplar's gold border and star.

### 5.2 Control row, proposed

```
+1. Group by--------+ +2. Sort within each group by--------------------+ +3. Filter: keep ... holds-----------------+  39 of 39 shown
|[Class (body)   v] | |[Year              v]  Order? [Newest first  v] | |[ part of a name, year...][Apply][Clear]  | [Done: close and return]
+-------------------+ +-------------------------------------------------+ +------------------------------------------+
```

- **Order?** (B11), a drop-down of two choices worded for the sort, replaces the Descending check box. It orders only the vehicles within each group; the groups keep their own order (B7), as box 2's title says. Box 2 is 400 px (was 290).
- **Enter in the filter box applies the filter** (B9); typing alone still does nothing (B2).

### 5.3 Selection row, proposed

```
Returned when closed:                selectedNames = {'2009_Honda_Fit_Sport'};   % 1 vehicle(s)      [Copy names] [Select all shown] [Clear selection]
the selected, in the order shown
```

- "Clear" becomes **Clear selection**, so it is not taken for "Clear filters" (120 px).
- **Copy names** is grayed out while nothing is selected (today it copies the sentence "(none selected: ...)", which is not MATLAB).

### 5.4 Tooltips to add (rule 14)

| Control | Proposed tooltip |
|---|---|
| Order? | "The order of the vehicles under each heading (the headings keep their own order)" |
| Apply filter | "Keep, of the vehicles shown, those whose name, MATLAB name or class holds every word typed. A filter that matches none is not applied." |
| Clear filters | "Remove every filter: show all the vehicles again" |
| Done: close and return | "Close this window and return the selected vehicles' MATLAB names (with none selected: a fresh copy of the default test vehicle)" |
| Select all shown | "Tick Select on every vehicle shown (not on those the filters hide)" |
| Clear selection | "Untick Select on every vehicle shown" |
| Select (each row) | "Return this vehicle's MATLAB name when the window is closed" |
| Edit labels | "Open in the label painter, fcn_CarMesh3D_paintLabels (asks: the vehicle or a demo copy)" |
| Review | "Open in the Model Reviewer, fcn_CarMesh3D_reviewVehicle (asks: the vehicle or a demo copy)" |

The question before Edit labels says "mesh editor"; Claude proposes "label painter", the name used everywhere else.

### 5.5 Kept as now

The list (4.3), the pictures and their cache, the review status rules, the opening progress, all options, outputs and hooks (4.5). Nothing is remembered between calls (B8).

## 6. Differences found between the code and its help text

(For Sean's information; Claude changed no code.)
- `fcn_CarMesh3D_browseLibrary.m` line 1033: Descending reverses the groups as well as the vehicles in them, so "Exemplars first" with Descending puts the exemplars last, and box 2's title ("Sort within each group") does not say so (C2S 3).
- Line 365: Copy names copies whatever text is shown, so with nothing selected it copies a sentence, not a cell array.
- Lines 614-628: `browser.Result()` makes a new demo copy at each call while nothing is selected (the result is fixed only when the window closes).
- Line 387: `browser.Open(name, ...)` with a name not in the list fails with MATLAB's indexing error, not a clear message.
- Lines 318, 356, 369: the comments say "Row 2", "Row 3", "Row 4"; the grid's rows are 1, 2, 3.

## 7. Test vehicles

The browser's test (`script_test_fcn_CarMesh3D_browseLibrary.m`) runs on the real library (more than 10 vehicles, with exemplars). No change proposed; the GUI test vehicle (painter task P1) will appear in the list like any other finished vehicle, unless Sean wants it left out (to check: it lives under `Data/Samples`).

## 8. Open questions

**(Claude to Sean)**

*(None open.)*

**(Sean to Claude)**


*(None open.)*

## 9. Open issues

*(Sean adds issues here.)*

## 10. Change log

- 2026-11-23 16:20: started by Claude (thread C) from the window as built (code of 2026-11-22 23:38) and its picture; Sean's rules for this window (B1 to B5) gathered from the code's revision history; the painter file's rules referred to, not repeated; proposal and C2S 1 to 5 for Sean's review. No code changed.
- 2026-11-23 17:56: reviewed by Sean; C2S 1 to 5 answered and closed (thread below). Rules B6 to B9 added from the answers; sections 3.2, 5.2 to 5.5 updated to match. No code changed yet.

  **Closed questions (2026-11-23), with Sean's answers as written:**

  **C2S 1. The Descending check box.** Rules 6 and 10 say on/off choices are radio buttons.
  - (A) *Recommended.* A radio pair "Order?" with A-Z / Z-A (or Ascending / Descending if it fits) in box 2.
  - (B) Keep the check box, as a stated exception for this window.

  (B)

  **C2S 2. The Select check box on each row.** A list of about 40 rows, each with an on/off choice.
  - (A) *Recommended.* Keep the check box, as a stated exception to rules 6 and 10 for picking items from a list (it is what users expect, and one click toggles it; an Off/On pair on 40 rows is heavier to read).
  - (B) An Off/On radio pair on each row, like the painter.

  (A)

  **C2S 3. Descending and the order of the groups.** Today Descending also reverses the groups (exemplars last, classes Z to A).
  - (A) *Recommended.* Groups always in their own order (classes A to Z, years oldest first, reviewed first, exemplars first); Order? changes only the vehicles within each group, as box 2's title says.
  - (B) Keep it as now, and say so in box 2's title.
  - (C) A second Order? for the groups, in box 1.

  (A)

  **C2S 4. Remembering the arrangement, and Reset to defaults** (rules 17, 23, 24).
  - (A) The window remembers Group by and Sort/Order (MATLAB preferences, group `CarMesh3D`) for next time; options given to the call still win; a **Reset to defaults** button puts back class / class / A-Z and clears the filters.
  - (B) *Recommended.* As now: each call opens at its options or the defaults, so nothing needs resetting; no new button. (The browser is opened often by scripts, which expect the same list each time.)

  (B)

  **C2S 5. Enter in the filter box.**
  - (A) *Recommended.* Enter applies the filter, the same as pressing Apply filter (typing alone still does nothing, per B2).
  - (B) Only the button applies it, as now.

  (A)

  (Sean to Claude, same review: "See answers listed under each C2S question above".)
- 2026-11-23 18:02 (Sean, Q20 (A)): rule B10 added (painter rule 25: every input argument shown in the GUI).
- 2026-11-23 21:30: Sean's test of the 18:05 build (T1 to T5), C2S 6 asked from his T2 note and answered (A), and closed (threads below). T2 found a bug (Descending and the sort drop-down undid each other), fixed. Rule B6 changed (only Select stays a check box), B7 reworded, B11 added (the Order? drop-down); sections 4.5 and 5.2 to 5.4 updated. Built and tested (script_test_fcn_CarMesh3D_browseLibrary passes); README updated (`Order=` option).

  **Sean's test results (2026-11-23 21:17), with Claude's reply:**

  T-list:

  > T1 (Claude, needs your OK): run script_test_fcn_CarMesh3D_browseLibrary. It builds hidden windows, which earlier took your cursor with the large painter, so I'll run it only while you're away or when you say OK. If it passes, I'll copy the two files into the repo.

  Sent the OK

  > T2 (Sean): fcn_CarMesh3D_browseLibrary(), then Group by "Exemplars first", then tick Descending. Exemplars should stay at the top, and the order within each group should reverse.

  Not sure what "order within each group should reverse. When I select "Exemplars first", the remainder go into "Other vehicles (29)". If I then tell it sort by Year, that works - in Exemplars and in Other, both groups are sorted by Year lowest to highest. But if I then hit "Descending", the Sort with each group by suddenly jumps selection (by itself) to "Class (body style)" and the years are definitely not sorted highest to lowest. When selecting the "Descending" checkbox, the selection of "Sort within each group by" should not change by itself. I was expecting that, if the Sort within each group is by Year, and then I hit descending, I should see the newest year at top, and oldest at bottom. As well, the name descending is odd and actually doesn't fit will with the purpose of this button. For example, the default ordering for year should be "Sorted Newest to Oldest" since newer vehilces are more relevant than old ones. But for Class, the sort order is "Alphabetical" which some might not realize is "Ascending" - it is an odd way to describe alphabetical order, as the word implies a metric (mass, time, length). Perhaps the Sort Option should be a drop-down menu or other design? and perhaps one that is specific to the "Sort within each group by" selected?

  > (Claude, 21:25) Sean is right on both counts. **The jump is a bug**, now fixed: the Descending box's callback kept the sort the window opened with (Class), and the sort drop-down's callback kept the Descending value the window opened with, so each undid the other (anonymous functions keep the values from when they were made). Both now read the current values. The test now checks this exact case: Exemplars first, sort by Year, tick Descending: the sort stays Year, newest first in both groups; then choosing Length keeps Descending ticked. The fixed code is in `pending\browseLibrary_2026_11_23b\` and is not yet in the repo: its test builds hidden windows, so Claude runs it when Sean says OK. **The naming** is C2S 6 above.


  > T3 (Sean): type honda in the filter box and press Enter. The list should narrow, the box should empty, and the count should read "… shown; filters: "honda"".

  Works exactly as described.

  > T4 (Sean): type toyota, then click Apply filter. There should be one warning, not two, and the filter should not be applied.

  Works exactly as described.

  > T5 (Sean): untick everything. Copy names should be grayed out. Hover over the buttons and check boxes; every one should show a tooltip.

  Works exactly as described.

  Re: C2S 6. The sort order control: Please go with Option A

  **C2S 6, closed (Sean 21:22: "Please go with Option A"):**

  **C2S 6. The sort order control** (from Sean's T2 note below, 21:17). Sean: "Descending" is an odd word for alphabetical order, and each sort has a natural order of its own (newest vehicles first, for example). This changes the answer to C2S 1 (keep the Descending check box), so it is asked again.
  - (A) *Recommended.* Replace the Descending check box with an **Order?** drop-down beside the sort drop-down, whose two choices are worded for the sort chosen, and which starts at that sort's own default (first below) each time the sort changes:
    - Name, Make, Class: **A to Z** / Z to A
    - Year, Date built, Date reviewed: **Newest first** / Oldest first
    - Length: **Longest first** / Shortest first
    - Score: **Highest first** / Lowest first
    - Review (% approved): **Most approved first** / Least approved first

    The call's `Descending=` option stays for old calls (true: Z to A, newest, longest, highest, most approved first), and a new `Order=` option takes the words shown ('A to Z', 'Newest first' ...); with neither, each sort opens at its own default. The box title stays "2. Sort within each group by"; groups keep their own order (B7).
  - (B) The same two worded choices, but as a radio pair under the sort drop-down (rule 22: "Order?" with its two choices), its words changing with the sort. Box 2 needs a second line (the control row grows from 66 to about 90 px).
  - (C) Keep the check box, renamed "Reverse order", with one default order for all sorts (as now, A to Z and smallest first).
- 2026-11-23 22:05: Sean's test of the Order? build (21:36, below). Name sort dropped (Sean, 21:54; C2S 7 closed in chat: "Suggest dropping name, because we already have sorting by Make"): rule B12. Text sorts now ignore case ("GUITestVehicle" came before "GenericSedan", found by the new test). New test of all 112 arrangements (7 Group by x 8 sorts x 2 orders): groups in their own order, vehicles within each group in the order chosen, and each header just above its group; it passes. Groups shown Z to A not reproduced: C2S 8.

  **Sean's test results (2026-11-23 21:36):**

  > To try it, use the demo menu's browseLibrary item, sort by Year, and switch Order? between Newest first and Oldest first.

  Results: (using "Group by")
  Sort by?    Ordering?         Behavior?
  Name        A to Z            Groups get sorted A to Z (correct), cars within each group not sorted by any clear metric because name not clear for in-group. For example, in Coupe group, user would think the names were CarMesh3D, Honda Civic Si, Ford Mustang. But C, H, F is not a sort order of either Z to A or A to Z (bug?) Need to disambiguate the word "name".
  Name        Z to A            Buggy. Groups NOT sorted A to Z (bug), cars within each group NOT sorted by any clear metric because name not clear for in-group. For example, in Coupe group, user would think the names were CarMesh3D, Honda Civic Si, Ford Mustang. But C, H, F is not a sort order of either Z to A or A to Z (bug?) Need to disambiguate the word "name".
  Year        Newest first      Works
  Year        Newest first      Works
  Make        A to Z            Works
  Make        Z to A            Works
  (stopped here because it was tedious - suggest automating this test because permutations are too many)
- 2026-11-23 22:12: C2S 8 answered by Sean's screenshot (22:05: Group by Class, sort by Class, Z to A; "Expecting in the Coupe grouping for Honda to be at top, then Ford in middle, then CarMesh"). Cause: sorting by the same thing as the groups made every vehicle in a group a tie, and ties were ordered by name (which starts with the year), always A to Z, so the coupes came 2006, 2012, 2026. Fixed: rule B13. The test checks this case and, for every text sort, that makes follow the order chosen; it passes. Closed:

  **C2S 8. Groups shown Z to A (Sean's 21:36 result, "Name, Z to A").** Claude could not reproduce it: in a hidden window, with Group by Class and every sort and order, the groups come out in their own order, and each header sits just above its own vehicles (now checked by the test for all 112 arrangements). To find it, Claude needs:
  - which Group by was chosen (Class, the default?), and
  - if Sean can, a screenshot of the list as it looked, pasted here or saved in `Project_CarMesh3D\pictures\`. (Claude will not capture a browser window itself: that hung MATLAB at 21:40.)
- 2026-11-23 22:12: "Review now (for Sean)" section added at the top, with test steps T6 to T10 for Sean's results (Sean, 22:10: keep the tests in this file so they go in the change log).
- 2026-11-23 23:05: return point pushed by Sean (23:01) with the list version; local copy in `Project_CarMesh3D\backups\browseLibrary_listVersion_2026_11_23`. Sean chose the redesign (Q23 (A), 22:59: a text table and a preview panel, in place of the list of picture rows). Section 3.3 proposed, with C2S 9 to 12. The list version's test steps, never answered, retired from "Review now":

  ## Review now (for Sean)

  *Added 2026-11-23 22:12 by Claude. Sean writes his result under each step (works, or what he saw). When a round is done, Claude moves the steps and results into the change log (section 10) and clears this section for the next round.*

  **What Claude already tested (by script, hidden):** `script_test_fcn_CarMesh3D_browseLibrary.m` passes (22:10, 38 s, no windows or timers left). It covers every arrangement, 7 Group by x 8 sorts x 2 orders = 112: the groups in their own order, the vehicles within each group in the order chosen, and each header just above its group; the coupe case from Sean's screenshot; Order= and the older Descending=; Enter in the filter box; tooltips on every control; Copy names grayed out; the demo copy made once; Open() with an unknown name; the data folder in the subtitle.

  **What needs Sean's eyes and hands** (open it from the demo menu: "browseLibrary: browse the vehicle library and pick vehicles"):

  **T6. The Order? words.** Pick each sort in turn. The Order? choices change to fit it: Make and Class show A to Z / Z to A; Year, Date built and Date reviewed show Newest first / Oldest first; Length shows Longest first / Shortest first; Score shows Highest first / Lowest first; Review shows Most approved first / Least approved first. Each new sort starts at its first choice. "Name" is no longer in the sort list.

  (Sean's result:)

  **T7. The coupe case.** Group by Class, sort by Class, Order? Z to A. The coupes read Honda Civic Si, Ford Mustang GT, CarMesh3D Generic Coupe. Switch to A to Z: they reverse.

  (Sean's result:)

  **T8. Edit labels on any row.** The question names the "label painter" (it said "mesh editor" before), and "Open a demo copy" is the default button. Cancel closes the question without opening anything.

  (Sean's result:)

  **T9. Done: close and return, with nothing selected.** The window closes, and the command window says a fresh copy of the Fit is returned.

  (Sean's result:)

  **T10. Look and feel.** Box 2 is wider now (400 px). Nothing in the top row is cut off at Sean's window size, the filter box's title especially.

  (Sean's result:)

  ---
- 2026-11-23 23:06 (Sean): C2S 9 to 12 answered: "your proposals are good starts... Please proceed." So each (A): the boxes only sort (headings do not); a tinted bold row per group; the columns Select, ★, Vehicle, Year, Make, Class, Length, Score, Review, License; the preview shows the row last clicked. Built 23:06 to 23:59 (table and preview, section 3.3). The questions as asked:
  - C2S 9 (sorting by a column heading): (A) the boxes only; (B) a heading sets the Sort box; (C) headings sort by themselves, ignoring groups.
  - C2S 10 (groups in the table): (A) a tinted bold row per group; (B) a Group column instead.
  - C2S 11 (columns): (A) as above; (B) fewer; (C) Sean lists them.
  - C2S 12 (the preview): (A) the row last clicked; (B) on hover only; (C) a separate window on double-click.
- 2026-11-24 01:28 (Sean): T13 (the preview panel scrolls when the window is short): **pass**. C2S 13 (the tree rule) opened.

- 2026-11-24 02:20 (Sean): C2S 13 answered: "agree with (A)". Built 02:20 to 02:35: the buttons close the browser and return the step (third output `nextStep`); `fcn_CarMesh3D_openTool` (new) opens it; the demo menu's library example calls it; the browser opens no tool itself. The question as asked:
  > **C2S 13 (= chat Q31, 2026-11-24 01:32). The View / Edit labels / Review buttons and the tree rule.** Sean, 01:28: "let's try to follow a clean 'tree' paradigm where entry in/out of a branch is mediated by the trunk, not via other branches." Today these buttons open the viewer, the painter and the reviewer from inside the browser (search `case 'view'` in the code).
  > - (A) *Recommended.* Keep the buttons, but each closes the browser and returns the chosen vehicle and the step asked for to its caller (the demo menu), which opens that tool. Students keep the same quick path; only the trunk opens tools.
  > - (B) Remove the buttons: the browser only returns the chosen vehicles, and the next tool is picked from the demo menu.
- 2026-11-24 02:35 (Claude): tests after C2S 13, run hidden with Sean's OK: the browser's test (View now checked to close the browser and return the vehicle in the preview, with no viewer opened), `fcn_CarMesh3D_openTool`'s and the demo menu's all pass; the real Fit's files unchanged; no timers left.
- 2026-11-24 06:06 to 07:04 (Agent D, for Claude; Sean offline; Q35/Q36 A, Q39, Q40 A): **the browser made fully drivable and tested by script.**
  - Every control has a unique Tag. New hooks: State, SetState, Press, Key, CheckLayout (through `fcn_CarMesh3D_guiDriver`), SelectRow and TickRow (through the table's own callbacks), SetSize, UseAsDemo, UseRepoDemo. Old hooks kept.
  - **Demo vehicle** (Q35, Q36 A): "★ Use as demo vehicle" and "Back to the repo's demo" in the preview (calling `fcn_CarMesh3D_demoVehicle`; a refused vehicle's reason in red in a new hint line); a "Demo" ★ column; with no vehicle chosen, the browser returns a copy of the demo vehicle (the user's own choice if set), not the Fit by name.
  - **Automated:** all 560 Group × Sort × Order × Filter combinations (set through the controls), checking the rows, their order, the group headers, the preview, the ticks and which buttons are enabled; 3 random walks of 250 steps (44 actions) with the same rules after every step, and a rule that no other window opens or closes (tree rule); View, Edit labels and Review return the right step, close the browser and open nothing; Done and the window's X close in about 0.02 s; an empty list; layout at 1400×900, 800×500, 640×400, 1600×1000, 1024×700 (and once in a visible window); the demo buttons (the preference put back by onCleanup).
  - **Bugs found and fixed:** after a re-sort or filter the highlighted row stayed on the old row number (showing another vehicle than the preview); clicking a group header row moved the highlight off the previewed vehicle; with nothing in the preview, View, Edit labels, Review and Select were still enabled; at 640×400 the table was 142 px wide, the filter box 0 px and Done off the window (widths now follow the window; short button words when narrow).
  - **Not fixed:** the title bar's version line is cut off below about 1200 px (`fcn_CarMesh3D_addTitleBar`); long MATLAB names cut off in the preview at 640 px; Copy names not tested (it would overwrite the clipboard); the demo test changes the shared preference for a few seconds.
  - Report: `Desktop\Claude\Project_CarMesh3D\agents\D\REPORT_browseLibrary.md`. T38 to T41 in Review now.
