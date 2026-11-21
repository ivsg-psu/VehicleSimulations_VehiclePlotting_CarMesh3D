# Sources: 2026_CarMesh3D_Generic_StationWagon

A **generic station wagon**, not a real vehicle: a template for vehicles of this body style.

- **Numbers** (dimensions, masses, inertias, CG, engine): the average of the 4 vehicles filed under `Data\BodyStyles\StationWagon` that have a vehicleParameters file, each from its own `vehicleParameters_sources.md` (published values, P; calculated, C; or estimates, E):
  - 2002_Subaru_Outback_Legacy
  - 2014_Volvo_V60_RDesign
  - 2021_Subaru_Outback_LimitedXT
  - 2025_Volkswagen_Golf_RVariantMk8

- **Tire:** 225/60HR16: of the markings averaged (225/40R18, 225/60HR16, 225/60R18, 235/40R18), the one whose diameter (0.676 m) is closest to their mean (0.671 m).
- **Structure** (field names, descriptions, units): from 2021 Subaru Outback LimitedXT.
- **Shape:** the style's approved exemplar (Data\bodyStyles.csv, Exemplars column), refit to these numbers by `fcn_CarMesh3D_fillBodyStyleMesh`.

Averaged fields (values present of vehicles averaged): Mass (4 of 4), MassCurb (4 of 4), MassGross (4 of 4), MassCurbFrontAxle (4 of 4), MassCurbRearAxle (4 of 4), Ixx (4 of 4), IxxCurb (4 of 4), IxxGross (4 of 4), Iyy (4 of 4), IyyCurb (4 of 4), IyyGross (4 of 4), Izz (4 of 4), IzzCurb (4 of 4), IzzGross (4 of 4), DistancesWheelbase (4 of 4), DistancesLength (4 of 4), DistancesFrontOverhang (4 of 4), DistancesRearOverhang (4 of 4), DistancesFrontTrack (4 of 4), DistancesRearTrack (4 of 4), DistancesWidth (4 of 4), DistancesWidthWithMirrors (4 of 4), DistancesHeight (4 of 4), DistancesGroundClearance (4 of 4), DistancesCGFromRearAxle (4 of 4), DistancesCGAboveGround (4 of 4), TireFrontCorneringCoefficient (4 of 4), TireRearCorneringCoefficient (4 of 4), MinimumTurnRadius (4 of 4), EngineDisplacement (4 of 4), EngineCylinders (4 of 4), EnginePeakHorsepower (4 of 4), EngineSpeedAtPeakHorsepower (4 of 4), EngineTorqueAtPeakHorsepower (4 of 4), AccelerationZeroToSixtyTime (4 of 4).

Made 2026-11-21 by Claude for S. Brennan.
