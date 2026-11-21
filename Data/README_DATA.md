# Data

Vehicles are filed by body style:

```
Data/
  BodyStyles/
    Sedan/
      2025_Toyota_Camry_XV80/
    Liftback/
      2013_Toyota_Prius_Four/
    CompactCargoVan/
      2014_Ford_TransitConnect_XLTCargoLWB/
    ...                 (one folder per style in bodyStyles.csv; 22 in all)
  Samples/
    2026_CarMesh3D_Sample_GenericSedan/   (made-up vehicles, not real models)
```

Each vehicle folder is named `YEAR_Make_Model_Trimline` (letters and digits in each part, CamelCase for several words; for example `2014_Ford_TransitConnect_XLTCargoLWB`). An ID may be used by only one folder. `fcn_CarMesh3D_findVehicleFiles(ID)` finds a vehicle wherever it is filed, and its `BodyStyle` comes from the style folder it sits in. Each vehicle folder holds:

- `vehicleParameters_<ID>.mat`: the IVSG vehicleParameters structure (with `vehicleParameters_sources.md` noting where each value came from)
- `model/`: the downloaded 3D model (in `model/source/`) and its `LICENSE.txt`. A fresh download may instead be left directly in the vehicle folder; it is still found (`ModelFiles`).
- `script_CarMesh3D_vehicle_<ID>.m`: the standard script, copied from `script_CarMesh3D_vehicle_TEMPLATE.m`
- `vehicleMesh_<ID>.mat`: the finished mesh, made by the script
- `vehicleLevels_<ID>.mat`: the detail levels (lighter versions of the mesh, for animation), made by the script
- `vehicleOutline_<ID>.mat`: the top-down (2D) outlines (body, upward glass, wheels, lights), made by the script
- `checks/`: the standard check images and GIFs, made by the script

Every vehicle with a finished mesh is an **exemplar** of its style: when a vehicle has no model of its own, `fcn_CarMesh3D_fillBodyStyleMesh` refits the style's exemplar closest in size (length, width, height, wheelbase) to that vehicle's dimensions.

Also here:

- `script_CarMesh3D_vehicle_TEMPLATE.m`: the template for each vehicle's script
- `referenceVehicles.csv`: the list of finished, checked vehicles (written by `fcn_CarMesh3D_addReferenceVehicle`)
- `bodyStyles.csv`: the body styles: ID, name, description, core or optional, and suggested vehicles (read by `fcn_CarMesh3D_loadBodyStyles`). A style's folder is its ID with a capital first letter (`compactCargoVan` is `BodyStyles/CompactCargoVan`).

See "Adding a vehicle" in the main README for the steps.
