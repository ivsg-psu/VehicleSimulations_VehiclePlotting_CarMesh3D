# 2009 Honda Fit Sport: L2F entries from Honda's own information (experiment)

*(2026-11-26, about 19:50 (the time first written here, 19:55, was guessed); Claude, at Sean's request of 19:45. Status: **auto**. Nothing here is verified yet, and none of it has gone into `lampFunctions_2009_Honda_Fit_Sport.csv`. The cell-by-cell data is in `lampFunctionsSources_2009_Honda_Fit_Sport.csv`, next to the matrix file.)*

## 1. Where the information came from

| Source | What it gave | Accessed |
|---|---|---|
| Honda, *2009 Fit Online Reference Owner's Manual* (U.S. and Canada), https://techinfo.honda.com/rjanisis/pubs/om/atk620/atk62009oma.pdf | the headlight switch and its positions (p. 74), high beams, fog lights and daytime running lights (p. 75), indicators (pp. 64–65), the hazard button (p. 76), the bulb table (p. 319) | 2026-11-26 |
| Honda, *2008 Fit Owner's Manual*, p. 76 (a copy on manualsdir.com), https://www.manualsdir.com/manuals/99893/honda-2008-fit.html?page=76 | the DRL text marked "Canadian models only" | 2026-11-26 |

This is the manufacturer's own manual, found by an ordinary web search. That is the best kind of source for this.

## 2. Honda's names for the signals

| Our signal | Honda's name (2009 manual) | What Honda says |
|---|---|---|
| LowBeam | Headlights | the switch's headlight position "turns on the headlights"; pulling the lever back "returns to low beams" |
| HighBeam | High Beams; Flash high beams | lever pushed forward; a light pull flashes them |
| Running | Daytime Running Lights | the high beams "with reduced brightness", ignition on and parking brake released |
| Parking and Tail | (the switch's first position) | turns on "the parking lights, taillights, instrument panel lights, side-marker lights, and rear license plate lights" |
| TurnLeft, TurnRight | Turn Signal | |
| Hazards | Hazard Warning button | flashes all outside turn signals |
| Fog | Fog Lights (Sport model) | only "when the headlights are on low beam" |
| Brake | Stop/Taillights; High-mount brake light | |
| Backup | Back-up lights | |

## 3. What changes from the Fit's matrix today

The manual agrees with most of today's matrix: the headlamps, turn signals, fog lamps, rear tail/brake and backup lamps. Five things change or need a decision:

1. **The front marker lamps are not daytime running lights.** One 3.8 W amber bulb is both the parking light and the side marker. It lights with Parking and Tail. The manual's DRL is the high beams only, so Running goes from 1 (default) to 0.
2. **The rear-center lamp is the high-mount brake light, an LED.** It is labeled `tailBrakeLamp`, which is why it lights with Tail and Parking (0.4). Honda lists it apart from the taillights, so it should be Brake only. Better still, its kind could become `highMountStopLamp`, one of today's new kinds. That is a label change on the mesh.
3. **No emergency stop signal** is described in the 2009 manual, so EmergencyBrake goes to 0 on the tail/brake and high-mount lamps. This rests on the manual not mentioning it, so it is the weakest entry here.
4. **The daytime running lights: which market?** The 2009 manual describes the DRL with no region. The 2008 manual marks it "Canadian models only". A U.S. 2009 Fit Sport probably has no DRL. Sean's 0.3 stays for now, flagged.
5. **Lamps the mesh has no unit for:**
   - the license plate lights (5 W), which light in the parking position;
   - the interior lights: ceiling, cargo area and map. These belong to `fcn_CarMesh3D_interiorSignals` (Dome, MapLeft and MapRight, TrunkOpen).

The bulb wattages are recorded in the notes but not used. The taillight filament is 5 W of 21 W (0.24), and the matrix keeps its default 0.4.

## 4. The per-cell record (the format proposed)

`lampFunctionsSources_<ID>.csv` has one row per cell that has a source. Its columns:
- **Unit** and **Signal** name the cell.
- **Value** is the value found.
- **Status** is one of three:
  - `auto`: found by Claude; not trusted until checked.
  - `verified`: checked by a person (initials and date to be added).
  - `default`: no source, so the default stays.
- **MakerName** is the manufacturer's name for the signal.
- **Source** is the link, and **Page** the page or section.
- **Accessed** is the date the link was read.
- **Note** says what the source says.

The matrix file `lampFunctions_<ID>.csv` stays as it is. The sources file sits beside it, and the L2F window reads both.

## 5. Open question for Sean (Q98: how the L2F window shows sources)

- **(A) (recommended)** Cells with an `auto` status are drawn in an orange font. Clicking a cell fills a one-line strip under the matrix with that cell's maker name, source link (clickable), page and access date. A "Mark verified" button sits on that strip. This uses no extra width, and the strip changes as you click from cell to cell, which suits sources that differ cell by cell.
- **(B)** The same orange font, plus a fourth "Sources" panel below the matrix that lists every sourced cell of the vehicle, with links. Everything is visible at once, but it takes space in a window that the tier 2 and 3 columns have already made crowded.
- **(C)** Only the orange font and a row-level Source column (what the file has today). This is simplest, but it cannot hold a different link per cell.

(MATLAB's `uitable` can color single cells with `addStyle(..., 'cell', ...)`, but it has no tooltip per cell, so hovering is not an option. Clicking can be.)
