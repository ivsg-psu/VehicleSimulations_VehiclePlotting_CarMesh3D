# DataSomeday: vehicles set aside for now

This folder sits beside `Data` and holds every vehicle not yet in CarMesh3D's working library, the "someday" vehicles. It has the same layout as `Data`: `DataSomeday/BodyStyles/<Style>/<ID>` for real vehicles and `DataSomeday/Samples/<ID>` for made-up ones.

**What goes here** (Sean, 2026-11-24 11:01 and 11:11):
- **new downloads** (every new vehicle starts here);
- **meshes still being processed**;
- **meshes that miss a core requirement**, above all a download with no front seats or no steering wheel.

The core requirements are listed in the main README, under "What makes a good mesh: the core requirements". A vehicle moves into `Data` only when its mesh meets all of them. A vehicle set aside for a missing requirement has a README.md in its folder saying what is missing.

## The decision (Sean, 2026-11-24 11:01)

> "For vehicles that have no steering wheel or seat, let's put them in a standby folder parallel to the data folder used for vehicles. The reasoning is that the vehicles without the internal features are likely going to require additional processing and are likely to have low verification scores, so we want to keep them out of our repeated processing pipeline. Essentially, for now, these are someday vehicles and perhaps we should even label that parallel folder accordingly."

**The rule.** A vehicle moves here when its download is missing either front seat or the steering wheel. Both are found by `fcn_CarMesh3D_findInteriorObjects`, which became a build step in every vehicle script on 2026-11-24. The animator needs both:
- the seats place the driver's eye for the driver's view;
- the steering wheel turns with the steering (`fcn_CarMesh3D_turnSteeringWheel`).

The 2D outlines also draw both as the vehicle's interior.

**The reasons:**
- A download without these interior parts will likely need more work by hand, such as a better download or parts added.
- It is likely to score low in verification.

Keeping these vehicles out of `Data` keeps them out of the rebuilds and tests that run over the whole library again and again.

**How they are kept out.** Listing every vehicle (`fcn_CarMesh3D_findVehicleFiles('')`) covers `Data` only, so a vehicle here is not listed, built or tested with the library. This covers the library browser, the command-window browser, the body styles' vehicle lists and the library rebuilds. Looked up by its ID, a vehicle here is still found (`IsSomeday` is true), so its own script runs while it is being processed. No list had to be edited, except:
- **`Data/bodyStyles.csv`:** the 2005 HiAce was the `fullSizeCargoVan` style's exemplar and was removed from it. That style has no exemplar until a full-size van with a wheel is added.
- **`.gitignore`:** it leaves out the downloads, caches and check animations here as it does under `Data`.

Everything else in each folder is kept as it was: the script, the finished mesh, the parameters, the checks and the downloaded model.

## The vehicles moved (2026-11-24)

| Vehicle | Missing | Notes |
|---|---|---|
| 2010 Toyota Camry XV40 | both seats and the wheel | the best "seats" were the door openings (score about 1.0, against the 1.5 needed) |
| 2005 Toyota HiAce H200 DX | the wheel | was the `fullSizeCargoVan` exemplar |
| 1996 Dodge Caravan ES | the wheel | scored 0.05: too little of a ring to count |
| 2020 Toyota Supra 3.0 | the wheel | |
| 2023 Honda Accord SE | the wheel | from the finder's first library run; its script is on an older template |
| 2026 CarMesh3D Generic full-size cargo van | the wheel | made-up: the HiAce refit, so it inherits the missing wheel |

Also moved on 2026-11-24 (Sean, 11:11): **all 30 downloads not yet processed** (no finished mesh). These include the first-look scripts of the 2023 Civic Type R, the 2002 Camry XV30 and the 2017 Accord LX, which are on an older template. These folders have no README.md of their own: they are simply not processed yet. Check each one's interior before processing it.

## To move a vehicle into `Data`

1. Process it here (its script runs from this folder) until it meets every core requirement. For a vehicle set aside, fix what is missing: a better download, or the seats or wheel added.
2. Move its folder to the same place under `Data`.
3. Run its script.
4. If it was an exemplar, add it back to `Data/bodyStyles.csv`.

## Large files

Each vehicle's downloaded model lives in its `model/` folder. These folders are left out of git here as under `Data`. The copy in the IVSG large-file storage area is still filed under `Data/...`; move it to the matching `DataSomeday/...` path there when convenient.
