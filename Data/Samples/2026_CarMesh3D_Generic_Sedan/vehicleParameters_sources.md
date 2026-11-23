# Sources: 2026_CarMesh3D_Generic_Sedan

A **generic sedan**, not a real vehicle: a template for vehicles of this body style.

- **Numbers** (dimensions, masses, inertias, CG, engine): the average of the 8 vehicles filed under `Data\BodyStyles\Sedan` that have a vehicleParameters file, each from its own `vehicleParameters_sources.md` (published values, P; calculated, C; or estimates, E):
  - 2002_Toyota_Camry_XV30LE
  - 2009_Toyota_Corolla_LE
  - 2010_Toyota_Camry_XV40
  - 2011_Ford_Fusion_Sport
  - 2013_Honda_Accord_LX
  - 2017_Honda_Accord_LX
  - 2023_Honda_Accord_SE
  - 2025_Toyota_Camry_XV80

- **Tire:** P225/45VR18: of the markings averaged (P205/55R16, P205/65HR16, P205/65R15, P205/65R16, P205/65VR16, P215/60R16, P225/45VR18, P225/50VR17), the one whose diameter (0.660 m) is closest to their mean (0.660 m).
- **Structure** (field names, descriptions, units): from 2025 Toyota Camry XV80.
- **Shape:** the style's approved exemplar (Data\bodyStyles.csv, Exemplars column), refit to these numbers by `fcn_CarMesh3D_fillBodyStyleMesh`.

Averaged fields (values present of vehicles averaged): Mass (8 of 8), MassCurb (8 of 8), MassGross (8 of 8), MassCurbFrontAxle (8 of 8), MassCurbRearAxle (8 of 8), Ixx (8 of 8), IxxCurb (8 of 8), IxxGross (8 of 8), Iyy (8 of 8), IyyCurb (8 of 8), IyyGross (8 of 8), Izz (8 of 8), IzzCurb (8 of 8), IzzGross (8 of 8), DistancesWheelbase (8 of 8), DistancesLength (8 of 8), DistancesFrontOverhang (8 of 8), DistancesRearOverhang (8 of 8), DistancesFrontTrack (8 of 8), DistancesRearTrack (8 of 8), DistancesWidth (8 of 8), DistancesWidthWithMirrors (8 of 8), DistancesHeight (8 of 8), DistancesGroundClearance (8 of 8), DistancesCGFromRearAxle (8 of 8), DistancesCGAboveGround (8 of 8), TireFrontCorneringCoefficient (8 of 8), TireRearCorneringCoefficient (8 of 8), MinimumTurnRadius (8 of 8), EngineDisplacement (8 of 8), EngineCylinders (8 of 8), EnginePeakHorsepower (8 of 8), EngineSpeedAtPeakHorsepower (8 of 8), EngineTorqueAtPeakHorsepower (8 of 8), AccelerationZeroToSixtyTime (8 of 8).

Made 2026-11-22 by Claude for S. Brennan.
