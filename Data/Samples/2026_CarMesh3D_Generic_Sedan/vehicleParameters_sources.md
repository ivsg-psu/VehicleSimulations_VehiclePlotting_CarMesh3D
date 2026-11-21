# Sources: 2026_CarMesh3D_Generic_Sedan

A **generic sedan**, not a real vehicle: a template for vehicles of this body style.

- **Numbers** (dimensions, masses, inertias, CG, engine): the average of the 7 vehicles filed under `Data\BodyStyles\Sedan` that have a vehicleParameters file, each from its own `vehicleParameters_sources.md` (published values, P; calculated, C; or estimates, E):
  - 2002_Toyota_Camry_XV30LE
  - 2006_Toyota_Camry_24G
  - 2010_Toyota_Camry_XV40
  - 2013_Honda_Accord_LX
  - 2017_Honda_Accord_LX
  - 2023_Honda_Accord_SE
  - 2025_Toyota_Camry_XV80

- **Tire:** P215/60R16: of the markings averaged (P205/65HR16, P205/65R15, P205/65R16, P205/65VR16, P215/60R16, P225/50VR17), the one whose diameter (0.664 m) is closest to their mean (0.665 m).
- **Structure** (field names, descriptions, units): from 2025 Toyota Camry XV80.
- **Shape:** the style's approved exemplar (Data\bodyStyles.csv, Exemplars column), refit to these numbers by `fcn_CarMesh3D_fillBodyStyleMesh`.

Averaged fields (values present of vehicles averaged): Mass (7 of 7), MassCurb (7 of 7), MassGross (7 of 7), MassCurbFrontAxle (7 of 7), MassCurbRearAxle (7 of 7), Ixx (7 of 7), IxxCurb (7 of 7), IxxGross (7 of 7), Iyy (7 of 7), IyyCurb (7 of 7), IyyGross (7 of 7), Izz (7 of 7), IzzCurb (7 of 7), IzzGross (7 of 7), DistancesWheelbase (7 of 7), DistancesLength (7 of 7), DistancesFrontOverhang (7 of 7), DistancesRearOverhang (7 of 7), DistancesFrontTrack (7 of 7), DistancesRearTrack (7 of 7), DistancesWidth (7 of 7), DistancesWidthWithMirrors (7 of 7), DistancesHeight (7 of 7), DistancesGroundClearance (7 of 7), DistancesCGFromRearAxle (7 of 7), DistancesCGAboveGround (7 of 7), TireFrontCorneringCoefficient (7 of 7), TireRearCorneringCoefficient (7 of 7), MinimumTurnRadius (7 of 7), EngineDisplacement (7 of 7), EngineCylinders (7 of 7), EnginePeakHorsepower (7 of 7), EngineSpeedAtPeakHorsepower (7 of 7), EngineTorqueAtPeakHorsepower (7 of 7), AccelerationZeroToSixtyTime (7 of 7).

Made 2026-11-21 by Claude for S. Brennan.
