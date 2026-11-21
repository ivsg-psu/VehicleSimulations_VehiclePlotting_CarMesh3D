# Sources: 2026_CarMesh3D_Generic_FullSizeCargoVan

A **generic full-size cargo van**, not a real vehicle: a template for vehicles of this body style.

- **Numbers** (dimensions, masses, inertias, CG, engine): the average of the 1 vehicles filed under `Data\BodyStyles\FullSizeCargoVan` that have a vehicleParameters file, each from its own `vehicleParameters_sources.md` (published values, P; calculated, C; or estimates, E):
  - 2005_Toyota_HiAce_H200DX

- **Tire:** 195/80R15: of the markings averaged (195/80R15), the one whose diameter (0.693 m) is closest to their mean (0.693 m).
- **Structure** (field names, descriptions, units): from 2005 Toyota HiAce H200DX.
- **Shape:** the style's approved exemplar (Data\bodyStyles.csv, Exemplars column), refit to these numbers by `fcn_CarMesh3D_fillBodyStyleMesh`.

Averaged fields (values present of vehicles averaged): Mass (1 of 1), MassCurb (1 of 1), MassGross (1 of 1), MassCurbFrontAxle (1 of 1), MassCurbRearAxle (1 of 1), Ixx (1 of 1), IxxCurb (1 of 1), IxxGross (1 of 1), Iyy (1 of 1), IyyCurb (1 of 1), IyyGross (1 of 1), Izz (1 of 1), IzzCurb (1 of 1), IzzGross (1 of 1), DistancesWheelbase (1 of 1), DistancesLength (1 of 1), DistancesFrontOverhang (1 of 1), DistancesRearOverhang (1 of 1), DistancesFrontTrack (1 of 1), DistancesRearTrack (1 of 1), DistancesWidth (1 of 1), DistancesWidthWithMirrors (1 of 1), DistancesHeight (1 of 1), DistancesGroundClearance (1 of 1), DistancesCGFromRearAxle (1 of 1), DistancesCGAboveGround (1 of 1), TireFrontCorneringCoefficient (1 of 1), TireRearCorneringCoefficient (1 of 1), MinimumTurnRadius (1 of 1), EngineDisplacement (1 of 1), EngineCylinders (1 of 1), EnginePeakHorsepower (1 of 1), EngineSpeedAtPeakHorsepower (1 of 1), EngineTorqueAtPeakHorsepower (1 of 1), AccelerationZeroToSixtyTime (1 of 1).

Made 2026-11-21 by Claude for S. Brennan.
