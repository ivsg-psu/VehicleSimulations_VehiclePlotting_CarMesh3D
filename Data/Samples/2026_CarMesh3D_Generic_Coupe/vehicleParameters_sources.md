# Sources: 2026_CarMesh3D_Generic_Coupe

A **generic coupe**, not a real vehicle: a template for vehicles of this body style.

- **Numbers** (dimensions, masses, inertias, CG, engine): the average of the 2 vehicles filed under `Data\BodyStyles\Coupe` that have a vehicleParameters file, each from its own `vehicleParameters_sources.md` (published values, P; calculated, C; or estimates, E):
  - 2006_Ford_Mustang_GT
  - 2012_Honda_Civic_Si

- **Tire:** P235/55ZR17: of the markings averaged (P215/45ZR17, P235/55ZR17), the one whose diameter (0.690 m) is closest to their mean (0.658 m).
- **Structure** (field names, descriptions, units): from 2006 Ford Mustang GT.
- **Shape:** the style's approved exemplar (Data\bodyStyles.csv, Exemplars column), refit to these numbers by `fcn_CarMesh3D_fillBodyStyleMesh`.

Averaged fields (values present of vehicles averaged): Mass (2 of 2), MassCurb (2 of 2), MassGross (2 of 2), MassCurbFrontAxle (2 of 2), MassCurbRearAxle (2 of 2), Ixx (2 of 2), IxxCurb (2 of 2), IxxGross (2 of 2), Iyy (2 of 2), IyyCurb (2 of 2), IyyGross (2 of 2), Izz (2 of 2), IzzCurb (2 of 2), IzzGross (2 of 2), DistancesWheelbase (2 of 2), DistancesLength (2 of 2), DistancesFrontOverhang (2 of 2), DistancesRearOverhang (2 of 2), DistancesFrontTrack (2 of 2), DistancesRearTrack (2 of 2), DistancesWidth (2 of 2), DistancesWidthWithMirrors (2 of 2), DistancesHeight (2 of 2), DistancesGroundClearance (2 of 2), DistancesCGFromRearAxle (2 of 2), DistancesCGAboveGround (2 of 2), TireFrontCorneringCoefficient (2 of 2), TireRearCorneringCoefficient (2 of 2), MinimumTurnRadius (2 of 2), EngineDisplacement (2 of 2), EngineCylinders (2 of 2), EnginePeakHorsepower (2 of 2), EngineSpeedAtPeakHorsepower (2 of 2), EngineTorqueAtPeakHorsepower (2 of 2), AccelerationZeroToSixtyTime (2 of 2).

Made 2026-11-21 by Claude for S. Brennan.
