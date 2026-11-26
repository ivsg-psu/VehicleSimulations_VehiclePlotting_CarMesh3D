# CarMesh3D naming table: labels, signals and flags (Q95 (A), for approval)

*Drafted by Claude, 2026-11-26 12:50, after Sean's Q95 answer (12:14): "do option A, with ... a very clear description of the variable usage, even a paragraph if necessary for each." Nothing here is renamed yet. Sean marks up this file; Claude renames in one step (code, tests, data, docs, AnimateCar3D), with no aliases (Sean, 10:36), once the table is approved.*

## 1. Why

Values passed between functions and repos mix three different kinds of thing, and today their names do not say which:

- **What a face *is*** (a label): its part (body, glass, wheel, light, trim, interior), and for a lamp face its lamp kind (headlamp, tailBrakeLamp, ...). Labels are set when a mesh is built or painted, saved in the mesh, and do not change while a vehicle drives.
- **What is *switched on*** (a signal): the driver's and the vehicle's controls at one moment, such as the low beams, a turn signal, the brake. Signals change every frame of an animation and are never saved in the mesh.
- **Whether something is so** (a flag): a true or false setting passed in or out, such as "show the ground" or "draw it hidden".

Sean's style (12:12): prefix the names that cross function boundaries so a reader knows the kind at a glance: `label...` for labels, `signal...` for signals, `flag...` (or `flag_...`) for flags. AnimateCar3D and later repos will take these names as given ("this repo will force naming acceptance by other repos", Sean, 10:36).

## 2. The prefixes (proposed rules)

| Prefix | For | Example names | Not for |
|---|---|---|---|
| `label` | A face's part or lamp kind, and anything that stores or chooses labels | `labelPart`, `labelLamp`, `labelGlass`, `labelTailBrakeLamp` | what is lit |
| `signal` | A control's state at one moment: on/off, low/high, 0 to 1 | `signalLowBeam`, `signalTurnLeft`, `signalBrake` | what a face is |
| `flag` | A true/false setting or result | `flagShowGround`, `flagNight`, `flagVisible` | a 0-to-1 amount (that is a signal or a plain number) |
| `unit` (kept) | One physical lamp of a vehicle (front-left headlamp) | `unitNames`, `UnitPatches` | a lamp *kind* |

