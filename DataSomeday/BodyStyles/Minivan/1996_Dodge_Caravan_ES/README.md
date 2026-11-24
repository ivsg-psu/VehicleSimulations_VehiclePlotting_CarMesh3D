# 1996 Dodge Caravan ES: a someday vehicle

This vehicle was moved out of `Data` into `DataSomeday` on 2026-11-24 (Sean, 11:01), with every vehicle whose download is missing a front seat or the steering wheel. See `DataSomeday/README.md` for the decision and the reasons.

## Why it is here

The seat and steering-wheel finder (`fcn_CarMesh3D_findInteriorObjects`, a build step in every vehicle script since 2026-11-24): **No steering wheel found** (score 0.05: something may be modeled there, but too little of a ring to count). Both front seats were found (2.61, 2.80).

Downloads without these interior parts are likely to need more work by hand and to score low in verification, so they are kept out of the repeated build and test pipeline until someone takes them up.

## What still works, and what does not

- Its files are kept as they were: the script, the finished mesh, the parameters, the checks, and the downloaded model in `model/` (left out of git, as in `Data`).
- `fcn_CarMesh3D_findVehicleFiles`, the library browser and every other tool look only under `Data`, so they no longer list this vehicle, and its script will not run from here.

## To bring it back

Fix what is missing (a better download, or the seats or wheel added), move the folder back to the same place under `Data` (`Data/BodyStyles/<Style>/<ID>` or `Data/Samples/<ID>`), and run its script.
