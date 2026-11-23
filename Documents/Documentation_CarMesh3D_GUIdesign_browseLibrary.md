# Design: the library browser, `fcn_CarMesh3D_browseLibrary`

*The style and layout choices for the library browser, kept so the window can be rebuilt from this file. Edit it freely: it is the place to change the design, and Claude builds from it. Started 2026-11-23 16:20 by Claude from the window as built (`fcn_CarMesh3D_browseLibrary.m`, last changed 2026-11-22 23:38, and its picture `Images/functions/fcn_CarMesh3D_browseLibrary.png`).*

**Status:** REVIEWED by Sean 2026-11-23 17:56 (C2S 1 to 5 answered; see the change log). Section 4 describes the window as it is today; section 5 is the agreed design, not yet built. Sections marked **(Sean)** are Sean's words or decisions; **(Claude, to confirm)** marks Claude's fill-ins.

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
- B6. **Two stated exceptions to rules 6 and 10 (on/off choices as radio pairs): the Descending check box and the Select check box on each row stay check boxes.** (C2S 1, C2S 2)
- B7. **Group by sets the order of the groups; Descending reverses only the vehicles within each group.** Groups are always in their own order: classes A to Z, years oldest first, reviewed first, exemplars first. (C2S 3)
- B8. **Nothing is remembered between calls:** each call opens at its options or the defaults, so there is no Reset to defaults button (rules 23, 24 do not apply). Scripts open this window often and expect the same list each time. (C2S 4)
- B9. **Enter in the filter box applies the filter**, the same as Apply filter; typing alone still does nothing (B2). (C2S 5)

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

## 4. The window as built today

### 4.1 Control row (top)

| Control | Kind | Default | Tooltip | What it does |
|---|---|---|---|---|
| **1. Group by** | box (bold title) with a drop-down: Class (body style), Make, Year, Review status, Exemplars first, License, (no groups) | Class (or `GroupBy=`) | "The headings the list is divided under" | Divides the list under headings, one per group. |
| **2. Sort within each group by** | box with a drop-down: Name, Year, Make, Class (body style), Length, Score, Review (% approved), Date built, Date reviewed | Class (or `SortBy=`) | "The order of the vehicles under each heading" | Orders the vehicles in each group; ties by name, A to Z. Missing values (no review date, say) go last. |
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
| `SortBy` | 'class' | 'name', 'year', 'make', 'class', 'length', 'score', 'review', 'built', 'reviewDate'. |
| `GroupBy` | 'class' | 'class', 'make', 'year', 'review', 'exemplar', 'license', 'none'. |
| `Descending` | false | Descending order. |
| `Selected` | {} | Names ticked at the start. |
| `DefaultVehicle` | '2009_Honda_Fit_Sport' | Copied and returned when none is selected. |
| `Wait` | true when visible | Wait until closed. |
| `Visible` | true | false builds it hidden (tests). |
| `DataFolder` | [] (the one next to Functions) | The library's Data folder. |
| `FigNum` | [] | -1: fast mode, no input checks. |

**`selectedNames`**: the selected MATLAB names in the order shown; with none, `{<folder of a fresh copy of DefaultVehicle>}` (a message in the command window says so). With `Wait=false`: the selection when the window opened.

**`browser`**: `Figure`, `Vehicles` (one element per vehicle: ID, Name, Year, Make, Model, Trim, Folder, class, size, score, build, license, review fields, picture files), `Order()`, `SetSort(key, flagDescending)`, `SetGroup(key)`, `ApplyFilter(text)` (true if applied), `ClearFilters()`, `Filters()`, `Open(name, tool, (flagUseCopy))` ('view', 'edit', 'review'), `Select(names)`, `Deselect(names)`, `Selected()`, `Result()`, `Close()`.

## 5. Agreed design (2026-11-23; not yet built)

### 5.1 What already follows the rules (keep)

- The three numbered boxes, left to right (B1); the filter button, stacking, and the never-empty list (B2); the selection as text with Copy names (B3); the title bar (B4); `Vehicles=` (B5).
- Buttons only for actions (rule 11); warnings in the window; the question before Edit labels and Review, with the demo copy as the default (a safe default).
- The pictures kept between calls; the exemplar's gold border and star.

### 5.2 Control row, proposed

```
+1. Group by--------+ +2. Sort within each group by-----+ +3. Filter: keep ... holds-----------------+  39 of 39 shown
|[Class (body)   v] | |[Class (body style) v] [ ]Descending| |[ part of a name, year...][Apply][Clear]  | [Done: close and return]
+-------------------+ +----------------------------------+ +------------------------------------------+
```

- **Descending** stays a check box (B6). It now reverses only the vehicles within each group; the groups keep their own order (B7), as box 2's title says.
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
| Descending | "Reverse the order of the vehicles under each heading (the headings keep their order)" |
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
