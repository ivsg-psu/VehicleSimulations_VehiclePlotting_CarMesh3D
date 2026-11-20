# Data

One folder per vehicle, named `YEAR_Make_Model_Trimline` (letters and digits in each part, CamelCase for several words; for example `2014_Ford_TransitConnect_XLTCargoLWB`). Each folder holds:

- `vehicleParameters_<ID>.mat`: the IVSG vehicleParameters structure (with `vehicleParameters_sources.md` noting where each value came from)
- `model/`: the downloaded 3D model (in `model/source/`) and its `LICENSE.txt`
- `script_CarMesh3D_vehicle_<ID>.m`: the standard script, copied from `script_CarMesh3D_vehicle_TEMPLATE.m`
- `vehicleMesh_<ID>.mat`: the finished mesh, made by the script
- `vehicleLevels_<ID>.mat`: the detail levels (lighter versions of the mesh, for animation), made by the script
- `checks/`: the standard check images and GIFs, made by the script

Also here:

- `script_CarMesh3D_vehicle_TEMPLATE.m`: the template for each vehicle's script
- `referenceVehicles.csv`: the list of finished, checked vehicles (written by `fcn_CarMesh3D_addReferenceVehicle`)

See "Adding a vehicle" in the main README for the steps.
