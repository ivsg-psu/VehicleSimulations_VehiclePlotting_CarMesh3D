# Sources for vehicleParameters_1999_Ford_F150_XLTSuperCabFlareside.mat

Vehicle: US 1999 F-150 XLT SuperCab Flareside 4x2 (tenth generation), 138.5 in wheelbase, 6.5 ft box, 4.6 L V8. The 3D model is a 1998 F-150 (same generation).

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 1999, Ford, F-150, XLTSuperCabFlareside | P | US 1999 F-150 XLT SuperCab Flareside 4x2 (tenth generation), 138.5 in wheelbase, 6.5 ft box, 4.6 L V8. The 3D model is a 1998 F-150 (same generation). |
| MassCurb, Mass | 1923.7 kg | P | 4,241 lb, Lariat SuperCab Flareside 4x2 (autoblog.com; the XLT is similar) |
| MassCurbFrontAxle | 1096.5 kg | E | Not published; typical front share for an empty pickup (57%) |
| MassCurbRearAxle | 827.2 kg | C | Curb mass - front-axle mass |
| MassGross | 2744.2 kg | P | 6,050 lb (autoblog.com) |
| DistancesWheelbase | 3.518 m | P | 138.5 in (autoblog.com; kbb.com) |
| DistancesLength | 5.702 m | P | 224.5 in (autoblog.com, 1999 SuperCab Flareside 4x2, 138.5 in WB) |
| DistancesWidth | 2.009 m | P | 79.1 in (autoblog.com) |
| DistancesWidthWithMirrors | 2.279 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.849 m | P | 72.8 in (autoblog.com) |
| DistancesGroundClearance | 0.178 m | E | Not published for the 4x2; 7.3 in for the 4x4 SuperCab (edmunds.com) |
| DistancesFrontTrack | 1.670 m | E | Not published by these sources; from the downloaded 3D model (its wheel positions, scaled by the published wheelbase); check |
| DistancesRearTrack | 1.670 m | E | Not published by these sources; from the downloaded 3D model (its wheel positions, scaled by the published wheelbase); check |
| DistancesFrontOverhang | 0.976 m | E | Not published. 45% of the total overhang (length - wheelbase = 2.184 m): the share in the downloaded 3D model (its axle positions); check against a side photo |
| DistancesRearOverhang | 1.208 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 2.005 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.75 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P235/70R16 | P | P235/70R16 (cars.com, 1999 F-150) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 6.17 m | C | Half of the turning diameter: 40.5 ft turning diameter, SuperCab 138.5 in WB (kbb.com) |
| Ixx, IxxCurb / IxxGross | 691 / 969 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 3820 / 4779 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 3968 / 5049 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 4.600 L | P | 4.6 L V8 (auto123.com) |
| EngineCylinders | 8 | P | V8 |
| EnginePeakHorsepower | 220.0 hp | P | 220 hp (auto123.com) |
| EngineSpeedAtPeakHorsepower | 4500 rpm | E | Not looked up: the usual peak speed of this engine |
| EngineTorqueAtPeakHorsepower | 256.8 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 9.0 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