- R1. The prefix goes on **names**: option names, struct fields, hook names, saved field names and variables passed in or out. **String values** (a mesh's saved lamp keys such as `'tailBrakeLamp'`, a part name such as `'glass'`) keep the names Q92 gave them: they are the *values* of a label, not variable names.
- R2. Inside a function, variables follow the same prefixes as a file is touched (not a separate sweep), unless Sean asks for a sweep. **(Decision D3 below.)**
- R3. Lamp *units* keep their own names (they are things, not labels or signals).
- R4. Names that are none of the three (sizes, colors, files, handles) keep their names.

## 3. Decisions for Sean (mark one in each)

- **D1. Case of option names.** MATLAB Name=Value options in this repo are UpperCamelCase (`ShowEdges=true`). With prefixes, the choices:
  - (a) `FlagShowEdges=true`, `SignalLowBeam=true` (prefix capitalized, matching the other options; Claude's recommendation);
  - (b) `flagShowEdges=true` (prefix lowercase; options would then mix cases);
  - (c) `flag_ShowEdges=true` (Sean's underscore form).
- **D2. Signals as one struct or as options.** Today plotVehicle takes `LightStates=struct('Headlights','low','TurnLeft',true)`. The choices:
  - (a) keep one struct, renamed `Signals`, with prefixed fields: `Signals=struct('signalLowBeam',true,'signalTurnLeft',true)` (Claude's recommendation: one input, easy to pass frame by frame from AnimateCar3D);
  - (b) one option per signal: `SignalLowBeam=true, SignalTurnLeft=true`.
- **D3. Variables inside functions:** (a) renamed as each file is touched (recommended); (b) one sweep now.
- **D4. `Headlights` ('off'/'low'/'high') and `Tail` ('off'/'on'/'brake'):** these older text-valued signals overlap the newer true/false ones (`LowBeam`, `HighBeam`, `Brake`, `Parking`). Choices: (a) drop them, keeping only the true/false signals of the lamp-to-function matrix (recommended: one meaning per name); (b) keep both.

## 4. Mesh fields (saved in every mesh and detail level)

Each row: today's name, the proposed name, and how it is used.

| Today | Proposed | Kind |
|---|---|---|
| `PartNames` | `labelPartNames` | label |
| `FacePartIndex` | `labelFacePart` | label |
| `FaceAlsoParts` | `labelFaceAlsoParts` | label |
| `LightTypeNames` | `labelLampNames` | label |
| `FaceLightType` | `labelFaceLamp` | label |
| `FaceLightFunctions` | `labelFaceAlsoLamps` | label |
| `FaceCoverLamp` | `labelFaceCoverLamp` | label |
| `TextureColorParts` | `labelTextureColorParts` | label |
| `InteriorObjectNames`, `FaceInteriorObject` | `labelInteriorNames`, `labelFaceInterior` | label |
| `FaceHiddenSet`, `HiddenSetNames` | `labelFaceHiddenSet`, `labelHiddenSetNames` | label |
| `LampSwitching` | `signalLampSwitching` | signal (per vehicle) |
| `SeeThroughReliable` | `flagSeeThroughReliable` | flag |

**`labelPartNames` (today `PartNames`).** The list of part names a mesh's faces can have, in a fixed order: `{'body';'glass';'wheel';'light';'trim';'interior'}` (older meshes may stop at 'trim'). A face's part is stored as an index into this list (`labelFacePart`), so the list must not be reordered. Set when a mesh is built (fcn_CarMesh3D_labelParts) and extended (never reordered) when a part is first used. Read by every plot, the viewer, the painter and AnimateCar3D's tinting.

**`labelFacePart` (today `FacePartIndex`).** One number per face (M x 1): the index of that face's main part in `labelPartNames`. Set by fcn_CarMesh3D_labelParts at build time and changed by the painter and fcn_CarMesh3D_editLabels. Decides each face's color by part, which faces are glass (see-through), and which are lamps (the 'light' part).

**`labelFaceAlsoParts` (today `FaceAlsoParts`).** M x P true/false: the *other* parts a face also belongs to besides its main one (a lamp lens that is also glass). Set by the painter's "also" labels and editLabels' `AlsoParts`. Read where a face must act as two parts at once (glass while a lamp is off).

**`labelLampNames` (today `LightTypeNames`).** The list of lamp kinds a lamp face can have, in the fixed order of fcn_CarMesh3D_lampTypes: `headlamp, turnSignalLamp, runningLamp, tailBrakeLamp, backupLamp, highBeamLamp, fogLamp, reflector, licensePlateLamp, markerLamp, warningLamp` (the Q92 keys). New kinds are only ever added at the end. Read wherever a lamp kind is turned into a name or a color.

**`labelFaceLamp` (today `FaceLightType`).** One number per face: 0 for a face that is not a lamp (or a lamp of no kind yet), else the index of its lamp kind in `labelLampNames`. Set by labelParts (from material and group names, then position) and by the painter. Together with the lamp units (fcn_CarMesh3D_lampUnits) it decides which faces light for which signal.

**`labelFaceAlsoLamps` (today `FaceLightFunctions`).** M x K true/false: the *other* lamp kinds a lamp face also is (one lamp that is both tail/brake and turn signal). Set by editLabels' `AlsoLightTypes` and the painter. Read by fcn_CarMesh3D_lampUnits, so such a face joins the units of each kind it is.

**`labelFaceCoverLamp` (today `FaceCoverLamp`).** One number per face: for a clear cover over a lamp (glass that is also a lamp's lens), the lamp kind it covers, else 0. Set by fcn_CarMesh3D_findLampCovers and the painter. Read by plotVehicle, which draws a cover see-through while its lamp is off and solid while it is lit.

**`labelTextureColorParts`.** The parts whose colors came from a texture (so a fix to one face's color should not be spread to the whole part). Set at import; read by the painter and editLabels when they choose a part's usual color.

**`labelInteriorNames`, `labelFaceInterior`.** The interior objects found (seats, steering wheel, console) and, per face, which one it belongs to (0 for none). Set by fcn_CarMesh3D_findInteriorObjects; read by the outline maker and AnimateCar3D's steering wheel.

**`labelFaceHiddenSet`, `labelHiddenSetNames`.** Per face, the hidden set it is in (0 for shown), and the sets' names ('hidden', 'hard top', ...). A hidden face is kept in the mesh but not drawn unless asked for (`ShowHidden`). Set by the painter's Hide and editLabels' `Hide`.

**`signalLampSwitching` (today `LampSwitching`).** A vehicle's own rule for which signals light a lamp kind, where it differs from the default (fog lamps lit with the high beams on some vehicles). A structure with one field per lamp kind, each a list of signal names. Set by hand in a vehicle's build script; read by fcn_CarMesh3D_lampFunctions when it makes the default lamp-to-function matrix. (It is about signals, though it is saved in the mesh.)

**`flagSeeThroughReliable` (today `SeeThroughReliable`).** True when the downloaded model's transparency can be trusted to find the glass. Set at import; read by labelParts, which otherwise finds glass by name and position.

## 5. Signals (what is switched on, at one moment)

Today these are the fields of plotVehicle's `LightStates` and of the viewer's night lamps, and the columns of each vehicle's lamp-to-function matrix (`lampFunctions_<ID>.csv`, from fcn_CarMesh3D_lampSignals).

| Today | Proposed (D2 (a)) | Values |
|---|---|---|
| `LightStates` (the struct) | `Signals` | struct |
| `LowBeam` | `signalLowBeam` | true/false |
| `HighBeam` | `signalHighBeam` | true/false |
| `Running` | `signalRunning` | true/false |
| `Parking` | `signalParking` | true/false |
| `TurnLeft` | `signalTurnLeft` | true/false |
| `TurnRight` | `signalTurnRight` | true/false |
| `Hazards` | `signalHazards` | true/false |
| `Tail` | `signalTail` | true/false (D4 (a)); today 'off'/'on'/'brake' |
| `Brake` | `signalBrake` | true/false |
| `Backup` | `signalBackup` | true/false |
| `FogLights` | `signalFog` | true/false |
| `Reflectors` | `signalReflectors` | 0 to 1 |
| `Headlights` | (dropped, D4 (a)) | today 'off'/'low'/'high' |

**`Signals` (today `LightStates`).** All the signals at one moment, as one structure with any of the fields below (a field left out is off). Given to fcn_CarMesh3D_plotVehicle each frame (AnimateCar3D builds one per vehicle per frame from its motion file), and held by the viewer and the painter for their night view. Never saved in a mesh. A lamp lights when any signal that its unit's row of the lamp-to-function matrix lights is on; its brightness is the largest of those entries.

**`signalLowBeam`, `signalHighBeam`.** The headlamps dipped, and on full. True/false. With `signalHighBeam` on, the low-beam lamps also stay lit (Sean's rule, carried from 'high'). Read by plotVehicle (lamps, glows and the beams' light pools on the ground), the V&V headlight pictures and the lamp-functions window.

**`signalRunning`.** The daytime running lights. True/false. Lights the running lamps and, by default, the marker lamps (FMVSS 108 S7.4).

**`signalParking`.** Parking lights: the vehicle stopped with its lights on. True/false. Lights the front parking lamps, the tail lamps (dim), the license-plate lamp and the marker lamps, by each vehicle's matrix.

**`signalTurnLeft`, `signalTurnRight`.** A turn signal lit (the flashing is the caller's: AnimateCar3D turns it on and off by its own clock). True/false. Lights that side's turn-signal lamps, and on vehicles whose rear turn signal is the tail/brake lamp, that lamp brighter.

**`signalHazards`.** Both turn signals and any warning lamps (beacons). True/false; the same as both turn signals for the turn lamps.

**`signalTail`.** The tail lamps on (dim red), with the headlamps or parking lights. True/false under D4 (a); today a text value 'off'/'on'/'brake', where 'brake' meant bright. Also lights the license-plate lamp.

**`signalBrake`.** The brake pedal pressed: the tail/brake lamps bright, and the high center stop lamp. True/false.

**`signalBackup`.** Reverse gear: the backup lamps. True/false.

**`signalFog`.** The fog lamps switched on (or, on a vehicle whose `signalLampSwitching` says so, with the high beams). True/false.

**`signalReflectors`.** How much outside light reaches the reflectors (another vehicle's headlamps, a street light), 0 (none) to 1 (full). A number, not a flag, so reflectors can glow partly. Set by AnimateCar3D from other vehicles' lamps (change request CR 1).

## 6. Flags passed in or out (options that are true/false)

Proposed under D1 (a). Every one is a setting given to a function, or (marked "out") a result.

| Function(s) | Today | Proposed | How it is used |
|---|---|---|---|
| plotVehicle | `ShowEdges` | `FlagShowEdges` | Draw each face's edges (the Mesh button in the GUIs). |
| plotVehicle | `LightEffects` | `FlagLightEffects` | Draw the glows round lit lamps and the light pools on the ground (night scenes); off for speed. |
| plotVehicle | `ShowHidden` (names, true, false) | `labelShowHidden` | Which hidden sets to draw. Not a flag: it can be a list of set names, so it is a label choice. |
| viewLabels | `ShowTools` | `FlagShowTools` | Show the old tool row inside a host window. |
| viewLabels | `PhotoOptions` | `FlagPhotoOptions` | Show the photo's options under the photo. |
| viewLabels, paintLabels, many | `Visible` | `FlagVisible` | Build the window shown (false: hidden, for tests). |
| viewLabels, paintLabels | `Wait` | `FlagWait` | Wait until the window is closed before returning. |
| viewLabels | `CheckStale` | `FlagCheckStale` | Warn when a vehicle's mesh variable is older than its saved label fixes. |
| viewLabels (state) | ground shown (`SetGround`/`Ground`) | `SetFlagGround`/`FlagGround` | The ground in 1 m squares shown (the Grid button). Starts true in every window. |
| viewLabels (state) | night view (`SetNightView`/`NightView`) | `SetFlagNight`/`FlagNight` | The night scene (the sun/moon button). |
| viewLabels (state) | boundaries (`SetBoundaries`/`Boundaries`) | `SetFlagShowEdges`/`FlagShowEdges` | The faces' edges drawn (the Mesh button); the same meaning as plotVehicle's. |
| paintLabels (state) | `SetMirror`/`Mirror` | `SetFlagMirror`/`FlagMirror` | Paint the mirrored face on the other side too. |
| paintLabels (state) | `SetShowHidden`/`ShowHidden` | `SetFlagShowHidden`/`FlagShowHidden` | Show the hidden faces (magenta) so they can be unhidden. |
| labelParts | `AutoHighBeams` | `FlagAutoHighBeams` | Split each headlamp into low and high beams by position when no high-beam faces are named. |
| labelParts | `LampCovers` | `FlagFindLampCovers` | Find the clear covers over lamps (labelFaceCoverLamp). |
| labelParts | `SeeThroughGlass` | `FlagSeeThroughGlass` | Treat see-through materials as glass. |
| labelParts | `UseMaterialColors` | `FlagUseMaterialColors` | Color faces from their materials (else from their parts). |
| meshWithLabelEdits | `LampFunctions` | `FlagLampFunctions` | Attach the vehicle's lamp-to-function matrix to the mesh it returns. |
| meshWithLabelEdits, loadDetailLevels | `OrientFaces` | `FlagOrientFaces` | Turn faces to agree (outward normals) when loading. |
| meshWithLabelEdits | `Always` | `FlagAlways` | Apply the label fixes even when the mesh looks up to date. |
| loadDetailLevels, loadOutline2D | `MakeIfMissing`, `SaveIfMade` | `FlagMakeIfMissing`, `FlagSaveIfMade` | Build what is missing, and save what was built. |
| simplifyMesh | `ClearWheels`, `KeepOneSided`, `VisibilityCheck` | `FlagClearWheels`, `FlagKeepOneSided`, `FlagVisibilityCheck` | Simplifier switches (see its help). |
| fitMeshToSpec, makeOutline2D, simplifyMesh | `Symmetric` | `FlagSymmetric` | Make the result left-right symmetric. |
| addFloorPanel | `OnlyWhereOpen` | `FlagOnlyWhereOpen` | Add the floor panel only where the model is open from below. |
| fixFlippedFaces | `RemoveDoubleLayers` | `FlagRemoveDoubleLayers` | Remove faces doubled back to back. |
| findInteriorObjects | `Seats`, `SteeringWheel` | `FlagSeats`, `FlagSteeringWheel` | Which interior objects to find. |
| updateCamera | `FollowHeight`, `FollowPitch` | `FlagFollowHeight`, `FlagFollowPitch` | The chase camera follows the vehicle's height and pitch. |
| listVehicles, browseVehicles | `IncludeUnfinished` | `FlagIncludeUnfinished` | List DataSomeday's unfinished vehicles too. |
| editLabels, browseVehicles | `Interactive` | `FlagInteractive` | Open the click-to-select editor. |
| assessAxes | `Dark` | `FlagDark` | Dark axes (the night pictures). |
| answerQueue | `Clipboard`, `Remember` | `FlagClipboard`, `FlagRemember` | Copy Done and NOW to the clipboard; remember the queue folder. |
| runVehicleChecks | `SaveFigs`, `SaveGifs` | `FlagSaveFigs`, `FlagSaveGifs` | Save the check figures and animations. |
| convertPhotos, convertToOBJ | `DryRun`, `Overwrite` | `FlagDryRun`, `FlagOverwrite` | Report only; overwrite existing files. |
| convertPhotos, findInteriorObjects, checkHiddenFaces | `Verbose`, `Quiet` | `FlagVerbose` (Quiet becomes `FlagVerbose=false`) | Print progress. |
| demoVehicle | `Reset`, `UsePreference` | `FlagReset`, `FlagUsePreference` | Forget the remembered demo vehicle; use it. |
| guiRandomWalk | `StopOnFailure` | `FlagStopOnFailure` | Stop a random walk at the first failure. |
| plotSideImage | `SetView`, `ShowVehicle` | `FlagSetView`, `FlagShowVehicle` | Set the camera; draw the vehicle over the image. |
| viewDetailLevels | `Turn` | `FlagTurn` | Turn the lineup slowly. |
| icons, loadCache | `Enabled` | `FlagEnabled` | The button enabled; the cache used. |
| userInfo | `Ask` | `FlagAsk` | Ask for the user's name if not known. |
| lampFunctions | `Save` | `FlagSave` | Save the matrix to the vehicle's CSV. |
| runDemoExample | `Run` | `FlagRun` | Run the example (else only print it). |

## 7. Lamp-unit and label names that stay (for reference)

- Lamp unit names (`'front-left headlamp'`) and their field forms (`front_left_headlamp`) in `UnitPatches`, `LightOffColors`, `CoverPatches`, `Glow`: unchanged (R3).
- `LightPatches` (lamps grouped by kind; fields are the Q92 lamp keys): proposed `labelLampPatches`, since it is grouped by label. **(Sean: keep `LightPatches`, or rename?)**
- Label keys used by the viewer and the painter (`'part_glass'`, `'light_tailBrakeLamp'`): values, unchanged (R1).

## 8. After approval

1. One rename, like Q92: functions, tests, every mesh and detail level (the saved field names in section 4), build scripts, README, design files; AnimateCar3D's calls and its test; no aliases.
2. The README gets a short "Names" section: the three prefixes and this table's link.
3. A test checks that no function's options or a mesh's fields use the old names.

*Sean: mark each decision (D1 to D4) and any row you want different; "approve" when ready.*
