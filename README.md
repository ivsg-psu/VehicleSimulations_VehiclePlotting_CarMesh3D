# CarMesh3D

Sparse, correctly scaled 3D vehicle meshes for plotting and animation in MATLAB.

CarMesh3D turns a 3D model of a vehicle (a free download, or the built-in sample) into a light mesh that:

- matches published dimensions: length, width, height, wheelbase, track, tire size, and front overhang;
- has outward-pointing normals, so lighting looks right;
- has vehicle-like colors with see-through glass;
- animates quickly, because the whole vehicle moves by changing one transform matrix.

The workflow is meant to be simple enough for undergraduate students to make a new vehicle quickly from easy-to-find public data.

> **Status:** prototype (2026_11_19). All test scripts pass in MATLAB R2025b, and FBX conversion was tested with Blender 5.3 on a downloaded model.

---

## Getting started

1. Put this folder somewhere whose path has **no minus signs** (spaces are fine).
2. Open MATLAB (R2021a or newer; written for 2025a/2025b) and run `script_demo_CarMesh3D.m` from this folder.
3. The demo walks through every step for a 2013 Toyota Prius Four and ends with an animation.

There are no MATLAB toolbox dependencies. The demo only adds `Functions` and `Data` to the MATLAB path.

**For FBX, glTF, GLB, or .blend models**, also install [Blender](https://www.blender.org) (free). CarMesh3D finds it in the usual install folders. If Blender is installed somewhere else, run `setenv('CARMESH3D_BLENDER_PATH','<full path to blender.exe>')` once per MATLAB session, or pass `BlenderPath=...`. The converted `.obj` is saved next to the original as `<name>_converted.obj` and reused on later calls.

## Folders

| Folder | Contents |
|---|---|
| (root) | `script_demo_CarMesh3D.m`, the main overview script; this README |
| `Functions` | Core functions `fcn_CarMesh3D_<name>.m`, each with a test script `script_CarMesh3D_<name>.m` |
| `Data` | Vehicle specification files (e.g. `vehicleParameters_2013ToyotaPriusFour.mat`), downloaded models, finished meshes |
| `Images` | Images for this README |

## The workflow

| Step | Function | What it does |
|---|---|---|
| 1. Vehicle spec | `fcn_CarMesh3D_loadVehicleSpec` or `fcn_CarMesh3D_fillVehicleSpec` | Loads an IVSG vehicleParameters `.mat` file, or takes typed-in values. Converts a tire size such as `195/65R15` to a diameter. |
| 2. Shape source | `fcn_CarMesh3D_importMesh` or `fcn_CarMesh3D_fillSampleMesh` | Reads a downloaded OBJ (with materials and groups) or STL, or builds a simple sample car. FBX, glTF, GLB, and .blend files are converted to OBJ first by `fcn_CarMesh3D_convertToOBJ`, which runs Blender in the background. |
| 3. Normalize | `fcn_CarMesh3D_normalizeMesh` | Rotates into the vehicle frame (X forward, Y left, Z up), converts units to meters, and puts the origin on the ground. |
| 4. Label parts | `fcn_CarMesh3D_labelParts` | Marks each face as body, glass, wheel, light, or trim from material and group names. Numbers the wheels FL, FR, RL, RR. Sets colors and glass transparency. |
| 5. Fit to spec | `fcn_CarMesh3D_fitMeshToSpec` | Scales the body to length, width, and height, then stretches it so the axles land at the true wheelbase. Moves each wheel, without stretching it, to the true track and tire diameter. Puts the origin below the rear axle. |
| 6. Simplify | `fcn_CarMesh3D_simplifyMesh` | Merges duplicate vertices, removes bad faces, reduces to a face budget, and makes all normals point outward. |
| 7. Validate | `fcn_CarMesh3D_validateMesh` | Returns a table of target vs. measured dimensions with percent error, plus side, top, and front views. |
| 8. Plot / animate | `fcn_CarMesh3D_plotVehicle` | Draws the mesh as a few patches under one `hgtransform`. Pass `PlotHandles` back in to move the vehicle quickly. |

Labeling comes before fitting so the fit can treat wheels as rigid objects.

### Minimal example

```matlab
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec('Data/vehicleParameters_2013ToyotaPriusFour.mat');
vehicleMesh = fcn_CarMesh3D_importMesh('Data/myDownloadedCar.obj', License='CC0');
vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, UpAxis='+y', ForwardAxis='-z');
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, TargetFaces=3000);
disp(fcn_CarMesh3D_validateMesh(vehicleMesh, vehicleSpec));

h = fcn_CarMesh3D_plotVehicle(vehicleMesh, FigNum=1);
for k = 1:200
    fcn_CarMesh3D_plotVehicle(vehicleMesh, Pose=[0.1*k 0 0], PlotHandles=h, FigNum=-1);
    drawnow limitrate;
end
```

## Calling convention

All functions follow the IVSG convention: required inputs first, then optional inputs as `Name=Value` pairs.

- `FigNum=[]` (or omitted): no plot, except for `fcn_CarMesh3D_plotVehicle`, which plots into the current figure.
- `FigNum=n`: plot results into figure `n`.
- `FigNum=-1`: fast mode, which skips input checks and plots.
- Input checks can also be turned off for every function with the environment variables `MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS` and `MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG`.

Test-script figures are numbered 1xxxx for demos, 2xxxx for tests, 8xxxx for fast mode, and 9xxxx for bugs. Fail conditions are wrapped in `if 1==0` blocks.

## The vehicle frame

Normalized meshes follow ISO 8855: **X forward, Y left, Z up**, in meters, with the tires touching Z = 0. After fitting, the default origin is on the ground below the center of the rear axle (`Origin='center'` is also available).

## The mesh structure

| Field | Size | Set by | Meaning |
|---|---|---|---|
| `Name`, `Source`, `License` | text | import / sample | Where the mesh came from. Always record the license of downloaded models. |
| `Units`, `Frame` | text | import, normalize | `'m'` and `'ISO8855'` after normalizing |
| `Vertices` | N x 3 | all | Vertex positions |
| `Faces` | M x 3 | all | Triangles (indices into `Vertices`) |
| `MaterialNames`, `MaterialColors`, `MaterialAlpha` | K x 1, K x 3, K x 1 | import | Materials from the file (colors are NaN if unknown) |
| `FaceMaterialIndex` | M x 1 | import | Material of each face |
| `GroupNames`, `FaceGroupIndex` | G x 1, M x 1 | import | Group or object of each face |
| `NormalizeInfo` | struct | normalize | Rotation, units scale, offset used |
| `PartNames` | 5 x 1 | label | `{'body';'glass';'wheel';'light';'trim'}` |
| `FacePartIndex` | M x 1 | label | Part of each face |
| `FaceWheelIndex` | M x 1 | label | 0, or 1 FL, 2 FR, 3 RL, 4 RR |
| `FaceColors`, `FaceAlpha` | M x 3, M x 1 | label | Display color and transparency |
| `VehicleSpec`, `AxleX`, `FitInfo` | struct, 1 x 2, struct | fit | Spec used, axle positions, fit details |
| `FaceNormals`, `SimplifyInfo` | M x 3, struct | simplify | Unit outward normals, face counts |

## Vehicle specification files

`fcn_CarMesh3D_loadVehicleSpec` reads IVSG `vehicleParameters` `.mat` files. Values are converted to meters using their `_Units` fields:

| vehicleParameters field | CarMesh3D spec field |
|---|---|
| `DistancesLength` | `OverallLength` |
| `DistancesWidth` | `OverallWidth` |
| `DistancesWidthWithMirrors` | `WidthWithMirrors` |
| `DistancesHeight` | `OverallHeight` |
| `DistancesWheelbase` | `Wheelbase` |
| `DistancesFrontTrack`, `DistancesRearTrack` | `TrackFront`, `TrackRear` |
| `DistancesFrontOverhang` | `FrontOverhang` |
| `DistancesGroundClearance` | `GroundClearance` |
| `TireSidewallMarkings` | `TireSize` (and so `TireDiameter`) |
| `Year`, `Make`, `Model`, `Trim` | `Name` |

If the file also has `DistancesRearOverhang`, the loader warns when it disagrees with length minus wheelbase minus front overhang.

Note: in the Prius file, the `_Text` descriptions of both overhangs say "from the center of the rear axle." The values use the usual definitions (front axle to front bumper, rear axle to rear bumper), and 0.924 + 2.700 + 0.856 = 4.480. The descriptions should probably be corrected.

## Finding models

- **CC0 (no attribution needed):** Kenney.nl, OpenGameArt.org, and itch.io (search "low poly car" and filter by license). These are mostly generic body types; scaling a generic sedan to a specific car's dimensions works well for plots.
- **Sketchfab:** many specific production models are available. Filter by "Downloadable," check the license (usually CC-BY, which requires attribution), and expect dense meshes that need `TargetFaces`.
- OBJ and STL are read directly. FBX, glTF, GLB, and .blend are converted through Blender, which writes Z-up axes. After converting, normalize with `UpAxis='+z'` and check the plot to find the forward axis (often `'-y'` or `'+y'`).
- Very old ASCII FBX files (version 6.1 and earlier) can't be read by Blender.
- **Always check the normalize plot.** Part names in downloaded files can be misleading. In the test model `Car3.fbx`, the parts named "Front" are actually at the rear. The red X arrow must point at the front bumper (headlights, not the wing or taillights).
- **Textures are not read.** Many downloaded models color their surfaces with texture images (materials named `*_Baked`). Those faces get a default color, so use `BodyColor=` in `fcn_CarMesh3D_labelParts`, and `PartRules=` when a big body part has a misleading name (e.g. `PartRules={'Bumper_Front','body'}`).
- Some models have no separate glass, so there is nothing to make transparent.
- Wheel-named parts near the car's centerline (axles, drive shafts) are labeled trim automatically so they don't throw off the wheel positions.

## TO-DO

- Shape from blueprints: extrude traced side, front, and top silhouettes
- Parametric body template as a fallback shape source
- Overlay a side-view photo during validation
- Fitting that accounts for mirrors (published widths usually exclude mirrors; `WidthWithMirrors` is already stored)
- Labeling of STL files by geometry (they have no material names)
- CSV input for many vehicles at once

## License

To be decided by the project owner (IVSG repositories typically use MIT).
