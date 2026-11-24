# 2006 Nissan Frontier SE King Cab

The CarMesh3D mesh of a 2006 Nissan Frontier SE King Cab (a midsize pickup). Its parameters are in `vehicleParameters_2006_Nissan_Frontier_SEKingCab.mat`, and their sources are in `vehicleParameters_sources.md`. The mesh is built by `script_CarMesh3D_vehicle_2006_Nissan_Frontier_SEKingCab.m`.

## The download

- **Source:** "2006 Nissan Frontier" by ActsOfDoge on Sketchfab, https://sketchfab.com/3d-models/2006-nissan-frontier-50bab4a5b1ee4c2e8bc9c268b8d072fa
- **License:** Free Standard. See `model\LICENSE.txt`.
- **File:** `model\source\Nissan_Frontier.glb`. The download was named `2008 Nissan Frontier.glb`; the spaces were removed.

## Left- or right-hand drive? Left; the download is not mirrored

Every CarMesh3D mesh is left-hand drive (Sean, 2026-11-24 10:38). A right-hand-drive download is mirrored at import by setting `importMirror = true` in its script, which calls `fcn_CarMesh3D_mirrorMesh` right after `fcn_CarMesh3D_normalizeMesh`.

**This download is left-hand drive,** so its script has `importMirror = false`. How that was settled, on 2026-11-24:
1. The seat and steering-wheel finder (`fcn_CarMesh3D_findInteriorObjects`), run on the committed mesh, found the wheel on the right (−y; x forward, y left, z up). The download looked right-hand drive, and Sean asked for it to be mirrored (10:38).
2. Mirrored and rebuilt, the mesh then had its wheel on the right. A top-down picture of the dashboard settled it (`Desktop\Claude\Project_CarMesh3D\pictures\frontier_mirror_check.png`): **the download itself, imported and turned but not mirrored, has its steering wheel on the left.**
3. The committed mesh, built 2026-11-22 by an older symmetric build, had **two** steering wheels. That build reduced the left half and mirrored it onto the right, copying the wheel too. The finder then picked the right-hand copy. The symmetric build now keeps one-sided pieces such as the wheel where they are (`KeepOneSided`), so the rebuilt mesh has one wheel, on the left.
