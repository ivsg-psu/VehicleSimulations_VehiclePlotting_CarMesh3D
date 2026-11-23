# Sources: 2026_CarMesh3D_Generic_StationWagon

A **generic station wagon**, not a real vehicle: a template for vehicles of this body style.

- **Numbers** (dimensions, masses, inertias, CG, engine): the average of the 3 vehicles filed under `Data\BodyStyles\StationWagon` that have a vehicleParameters file, each from its own `vehicleParameters_sources.md` (published values, P; calculated, C; or estimates, E):
  - 2014_Volvo_V60_RDesign
  - 2021_Subaru_Outback_LimitedXT
  - 2025_Volkswagen_Golf_RVariantMk8

- **Tire:** 235/40R18: of the markings averaged (225/40R18, 225/60R18, 235/40R18), the one whose diameter (0.645 m) is closest to their mean (0.670 m).
- **Structure** (field names, descriptions, units): from 2021 Subaru Outback LimitedXT.
- **Shape:** the style's approved exemplar (Data\bodyStyles.csv, Exemplars column), refit to these numbers by `fcn_CarMesh3D_fillBodyStyleMesh`.

Averaged fields (values present of vehicles averaged): Mass (3 of 3), MassCurb (3 of 3), MassGross (3 of 3), MassCurbFrontAxle (3 of 3), MassCurbRearAxle (3 of 3), Ixx (3 of 3), IxxCurb (3 of 3), IxxGross (3 of 3), Iyy (3 of 3), IyyCurb (3 of 3), IyyGross (3 of 3), Izz (3 of 3), IzzCurb (3 of 3), IzzGross (3 of 3), DistancesWheelbase (3 of 3), DistancesLength (3 of 3), DistancesFrontOverhang (3 of 3), DistancesRearOverhang (3 of 3), DistancesFrontTrack (3 of 3), DistancesRearTrack (3 of 3), DistancesWidth (3 of 3), DistancesWidthWithMirrors (3 of 3), DistancesHeight (3 of 3), DistancesGroundClearance (3 of 3), DistancesCGFromRearAxle (3 of 3), DistancesCGAboveGround (3 of 3), TireFrontCorneringCoefficient (3 of 3), TireRearCorneringCoefficient (3 of 3), MinimumTurnRadius (3 of 3), EngineDisplacement (3 of 3), EngineCylinders (3 of 3), EnginePeakHorsepower (3 of 3), EngineSpeedAtPeakHorsepower (3 of 3), EngineTorqueAtPeakHorsepower (3 of 3), AccelerationZeroToSixtyTime (3 of 3).

Made 2026-11-22 by Claude for S. Brennan.
